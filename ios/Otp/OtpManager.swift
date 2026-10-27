/*
 * Copyright (C) 2026 Yubico.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *       http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import Flutter
import Foundation
import YubiKit

/// iOS implementation of the two YubiOTP slots.
///
/// The ManagementManager owns USB monitoring and arbitrates every key operation;
/// this manager deliberately owns no connection or device monitor of its own.
final class OtpManager {
    static let channelSuffix = "otp"
    static let channelName = "com.yubico.authenticator/\(channelSuffix)"

    private let managementManager: ManagementManager
    private var channel: FlutterMethodChannel?
    private var operationInFlight = false

    private init(managementManager: ManagementManager) {
        self.managementManager = managementManager
    }

    @discardableResult
    static func register(
        with messenger: FlutterBinaryMessenger,
        managementManager: ManagementManager
    ) -> OtpManager {
        let manager = OtpManager(managementManager: managementManager)
        let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
        channel.setMethodCallHandler { [weak manager] call, result in
            manager?.handle(call, result: result)
        }
        manager.channel = channel
        return manager
    }

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let localMethods = [
            "generateStaticPassword", "modhexEncodeSerial", "getKeyboardLayouts", "formatYubiOtpCsv",
        ]
        if localMethods.contains(call.method) {
            do {
                let args = call.arguments as? [String: Any] ?? [:]
                let value = try Self.compute(call.method, args: args)
                result(Self.jsonString(value))
            } catch {
                result(Self.flutterError(error))
            }
            return
        }

        guard ["get", "configureSlot", "deleteSlot", "swapSlots"].contains(call.method) else {
            result(FlutterMethodNotImplemented)
            return
        }
        guard !operationInFlight else {
            result(FlutterError(code: "busy", message: "An OTP operation is already in progress", details: nil))
            return
        }
        operationInFlight = true

        let args = call.arguments as? [String: Any] ?? [:]
        Task {
            do {
                let (snapshot, _) = try await managementManager.runApplicationOperation { connection in
                    try await OtpController.execute(call.method, args: args, connection: connection)
                }
                await MainActor.run {
                    self.operationInFlight = false
                    result(snapshot)
                }
            } catch {
                NSLog("[OtpManager] %@ failed: %@", call.method, String(describing: error))
                await MainActor.run {
                    self.operationInFlight = false
                    result(Self.flutterError(error))
                }
            }
        }
    }

    private static func compute(_ method: String, args: [String: Any]) throws -> Any {
        switch method {
        case "getKeyboardLayouts":
            return OtpKeyboardLayouts.characters
        case "generateStaticPassword":
            guard let length = args["length"] as? Int, length >= 0,
                  let layout = args["layout"] as? String else {
                throw OtpError.message("Invalid static-password length or keyboard layout")
            }
            let alphabet = try OtpKeyboardLayouts.alphabet(for: layout)
                .filter { $0 != "\t" && $0 != "\n" && $0 != " " }
            guard !alphabet.isEmpty else { throw OtpError.message("Keyboard layout has no password characters") }
            var generator = SystemRandomNumberGenerator()
            let password = String((0..<length).map { _ in alphabet.randomElement(using: &generator)! })
            return ["password": password]
        case "modhexEncodeSerial":
            guard let serial = args["serial"] as? Int, (0...Int(UInt32.max)).contains(serial) else {
                throw OtpError.message("Invalid YubiKey serial number")
            }
            var bytes = Data([0xff, 0x00])
            var value = UInt32(serial).bigEndian
            withUnsafeBytes(of: &value) { bytes.append(contentsOf: $0) }
            return ["encoded": YubiOTP.Modhex.encode(bytes)]
        case "formatYubiOtpCsv":
            guard let serial = args["serial"] as? Int,
                  let publicId = args["publicId"] as? String,
                  let privateId = args["privateId"] as? String,
                  let key = args["key"] as? String,
                  let publicData = YubiOTP.Modhex.decode(publicId),
                  let privateData = Self.decodeHex(privateId),
                  let keyData = Self.decodeHex(key) else {
                throw OtpError.message("Invalid Yubico OTP CSV values")
            }
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.calendar = Calendar(identifier: .gregorian)
            formatter.timeZone = .current
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            let csv = [
                String(serial),
                YubiOTP.Modhex.encode(publicData),
                privateData.map { String(format: "%02x", $0) }.joined(),
                keyData.map { String(format: "%02x", $0) }.joined(),
                "",
                formatter.string(from: Date()),
                "",
            ].joined(separator: ",")
            return ["csv": csv]
        default:
            throw OtpError.message("Unknown local OTP method")
        }
    }

    fileprivate static func decodeHex(_ string: String) -> Data? {
        guard string.count.isMultiple(of: 2) else { return nil }
        var result = Data()
        var index = string.startIndex
        while index < string.endIndex {
            let end = string.index(index, offsetBy: 2)
            guard let byte = UInt8(string[index..<end], radix: 16) else { return nil }
            result.append(byte)
            index = end
        }
        return result
    }

    fileprivate static func jsonString(_ value: Any) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: value),
              let string = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return string
    }

    private static func flutterError(_ error: Error) -> FlutterError {
        if error is CancellationError {
            return FlutterError(code: "CancellationException", message: "Operation cancelled", details: nil)
        }
        if let sessionError = error as? YubiOTP.SessionError {
            if case .cancelled = sessionError {
                return FlutterError(code: "CancellationException", message: "Operation cancelled", details: nil)
            }
        }
        if let connectionError = error as? SmartCardConnectionError {
            switch connectionError {
            case .cancelled, .cancelledByUser:
                return FlutterError(code: "CancellationException", message: "NFC scan cancelled", details: nil)
            default: break
            }
        }
        if let sessionError = error as? YubiOTP.SessionError,
           case let .connectionError(connectionError, _) = sessionError {
            return flutterError(connectionError)
        }
        if let otpError = error as? OtpError {
            switch otpError {
            case .wrongDevice:
                return FlutterError(
                    code: "wrong_device",
                    message: "The scanned YubiKey does not match the selected device",
                    details: nil
                )
            case .deviceIdentityUnavailable:
                return FlutterError(
                    code: "device_identity_unavailable",
                    message: "The YubiKey serial number could not be verified",
                    details: nil
                )
            case .message:
                break
            }
        }
        return FlutterError(code: "otp_error", message: error.localizedDescription, details: nil)
    }
}

private actor OtpController {
    static func execute(
        _ method: String,
        args: [String: Any],
        connection: any SmartCardConnection
    ) async throws -> String {
        let session = try await YubiOTP.Session.makeSession(connection: connection)
        let serial = try? await session.getSerialNumber()
        if let expected = args["expectedSerial"] as? Int {
            guard expected >= 0 else { throw OtpError.wrongDevice }
            guard let serial else { throw OtpError.deviceIdentityUnavailable }
            guard UInt(expected) == serial else { throw OtpError.wrongDevice }
        }
        if method != "get" {
            guard let expected = args["expectedSerial"] as? Int, expected >= 0 else {
                throw OtpError.wrongDevice
            }
            guard let serial else { throw OtpError.deviceIdentityUnavailable }
            guard UInt(expected) == serial else { throw OtpError.wrongDevice }
        }

        switch method {
        case "get":
            break
        case "swapSlots":
            try await session.swapConfigurations()
        case "configureSlot":
            guard let slotName = args["slot"] as? String,
                  let slot = Self.slot(slotName),
                  let config = args["configuration"] as? [String: Any] else {
                throw OtpError.message("Invalid slot configuration")
            }
            let accessCode = try Self.accessCode(args["accessCode"])
            let configuration = try Self.configuration(config)
            try await session.putConfiguration(
                configuration,
                in: slot,
                accessCode: .unchanged,
                currentAccessCode: accessCode
            )
        case "deleteSlot":
            guard let slotName = args["slot"] as? String,
                  let slot = Self.slot(slotName) else {
                throw OtpError.message("Invalid OTP slot")
            }
            try await session.deleteConfiguration(
                in: slot,
                currentAccessCode: Self.accessCode(args["accessCode"])
            )
        default:
            throw OtpError.message("Unknown OTP operation")
        }

        let state = try await Self.slotState(session, serial: serial)
        return OtpManager.jsonString([
            "state": state,
            "result": NSNull(),
        ])
    }

    private static func slotState(_ session: YubiOTP.Session, serial: UInt?) async throws -> [String: Any] {
        let version = await session.version
        let configState = await session.configState
        let slot1: Bool
        let slot2: Bool
        if YubiOTP.Feature.checkConfigured.isSupported(by: version) {
            slot1 = try configState.isConfigured(.one)
            slot2 = try configState.isConfigured(.two)
        } else {
            // Older firmware does not report configuration state; match Android/desktop by
            // assuming both slots are occupied so an overwrite confirmation is required.
            slot1 = true
            slot2 = true
        }
        let serialValue: Any = serial.map { Int($0) as Any } ?? NSNull()
        return [
            "slot1_configured": slot1,
            "slot2_configured": slot2,
            "device_serial": serialValue,
        ]
    }

    private static func slot(_ id: String) -> YubiOTP.Slot? {
        switch id {
        case "one": .one
        case "two": .two
        default: nil
        }
    }

    private static func accessCode(_ value: Any?) throws -> YubiOTP.AccessCode? {
        guard let value = value as? String, !value.isEmpty else { return nil }
        guard let data = OtpManager.decodeHex(value) else {
            throw OtpError.message("OTP access code must be a hexadecimal string")
        }
        return try YubiOTP.AccessCode(data)
    }

    private static func configuration(_ json: [String: Any]) throws -> YubiOTP.SlotConfiguration {
        let options = json["options"] as? [String: Any] ?? [:]
        let appendCR = options["append_cr"] as? Bool ?? true
        let keyboard = YubiOTP.KeyboardOptions(appendCarriageReturn: appendCR)
        switch json["type"] as? String {
        case "hotp":
            guard let keyString = json["key"] as? String,
                  let key = Self.decodeBase32(keyString) else {
                throw OtpError.message("Invalid HOTP secret")
            }
            return try .hotp(
                key: key,
                digits: options["digits8"] as? Bool == true ? .eight : .six,
                tokenID: Data(),
                tokenIDEncoding: .modhexFirstTwoBytes,
                keyboard: keyboard
            )
        case "hmac_sha1":
            guard let keyString = json["key"] as? String,
                  let key = OtpManager.decodeHex(keyString) else {
                throw OtpError.message("Invalid HMAC-SHA1 key")
            }
            return try .hmacSHA1(
                key: key,
                requireTouch: options["require_touch"] as? Bool ?? false
            )
        case "static_password":
            guard let password = json["password"] as? String,
                  let layout = json["keyboard_layout"] as? String else {
                throw OtpError.message("Invalid static-password configuration")
            }
            return try .staticPassword(
                scanCodes: OtpKeyboardLayouts.scanCodes(for: password, layout: layout),
                keyboard: keyboard
            )
        case "yubiotp":
            guard let publicId = json["public_id"] as? String,
                  let publicData = YubiOTP.Modhex.decode(publicId),
                  let privateId = json["private_id"] as? String,
                  let privateData = OtpManager.decodeHex(privateId),
                  let keyString = json["key"] as? String,
                  let key = OtpManager.decodeHex(keyString) else {
                throw OtpError.message("Invalid Yubico OTP configuration")
            }
            return try .yubicoOTP(
                publicID: publicData,
                privateID: privateData,
                key: key,
                keyboard: keyboard
            )
        default:
            throw OtpError.message("Unsupported OTP configuration type")
        }
    }

    private static func decodeBase32(_ value: String) -> Data? {
        let alphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ234567")
        let input = value.uppercased().filter { !$0.isWhitespace && $0 != "=" }
        guard !input.isEmpty, [0, 2, 4, 5, 7].contains(input.count % 8) else {
            return nil
        }
        var accumulator: UInt64 = 0
        var bitCount = 0
        var result = Data()
        for character in input {
            guard let digit = alphabet.firstIndex(of: character) else { return nil }
            accumulator = (accumulator << 5) | UInt64(digit)
            bitCount += 5
            if bitCount >= 8 {
                bitCount -= 8
                result.append(UInt8((accumulator >> bitCount) & 0xff))
            }
        }
        return !result.isEmpty &&
            (bitCount == 0 || (accumulator & ((1 << bitCount) - 1)) == 0)
            ? result
            : nil
    }
}

enum OtpError: LocalizedError {
    case message(String)
    case wrongDevice
    case deviceIdentityUnavailable

    var errorDescription: String? {
        switch self {
        case let .message(message): message
        case .wrongDevice: "The scanned YubiKey does not match the selected device"
        case .deviceIdentityUnavailable: "The YubiKey serial number could not be verified"
        }
    }
}
