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
import YubiKit

final class FidoManager {
    static let channelSuffix = "fido"
    static let channelName = "com.yubico.authenticator/\(channelSuffix)"
    private static let resetEventsName = "ios.fido.reset"
    private static let fingerprintEventsName = "ios.fido.registerFingerprint"

    private let managementManager: ManagementManager
    private var methodChannel: FlutterMethodChannel?
    private let resetEvents = FidoEventHandler()
    private let fingerprintEvents = FidoEventHandler()
    private var cachedPin: String?
    private var cachedPinContext: String?
    private var resetTask: Task<Void, Never>?
    private var fingerprintTask: Task<Void, Never>?

    private init(managementManager: ManagementManager) {
        self.managementManager = managementManager
    }

    @discardableResult
    static func register(
        with messenger: FlutterBinaryMessenger,
        managementManager: ManagementManager
    ) -> FidoManager {
        let manager = FidoManager(managementManager: managementManager)
        let methodChannel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
        methodChannel.setMethodCallHandler { [weak manager] call, result in
            manager?.handle(call: call, result: result)
        }
        manager.methodChannel = methodChannel

        let resetChannel = FlutterEventChannel(name: resetEventsName, binaryMessenger: messenger)
        resetChannel.setStreamHandler(manager.resetEvents)
        let fingerprintChannel = FlutterEventChannel(name: fingerprintEventsName, binaryMessenger: messenger)
        fingerprintChannel.setStreamHandler(manager.fingerprintEvents)
        return manager
    }

