/*
 * Copyright (C) 2026 Yubico.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *       http://www.apache.org/licenses/LICENSE-2.0
 */

import Flutter
import CryptoKit
import CryptoTokenKit
import Security
import YubiKit

final class OathManager {
    static let channelSuffix = "oath"
    static let channelName = "com.yubico.authenticator/\(channelSuffix)"
    private let managementManager: ManagementManager
    private let controller = OathController()
    private var channel: FlutterMethodChannel?
    private var operationInFlight = false

    private init(managementManager: ManagementManager) {
        self.managementManager = managementManager
    }

    @discardableResult
    static func register(
        with messenger: FlutterBinaryMessenger,
        managementManager: ManagementManager
    ) -> OathManager {
        let manager = OathManager(managementManager: managementManager)
        let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
        channel.setMethodCallHandler { [weak manager] call, result in
            manager?.handle(call, result: result)
        }
        manager.channel = channel
        return manager
    }

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let methods = [
            "get", "unlock", "setPassword", "unsetPassword", "forgetPassword",
            "reset", "calculate", "addAccount", "renameAccount", "deleteAccount",
        ]
        guard methods.contains(call.method) else {
            return result(FlutterMethodNotImplemented)
        }
        guard !operationInFlight else {
            return result(FlutterError(code: "busy", message: "An OATH operation is already in progress", details: nil))
        }
        operationInFlight = true
        let args = call.arguments as? [String: Any] ?? [:]
        Task {
            do {
                let (json, _) = try await managementManager.runApplicationOperation { connection in
                    try await self.controller.execute(call.method, args: args, connection: connection)
                }
                await MainActor.run {
                    self.operationInFlight = false
                    result(json)
                }
            } catch {
                NSLog("[OathManager] %@ failed: %@", call.method, String(describing: error))
                await MainActor.run {
                    self.operationInFlight = false
                    result(Self.flutterError(error))
                }
            }
        }
    }

    private static func flutterError(_ error: Error) -> FlutterError {
        if error is CancellationError {
            return FlutterError(code: "CancellationException", message: "Operation cancelled", details: nil)
        }
        if let connectionError = error as? SmartCardConnectionError {
            switch connectionError {
            case .cancelled, .cancelledByUser:
                return FlutterError(code: "CancellationException", message: "NFC scan cancelled", details: nil)
            default: break
            }
        }
        if let oathError = error as? OATHSessionError,
           case let .connectionError(connectionError, _) = oathError {
            return flutterError(connectionError)
        }
        return FlutterError(code: "oath_error", message: error.localizedDescription, details: nil)
    }
}

