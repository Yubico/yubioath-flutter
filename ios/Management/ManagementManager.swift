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
/// Mirrors `android/.../management/ManagementManager.kt` plus the
/// `android/.../device/DeviceManager.kt` device-event stream. Tier 2 scope:
///  - emit `DeviceInfo` events when a wired YubiKey is attached / detached
///  - read `DeviceInfo` over NFC on demand
///  - write a `DeviceConfig` (toggle applications, lock code, reboot)
///  - factory-reset the management application
///
/// The wired-connection lifecycle is owned by `UsbCoordinator` so the USB
/// monitor can release and reacquire the connection around write operations.
final class ManagementManager: NSObject, AppContextManager {
    static let channelSuffix = "management"
    static let channelName = "com.yubico.authenticator/management"
    static let deviceEventsChannelName = "ios.devices.deviceInfo"

    private var methodChannel: FlutterMethodChannel?
    private var deviceEventsChannel: FlutterEventChannel?
    private let deviceEventsHandler = DeviceEventsHandler()
    private let coordinator = UsbCoordinator()

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

    // MARK: - AppContextManager

    func processYubiKey(_ connection: any SmartCardConnection) async throws {
        // Tier 2 owns its own connection lifecycle via `UsbCoordinator`.
    }

    func onPause() {
        // Tier 2: nothing to drop yet.
    }

    // MARK: - Method dispatch

