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

/// Reads device-level information using `ManagementSession`.
///
/// Mirrors `android/.../yubikit/DeviceInfoHelper.kt`. Today only exposes a
/// minimal `readSerial(via:)` used by the iOS placeholder UI; will grow to
/// return the full `DeviceInfo` for the eventual `currentDeviceProvider`.
enum DeviceInfoHelper {

    /// Reads device info via the requested transport and returns a string
    /// description suitable for the placeholder UI. Replace with a typed
    /// `DeviceInfo` model once the iOS providers are wired up.
    static func readSerial(via transport: String) async throws -> String {
        switch transport {
        case "usb":
            return try await ConnectionHelper.withWiredConnection { connection in
                try await readDescription(from: connection)
            }
        default:
            return try await ConnectionHelper.withNFCConnection(
                successMessage: "YubiKey detected"
            ) { connection in
                try await readDescription(from: connection)
            }
        }
    }

    private static func readDescription(
        from connection: any SmartCardConnection
    ) async throws -> String {
        let session = try await Management.Session.makeSession(connection: connection)
        let info = try await session.getDeviceInfo()
        return "\(info.description)"
    }
}