private actor OathController {
    private var accessKeys: [String: Data] = [:]

    func execute(
        _ method: String,
        args: [String: Any],
        connection: any SmartCardConnection
    ) async throws -> String {
        var metadata = try await OathMetadata.read(connection)
        if let expectedId = args["deviceId"] as? String, expectedId != metadata.deviceId {
            throw OathError.message("The scanned YubiKey does not match the selected OATH device")
        }
        var session = try await OATHSession.makeSession(connection: connection)
        var locked = metadata.hasKey
        var storedKey = try OathKeychain.read(metadata.deviceId)
        if method != "unlock" && method != "setPassword" && method != "unsetPassword" && method != "reset",
           locked, let key = accessKeys[metadata.deviceId] ?? storedKey {
            do {
                try await session.unlock(accessKey: key)
                accessKeys[metadata.deviceId] = key
                locked = false
            } catch OATHSessionError.invalidPassword {
                accessKeys.removeValue(forKey: metadata.deviceId)
                try OathKeychain.delete(metadata.deviceId)
                storedKey = nil
            }
        }

        var result: Any = NSNull()
        var calculatedId: Data?
        var calculatedCode: [String: Any]?
        switch method {
        case "get":
            break
        case "unlock":
            let password = try string("password", args)
            do {
                let key = try await session.deriveAccessKey(from: password)
                if metadata.hasKey { try await session.unlock(accessKey: key) }
                accessKeys[metadata.deviceId] = metadata.hasKey ? key : nil
                locked = false
                if args["remember"] as? Bool == true && metadata.hasKey {
                    try OathKeychain.save(key, deviceId: metadata.deviceId)
                    storedKey = key
                }
                result = true
            } catch OATHSessionError.invalidPassword {
                result = false
            }
        case "setPassword", "unsetPassword":
            if metadata.hasKey {
                guard let current = args["current"] as? String else {
                    throw OathError.message("The current OATH password is required")
                }
                do {
                    try await session.unlock(password: current)
                    locked = false
                } catch OATHSessionError.invalidPassword {
                    return try await snapshot(
                        session, metadata: metadata, locked: true,
                        remembered: storedKey != nil, result: false
                    )
                }
            }
            if method == "setPassword" {
                let password = try string("password", args)
                guard !password.isEmpty else { throw OathError.message("OATH password must not be empty") }
                let key = try await session.deriveAccessKey(from: password)
                try await session.setAccessKey(key)
                accessKeys[metadata.deviceId] = key
                if storedKey != nil { try OathKeychain.save(key, deviceId: metadata.deviceId) }
                metadata.hasKey = true
            } else {
                try await session.deleteAccessKey()
                try OathKeychain.delete(metadata.deviceId)
                accessKeys.removeValue(forKey: metadata.deviceId)
                storedKey = nil
                metadata.hasKey = false
            }
            locked = false
            result = true
        case "forgetPassword":
            try OathKeychain.delete(metadata.deviceId)
            accessKeys.removeValue(forKey: metadata.deviceId)
            storedKey = nil
        case "reset":
            try await session.reset()
            try OathKeychain.delete(metadata.deviceId)
            accessKeys.removeValue(forKey: metadata.deviceId)
            storedKey = nil
            metadata = try await OathMetadata.read(connection)
            session = try await OATHSession.makeSession(connection: connection)
            locked = metadata.hasKey
        case "addAccount":
            try requireUnlocked(locked)
            let template = try makeTemplate(args)
            let credentials = try await session.listCredentials()
            guard !credentials.contains(where: { $0.id == Data(template.identifier.utf8) }) else {
                throw OathError.message("An OATH account with this name and issuer already exists")
            }
            let credential = try await session.addCredential(template: template)
            result = serialize(credential)
        case "calculate", "renameAccount", "deleteAccount":
            try requireUnlocked(locked)
            let id = try string("credentialId", args)
            let credentials = try await session.calculateCredentialCodes()
            guard let credential = credentials.first(where: { hex($0.0.id) == id })?.0 else {
                throw OathError.message("The OATH account no longer exists on this YubiKey")
            }
            if method == "calculate" {
                let code = try await calculate(session, credential: credential)
                result = code
                calculatedCode = code
                calculatedId = credential.id
            } else if method == "renameAccount" {
                let name = try string("name", args)
                guard !name.isEmpty else { throw OathError.message("OATH account name must not be empty") }
                let issuer = args["issuer"] as? String
                let identifier = credentialIdentifier(name: name, issuer: issuer, type: credential.type)
                try validateIdentifier(identifier)
                guard !credentials.contains(where: { $0.0.id != credential.id && $0.0.id == Data(identifier.utf8) }) else {
                    throw OathError.message("An OATH account with this name and issuer already exists")
                }
                try await session.renameCredential(credential, newName: name, newIssuer: issuer)
                var renamed = serialize(credential)
                renamed["id"] = hex(Data(identifier.utf8))
                renamed["name"] = name
                renamed["issuer"] = issuer.map { $0 as Any } ?? NSNull()
                result = renamed
            } else {
                try await session.deleteCredential(credential)
            }
        default:
            throw OathError.message("Unknown OATH operation")
        }
        return try await snapshot(
            session, metadata: metadata, locked: locked, remembered: storedKey != nil,
            result: result, calculatedId: calculatedId, calculatedCode: calculatedCode
        )
    }

    private func snapshot(
        _ session: OATHSession,
        metadata: OathMetadata,
        locked: Bool,
        remembered: Bool,
        result: Any,
        calculatedId: Data? = nil,
        calculatedCode: [String: Any]? = nil
    ) async throws -> String {
        let version = await session.version
        var pairs: [[String: Any]] = []
        if !locked {
            for (credential, code) in try await session.calculateCredentialCodes() {
                var serializedCode = code.map(serialize)
                if credential.id == calculatedId {
                    serializedCode = calculatedCode
                } else if code != nil && credential.issuer == "Steam" && credential.type.period != nil {
                    serializedCode = try await calculate(session, credential: credential)
                }
                pairs.append([
                    "credential": serialize(credential),
                    "code": serializedCode.map { $0 as Any } ?? NSNull(),
                ])
            }
        }
        let data = try JSONSerialization.data(withJSONObject: [
            "state": [
                "device_id": metadata.deviceId,
                "version": [version.major, version.minor, version.micro],
                "has_key": metadata.hasKey,
                "locked": locked,
                "remembered": remembered,
                "keystore": "allowed",
            ],
            "credentials": pairs,
            "result": result,
        ])
        guard let json = String(data: data, encoding: .utf8) else {
            throw OathError.message("Failed to encode OATH response")
        }
        return json
    }

    private func calculate(_ session: OATHSession, credential: OATHSession.Credential) async throws -> [String: Any] {
        let now = Date()
        if credential.issuer == "Steam", let period = credential.type.period {
            var counter = UInt64(now.timeIntervalSince1970 / period).bigEndian
            let challenge = withUnsafeBytes(of: &counter) { Data($0) }
            let response = try await session.calculateCredentialResponse(for: credential.id, challenge: challenge)
            guard let last = response.last else { throw OathError.message("Empty Steam response") }
            let offset = Int(last & 0x0f)
            guard response.count >= offset + 4 else { throw OathError.message("Invalid Steam response") }
            var number = response.dropFirst(offset).prefix(4).reduce(UInt32(0)) { ($0 << 8) | UInt32($1) } & 0x7fffffff
            let alphabet = Array("23456789BCDFGHJKMNPQRTVWXY")
            var value = ""
            for _ in 0..<5 {
                value.append(alphabet[Int(number % UInt32(alphabet.count))])
                number /= UInt32(alphabet.count)
            }
            let start = Int(now.timeIntervalSince1970 / period) * Int(period)
            return ["value": value, "valid_from": start, "valid_to": start + Int(period)]
        }
        return serialize(try await session.calculateCredentialCode(for: credential, timestamp: now))
    }

    private func serialize(_ credential: OATHSession.Credential) -> [String: Any] {
        [
            "device_id": credential.deviceId,
            "id": hex(credential.id),
            "issuer": credential.issuer.map { $0 as Any } ?? NSNull(),
            "name": credential.name,
            "oath_type": Int(credential.type.code),
            "period": Int(credential.type.period ?? 0),
            "touch_required": credential.requiresTouch,
        ]
    }

    private func serialize(_ code: OATHSession.Code) -> [String: Any] {
        [
            "value": code.code,
            "valid_from": Int(code.validFrom.timeIntervalSince1970),
            "valid_to": code.validTo.timeIntervalSince1970.isFinite ? Int(code.validTo.timeIntervalSince1970) : 0,
        ]
    }

    private func makeTemplate(_ args: [String: Any]) throws -> OATHSession.CredentialTemplate {
        guard let raw = args["credential"] as? [String: Any],
              let name = raw["name"] as? String, !name.isEmpty,
              let secret = raw["secret"] as? FlutterStandardTypedData, !secret.data.isEmpty,
              let algorithmValue = raw["hash_algorithm"] as? UInt8,
              let algorithm = OATHSession.HashAlgorithm(rawValue: algorithmValue),
              let digits = raw["digits"] as? UInt8, (6...8).contains(digits),
              let typeValue = raw["oath_type"] as? Int else {
            throw OathError.message("Invalid OATH credential")
        }
        let type: OATHSession.CredentialType
        if typeValue == 0x20, let period = raw["period"] as? Int, period > 0 {
            type = .totp(period: Double(period))
        } else if typeValue == 0x10, let counter = raw["counter"] as? UInt32 {
            type = .hotp(counter: counter)
        } else {
            throw OathError.message("Invalid OATH type, period or counter")
        }
        let issuer = raw["issuer"] as? String
        try validateIdentifier(credentialIdentifier(name: name, issuer: issuer, type: type))
        return OATHSession.CredentialTemplate(
            type: type, algorithm: algorithm, secret: secret.data, issuer: issuer, name: name,
            digits: digits, requiresTouch: args["requireTouch"] as? Bool ?? false
        )
    }

    private func credentialIdentifier(name: String, issuer: String?, type: OATHSession.CredentialType) -> String {
        let label = issuer.map { "\($0):\(name)" } ?? name
        if let period = type.period, period != 30 { return "\(Int(period))/\(label)" }
        return label
    }

    private func validateIdentifier(_ identifier: String) throws {
        guard !identifier.isEmpty, identifier.utf8.count <= 64 else {
            throw OathError.message("OATH account name and issuer must fit within 64 bytes")
        }
    }

    private func string(_ key: String, _ args: [String: Any]) throws -> String {
        guard let value = args[key] as? String else { throw OathError.message("Missing OATH argument: \(key)") }
        return value
    }

    private func requireUnlocked(_ locked: Bool) throws {
        if locked { throw OathError.message("Unlock OATH before managing accounts") }
    }

    private func hex(_ data: Data) -> String {
        data.map { String(format: "%02x", $0) }.joined()
    }
}