    private func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
        if let args = call.arguments as? [String: Any],
           let context = args["context"] as? String,
           context != cachedPinContext {
            clearPin()
            cachedPinContext = context
        }
        switch call.method {
        case "getState":
            perform(result: result) { connection in
                try await self.state(from: connection)
            }
        case "setPin":
            guard let args = call.arguments as? [String: Any],
                  let newPin = args["newPin"] as? String else {
                return result(Self.invalidArguments())
            }
            let oldPin = args["pin"] as? String
            perform(result: result) { connection in
                try await self.setPin(newPin, oldPin: oldPin, on: connection)
            }
        case "unlock":
            guard let args = call.arguments as? [String: Any],
                  let pin = args["pin"] as? String else {
                return result(Self.invalidArguments())
            }
            perform(result: result) { connection in
                try await self.unlock(pin, on: connection)
            }
        case "getCredentials":
            perform(result: result) { connection in
                try await self.getCredentials(on: connection)
            }
        case "deleteCredential":
            guard let args = call.arguments as? [String: Any],
                  let credentialId = args["credentialId"] as? String,
                  let data = Self.parseHex(credentialId) else {
                return result(Self.invalidArguments())
            }
            perform(result: result) { connection in
                let session = try await Self.makeSession(connection)
                let token = try await self.token(for: session, permission: .credentialManagement)
                let management = try await session.credentialManagement(token: token)
                try await management.deleteCredential(WebAuthn.CredentialDescriptor(id: data))
                return NSNull()
            }
        case "getFingerprints":
            perform(result: result) { connection in
                try await self.getFingerprints(on: connection)
            }
        case "registerFingerprint":
            startFingerprintRegistration(result: result)
        case "renameFingerprint":
            guard let args = call.arguments as? [String: Any],
                  let templateId = args["templateId"] as? String,
                  let data = Self.parseHex(templateId),
                  let name = args["name"] as? String else {
                return result(Self.invalidArguments())
            }
            perform(result: result) { connection in
                let session = try await Self.makeSession(connection)
                let token = try await self.token(for: session, permission: .bioEnrollment)
                let bio = try await session.bioEnrollment(token: token)
                try await bio.setFriendlyName(name, for: data)
                return ["template_id": templateId, "name": name] as [String: Any]
            }
        case "deleteFingerprint":
            guard let args = call.arguments as? [String: Any],
                  let templateId = args["templateId"] as? String,
                  let data = Self.parseHex(templateId) else {
                return result(Self.invalidArguments())
            }
            perform(result: result) { connection in
                let session = try await Self.makeSession(connection)
                let token = try await self.token(for: session, permission: .bioEnrollment)
                let bio = try await session.bioEnrollment(token: token)
                try await bio.removeEnrollment(data)
                return NSNull()
            }
        case "enableEnterpriseAttestation":
            perform(result: result) { connection in
                let session = try await Self.makeSession(connection)
                let token = try await self.token(for: session, permission: .authenticatorConfig)
                let config = try await session.config(token: token)
                try await config.enableEnterpriseAttestation()
                return NSNull()
            }
        case "getFidoResetProperties":
            result([
                "success": true,
                "long_touch_for_reset": false,
                "transports_for_reset": ["nfc"],
            ])
        case "reset":
            resetTask?.cancel()
            resetTask = Task { await self.reset(result: result) }
        case "cancelReset":
            resetTask?.cancel()
            resetTask = nil
            result(NSNull())
        case "cancelRegisterFingerprint":
            fingerprintTask?.cancel()
            fingerprintTask = nil
            result(NSNull())
        case "clearPin":
            clearPin()
            result(NSNull())
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func perform(
        result: @escaping FlutterResult,
        operation: @escaping @Sendable (any SmartCardConnection) async throws -> Any
    ) {
        Task {
            do {
                let (value, _) = try await managementManager.runApplicationOperation(body: operation)
                await MainActor.run { result(value) }
            } catch {
                await MainActor.run { result(Self.flutterError(for: error)) }
            }
        }
    }

    private func state(from connection: any SmartCardConnection) async throws -> [String: Any] {
        let session = try await Self.makeSession(connection)
        let info = try await session.getInfo()
        let retries = info.options.clientPin == true
            ? try? await session.getPinRetries().retries
            : nil
        let options: [String: Any] = [
            "clientPin": info.options.clientPin.map { $0 as Any } ?? NSNull(),
            "credMgmt": info.options.credentialManagement ?? false,
            "credentialMgmtPreview": info.options.credentialMgmtPreview ?? false,
            "bioEnroll": info.options.bioEnroll.map { $0 as Any } ?? NSNull(),
            "alwaysUv": info.options.alwaysUV ?? false,
            "ep": info.options.enterpriseAttestation ?? NSNull() as Any,
            // iOS currently cannot safely persist the scoped read-only token.
            "perCredMgmtRO": false,
        ]
        return [
            "info": [
                "options": options,
                "min_pin_length": info.minPinLength ?? 4,
                "force_pin_change": info.forcePinChange ?? false,
                "remaining_disc_creds": info.remainingDiscoverableCredentials.map { $0 as Any } ?? NSNull(),
                "long_touch_for_reset": false,
                "transports_for_reset": ["nfc"],
            ],
            "unlocked": cachedPin != nil,
            "unlocked_read": cachedPin != nil,
            "pin_retries": retries ?? NSNull() as Any,
        ]
    }

    private func setPin(
        _ newPin: String,
        oldPin: String?,
        on connection: any SmartCardConnection
    ) async throws -> [String: Any] {
        let session = try await Self.makeSession(connection)
        do {
            if let oldPin {
                try await session.changePin(from: oldPin, to: newPin)
            } else {
                try await session.setPin(newPin)
            }
            cachedPin = newPin
            return ["success": true]
        } catch {
            return try await pinFailure(for: error, session: session)
        }
    }

    private func unlock(
        _ pin: String,
        on connection: any SmartCardConnection
    ) async throws -> [String: Any] {
        let session = try await Self.makeSession(connection)
        do {
            _ = try await token(for: session, permission: nil, pin: pin)
            cachedPin = pin
            return ["success": true]
        } catch {
            cachedPin = nil
            return try await pinFailure(for: error, session: session)
        }
    }

    private func pinFailure(for error: Error, session: CTAP2.Session) async throws -> [String: Any] {
        guard let sessionError = error as? CTAP2.SessionError,
              case let .ctapError(code, _) = sessionError else {
            throw error
        }
        switch code {
        case .pinInvalid, .pinAuthInvalid, .pinBlocked, .pinAuthBlocked:
            let retryResult = try? await session.getPinRetries()
            let retries = retryResult?.retries ?? 0
            return [
                "success": false,
                "pinRetries": retries,
                "authBlocked": code == .pinBlocked || code == .pinAuthBlocked,
            ]
        case .pinPolicyViolation:
            return ["success": false, "pinViolation": true]
        default:
            throw error
        }
    }

    private func getCredentials(on connection: any SmartCardConnection) async throws -> [[String: Any]] {
        let session = try await Self.makeSession(connection)
        let token = try await token(for: session, permission: .credentialManagement)
        let management = try await session.credentialManagement(token: token)
        var credentials = [[String: Any]]()
        for try await rp in management.rps {
            for try await credential in management.credentials(for: rp.rpIdHash) {
                credentials.append([
                    "rp_id": rp.rp.id,
                    "credential_id": Self.hex(credential.credentialId.id),
                    "user_id": Self.hex(credential.user.id),
                    "user_name": credential.user.name ?? "",
                    "display_name": credential.user.displayName ?? NSNull() as Any,
                ])
            }
        }
        return credentials
    }

    private func getFingerprints(on connection: any SmartCardConnection) async throws -> [[String: Any]] {
        let session = try await Self.makeSession(connection)
        let token = try await token(for: session, permission: .bioEnrollment)
        let bio = try await session.bioEnrollment(token: token)
        let enrollments = try await bio.enrollments.enumerate()
        return enrollments.map {
            [
                "template_id": Self.hex($0.templateId),
                "name": $0.friendlyName ?? NSNull() as Any,
            ]
        }
    }

    private func startFingerprintRegistration(result: @escaping FlutterResult) {
        fingerprintTask?.cancel()
        fingerprintTask = Task {
            do {
                let (fingerprint, _) = try await managementManager.runApplicationOperation { connection in
                    try await self.registerFingerprint(on: connection)
                }
                await MainActor.run { result(fingerprint) }
            } catch {
                await MainActor.run { result(Self.flutterError(for: error)) }
            }
            fingerprintTask = nil
        }
    }

    private func registerFingerprint(on connection: any SmartCardConnection) async throws -> [String: Any] {
        let session = try await Self.makeSession(connection)
        let token = try await token(for: session, permission: .bioEnrollment)
        let bio = try await session.bioEnrollment(token: token)
        var fingerprint: [String: Any]?
        for try await sample in bio.enroll() {
            switch sample {
            case .waitingForUser:
                break
            case let .sample(status, remaining):
                fingerprintEvents.send([
                    "status": status == .good ? "capture" : "capture-error",
                    "remaining": remaining,
                    "code": Self.sampleCode(status),
                ])
            case let .completed(templateId, _):
                fingerprint = ["template_id": Self.hex(templateId), "name": NSNull()]
            }
        }
        guard let fingerprint else {
            throw CancellationError()
        }
        return fingerprint
    }

    private func reset(result: @escaping FlutterResult) async {
        do {
            guard !(await managementManager.hasWiredDevice()) else {
                throw FidoOperationError.wiredResetUnsupported
            }
            resetEvents.send("touch")
            try await Task.sleep(for: .milliseconds(500))
            resetEvents.send("wait")
            _ = try await managementManager.runApplicationOperation { connection in
                let session = try await Self.makeSession(connection)
                try await session.reset().value
                return NSNull()
            }
            clearPin()
            await MainActor.run { result(NSNull()) }
        } catch {
            await MainActor.run { result(Self.flutterError(for: error)) }
        }
    }

    private func token(
        for session: CTAP2.Session,
        permission: CTAP2.ClientPin.Permission?,
        pin: String? = nil
    ) async throws -> CTAP2.Token {
        guard let pin = pin ?? cachedPin else {
            throw FidoOperationError.pinRequired
        }
        var actualPermission = permission ?? CTAP2.ClientPin.Permission()
        if permission == nil {
            let options = try await session.getInfo().options
            if options.credentialManagement == true || options.credentialMgmtPreview == true {
                actualPermission.insert(.credentialManagement)
            }
            if options.supportsBioEnroll || options.supportsUserVerificationMgmtPreview {
                actualPermission.insert(.bioEnrollment)
            }
            if options.authenticatorConfig == true {
                actualPermission.insert(.authenticatorConfig)
            }
        }
        let rpId = actualPermission.isEmpty ? "yubico-authenticator.example.com" : nil
        let permissions = actualPermission.isEmpty ? .getAssertion : actualPermission
        return try await session.getPinUVToken(
            using: .pin(pin),
            permissions: permissions,
            rpId: rpId
        )
    }

    private func clearPin() {
        cachedPin = nil
        cachedPinContext = nil
    }

    private static func makeSession(_ connection: any SmartCardConnection) async throws -> CTAP2.Session {
        try await CTAP2.Session.makeSession(connection: connection)
    }

    private static func invalidArguments() -> FlutterError {
        FlutterError(code: "invalid_args", message: "Invalid FIDO arguments", details: nil)
    }

    private static func flutterError(for error: Error) -> FlutterError {
        if let sessionError = error as? CTAP2.SessionError,
           case let .ctapError(code, _) = sessionError {
            let ctapCode: UInt8
            switch code {
            case .notAllowed: ctapCode = 0x30
            case .pinInvalid: ctapCode = 0x31
            case .pinBlocked: ctapCode = 0x32
            case .pinAuthInvalid: ctapCode = 0x33
            case .pinAuthBlocked: ctapCode = 0x34
            case .pinNotSet: ctapCode = 0x35
            case .pinPolicyViolation: ctapCode = 0x37
            case .keepaliveCancel: ctapCode = 0x2d
            case .userActionTimeout: ctapCode = 0x2f
            default: ctapCode = 0x7f
            }
            return FlutterError(
                code: "CtapException",
                message: String(
                    format: "com.yubico.yubikit.core.fido.CtapException: CTAP error: 0x%02x",
                    ctapCode
                ),
                details: nil
            )
        }
        if error is CancellationError {
            return FlutterError(code: "CancellationException", message: "Operation cancelled", details: nil)
        }
        return FlutterError(code: "fido_error", message: String(describing: error), details: nil)
    }

    private static func parseHex(_ value: String) -> Data? {
        guard !value.isEmpty, value.count.isMultiple(of: 2) else { return nil }
        var data = Data()
        var index = value.startIndex
        while index < value.endIndex {
            let next = value.index(index, offsetBy: 2)
            guard let byte = UInt8(value[index..<next], radix: 16) else { return nil }
            data.append(byte)
            index = next
        }
        return data
    }

    private static func hex(_ data: Data) -> String {
        data.map { String(format: "%02x", $0) }.joined()
    }

    private static func sampleCode(_ status: CTAP2.BioEnrollment.SampleStatus) -> Int {
        switch status {
        case .good: 0x00
        case .tooHigh: 0x01
        case .tooLow: 0x02
        case .tooLeft: 0x03
        case .tooRight: 0x04
        case .tooFast: 0x05
        case .tooSlow: 0x06
        case .poorQuality: 0x07
        case .tooSkewed: 0x08
        case .tooShort: 0x09
        case .mergeFailure: 0x0a
        case .exists: 0x0b
        case .noUserActivity: 0x0d
        case .noUserPresenceTransition: 0x0e
        case let .other(code): Int(code)
        }
    }
}

private enum FidoOperationError: Error {
    case pinRequired
    case wiredResetUnsupported
}

private final class FidoEventHandler: NSObject, FlutterStreamHandler {
    private var sink: FlutterEventSink?

    func send(_ event: Any) {
        DispatchQueue.main.async { [weak self] in self?.sink?(event) }
    }

    func onListen(withArguments _: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        sink = events
        return nil
    }

    func onCancel(withArguments _: Any?) -> FlutterError? {
        sink = nil
        return nil
    }
}
