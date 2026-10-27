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
import CommonCrypto
import CryptoTokenKit
import UIKit
import YubiKit

final class PivManager {
    static let channelSuffix = "piv"
    static let channelName = "com.yubico.authenticator/piv"
    private let managementManager: ManagementManager
    private let controller = PivController()
    private var channel: FlutterMethodChannel?
    private var busy = false
    private var backgroundObserver: NSObjectProtocol?

    private init(managementManager: ManagementManager) {
        self.managementManager = managementManager
        backgroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main
        ) { [weak self] _ in self?.onPause() }
    }

    deinit {
        if let backgroundObserver { NotificationCenter.default.removeObserver(backgroundObserver) }
    }

    @discardableResult
    static func register(with messenger: FlutterBinaryMessenger, managementManager: ManagementManager) -> PivManager {
        let manager = PivManager(managementManager: managementManager)
        let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
        channel.setMethodCallHandler { [weak manager] call, result in manager?.handle(call, result: result) }
        manager.channel = channel
        return manager
    }

    private func onPause() { Task { await controller.clear() } }

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let methods = [
            "get", "clearSession", "reset", "authenticate", "verifyPin", "changePin", "changePuk",
            "unblockPin", "setManagementKey", "getSlot", "generate", "importFile", "examineFile",
            "validateRfc4514", "delete", "moveKey",
        ]
        guard methods.contains(call.method) else { return result(FlutterMethodNotImplemented) }
        guard !busy else { return result(FlutterError(code: "busy", message: "A PIV operation is already in progress", details: nil)) }
        busy = true
        let args = call.arguments as? [String: Any] ?? [:]
        Task {
            do {
                let json: String
                if ["clearSession", "examineFile", "validateRfc4514"].contains(call.method) {
                    json = try await controller.local(call.method, args: args)
                } else {
                    (json, _) = try await managementManager.runApplicationOperation { connection in
                        try await self.controller.execute(call.method, args: args, connection: connection)
                    }
                }
                await MainActor.run { self.busy = false; result(json) }
            } catch {
                NSLog("[PivManager] %@ failed: %@", call.method, String(describing: error))
                await MainActor.run { self.busy = false; result(Self.flutterError(error)) }
            }
        }
    }

    private static func flutterError(_ error: Error) -> FlutterError {
        if error is CancellationError {
            return FlutterError(code: "CancellationException", message: "Operation cancelled", details: nil)
        }
        if let error = error as? PIVSessionError, case let .connectionError(connection, _) = error {
            return flutterError(connection)
        }
        if let error = error as? SmartCardConnectionError {
            switch error {
            case .cancelled, .cancelledByUser:
                return FlutterError(code: "CancellationException", message: "NFC scan cancelled", details: nil)
            default: break
            }
        }
        return FlutterError(code: "piv_error", message: error.localizedDescription, details: nil)
    }
}

