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

/// Opens and closes YubiKey smart-card connections.
///
/// Mirrors `android/.../yubikit/ConnectionHelper.kt`. NFC and wired
/// connections expose different `close` APIs in yubikit-swift, so the
/// helper provides one entry point per transport.
enum ConnectionHelper {

    /// Opens a wired (USB / Lightning) smart-card connection, runs `body`,
    /// then closes the connection. The connection is closed even if `body`
    /// throws.
    ///
    /// `WiredSmartCardConnection` is a namespace enum in yubikit-swift —
    /// `makeConnection()` returns the concrete `USBSmartCardConnection` or
    /// `LightningSmartCardConnection` boxed as `any SmartCardConnection`.
    static func withWiredConnection<T>(
        body: (any SmartCardConnection) async throws -> T
    ) async throws -> T {
        NSLog("[ConnectionHelper] opening wired connection…")
        let connection = try await WiredSmartCardConnection.makeConnection()
        NSLog("[ConnectionHelper] wired connection established")
        do {
            let value = try await body(connection)
            await connection.close(error: nil)
            return value
        } catch {
            await connection.close(error: error)
            throw error
        }
    }

    /// Opens an NFC smart-card connection (presents the system NFC sheet),
    /// runs `body`, then closes the connection. Closes with `successMessage`
    /// on success, or with the error description on failure.
    static func withNFCConnection<T>(
        alertMessage: String = "Hold your YubiKey near the top of the phone",
        successMessage: String = "Done",
        body: (NFCSmartCardConnection) async throws -> T
    ) async throws -> T {
        NSLog("[ConnectionHelper] opening NFC connection…")
        let connection = try await NFCSmartCardConnection.makeConnection(
            alertMessage: alertMessage
        )
        NSLog("[ConnectionHelper] NFC connection established")
        do {
            let value = try await body(connection)
            await connection.close(message: successMessage)
            return value
        } catch {
            await connection.close(message: "Error: \(error)")
            throw error
        }
    }
}
