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

/// MethodChannel + EventChannel handler for the Management application.
///
/// The coordinator retains wired connections and serializes complete operations.
@MainActor
final class ManagementManager: NSObject {
    static let channelSuffix = "management"
    static let channelName = "com.yubico.authenticator/management"
    static let deviceEventsChannelName = "ios.devices.deviceInfo"

    private var methodChannel: FlutterMethodChannel?
    private var deviceEventsChannel: FlutterEventChannel?
    private let deviceEventsHandler = DeviceEventsHandler()
    private let coordinator = UsbCoordinator()
    private var monitorTask: Task<Void, Never>?

    deinit {
        monitorTask?.cancel()
        let coordinator = coordinator
        Task { await coordinator.stop() }
    }

    func stop() async {
        monitorTask?.cancel()
        await coordinator.stop()
        await monitorTask?.value
        monitorTask = nil
        methodChannel?.setMethodCallHandler(nil)
        deviceEventsChannel?.setStreamHandler(nil)
    }

    private func performOperation(
        result: @escaping FlutterResult,
        body: @escaping @MainActor @Sendable () async -> Void
    ) {
        Task {
            do {
                try await coordinator.performOperation(body: body)
            } catch {
                result(FlutterError(
                    code: "busy",
                    message: "Another YubiKey operation is in progress or the manager has stopped.",
                    details: nil
                ))
            }
        }
    }

    @discardableResult
    static func register(with messenger: FlutterBinaryMessenger) -> ManagementManager {
        let manager = ManagementManager()
        manager.attach(messenger: messenger)
        manager.startUsbMonitor()
        return manager
    }

    private func attach(messenger: FlutterBinaryMessenger) {
        let mc = FlutterMethodChannel(name: Self.channelName, binaryMessenger: messenger)
        mc.setMethodCallHandler { [weak self] call, result in
            self?.handle(call: call, result: result)
        }
        methodChannel = mc

        let ec = FlutterEventChannel(name: Self.deviceEventsChannelName, binaryMessenger: messenger)
        ec.setStreamHandler(deviceEventsHandler)
        deviceEventsChannel = ec
    }

    // MARK: - Method dispatch

