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
/// `android/.../device/DeviceManager.kt` device-event stream. Tier 1 scope:
///  - emit `DeviceInfo` events when a wired YubiKey is attached / detached
///  - read `DeviceInfo` over NFC on demand
///
/// Future scope: write device config, deviceReset, setMode (mirroring the
/// remaining Android methods).
final class ManagementManager: NSObject, AppContextManager {
    static let channelSuffix = "management"
    static let channelName = "com.yubico.authenticator/management"
    static let deviceEventsChannelName = "ios.devices.deviceInfo"

    private var methodChannel: FlutterMethodChannel?
    private var deviceEventsChannel: FlutterEventChannel?
    private let deviceEventsHandler = DeviceEventsHandler()

    private var usbMonitorTask: Task<Void, Never>?

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
        // TODO (Tier 2): used when this manager is the active app context.
    }

    func onPause() {
        // TODO (Tier 2): drop pending operations.
    }

    // MARK: - Method dispatch

    private func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
        NSLog("[ManagementManager] received call: \(call.method)")
        switch call.method {
        case "readDeviceInfoNfc":
            Task { await self.readDeviceInfoOverNfc(result: result) }
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func readDeviceInfoOverNfc(result: @escaping FlutterResult) async {
        do {
            let info = try await ConnectionHelper.withNFCConnection(
                successMessage: "YubiKey detected"
            ) { connection in
                try await readDeviceInfo(from: connection)
            }
            let dict = DeviceInfoSerializer.serialize(info, name: deviceName(info), isNfc: true)
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

    // MARK: - USB monitor

    /// Continuously holds a wired connection open so we can detect attach +
    /// detach via `WiredSmartCardConnection.makeConnection()` and
    /// `Connection.waitUntilClosed()`.
    ///
    /// While the connection is held open, no other application
    /// (`OATH.Session`, `PIV.Session`, `FIDO2.Session`) can be opened against
    /// the same key. Tier 2 will introduce a release/reacquire handshake.
    private func startUsbMonitor() {
        usbMonitorTask?.cancel()
        usbMonitorTask = Task { [weak self] in
            while let self, !Task.isCancelled {
                await self.runUsbMonitorIteration()
            }
        }
    }

    private func runUsbMonitorIteration() async {
        do {
            NSLog("[ManagementManager] usb monitor: waiting for wired YubiKey…")
            let connection = try await WiredSmartCardConnection.makeConnection()
            NSLog("[ManagementManager] usb monitor: wired connection up")

            do {
                let info = try await readDeviceInfo(from: connection)
                let dict = DeviceInfoSerializer.serialize(
                    info,
                    name: deviceName(info),
                    isNfc: false
                )
                deviceEventsHandler.send(dict)
            } catch {
                NSLog("[ManagementManager] usb monitor: read failed: \(error)")
            }

            _ = await connection.waitUntilClosed()
            NSLog("[ManagementManager] usb monitor: wired connection closed")
            deviceEventsHandler.send(NSNull())
        } catch is CancellationError {
            return
        } catch {
            NSLog("[ManagementManager] usb monitor error: \(error)")
            try? await Task.sleep(for: .seconds(1))
        }
    }

    private func readDeviceInfo(from connection: any SmartCardConnection) async throws -> DeviceInfo {
        let session = try await Management.Session.makeSession(connection: connection)
        return try await session.getDeviceInfo()
    }

    private func deviceName(_ info: DeviceInfo) -> String {
        if info.isSKY { return "Security Key by Yubico" }
        let suffix = info.isFIPS ? " FIPS" : ""
        return "YubiKey\(suffix)"
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
        DispatchQueue.main.async { [weak self] in
            self?.sink?(event)
        }
    }

    func onListen(withArguments _: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        sink = events
        if let lastEvent { events(lastEvent) }
        return nil
    }

    func onCancel(withArguments _: Any?) -> FlutterError? {
        sink = nil
        return nil
    }
}
