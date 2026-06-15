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

/// MethodChannel handler for FIDO2 / passkeys operations.
///
/// Mirrors `android/.../fido/FidoManager.kt`. Will own:
///  - opening `FIDO2Session`
///  - PIN/UV setup, change, verify
///  - resident-credential listing / deletion
///  - fingerprint enrollment (bio-keys)
///  - reset
///
/// Notes vs Android:
///  - PIN/UV-auth-token cache (Android `PersistentPinUvAuthTokenStore`)
///    should use iOS Keychain instead of EncryptedSharedPreferences.
///  - U2F is not exposed by yubikit-swift over CCID on iOS today.
final class FidoManager: AppContextManager {
    static let channelSuffix = "fido"
    static let channelName = "com.yubico.authenticator/\(channelSuffix)"

    static func register(with messenger: FlutterBinaryMessenger) {
        // TODO: register MethodChannel.
    }

    func processYubiKey(_ connection: any SmartCardConnection) async throws {
        // TODO: open FIDO2Session, push state to Dart.
    }

    func onPause() {
        // TODO.
    }
}