    private func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
        NSLog("[ManagementManager] received call: \(call.method)")
        switch call.method {
        case "readDeviceInfoNfc":
            performOperation(result: result) { await self.readDeviceInfoOverNfc(result: result) }
        case "configure":
            guard let args = call.arguments as? [String: Any] else {
                return result(invalidArgs())
            }
            performOperation(result: result) { await self.configure(args: args, result: result) }
        case "setMode":
            // YubiKey 4 / NEO firmware setMode is not exposed in yubikit-swift
            // (no Mode/UsbInterface API). Surface as not-implemented for now.
            result(FlutterError(
                code: "unsupported",
                message: "setMode is not supported on iOS",
                details: nil
            ))
        case "deviceReset":
            guard let args = call.arguments as? [String: Any] else {
                return result(invalidArgs())
            }
            performOperation(result: result) { await self.deviceReset(args: args, result: result) }
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Read

    private func readDeviceInfoOverNfc(result: @escaping FlutterResult) async {
        do {
            let info = try await coordinator.withNFCConnection(
                successMessage: "YubiKey detected"
            ) { connection in
                try await Self.readDeviceInfo(from: connection)
            }
            let dict = DeviceInfoSerializer.serialize(info, name: deviceName(info), isNfc: true)
            // Surface the result on the event channel so any UI driven by
            // `iosYubikeyProvider` updates without the caller having to
            // re-feed the value.
            deviceEventsHandler.send(dict)
            await MainActor.run { result(dict) }
        } catch {
            if ManagementOperationError.isCancellation(error) {
                result(NSNull())
                return
            }
            NSLog("[ManagementManager] NFC read error: \(error)")
            await MainActor.run {
                result(FlutterError(
                    code: "yubikit_error",
                    message: String(describing: error),
                    details: nil
                ))
            }
        }
    }

    // MARK: - Write config

    private func configure(args: [String: Any], result: @escaping FlutterResult) async {
        let configMap = (args["config"] as? [String: Any]) ?? [:]
        let currentLockCode = Self.parseHex(args["currentLockCode"])
        let newLockCode = Self.parseHex(args["newLockCode"])
        let reboot = (args["reboot"] as? Bool) ?? false

        let writeOp: @Sendable (any SmartCardConnection, SCPKeyParams?) async throws -> ManagementRefresh<DeviceInfo> = { connection, scpKeyParams in
            let session = try await Management.Session.makeSession(connection: connection, scpKeyParams: scpKeyParams)
            let currentInfo = try await session.getDeviceInfo()
            let newConfig = Self.buildDeviceConfig(from: configMap, base: currentInfo.config)
            let refresh: (@Sendable () async throws -> DeviceInfo)?
            if reboot {
                refresh = nil
            } else {
                refresh = { try await session.getDeviceInfo() }
            }
            return try await ManagementRefresh<DeviceInfo>.perform(
                mutation: {
                    try await session.updateDeviceConfig(
                        newConfig,
                        reboot: reboot,
                        lockCode: currentLockCode,
                        newLockCode: newLockCode
                    )
                },
                refresh: refresh
            )
        }

        do {
            let target = try ManagementTarget(args["expectedDevice"])
            let (refresh, isNfc) = try await runManagementOperation(
                target: target, reconnectWired: reboot, discoverSCP: true, body: writeOp
            )
            publishRefresh(refresh, isNfc: isNfc)
            await MainActor.run { result(NSNull()) }
        } catch {
            if !ManagementOperationError.isCancellation(error) {
                NSLog("[ManagementManager] configure error: \(error)")
            }
            await MainActor.run {
                result(FlutterError(
                    code: ManagementOperationError.isCancellation(error)
                        ? "cancelled" : (error as? ManagementTargetError)?.code ?? "yubikit_error",
                    message: String(describing: error),
                    details: nil
                ))
            }
        }
    }

    // MARK: - Device reset

    private func deviceReset(args: [String: Any], result: @escaping FlutterResult) async {
        let resetOp: @Sendable (any SmartCardConnection, SCPKeyParams?) async throws -> ManagementRefresh<DeviceInfo> = { connection, scpKeyParams in
            let session = try await Management.Session.makeSession(connection: connection, scpKeyParams: scpKeyParams)
            return try await ManagementRefresh.perform(
                mutation: { try await session.resetDevice() },
                refresh: { try await session.getDeviceInfo() }
            )
        }

        do {
            let target = try ManagementTarget(args["expectedDevice"])
            let (refresh, isNfc) = try await runManagementOperation(
                target: target, discoverSCP: true, body: resetOp
            )
            publishRefresh(refresh, isNfc: isNfc)
            await MainActor.run { result(NSNull()) }
        } catch {
            if !ManagementOperationError.isCancellation(error) {
                NSLog("[ManagementManager] deviceReset error: \(error)")
            }
            await MainActor.run {
                result(FlutterError(
                    code: ManagementOperationError.isCancellation(error)
                        ? "cancelled" : (error as? ManagementTargetError)?.code ?? "yubikit_error",
                    message: String(describing: error),
                    details: nil
                ))
            }
        }
    }

    private func publishRefresh(_ refresh: ManagementRefresh<DeviceInfo>, isNfc: Bool) {
        switch refresh {
        case .updated(let info):
            deviceEventsHandler.send(DeviceInfoSerializer.serialize(
                info, name: deviceName(info), isNfc: isNfc
            ))
        case .failed(let error):
            NSLog("[ManagementManager] operation succeeded but metadata refresh failed: \(error)")
            deviceEventsHandler.send(FlutterError(
                code: "metadata_refresh_failed",
                message: "The operation succeeded, but updated YubiKey information could not be read: \(error)",
                details: nil
            ))
        case .pending:
            // Rebooted devices need a reconnect or rescan for fresh metadata.
            if isNfc {
                deviceEventsHandler.send(NSNull())
            } else {
                deviceEventsHandler.clearWiredDevice()
            }
        }
    }

    // MARK: - Routing

    /// Mutations keep the displayed transport and verify the key before execution.
    private func runManagementOperation<T: Sendable>(
        target: ManagementTarget? = nil,
        reconnectWired: Bool = false,
        successMessage: String = "Configuration updated",
        discoverSCP: Bool = false,
        capability: Capability? = nil,
        body: @Sendable @escaping (any SmartCardConnection, SCPKeyParams?) async throws -> T
    ) async throws -> (T, Bool) {
        let useWired: Bool
        if let target {
            useWired = target.transport == .usb
            if useWired {
                guard await coordinator.hasWiredDevice else {
                    throw ManagementTargetError.wiredDeviceUnavailable
                }
            }
        } else {
            useWired = await coordinator.hasWiredDevice
        }
        if useWired {
            let value = try await coordinator.withWiredConnection(reconnect: reconnectWired) { connection in
                if let target {
                    let info = try await Self.readDeviceInfo(from: connection)
                    try target.verify(info)
                }
                return try await body(connection, nil)
            }
            return (value, false)
        } else {
            let value = try await coordinator.withNFCConnection(
                successMessage: successMessage
            ) { connection in
                if target == nil && !discoverSCP {
                    return try await body(connection, nil)
                }
                let info = try await Self.readDeviceInfo(from: connection)
                try target?.verify(info)
                guard discoverSCP else { return try await body(connection, nil) }
                let discoveredParams = try await Self.readSCPKeyParams(from: connection, info: info)
                guard let capability else { return try await body(connection, discoveredParams) }
                // Swift maps the first raw FIPS flag to FIDO2; Android's OTP gate uses that raw flag.
                let capabilityBit = capability == .otp ? Capability.fido2.rawValue : capability.rawValue
                let params = info.fipsCapabilityFlags & capabilityBit != 0 ? discoveredParams : nil
                return try await body(connection, params)
            }
            return (value, true)
        }
    }

    // MARK: - USB monitor

    private func startUsbMonitor() {
        let coordinator = coordinator
        monitorTask = Task {
            await coordinator.startMonitoring(
                onAttach: { [weak self] info in
                    await MainActor.run {
                        guard let self else { return }
                        let dict = DeviceInfoSerializer.serialize(
                            info,
                            name: self.deviceName(info),
                            isNfc: false
                        )
                        self.deviceEventsHandler.send(dict)
                    }
                },
                onDetach: { [weak self] in
                    await MainActor.run {
                        self?.deviceEventsHandler.clearWiredDevice()
                    }
                },
                onError: { [weak self] error in
                    await MainActor.run {
                        self?.deviceEventsHandler.sendWiredError(FlutterError(
                            code: "yubikit_error",
                            message: String(describing: error),
                            details: nil
                        ))
                    }
                }
            )
        }
    }

    // MARK: - Helpers

    nonisolated fileprivate static func readDeviceInfo(from connection: any SmartCardConnection) async throws -> DeviceInfo {
        let session = try await Management.Session.makeSession(connection: connection)
        return try await session.getDeviceInfo()
    }

    nonisolated private static func readSCPKeyParams(
        from connection: any SmartCardConnection,
        info: DeviceInfo
    ) async throws -> SCPKeyParams? {
        guard info.fipsCapabilityFlags != 0 else { return nil }
        let session = try await SecurityDomainSession.makeSession(connection: connection)
        let keyInformation = try await session.getKeyInformation()
        guard let keyRef = keyInformation.keys.first(where: { $0.kid == .scp11b }) else {
            throw SCPError.responseParseError("No SCP11b key is available for this FIPS-capable YubiKey", source: .here())
        }
        let certificates = try await session.getCertificateBundle(for: keyRef)
        guard let publicKey = certificates.last?.publicKey, case let .ec(ecPublicKey) = publicKey else {
            throw SCPError.responseParseError("No usable SCP11b certificate is available for this FIPS-capable YubiKey", source: .here())
        }
        return try SCP11KeyParams(keyRef: keyRef, pkSdEcka: ecPublicKey)
    }

    private func deviceName(_ info: DeviceInfo) -> String {
        if info.isSKY { return "Security Key by Yubico" }
        let suffix = info.isFIPS ? " FIPS" : ""
        return "YubiKey\(suffix)"
    }

    private func invalidArgs() -> FlutterError {
        FlutterError(
            code: "invalid_args",
            message: "Expected map of arguments",
            details: nil
        )
    }

    /// Decodes a hex string (e.g. "0123456789abcdef") into `Data`. Returns nil
    /// if the input is missing, empty, has odd length, or contains non-hex.
    nonisolated fileprivate static func parseHex(_ raw: Any?) -> Data? {
        guard let s = raw as? String, !s.isEmpty, s.count.isMultiple(of: 2) else {
            return nil
        }
        var data = Data(capacity: s.count / 2)
        var index = s.startIndex
        while index < s.endIndex {
            let next = s.index(index, offsetBy: 2)
            guard let byte = UInt8(s[index..<next], radix: 16) else { return nil }
            data.append(byte)
            index = next
        }
        return data
    }

    /// Translates the Dart `DeviceConfig.toJson` payload into a yubikit-swift
    /// `DeviceConfig`. Falls back to fields from `base` when the JSON omits
    /// them (mirrors what the Dart side actually sends today, which is the
    /// full config plus the modified `enabled_capabilities`).
    nonisolated fileprivate static func buildDeviceConfig(
        from json: [String: Any],
        base: DeviceConfig
    ) -> DeviceConfig {
        var enabled: [DeviceTransport: UInt] = base.enabledCapabilities
        if let raw = json["enabled_capabilities"] as? [String: Any] {
            var next: [DeviceTransport: UInt] = [:]
            if let usb = (raw["usb"] as? NSNumber)?.uintValue {
                next[.usb] = usb
            }
            if let nfc = (raw["nfc"] as? NSNumber)?.uintValue {
                next[.nfc] = nfc
            }
            if !next.isEmpty { enabled = next }
        }

        let autoEject: TimeInterval?
        if json.keys.contains("auto_eject_timeout") {
            autoEject = (json["auto_eject_timeout"] as? NSNumber)?.doubleValue
        } else {
            autoEject = base.autoEjectTimeout
        }

        let chalResp: TimeInterval?
        if json.keys.contains("challenge_response_timeout") {
            chalResp = (json["challenge_response_timeout"] as? NSNumber)?.doubleValue
        } else {
            chalResp = base.challengeResponseTimeout
        }

        let flags: UInt8?
        if json.keys.contains("device_flags") {
            flags = (json["device_flags"] as? NSNumber)?.uint8Value
        } else {
            flags = base.deviceFlags
        }

        return DeviceConfig(
            autoEjectTimeout: autoEject,
            challengeResponseTimeout: chalResp,
            deviceFlags: flags,
            enabledCapabilities: enabled,
            isNFCRestricted: base.isNFCRestricted
        )
    }
}

private struct ManagementTarget: Sendable {
    let transport: DeviceTransport
    let serial: UInt?
    let version: [Int]
    let formFactor: Int
    let supportedCapabilities: [DeviceTransport: UInt]
    let isFips: Bool
    let isSky: Bool