private struct OathMetadata {
    let deviceId: String
    var hasKey: Bool

    static func read(_ connection: any SmartCardConnection) async throws -> OathMetadata {
        // The SDK keeps the OATH salt and lock status private, including on an empty key.
        // Read SELECT metadata before creating the SDK session, which selects again.
        let response = try await connection.send(data: Data([
            0x00, 0xa4, 0x04, 0x00, 0x07, 0xa0, 0x00, 0x00, 0x05, 0x27, 0x21, 0x01,
        ]))
        guard response.count >= 2 else { throw OathError.message("Incomplete OATH SELECT response") }
        guard response.suffix(2) == Data([0x90, 0x00]) else {
            throw OathError.message("Could not select the OATH application")
        }
        guard let records = TKBERTLVRecord.sequenceOfRecords(from: Data(response.dropLast(2))),
              let salt = records.first(where: { $0.tag == 0x71 })?.value else {
            throw OathError.message("Missing OATH device salt")
        }
        let deviceId = Data(SHA256.hash(data: salt).prefix(16))
            .base64EncodedString().replacingOccurrences(of: "=", with: "")
        return OathMetadata(deviceId: deviceId, hasKey: records.contains(where: { $0.tag == 0x74 }))
    }
}

private enum OathKeychain {
    private static let service = "com.yubico.authenticator.oath.access-key"

    private static func query(_ deviceId: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: deviceId,
        ]
    }

    static func read(_ deviceId: String) throws -> Data? {
        var request = query(deviceId)
        request[kSecReturnData as String] = true
        request[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(request as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = result as? Data else {
            throw OathError.message("Could not read the OATH access key from Keychain (\(status))")
        }
        return data
    }

    static func save(_ data: Data, deviceId: String) throws {
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        ]
        var status = SecItemUpdate(query(deviceId) as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            status = SecItemAdd(query(deviceId).merging(attributes) { _, value in value } as CFDictionary, nil)
        }
        guard status == errSecSuccess else {
            throw OathError.message("Could not save the OATH access key in Keychain (\(status))")
        }
    }

    static func delete(_ deviceId: String) throws {
        let status = SecItemDelete(query(deviceId) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw OathError.message("Could not delete the OATH access key from Keychain (\(status))")
        }
    }
}

private enum OathError: LocalizedError {
    case message(String)

    var errorDescription: String? {
        switch self {
        case let .message(message): message
        }
    }
}
