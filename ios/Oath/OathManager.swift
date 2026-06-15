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

/// MethodChannel handler for OATH operations.
///
/// Mirrors `android/.../oath/OathManager.kt`. Will own:
///  - opening `OATHSession` and (if needed) unlocking it via stored access key
///  - listing / calculating credentials
///  - adding / renaming / deleting credentials
///  - reset
///  - access-key set/unset, "remember password" via iOS Keychain
///    (analog of Android `KeyManager` + `keystore/`).
///
/// Channel name will be `"com.yubico.authenticator/oath"`.
final class OathManager: AppContextManager {
    static let channelSuffix = "oath"
    static let channelName = "com.yubico.authenticator/\(channelSuffix)"

    static func register(with messenger: FlutterBinaryMessenger) {
        // TODO: register MethodChannel and route calls to instance methods.
    }

    func processYubiKey(_ connection: any SmartCardConnection) async throws {
        // TODO: open OATHSession, refresh state, push to Dart.
    }

    func onPause() {
        // TODO: drop pending operations / clear in-flight state.
    }
}