    init(_ raw: Any?) throws {
        guard let fields = raw as? [String: Any],
              let transportName = fields["transport"] as? String,
              let version = fields["version"] as? [Int], version.count == 3,
              let formFactor = fields["formFactor"] as? Int,
              let capabilities = fields["supportedCapabilities"] as? [String: Int],
              let isFips = fields["isFips"] as? Bool,
              let isSky = fields["isSky"] as? Bool else {
            throw ManagementTargetError.invalidTarget
        }
        switch transportName {
        case "usb": transport = .usb
        case "nfc": transport = .nfc
        default: throw ManagementTargetError.invalidTarget
        }
        if fields["serial"] is NSNull {
            serial = nil
        } else if let value = fields["serial"] as? Int, value > 0 {
            serial = UInt(value)
        } else {
            throw ManagementTargetError.invalidTarget
        }
        self.version = version
        self.formFactor = formFactor
        self.supportedCapabilities = try Dictionary(uniqueKeysWithValues: capabilities.map { name, value in
            guard let mask = UInt(exactly: value) else {
                throw ManagementTargetError.invalidTarget
            }
            switch name {
            case "usb": return (DeviceTransport.usb, mask)
            case "nfc": return (DeviceTransport.nfc, mask)
            default: throw ManagementTargetError.invalidTarget
            }
        })
        self.isFips = isFips
        self.isSky = isSky
    }