    private func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
        NSLog("[ManagementManager] received call: \(call.method)")
        switch call.method {
        case "readDeviceInfoNfc":
            Task { await self.readDeviceInfoOverNfc(result: result) }
        case "configure":
            guard let args = call.arguments as? [String: Any] else {
                return result(invalidArgs())
            }
            Task { await self.configure(args: args, result: result) }
        case "setMode":
            // YubiKey 4 / NEO firmware setMode is not exposed in yubikit-swift
            // (no Mode/UsbInterface API). Surface as not-implemented for now.
            result(FlutterError(
                code: "unsupported",
                message: "setMode is not supported on iOS",
                details: nil
            ))
        case "deviceReset":
            Task { await self.deviceReset(result: result) }
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Read

    private func readDeviceInfoOverNfc(result: @escaping FlutterResult) async {
        do {
            let info = try await ConnectionHelper.withNFCConnection(
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

        let writeOp: @Sendable (any SmartCardConnection) async throws -> DeviceInfo = { connection in
            let session = try await Management.Session.makeSession(connection: connection)
            let currentInfo = try await session.getDeviceInfo()
            let newConfig = Self.buildDeviceConfig(from: configMap, base: currentInfo.config)
            try await session.updateDeviceConfig(
                newConfig,
                reboot: reboot,
                lockCode: currentLockCode,
                newLockCode: newLockCode
            )
            // After reboot the same session is gone; fetching fresh info would
            // fail. Return the optimistic value the caller already has.
            if reboot { return currentInfo }
            return try await session.getDeviceInfo()
        }

        do {
            let (info, isNfc) = try await runManagementOperation(body: writeOp)
            // Always emit so NFC reads (which are not covered by the USB
            // monitor) refresh the home tab. For USB the monitor will also
            // re-emit on reattach; the duplicate is harmless.
            let dict = DeviceInfoSerializer.serialize(info, name: deviceName(info), isNfc: isNfc)
            deviceEventsHandler.send(dict)
            await MainActor.run { result(NSNull()) }
        } catch {
            NSLog("[ManagementManager] configure error: \(error)")
            await MainActor.run {
                result(FlutterError(
                    code: "yubikit_error",
                    message: String(describing: error),
                    details: nil
                ))
            }
        }
    }

    // MARK: - Device reset

    private func deviceReset(result: @escaping FlutterResult) async {
        let resetOp: @Sendable (any SmartCardConnection) async throws -> DeviceInfo = { connection in
            let session = try await Management.Session.makeSession(connection: connection)
            try await session.resetDevice()
            return try await session.getDeviceInfo()
        }

        do {
            let (info, isNfc) = try await runManagementOperation(body: resetOp)
            let dict = DeviceInfoSerializer.serialize(info, name: deviceName(info), isNfc: isNfc)
            deviceEventsHandler.send(dict)
            await MainActor.run { result(NSNull()) }
        } catch {
            NSLog("[ManagementManager] deviceReset error: \(error)")
            await MainActor.run {
                result(FlutterError(
                    code: "yubikit_error",
                    message: String(describing: error),
                    details: nil
                ))
            }
        }
    }

    // MARK: - Routing

    /// Routes a management operation to either the wired (USB) coordinator
    /// or to a one-shot NFC scan, depending on whether a wired YubiKey is
    /// currently held by the monitor.
    private func runManagementOperation<T: Sendable>(
        body: @Sendable @escaping (any SmartCardConnection) async throws -> T
    ) async throws -> (T, Bool) {
        if await coordinator.hasWiredDevice {
            let value = try await coordinator.runWithReleasedUsb(body: body)
            return (value, false)
        } else {
            let value = try await ConnectionHelper.withNFCConnection(
                successMessage: "Configuration updated"
            ) { connection in
                try await body(connection)
            }
            return (value, true)
        }
    }

    // MARK: - USB monitor

    private func startUsbMonitor() {
        Task { [weak self] in
            await self?.coordinator.startMonitoring(
                onAttach: { [weak self] info in
                    guard let self else { return }
                    let dict = DeviceInfoSerializer.serialize(
                        info,
                        name: self.deviceName(info),
                        isNfc: false
                    )
                    self.deviceEventsHandler.send(dict)
                },
                onDetach: { [weak self] in
                    self?.deviceEventsHandler.send(NSNull())
                }
            )
        }
    }

    // MARK: - Helpers

    fileprivate static func readDeviceInfo(from connection: any SmartCardConnection) async throws -> DeviceInfo {
        let session = try await Management.Session.makeSession(connection: connection)
        return try await session.getDeviceInfo()
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
    fileprivate static func parseHex(_ raw: Any?) -> Data? {
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
    fileprivate static func buildDeviceConfig(
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

/// Bridges `FlutterEventChannel` to a simple `send(_:)` API. Stores the most
/// recent event so a freshly-attached listener immediately receives the
/// current device state.
private final class DeviceEventsHandler: NSObject, FlutterStreamHandler {
    private var sink: FlutterEventSink?
    private var lastEvent: Any?

    func send(_ event: Any) {
        lastEvent = event
        let hasSink = sink != nil
        NSLog("[DeviceEventsHandler] send (hasSink=\(hasSink))")
        DispatchQueue.main.async { [weak self] in
            self?.sink?(event)
        }
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

/// Owns the wired YubiKey connection lifecycle.
///
/// The USB monitor loop continuously holds a wired connection open via
/// `WiredSmartCardConnection.makeConnection()` + `Connection.waitUntilClosed()`
/// to detect attach + detach. When a write operation needs the connection,
/// `runWithReleasedUsb(body:)`:
///   1. flips the `paused` flag and explicitly closes the held connection,
///      which makes the monitor's `waitUntilClosed()` return without emitting
///      a detach event;
///   2. opens a fresh connection and runs `body` against it;
///   3. clears the `paused` flag and resumes the monitor, which will reopen
///      a fresh connection and emit a new attach event with the post-write
///      `DeviceInfo`.
actor UsbCoordinator {
    private var heldConnection: (any SmartCardConnection)?
    private var paused: Bool = false
    private var resumeContinuation: CheckedContinuation<Void, Never>?
    private var operationInFlight: Bool = false

    var hasWiredDevice: Bool { heldConnection != nil }

    func startMonitoring(
        onAttach: @Sendable @escaping (DeviceInfo) -> Void,
        onDetach: @Sendable @escaping () -> Void
    ) async {
        while !Task.isCancelled {
            if paused {
                await withCheckedContinuation { continuation in
                    resumeContinuation = continuation
                }
            }

            do {
                NSLog("[UsbCoordinator] waiting for wired YubiKey…")
                let connection = try await WiredSmartCardConnection.makeConnection()
                NSLog("[UsbCoordinator] wired connection up")
                heldConnection = connection

                do {
                    let info = try await ManagementManager.readDeviceInfo(from: connection)
                    NSLog("[UsbCoordinator] readDeviceInfo OK serial=\(info.serialNumber) version=\(info.version.major).\(info.version.minor).\(info.version.micro)")
                    onAttach(info)
                } catch {
                    NSLog("[UsbCoordinator] failed to read DeviceInfo: \(error)")
                }

                _ = await connection.waitUntilClosed()
                heldConnection = nil
                NSLog("[UsbCoordinator] wired connection closed (paused=\(paused))")

                if !paused {
                    onDetach()
                }
            } catch is CancellationError {
                return
            } catch {
                NSLog("[UsbCoordinator] monitor error: \(error)")
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }

    func runWithReleasedUsb<T: Sendable>(
        body: @Sendable @escaping (any SmartCardConnection) async throws -> T
    ) async throws -> T {
        guard !operationInFlight else {
            throw ManagementOperationError.alreadyInProgress
        }
        operationInFlight = true
        paused = true

        if let conn = heldConnection {
            await conn.close(error: nil)
            heldConnection = nil
        }

        do {
            let connection = try await WiredSmartCardConnection.makeConnection()
            do {
                let value = try await body(connection)
                await connection.close(error: nil)
                releaseAfterOperation()
                return value
            } catch {
                await connection.close(error: error)
                releaseAfterOperation()
                throw error
            }
        } catch {
            releaseAfterOperation()
            throw error
        }
    }

    private func releaseAfterOperation() {
        operationInFlight = false
        paused = false
        resumeContinuation?.resume()
        resumeContinuation = nil
    }
}

enum ManagementOperationError: Error {
    case alreadyInProgress
}