private actor PivController {
    private var pins: [String: String] = [:]
    private var keys: [String: Data] = [:]
    private var generation = 0
    private let slots: [PIV.Slot] = [.authentication, .signature, .keyManagement, .cardAuth] +
        (0x82...0x95).compactMap { PIV.Slot(rawValue: UInt8($0)) }
    private static let defaultKey = Data([1, 2, 3, 4, 5, 6, 7, 8, 1, 2, 3, 4, 5, 6, 7, 8, 1, 2, 3, 4, 5, 6, 7, 8])

    func clear() { generation += 1; pins.removeAll(); keys.removeAll() }

    func local(_ method: String, args: [String: Any]) throws -> String {
        if method == "clearSession" { clear(); return "{}" }
        if method == "validateRfc4514" {
            do {
                _ = try PivCrypto.distinguishedName(string("data", args))
                return try json(["status": true])
            } catch let error as PivError {
                if case .message = error { return try json(["status": false]) }
                throw error
            }
        }
        do {
            let material = try PivCrypto.parse(PivCrypto.unhex(string("data", args)), password: args["password"] as? String)
            let certificate = try material.certificate()
            return try json([
                "runtimeType": "result", "password": material.encrypted,
                "key_type": material.key.map { PivCrypto.keyType($0.publicKey).rawValue as Any } ?? NSNull(),
                "cert_info": try certificate.map(PivCrypto.certInfo) as Any? ?? NSNull(),
                "public_key_match": NSNull(),
            ])
        } catch PivError.invalidPassword {
            return try json(["runtimeType": "invalidPassword"])
        }
    }

    func execute(_ method: String, args: [String: Any], connection: any SmartCardConnection) async throws -> String {
        let generation = self.generation
        defer {
            if generation != self.generation { pins.removeAll(); keys.removeAll() }
        }
        // Read identity before selecting PIV so an NFC tap cannot modify a different key.
        let management = try await Management.Session.makeSession(connection: connection)
        let info = try await management.getDeviceInfo()
        if let expected = args["serial"] as? Int, info.serialNumber != UInt(expected) {
            throw PivError.message("The scanned YubiKey does not match the selected device")
        }
        let serial = info.serialNumber
        if !["get", "getSlot"].contains(method), serial == 0 || args["serial"] as? Int == nil {
            throw PivError.message("PIV changes require the selected YubiKey to have a readable serial number")
        }
        let context = String(serial)
        var session = try await PIVSession.makeSession(connection: connection)
        var pivman = try await Pivman.read(connection)
        var authenticated = false
        var result: Any = NSNull()

        switch method {
        case "get": break
        case "authenticate":
            let key = try PivCrypto.unhex(string("key", args))
            do {
                try await session.authenticate(with: key)
                keys[context] = key
                authenticated = true
                result = true
            } catch PIVSessionError.authenticationFailed {
                keys.removeValue(forKey: context)
                result = false
            } catch let error where error.responseStatus?.status == .securityConditionNotSatisfied {
                keys.removeValue(forKey: context)
                result = false
            }
        case "verifyPin", "changePin", "changePuk", "unblockPin":
            do {
                if method == "verifyPin" {
                    let pin = try string("pin", args)
                    let status = try await session.verifyPin(pin)
                    switch status {
                    case .success:
                        pins[context] = pin
                        if pivman.protected {
                            try await authorize(session, connection: connection, context: context, pivman: pivman)
                            authenticated = true
                        }
                        result = ["status": "success"]
                    case .fail(let retries):
                        pins.removeValue(forKey: context)
                        result = ["status": "invalid-pin", "attemptsRemaining": retries]
                    case .pinLocked:
                        pins.removeValue(forKey: context)
                        result = ["status": "invalid-pin", "attemptsRemaining": 0]
                    }
                } else if method == "changePin" {
                    let old = try string("pin", args)
                    let new = try string("newPin", args)
                    // Authenticate the derived key before changing the PIN to avoid losing access.
                    if pivman.salt != nil {
                        pins[context] = old
                        try await authorize(session, connection: connection, context: context, pivman: pivman)
                    }
                    try await session.changePin(from: old, to: new)
                    pins[context] = new
                    if pivman.salt != nil {
                        let salt = try random(16)
                        let key = try derive(new, salt: salt)
                        try await verify(session, pin: new)
                        try await setManagementKey(session, connection: connection, key: key, type: .tripleDES)
                        pivman.salt = salt
                        try await pivman.write(connection)
                    }
                    result = ["status": "success"]
                } else if method == "changePuk" {
                    try await session.changePuk(from: string("puk", args), to: string("newPuk", args))
                    result = ["status": "success"]
                } else {
                    guard pivman.salt == nil else {
                        throw PivError.message("A PIN-derived management key cannot be recovered with the PUK; use the original PIN or reset PIV")
                    }
                    let new = try string("newPin", args)
                    try await session.unblockPin(with: string("puk", args), newPin: new)
                    pins[context] = new
                    result = ["status": "success"]
                }
            } catch PIVSessionError.invalidPin(let retries, _) {
                pins.removeValue(forKey: context)
                result = ["status": "invalid-pin", "attemptsRemaining": retries]
            } catch PIVSessionError.pinLocked {
                pins.removeValue(forKey: context)
                result = ["status": "invalid-pin", "attemptsRemaining": 0]
            } catch let error as PIVSessionError {
                if error.responseStatus?.status == .conditionsNotSatisfied {
                    result = ["status": "pin-complexity"]
                } else { throw error }
            }
        case "reset":
            try await session.reset()
            pins.removeValue(forKey: context)
            keys.removeValue(forKey: context)
            session = try await PIVSession.makeSession(connection: connection)
            pivman = try await Pivman.read(connection)
        case "getSlot":
            let (metadata, certificate) = try await readSlot(session, slot: slot(args))
            result = [
                "metadata": metadata.map(serialize) as Any? ?? NSNull(),
                "certificate": certificate.map { PivCrypto.pem("CERTIFICATE", $0.der) } as Any? ?? NSNull(),
            ]
        default:
            // Validate/parse inputs before authenticating or modifying the device.
            let material = method == "importFile"
                ? try PivCrypto.parse(PivCrypto.unhex(string("data", args)), password: args["password"] as? String) : nil
            let certificate = try material?.certificate()
            let generateType = args["generateType"] as? String ?? "publicKey"
            let subject = method == "generate" && generateType != "publicKey"
                ? try PivCrypto.distinguishedName(string("subject", args)) : nil
            let type = method == "generate" ? try keyType(args) : nil
            if method == "generate", type == .x25519, generateType != "publicKey" {
                throw PivError.message("X25519 keys cannot sign certificates or certificate requests")
            }
            let from = method == "generate" && generateType == "certificate" ? try date("validFrom", args) : nil
            let to = method == "generate" && generateType == "certificate" ? try date("validTo", args) : nil
            if let from, let to, to <= from { throw PivError.message("Certificate expiry must follow its start date") }
            if let pin = args["pin"] as? String {
                try await verify(session, pin: pin)
                pins[context] = pin
            }
            try await authorize(session, connection: connection, context: context, pivman: pivman)
            authenticated = true
            switch method {
            case "setManagementKey":
                let key = try PivCrypto.unhex(string("key", args))
                guard let raw = args["keyType"] as? UInt8, let type = PIV.ManagementKeyType(rawValue: raw) else {
                    throw PivError.message("Invalid management key type")
                }
                let expectedLength = type == .aes128 ? 16 : (type == .aes256 ? 32 : 24)
                guard key.count == expectedLength else { throw PivError.message("Invalid management key length") }
                let store = args["storeKey"] as? Bool == true
                if store { try await verify(session, pin: pinForOperation(session, context: context)) }
                var protectedFields = pivman.stored || store ? try await Pivman.protectedFields(connection) : []
                try await setManagementKey(session, connection: connection, key: key, type: type)
                keys[context] = key
                pivman.salt = nil
                pivman.stored = store
                try await pivman.write(connection)
                if store || !protectedFields.isEmpty {
                    protectedFields.removeAll { $0.tag == 0x89 }
                    if store { protectedFields.append(TKBERTLVRecord(tag: 0x89, value: key)) }
                    try await Pivman.put(connection, id: Data([0x5f, 0xc1, 0x09]),
                                         value: PivCrypto.tlv(0x88, protectedFields.reduce(Data()) { $0 + $1.data }))
                }
            case "generate":
                guard let type, ["publicKey", "csr", "certificate"].contains(generateType) else {
                    throw PivError.message("Invalid key generation parameters")
                }
                let slot = try slot(args)
                let policy = try pinPolicy(args)
                let signingPin = subject != nil && policy != .never
                    ? try await pinForOperation(session, context: context) : nil
                if let signingPin { try await verify(session, pin: signingPin) }
                let key = try await session.generateKey(in: slot, type: type, pinPolicy: policy, touchPolicy: touchPolicy(args))
                var document = PivCrypto.pem("PUBLIC KEY", key.spki)
                if let subject {
                    if let signingPin { try await verify(session, pin: signingPin) }
                    let data = try await PivCrypto.generateDocument(
                        session: session, slot: slot, key: key, subject: subject, validFrom: from, validTo: to
                    )
                    document = PivCrypto.pem(generateType == "csr" ? "CERTIFICATE REQUEST" : "CERTIFICATE", data)
                    if generateType == "certificate" {
                        try await session.putCertificate(X509Cert(der: data), in: slot)
                        try await updateChuid(connection)
                    }
                }
                result = ["generate_type": generateType, "public_key": PivCrypto.pem("PUBLIC KEY", key.spki), "result": document]
            case "importFile":
                guard let material else { throw PivError.message("Missing key material") }
                let slot = try slot(args)
                if let key = material.key {
                    let pin = try pinPolicy(args)
                    let touch = try touchPolicy(args)
                    switch key {
                    case .rsa(let key): _ = try await session.putPrivateKey(key, in: slot, pinPolicy: pin, touchPolicy: touch)
                    case .ec(let key): _ = try await session.putPrivateKey(key, in: slot, pinPolicy: pin, touchPolicy: touch)
                    case .ed25519(let key): _ = try await session.putPrivateKey(key, in: slot, pinPolicy: pin, touchPolicy: touch)
                    case .x25519(let key): _ = try await session.putPrivateKey(key, in: slot, pinPolicy: pin, touchPolicy: touch)
                    }
                }
                if let certificate {
                    try await session.putCertificate(certificate, in: slot)
                    try await updateChuid(connection)
                }
                let (metadata, _) = try await readSlot(session, slot: slot)
                result = [
                    "metadata": metadata.map(serialize) as Any? ?? NSNull(),
                    "public_key": material.key.map { PivCrypto.pem("PUBLIC KEY", $0.publicKey.spki) } as Any? ?? NSNull(),
                    "certificate": certificate.map { PivCrypto.hex($0.der) } as Any? ?? NSNull(),
                ]
            case "delete":
                let slot = try slot(args)
                let cert = args["deleteCert"] as? Bool == true
                let key = args["deleteKey"] as? Bool == true
                guard cert || key else { throw PivError.message("Select a certificate or private key to delete") }
                if key, !(await session.supports(.moveDelete)) { throw PivError.message("Deleting private keys requires firmware 5.7 or later") }
                if cert { try await session.deleteCertificate(in: slot); try await updateChuid(connection) }
                if key { try await session.deleteKey(in: slot) }
            case "moveKey":
                let source = try slot(args)
                let destination = try slot(args, name: "destination")
                guard source != destination else { throw PivError.message("Source and destination slots must differ") }
                guard await session.supports(.moveDelete) else { throw PivError.message("Moving private keys requires firmware 5.7 or later") }
                let includeCertificate = args["includeCertificate"] as? Bool == true
                let (sourceMetadata, sourceCert) = try await readSlot(session, slot: source)
                guard sourceMetadata != nil else { throw PivError.message("The source slot has no private key") }
                if includeCertificate && sourceCert == nil { throw PivError.message("The source slot has no certificate to move") }
                let destinationMetadata = try await readSlot(session, slot: destination).0
                if destinationMetadata != nil {
                    guard args["overwriteKey"] as? Bool == true else { throw PivError.message("The destination slot already contains a private key") }
                    try await session.deleteKey(in: destination)
                }
                try await session.moveKey(from: source, to: destination)
                if includeCertificate, let sourceCert {
                    try await session.putCertificate(sourceCert, in: destination)
                    try await session.deleteCertificate(in: source)
                    try await updateChuid(connection)
                }
            default: throw PivError.message("Unknown PIV operation")
            }
        }
        return try await snapshot(session, connection: connection, pivman: pivman, authenticated: authenticated, result: result)
    }

    private func authorize(_ session: PIVSession, connection: any SmartCardConnection, context: String, pivman: Pivman) async throws {
        if pivman.protected {
            let pin = try await pinForOperation(session, context: context)
            try await verify(session, pin: pin)
            let key: Data
            if let salt = pivman.salt { key = try derive(pin, salt: salt) }
            else {
                guard let stored = try await Pivman.protectedFields(connection).first(where: { $0.tag == 0x89 }) else {
                    throw PivError.message("Protected management key is missing")
                }
                key = stored.value
            }
            try await session.authenticate(with: key)
            try await verify(session, pin: pin)
        } else {
            try await session.authenticate(with: keys[context] ?? Self.defaultKey)
        }
    }

    private func verify(_ session: PIVSession, pin: String) async throws {
        switch try await session.verifyPin(pin) {
        case .success: break
        case .fail(let attempts): throw PivError.message("Incorrect PIV PIN (\(attempts) attempts remaining)")
        case .pinLocked: throw PivError.message("The PIV PIN is blocked")
        }
    }

    private func pinForOperation(_ session: PIVSession, context: String) async throws -> String {
        if let pin = pins[context] { return pin }
        if await session.supports(.metadata), try await session.getPinMetadata().isDefault { return "123456" }
        throw PivError.message("Verify the PIV PIN again before performing this operation")
    }

    private func readSlot(_ session: PIVSession, slot: PIV.Slot) async throws -> (PIV.SlotMetadata?, X509Cert?) {
        var metadata: PIV.SlotMetadata?
        if await session.supports(.metadata) {
            do { metadata = try await session.getMetadata(in: slot) }
            catch let error where error.responseStatus?.status == .referencedDataNotFound || error.responseStatus?.status == .fileNotFound {}
        }
        var certificate: X509Cert?
        do { certificate = try await session.getCertificate(in: slot) }
        catch let error where error.responseStatus?.status == .fileNotFound || error.responseStatus?.status == .referencedDataNotFound {}
        return (metadata, certificate)
    }

    private func snapshot(_ session: PIVSession, connection: any SmartCardConnection, pivman: Pivman,
                          authenticated: Bool, result: Any) async throws -> String {
        let version = await session.version
        let supportsBio: Bool
        do {
            _ = try await session.getBioMetadata()
            supportsBio = true
        } catch let error where [.referencedDataNotFound, .fileNotFound, .incorrectParameters,
                                 .wrongParametersP1P2, .invalidInstruction].contains(error.responseStatus?.status) {
            supportsBio = false
        }
        var metadata: Any = NSNull()
        let attempts: Int
        if await session.supports(.metadata) {
            let key = try await session.getManagementKeyMetadata()
            let pin = try await session.getPinMetadata()
            let puk = try await session.getPukMetadata()
            attempts = pin.retriesRemaining
            metadata = [
                "management_key_metadata": ["key_type": key.keyType.rawValue, "default_value": key.isDefault, "touch_policy": key.touchPolicy.rawValue],
                "pin_metadata": serialize(pin), "puk_metadata": serialize(puk),
            ]
        } else {
            let response = try await connection.send(data: Data([0, 0x20, 0, 0x80]))
            guard response.count >= 2 else { throw PivError.message("Incomplete PIV PIN status") }
            let sw = response.suffix(2)
            if sw.first == 0x63 { attempts = Int(sw.last! & 0x0f) }
            else if sw == Data([0x69, 0x83]) { attempts = 0 }
            else { throw PivError.message("Could not read PIV PIN retries") }
        }
        var serializedSlots: [[String: Any]] = []
        for slot in slots {
            let (slotMetadata, cert) = try await readSlot(session, slot: slot)
            let certKey = try cert.flatMap(PivCrypto.publicKey)
            serializedSlots.append([
                "slot": slot.rawValue, "metadata": slotMetadata.map(serialize) as Any? ?? NSNull(),
                "cert_info": try cert.map(PivCrypto.certInfo) as Any? ?? NSNull(),
                "public_key_match": slotMetadata.flatMap { m in certKey.map { $0 == m.publicKey } } as Any? ?? NSNull(),
            ])
        }
        return try json([
            "state": [
                "version": [version.major, version.minor, version.micro], "authenticated": authenticated,
                "derived_key": pivman.salt != nil, "stored_key": pivman.stored,
                "pin_attempts": attempts, "supports_bio": supportsBio,
                "chuid": try await Pivman.get(connection, id: Data([0x5f, 0xc1, 0x02])).map(PivCrypto.hex) as Any? ?? NSNull(),
                "ccc": try await Pivman.get(connection, id: Data([0x5f, 0xc1, 0x07])).map(PivCrypto.hex) as Any? ?? NSNull(),
                "metadata": metadata,
            ],
            "slots": serializedSlots, "result": result,
        ])
    }

    private func serialize(_ metadata: PIV.SlotMetadata) -> [String: Any] {
        ["key_type": metadata.keyType.rawValue, "pin_policy": metadata.pinPolicy.rawValue,
         "touch_policy": metadata.touchPolicy.rawValue, "generated": metadata.generated,
         "public_key": PivCrypto.pem("PUBLIC KEY", metadata.publicKey.spki)]
    }

    private func serialize(_ metadata: PIV.PinPukMetadata) -> [String: Any] {
        ["default_value": metadata.isDefault, "total_attempts": metadata.retriesTotal, "attempts_remaining": metadata.retriesRemaining]
    }

    private func slot(_ args: [String: Any], name: String = "slot") throws -> PIV.Slot {
        guard let raw = UInt8(try string(name, args), radix: 16), let slot = PIV.Slot(rawValue: raw), slot != .attestation else {
            throw PivError.message("Invalid PIV slot")
        }
        return slot
    }

    private func keyType(_ args: [String: Any]) throws -> PIV.KeyType {
        guard let raw = args["keyType"] as? UInt8, let type = PIV.KeyType(rawValue: raw) else { throw PivError.message("Invalid PIV key type") }
        return type
    }

    private func pinPolicy(_ args: [String: Any]) throws -> PIV.PinPolicy {
        guard let raw = args["pinPolicy"] as? UInt8, let policy = PIV.PinPolicy(rawValue: raw) else { throw PivError.message("Invalid PIN policy") }
        return policy
    }

    private func touchPolicy(_ args: [String: Any]) throws -> PIV.TouchPolicy {
        guard let raw = args["touchPolicy"] as? UInt8, let policy = PIV.TouchPolicy(rawValue: raw) else { throw PivError.message("Invalid touch policy") }
        return policy
    }

    private func string(_ name: String, _ args: [String: Any]) throws -> String {
        guard let value = args[name] as? String else { throw PivError.message("Missing PIV argument: \(name)") }
        return value
    }

    private func date(_ name: String, _ args: [String: Any]) throws -> Date {
        let text = try string(name, args)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let value = formatter.date(from: text) ?? ISO8601DateFormatter().date(from: text) else { throw PivError.message("Invalid certificate date") }
        return value
    }

    private func json(_ data: [String: Any]) throws -> String {
        String(decoding: try JSONSerialization.data(withJSONObject: data), as: UTF8.self)
    }

    private func random(_ length: Int) throws -> Data {
        var data = Data(count: length)
        let status = data.withUnsafeMutableBytes { SecRandomCopyBytes(kSecRandomDefault, length, $0.baseAddress!) }
        guard status == errSecSuccess else { throw PivError.message("Could not generate random data") }
        return data
    }

    private func derive(_ pin: String, salt: Data) throws -> Data {
        try PivCrypto.deriveKey(password: pin, salt: salt, rounds: 10000, length: 24, prf: CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA1))
    }

    private func setManagementKey(_ session: PIVSession, connection: any SmartCardConnection,
                                  key: Data, type: PIV.ManagementKeyType) async throws {
        if type == .tripleDES, !(await session.supports(.aesKey)) {
            // The SDK currently applies its AES firmware check to 3DES as well.
            let data = Data([type.rawValue]) + PivCrypto.tlv(0x9b, key)
            let response = try await connection.send(data: Data([0, 0xff, 0xff, 0xff, UInt8(data.count)]) + data)
            guard response.suffix(2) == Data([0x90, 0]) else { throw PivError.message("Could not set the PIV management key") }
        } else {
            try await session.setManagementKey(key, type: type, requiresTouch: false)
        }
    }

    private func updateChuid(_ connection: any SmartCardConnection) async throws {
        let fascn = try PivCrypto.unhex("d4e739da739ced39ce739d836858210842108421c84210c3eb")
        let value = PivCrypto.tlv(0x30, fascn) + PivCrypto.tlv(0x34, try random(16)) +
            PivCrypto.tlv(0x35, Data("20300101".utf8)) + PivCrypto.tlv(0x3e, Data()) + PivCrypto.tlv(0xfe, Data())
        try await Pivman.put(connection, id: Data([0x5f, 0xc1, 0x02]), value: value)
    }
}