    func verify(_ info: DeviceInfo) throws {
        if let serial {
            guard info.serialNumber == serial else {
                throw ManagementTargetError.deviceChanged
            }
        } else {
            // Without serials, metadata matching cannot distinguish identical keys.
            guard info.serialNumber == 0,
                  version == [Int(info.version.major), Int(info.version.minor), Int(info.version.micro)],
                  formFactor == Int(info.formFactor.rawValue),
                  supportedCapabilities == info.supportedCapabilities,
                  isFips == info.isFIPS,
                  isSky == info.isSKY else {
                throw ManagementTargetError.deviceChanged
            }
        }
    }
}

private enum ManagementTargetError: Error, CustomStringConvertible {
    case invalidTarget
    case deviceChanged
    case wiredDeviceUnavailable

    var code: String {
        switch self {
        case .invalidTarget: "invalid_args"
        case .deviceChanged: "device_changed"
        case .wiredDeviceUnavailable: "device_unavailable"
        }
    }

    var description: String {
        switch self {
        case .invalidTarget: "Expected the selected YubiKey identity and transport."
        case .deviceChanged: "The connected YubiKey does not match the selected device."
        case .wiredDeviceUnavailable: "The selected wired YubiKey is no longer connected."
        }
    }
}

/// Bridges `FlutterEventChannel` to a simple `send(_:)` API. Stores the most
/// recent event so a freshly-attached listener immediately receives the
/// current device state.
@MainActor
private final class DeviceEventsHandler: NSObject, @preconcurrency FlutterStreamHandler {
    private var sink: FlutterEventSink?
    private var lastEvent: Any?
    private var displayedIsNfc = false

