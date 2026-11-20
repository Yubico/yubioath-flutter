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
import OSLog

private let managementLog = Logger(subsystem: "com.yubico.authenticator", category: "management")

/// MethodChannel + EventChannel handler for the Management application.
///
/// The coordinator retains wired connections and serializes complete operations.
@MainActor
final class ManagementManager: NSObject {
    static let channelName = "com.yubico.authenticator/management"
    static let deviceEventsChannelName = "ios.devices.deviceInfo"

    private var methodChannel: FlutterMethodChannel?
    private var deviceEventsChannel: FlutterEventChannel?
    private let deviceEventsHandler = DeviceEventsHandler()
    private let coordinator = ConnectionCoordinator.shared
    private var monitorTask: Task<Void, Never>?

    func stop() async {
        monitorTask?.cancel()
        await coordinator.stop()
        await monitorTask?.value
        monitorTask = nil
        detach()
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

    func register(with messenger: FlutterBinaryMessenger) {
        detach()
        let mc = FlutterMethodChannel(name: Self.channelName, binaryMessenger: messenger)
        mc.setMethodCallHandler { [weak self] call, result in
            self?.handle(call: call, result: result)
        }
        methodChannel = mc

        let ec = FlutterEventChannel(name: Self.deviceEventsChannelName, binaryMessenger: messenger)
        ec.setStreamHandler(deviceEventsHandler)
        deviceEventsChannel = ec

        if monitorTask == nil { startWiredMonitor() }
    }

    private func detach() {
        methodChannel?.setMethodCallHandler(nil)
        deviceEventsChannel?.setStreamHandler(nil)
        deviceEventsHandler.clearSink()
        methodChannel = nil
        deviceEventsChannel = nil
    }

    // MARK: - Method dispatch

    private func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
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
            let device = try await coordinator.withNFCConnection(
                successMessage: "YubiKey detected"
            ) { connection in
                try await Self.readNamedDevice(from: connection)
            }
            deviceEventsHandler.update(device, isNfc: true, scannedNfc: true)
            result(NSNull())
        } catch {
            if ManagementOperationError.isCancellation(error) {
                result(NSNull())
                return
            }
            managementLog.error("NFC read failed: \(String(describing: error), privacy: .private)")
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

        let writeOp: @Sendable (any SmartCardConnection, SCPKeyParams?) async throws -> ManagementRefresh<NamedDevice> = { connection, scpKeyParams in
            let name = try await YubiKey(connection: connection).deviceName
            let session = try await Management.Session.makeSession(connection: connection, scpKeyParams: scpKeyParams)
            let currentInfo = try await session.getDeviceInfo()
            let newConfig = Self.buildDeviceConfig(from: configMap, base: currentInfo.config)
            let refresh: (@Sendable () async throws -> NamedDevice)?
            if reboot {
                refresh = nil
            } else {
                refresh = { NamedDevice(info: try await session.getDeviceInfo(), name: name) }
            }
            return try await ManagementRefresh<NamedDevice>.perform(
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
                target: target, reconnectWired: reboot, body: writeOp
            )
            publishRefresh(refresh, isNfc: isNfc)
            await MainActor.run { result(NSNull()) }
        } catch {
            if !ManagementOperationError.isCancellation(error) {
                managementLog.error("Configuration failed: \(String(describing: error), privacy: .private)")
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
        let resetOp: @Sendable (any SmartCardConnection, SCPKeyParams?) async throws -> ManagementRefresh<NamedDevice> = { connection, scpKeyParams in
            let name = try await YubiKey(connection: connection).deviceName
            let session = try await Management.Session.makeSession(connection: connection, scpKeyParams: scpKeyParams)
            return try await ManagementRefresh.perform(
                mutation: { try await session.resetDevice() },
                refresh: { NamedDevice(info: try await session.getDeviceInfo(), name: name) }
            )
        }

        do {
            let target = try ManagementTarget(args["expectedDevice"])
            let (refresh, isNfc) = try await runManagementOperation(
                target: target, successMessage: "YubiKey reset", body: resetOp
            )
            publishRefresh(refresh, isNfc: isNfc)
            await MainActor.run { result(NSNull()) }
        } catch {
            if !ManagementOperationError.isCancellation(error) {
                managementLog.error("Device reset failed: \(String(describing: error), privacy: .private)")
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

    private func publishRefresh(_ refresh: ManagementRefresh<NamedDevice>, isNfc: Bool) {
        switch refresh {
        case .updated(let device):
            deviceEventsHandler.update(device, isNfc: isNfc)
        case .failed(let error):
            managementLog.warning("Operation succeeded but metadata refresh failed: \(String(describing: error), privacy: .private)")
            deviceEventsHandler.fail(
                code: "metadata_refresh_failed",
                message: "The operation succeeded, but updated YubiKey information could not be read: \(error)",
                isNfc: isNfc
            )
        case .pending:
            // Rebooted devices need a reconnect or rescan for fresh metadata.
            deviceEventsHandler.clear(isNfc: isNfc)
        }
    }

    // MARK: - Routing

    /// Runs an application operation on the selected YubiKey and transport.
    ///
    /// Waits for any in-flight operation instead of failing, and only provides
    /// SCP parameters over NFC when `capability` is FIPS capable.
    /// With `acceptOtherNfcDevice`, an NFC tap of a different key is not an
    /// error: the result reports that key, and `value` is nil if `body` failed
    /// on it. Use this only for reads.
    func runApplicationOperation<T: Sendable>(
        expectedDevice: Any?,
        capability: Capability,
        acceptOtherNfcDevice: Bool = false,
        successMessage: String = "Done",
        body: @Sendable @escaping (any SmartCardConnection, SCPKeyParams?) async throws -> T
    ) async throws -> ApplicationOutcome<T> {
        let target = try ManagementTarget(expectedDevice)
        guard acceptOtherNfcDevice, target.transport == .nfc else {
            let value = try await coordinator.performQueuedOperation {
                try await self.runManagementOperation(
                    target: target,
                    successMessage: successMessage,
                    scpCapability: capability,
                    body: body
                ).0
            }
            return ApplicationOutcome(value: value, otherDevice: nil)
        }
        let coordinator = coordinator
        return try await coordinator.performQueuedOperation {
            try await coordinator.withNFCConnection(successMessage: successMessage) { connection in
                let device = try await Self.readNamedDevice(from: connection)
                do {
                    try target.verify(device.info)
                } catch ManagementTargetError.deviceChanged {
                    do {
                        let params = try await Self.readSCPKeyParams(
                            from: connection, info: device.info, capability: capability
                        )
                        return ApplicationOutcome(value: try await body(connection, params), otherDevice: device)
                    } catch {
                        if ManagementOperationError.isCancellation(error) { throw error }
                        managementLog.warning("Read failed on another NFC YubiKey: \(String(describing: error), privacy: .private)")
                        return ApplicationOutcome(value: nil, otherDevice: device)
                    }
                }
                let params = try await Self.readSCPKeyParams(
                    from: connection, info: device.info, capability: capability
                )
                return ApplicationOutcome(value: try await body(connection, params), otherDevice: nil)
            }
        }
    }

    /// Displays a key read over NFC by another application, like a Home scan.
    /// `extras` are delivered with this event only, e.g. the application state
    /// that was read in the same tap.
    func publishNfcDevice(_ device: NamedDevice, extras: [String: Any] = [:]) {
        deviceEventsHandler.update(device, isNfc: true, scannedNfc: true, extras: extras)
    }

    /// Flutter error code for cancellation and device-binding failures, if any.
    nonisolated static func sharedErrorCode(for error: Error) -> String? {
        if ManagementOperationError.isCancellation(error) { return "cancelled" }
        return (error as? ManagementTargetError)?.code
    }

    /// Mutations keep the displayed transport and verify the key before execution.
    private func runManagementOperation<T: Sendable>(
        target: ManagementTarget,
        reconnectWired: Bool = false,
        successMessage: String = "Configuration updated",
        scpCapability: Capability? = nil,
        body: @Sendable @escaping (any SmartCardConnection, SCPKeyParams?) async throws -> T
    ) async throws -> (T, Bool) {
        if target.transport == .usb {
            let value = try await coordinator.withWiredConnection(reconnect: reconnectWired) { connection in
                let info = try await Self.readDeviceInfo(from: connection)
                try target.verify(info)
                return try await body(connection, nil)
            }
            return (value, false)
        } else {
            let value = try await coordinator.withNFCConnection(
                successMessage: successMessage
            ) { connection in
                let info = try await Self.readDeviceInfo(from: connection)
                try target.verify(info)
                let discoveredParams = try await Self.readSCPKeyParams(
                    from: connection, info: info, capability: scpCapability
                )
                return try await body(connection, discoveredParams)
            }
            return (value, true)
        }
    }

    // MARK: - Wired monitor

    private func startWiredMonitor() {
        monitorTask = Task { [coordinator, deviceEventsHandler] in
            await coordinator.startMonitoring(
                onAttach: { device in deviceEventsHandler.update(device, isNfc: false) },
                onDetach: { deviceEventsHandler.clear(isNfc: false) },
                onError: { error in
                    deviceEventsHandler.fail(
                        code: "yubikit_error",
                        message: String(describing: error),
                        isNfc: false
                    )
                }
            )
        }
    }

    // MARK: - Helpers

    nonisolated fileprivate static func readDeviceInfo(from connection: any SmartCardConnection) async throws -> DeviceInfo {
        let session = try await Management.Session.makeSession(connection: connection)
        return try await session.getDeviceInfo()
    }

    nonisolated fileprivate static func readNamedDevice(from connection: any SmartCardConnection) async throws -> NamedDevice {
        let key = try await YubiKey(connection: connection)
        return NamedDevice(info: key.deviceInfo, name: key.deviceName)
    }

    /// Management uses SCP on any FIPS-capable key; applications only when
    /// their own capability is FIPS capable.
    nonisolated private static func readSCPKeyParams(
        from connection: any SmartCardConnection,
        info: DeviceInfo,
        capability: Capability?
    ) async throws -> SCPKeyParams? {
        let requiredFlags = capability?.rawValue ?? info.fipsCapabilityFlags
        guard info.fipsCapabilityFlags & requiredFlags != 0 else { return nil }
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

/// Keeps a snapshot of each transport so new listeners receive both devices.
@MainActor
private final class DeviceEventsHandler: NSObject, @preconcurrency FlutterStreamHandler {
    private var sink: FlutterEventSink?
    private var wired: [String: Any]?
    private var nfc: [String: Any]?

    /// `extras` are sent with this event only and are not replayed.
    func update(
        _ device: NamedDevice,
        isNfc: Bool,
        scannedNfc: Bool = false,
        extras: [String: Any] = [:]
    ) {
        let info = DeviceInfoSerializer.serialize(device.info, name: device.name, isNfc: isNfc)
        set(["device": info], isNfc: isNfc, scannedNfc: scannedNfc, extras: extras)
    }

    func clear(isNfc: Bool) {
        set(nil, isNfc: isNfc)
    }

    func fail(code: String, message: String, isNfc: Bool) {
        set(["error": ["code": code, "message": message]], isNfc: isNfc)
    }

    private func set(
        _ value: [String: Any]?,
        isNfc: Bool,
        scannedNfc: Bool = false,
        extras: [String: Any] = [:]
    ) {
        if isNfc {
            nfc = value
        } else {
            wired = value
        }
        sink?(snapshot(scannedNfc: scannedNfc).merging(extras) { _, extra in extra })
    }

    private func snapshot(scannedNfc: Bool = false) -> [String: Any] {
        [
            "wired": wired as Any? ?? NSNull(),
            "nfc": nfc as Any? ?? NSNull(),
            "scanned_nfc": scannedNfc,
        ]
    }

    func onListen(withArguments _: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        sink = events
        events(snapshot())
        return nil
    }

    func onCancel(withArguments _: Any?) -> FlutterError? {
        clearSink()
        return nil
    }

    func clearSink() {
        sink = nil
    }
}

// MARK: - ConnectionCoordinator

/// Owns wired and NFC connections and serializes operations on them.
actor ConnectionCoordinator {
    static let shared = ConnectionCoordinator()

    private var wiredConnection: (any SmartCardConnection)?
    private var nfcConnection: NFCSmartCardConnection?
    /// Dismissal of the last NFC sheet, which keeps showing its success message
    /// after the result has been returned.
    private var nfcClosing: Task<Void, Never>?
    private var operationInFlight: Bool = false
    private var operationTask: Task<Void, Never>?
    private var idleWaiters: [CheckedContinuation<Void, Never>] = []
    private var stopped = false
    private var connectionGeneration = 0

    private init() {}

    var hasWiredDevice: Bool { wiredConnection != nil }

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

    /// Like `performOperation`, but waits for the current operation to finish.
    func performQueuedOperation<T: Sendable>(
        body: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        await waitUntilIdle()
        guard !stopped else { throw CancellationError() }
        operationInFlight = true
        defer { finishOperation() }
        let task = Task { try await body() }
        operationTask = Task {
            await withTaskCancellationHandler {
                _ = await task.result
            } onCancel: {
                task.cancel()
            }
        }
        return try await task.value
    }

    fileprivate func stop() async {
        stopped = true
        operationTask?.cancel()
        connectionGeneration += 1
        let wired = wiredConnection
        let nfc = nfcConnection
        wiredConnection = nil
        nfcConnection = nil
        resumeIdleWaiters()
        await wired?.close(error: CancellationError())
        await nfc?.close(error: CancellationError())
        await nfcClosing?.value
        await operationTask?.value
    }

    fileprivate func startMonitoring(
        onAttach: @escaping @MainActor @Sendable (NamedDevice) -> Void,
        onDetach: @escaping @MainActor @Sendable () -> Void,
        onError: @escaping @MainActor @Sendable (Error) -> Void
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
                wiredConnection = connection

                do {
                    let info = try await ManagementManager.readNamedDevice(from: connection)
                    if !stopped { await onAttach(info) }
                } catch {
                    if !stopped && !Task.isCancelled {
                        await onError(error)
                    }
                }
                finishOperation()

                _ = await connection.waitUntilClosed()
                if generation == connectionGeneration {
                    wiredConnection = nil
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
                       case .setupFailed = error,
                       try await USBSmartCardConnection.availableDevices().isEmpty {
                        continue
                    }
                } catch {
                    if stopped || Task.isCancelled { return }
                    await onError(error)
                    continue
                }
                managementLog.error("Wired monitor failed: \(String(describing: error), privacy: .private)")
                await onError(error)
            }
        }
    }

    func withWiredConnection<T: Sendable>(
        reconnect: Bool,
        body: @Sendable @escaping (any SmartCardConnection) async throws -> T
    ) async throws -> T {
        try Task.checkCancellation()
        guard !stopped, let connection = wiredConnection else {
            throw ManagementTargetError.wiredDeviceUnavailable
        }
        let value = try await body(connection)
        if reconnect {
            // Reboot invalidates this connection; let the monitor reacquire it.
            connectionGeneration += 1
            wiredConnection = nil
            await connection.close(error: nil)
        }
        return value
    }

    func withNFCConnection<T: Sendable>(
        successMessage: String,
        body: @Sendable (NFCSmartCardConnection) async throws -> T
    ) async throws -> T {
        await nfcClosing?.value
        nfcClosing = nil
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
            // Return without waiting for iOS to dismiss the sheet, so the UI
            // updates right away. The next NFC operation waits for it instead.
            nfcClosing = Task { await connection.close(message: successMessage) }
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

struct NamedDevice: Sendable {
    let info: DeviceInfo
    let name: String
}

struct ApplicationOutcome<T: Sendable>: Sendable {
    let value: T?
    /// Set when the operation ran on a different NFC key than the displayed one.
    let otherDevice: NamedDevice?
}