private struct Pivman {
    var fields: [TKTLVRecord]
    var salt: Data? {
        get { fields.first(where: { $0.tag == 0x82 })?.value }
        set {
            fields.removeAll { $0.tag == 0x82 }
            if let newValue { fields.append(TKBERTLVRecord(tag: 0x82, value: newValue)) }
        }
    }
    var stored: Bool {
        get { (fields.first(where: { $0.tag == 0x81 })?.value.first ?? 0) & 2 != 0 }
        set {
            var flags = fields.first(where: { $0.tag == 0x81 })?.value.first ?? 0
            flags = newValue ? flags | 2 : flags & ~2
            fields.removeAll { $0.tag == 0x81 }
            fields.append(TKBERTLVRecord(tag: 0x81, value: Data([flags])))
        }
    }
    var protected: Bool { stored || salt != nil }

    static func read(_ connection: any SmartCardConnection) async throws -> Pivman {
        let data = try await get(connection, id: Data([0x5f, 0xff, 0]))
        return Pivman(fields: try data.flatMap { $0.isEmpty ? [] : try PivCrypto.children($0, tag: 0x80) } ?? [])
    }

    func write(_ connection: any SmartCardConnection) async throws {
        try await Self.put(connection, id: Data([0x5f, 0xff, 0]),
                           value: PivCrypto.tlv(0x80, fields.reduce(Data()) { $0 + $1.data }))
    }