    func send(_ event: Any) {
        if let device = event as? [String: Any] {
            displayedIsNfc = device["is_nfc"] as? Bool ?? false
        } else if event is NSNull {
            displayedIsNfc = false
        }
        lastEvent = event
        let hasSink = sink != nil
        NSLog("[DeviceEventsHandler] send (hasSink=\(hasSink))")
        sink?(event)
    }

    func clearWiredDevice() {
        guard !displayedIsNfc else { return }
        send(NSNull())
    }

    func sendWiredError(_ error: FlutterError) {
        guard !displayedIsNfc else { return }
        send(error)
    }

    func onListen(withArguments _: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        NSLog("[DeviceEventsHandler] onListen (hasLastEvent=\(lastEvent != nil))")
        sink = events
        if let lastEvent { events(lastEvent) }
        return nil
    }

    func onCancel(withArguments _: Any?) -> FlutterError? {
        NSLog("[DeviceEventsHandler] onCancel")
        sink = nil
        return nil
    }
}

// MARK: - UsbCoordinator

/// Retains wired connections until disconnect, reboot, or explicit shutdown.
actor UsbCoordinator {
    private var heldConnection: (any SmartCardConnection)?
    private var nfcConnection: NFCSmartCardConnection?
    private var operationInFlight: Bool = false
    private var operationTask: Task<Void, Never>?
    private var idleWaiters: [CheckedContinuation<Void, Never>] = []
    private var stopped = false
    private var connectionGeneration = 0

    var hasWiredDevice: Bool { heldConnection != nil }

    func performOperation(
        body: @escaping @MainActor @Sendable () async -> Void
    ) async throws {
        guard !stopped && !operationInFlight else {
            throw ManagementOperationError.alreadyInProgress
        }
        operationInFlight = true
        defer { finishOperation() }
        let task = Task { await body() }
        operationTask = task
        await task.value
    }

    func stop() async {
        stopped = true
        operationTask?.cancel()
        connectionGeneration += 1
        let wired = heldConnection
        let nfc = nfcConnection
        heldConnection = nil
        nfcConnection = nil
        resumeIdleWaiters()
        await wired?.close(error: CancellationError())
        await nfc?.close(error: CancellationError())
        await operationTask?.value
    }

    func startMonitoring(
        onAttach: @Sendable @escaping (DeviceInfo) async -> Void,
        onDetach: @Sendable @escaping () async -> Void,
        onError: @Sendable @escaping (Error) async -> Void
    ) async {
        var lastConnectionWasUsb = false
        while !stopped && !Task.isCancelled {
            do {
                await waitUntilIdle()
                guard !stopped && !Task.isCancelled else { return }
                let connection = try await WiredSmartCardConnection.makeConnection()
                lastConnectionWasUsb = connection is USBSmartCardConnection
                await waitUntilIdle()
                guard !stopped && !Task.isCancelled else {
                    await connection.close(error: CancellationError())
                    return
                }
                // Reserve the same gate for the initial metadata read.
                operationInFlight = true
                connectionGeneration += 1
                let generation = connectionGeneration
                heldConnection = connection

                do {
                    let info = try await ManagementManager.readDeviceInfo(from: connection)
                    if !stopped { await onAttach(info) }
                } catch {
                    if !stopped && !Task.isCancelled {
                        await onError(error)
                    }
                }
                finishOperation()

                _ = await connection.waitUntilClosed()
                if generation == connectionGeneration {
                    heldConnection = nil
                    await waitUntilIdle()
                    if generation == connectionGeneration && !stopped && !Task.isCancelled {
                        await onDetach()
                    }
                }
            } catch {
                if stopped || Task.isCancelled { return }
                do {
                    try await Task.sleep(for: .seconds(1))
                    guard !stopped && !Task.isCancelled else { return }
                    // Slot discovery can race USB removal. Confirm presence
                    // before treating a failed USB setup as an access error.
                    if lastConnectionWasUsb,
                       let connectionError = error as? SmartCardConnectionError,
                       case .setupFailed = connectionError,
                       try await USBSmartCardConnection.availableDevices().isEmpty {
                        continue
                    }
                } catch {
                    if stopped || Task.isCancelled { return }
                    await onError(error)
                    continue
                }
                NSLog("[UsbCoordinator] monitor error: \(error)")
                await onError(error)
            }
        }
    }

    func withWiredConnection<T: Sendable>(
        reconnect: Bool,
        body: @Sendable @escaping (any SmartCardConnection) async throws -> T
    ) async throws -> T {
        try Task.checkCancellation()
        guard !stopped, let connection = heldConnection else {
            throw ManagementTargetError.wiredDeviceUnavailable
        }
        let value = try await body(connection)
        if reconnect {
            // Reboot invalidates this connection; let the monitor reacquire it.
            connectionGeneration += 1
            heldConnection = nil
            await connection.close(error: nil)
        }
        return value
    }

    func withNFCConnection<T: Sendable>(
        successMessage: String,
        body: @Sendable (NFCSmartCardConnection) async throws -> T
    ) async throws -> T {
        try Task.checkCancellation()
        guard !stopped else { throw CancellationError() }
        let connection = try await NFCSmartCardConnection.makeConnection(
            alertMessage: "Hold your YubiKey near the top of the phone"
        )
        nfcConnection = connection
        do {
            try Task.checkCancellation()
            guard !stopped else { throw CancellationError() }
            let value = try await body(connection)
            await connection.close(message: successMessage)
            nfcConnection = nil
            return value
        } catch {
            await connection.close(error: error)
            nfcConnection = nil
            throw error
        }
    }

    private func waitUntilIdle() async {
        while operationInFlight && !stopped {
            await withCheckedContinuation { idleWaiters.append($0) }
        }
    }

    private func finishOperation() {
        operationTask = nil
        operationInFlight = false
        resumeIdleWaiters()
    }

    private func resumeIdleWaiters() {
        let waiters = idleWaiters
        idleWaiters.removeAll()
        for waiter in waiters { waiter.resume() }
    }
}

enum ManagementOperationError: Error {
    case alreadyInProgress

    static func isCancellation(_ error: Error) -> Bool {
        if error is CancellationError { return true }
        guard let error = error as? SmartCardConnectionError else { return false }
        switch error {
        case .cancelled, .cancelledByUser: return true
        default: return false
        }
    }
}

enum ManagementRefresh<T: Sendable>: Sendable {
    case updated(T)
    case failed(Error)
    case pending

    static func perform(
        mutation: @Sendable () async throws -> Void,
        refresh: (@Sendable () async throws -> T)?
    ) async throws -> Self {
        try await mutation()
        guard let refresh else { return .pending }
        do {
            return .updated(try await refresh())
        } catch {
            return .failed(error)
        }
    }
}
