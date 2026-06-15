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

/// Per-application MethodChannel handler.
///
/// Mirrors the abstract `AppContextManager.kt`: at most one manager owns a
/// connection at a time. `DeviceManager` switches between them as the user
/// navigates between sections (Accounts / Passkeys / Certificates / Home).
///
/// Each concrete manager (`OathManager`, `FidoManager`, `PivManager`,
/// `ManagementManager`) registers its own MethodChannel and processes
/// incoming connections via `processYubiKey(_:)`.
protocol AppContextManager: AnyObject {

    /// Channel name suffix used to namespace this app's MethodChannel.
    /// e.g. `"oath"` → `"com.yubico.authenticator/oath"`.
    static var channelSuffix: String { get }

    /// Called by `DeviceManager` when a connection becomes available
    /// (USB attach, NFC tap) and this manager is the active context.
    func processYubiKey(_ connection: any SmartCardConnection) async throws

    /// Called when the user navigates away from this manager's section.
    func onPause()
}