    static func protectedFields(_ connection: any SmartCardConnection) async throws -> [TKTLVRecord] {
        guard let data = try await get(connection, id: Data([0x5f, 0xc1, 0x09])), !data.isEmpty else { return [] }
        return try PivCrypto.children(data, tag: 0x88)
    }

    // Pivman objects are not exposed by the Swift SDK. These short APDUs use
    // the already-selected PIV application and preserve the SDK authentication.
    static func get(_ connection: any SmartCardConnection, id: Data) async throws -> Data? {
        let command = PivCrypto.tlv(0x5c, id)
        let response = try await connection.send(data: Data([0, 0xcb, 0x3f, 0xff, UInt8(command.count)]) + command + Data([0]))
        guard response.count >= 2 else { throw PivError.message("Incomplete PIV object response") }
        if response.suffix(2) == Data([0x6a, 0x82]) { return nil }
        guard response.suffix(2) == Data([0x90, 0]) else { throw PivError.message("Could not read PIV object (\(PivCrypto.hex(response.suffix(2))))") }
        let records = try PivCrypto.records(Data(response.dropLast(2)))
        guard records.count == 1, records[0].tag == 0x53 else { throw PivError.message("Invalid PIV object response") }
        return records[0].value
    }

    static func put(_ connection: any SmartCardConnection, id: Data, value: Data) async throws {
        let command = PivCrypto.tlv(0x5c, id) + PivCrypto.tlv(0x53, value)
        guard command.count <= 255 else { throw PivError.message("PIV management object is too large") }
        let response = try await connection.send(data: Data([0, 0xdb, 0x3f, 0xff, UInt8(command.count)]) + command)
        guard response.suffix(2) == Data([0x90, 0]) else { throw PivError.message("Could not write PIV management object") }
    }
}
