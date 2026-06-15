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

/// Top-level "placeholder" channel used by the iOS bring-up UI.
///
/// Once `DeviceManager` + per-app managers (`OathManager`, `FidoManager`,
/// `PivManager`, `ManagementManager`) are in place this can be retired —
/// `currentDeviceProvider` will be driven by `ManagementManager` instead.
final class YubiKitChannel {
    static let channelName = "com.yubico.authenticator/yubikit"

    static func register(with messenger: FlutterBinaryMessenger) {
        let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
        let handler = YubiKitChannel()
        channel.setMethodCallHandler { call, result in
            handler.handle(call: call, result: result)
        }
    }

    func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
        NSLog("[YubiKitChannel] received call: \(call.method)")
        switch call.method {
        case "readSerial":
            let args = call.arguments as? [String: Any]
            let via = (args?["via"] as? String) ?? "nfc"
            Task {
                do {
                    let serial = try await DeviceInfoHelper.readSerial(via: via)
                    NSLog("[YubiKitChannel] success: \(serial)")
                    await MainActor.run { result(serial) }
                } catch {
                    NSLog("[YubiKitChannel] error: \(error)")
                    await MainActor.run {
                        result(FlutterError(
                            code: "yubikit_error",
                            message: String(describing: error),
                            details: nil
                        ))
                    }
                }
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}

