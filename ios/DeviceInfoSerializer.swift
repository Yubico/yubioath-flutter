/*
 * Copyright (C) 2026 Yubico.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *       http://www.apache.org/licenses/LICENSE-2.0
 */

import Foundation
import YubiKit

/// Serializes a yubikit-swift `DeviceInfo` into the dictionary shape that the
/// Dart side decodes via `DeviceInfo.fromJson`.
///
/// Mirrors `android/.../device/Info.kt` — keys must match exactly.
enum DeviceInfoSerializer {

    static func serialize(
        _ info: DeviceInfo,
        name: String,
        isNfc: Bool,
        usbPid: Int? = nil
    ) -> [String: Any] {
        var dict: [String: Any] = [
            "config": serializeConfig(info.config),
            "version": serializeVersion(info.version),
            "form_factor": Int(info.formFactor.rawValue),
            "is_locked": info.isConfigLocked,
            "is_sky": info.isSKY,
            "is_fips": info.isFIPS,
            "name": name,
            "is_nfc": isNfc,
            "pin_complexity": info.pinComplexity,
            "supported_capabilities": serializeCapabilities(info.supportedCapabilities),
            "fips_capable": Int(info.fipsCapabilityFlags),
            "fips_approved": Int(info.fipsApprovalFlags),
            "reset_blocked": Int(info.resetBlockedFlags),
            "version_qualifier": defaultVersionQualifier(info.version),
        ]

        // `serial` and `usb_pid` are nullable in the Dart model. yubikit-swift
        // exposes `serialNumber: UInt`; treat 0 as "no serial available".
        if info.serialNumber != 0 {
            dict["serial"] = Int(info.serialNumber)
        } else {
            dict["serial"] = NSNull()
        }
        dict["usb_pid"] = usbPid as Any? ?? NSNull()

        return dict
    }

    private static func serializeConfig(_ config: DeviceConfig) -> [String: Any] {
        var dict: [String: Any] = [
            "enabled_capabilities": serializeCapabilities(config.enabledCapabilities),
        ]
        dict["device_flags"] = config.deviceFlags.map { Int($0) } ?? NSNull()
        dict["challenge_response_timeout"] = config.challengeResponseTimeout
            .map { Int($0) } ?? NSNull()
        dict["auto_eject_timeout"] = config.autoEjectTimeout
            .map { Int($0) } ?? NSNull()
        return dict
    }

    private static func serializeCapabilities(
        _ caps: [DeviceTransport: UInt]
    ) -> [String: Any] {
        var out: [String: Any] = [:]
        if let usb = caps[.usb] { out["usb"] = Int(usb) }
        if let nfc = caps[.nfc] { out["nfc"] = Int(nfc) }
        return out
    }

    private static func serializeVersion(_ version: Version) -> [Int] {
        [Int(version.major), Int(version.minor), Int(version.micro)]
    }

    /// yubikit-swift does not surface a `VersionQualifier`, but the Dart model
    /// requires one. Fill in a "release" qualifier with the firmware version
    /// so the Dart side can parse the payload.
    private static func defaultVersionQualifier(_ version: Version) -> [String: Any] {
        [
            "version": serializeVersion(version),
            "type": 2, // ReleaseType.release
            "iteration": 0,
        ]
    }
}
