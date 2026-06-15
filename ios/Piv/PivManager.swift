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

/// MethodChannel handler for PIV operations.
///
/// Mirrors `android/.../piv/PivManager.kt`. Will own:
///  - PIV state + slot metadata
///  - PIN / PUK / management-key operations (incl. PIN-protected MGM)
///  - certificate read / import / export / generate
///  - key generation, signing, attestation
///  - reset
///
/// Pivman data and key-material parsing utilities (Android
/// `PivmanUtils.kt`, `KeyMaterialParser.kt`, `CertificateUtils.kt`,
/// `X500DnUtils.kt`) translate directly — re-implement as needed using
/// `Security.framework` for ASN.1 / certs.
final class PivManager: AppContextManager {
    static let channelSuffix = "piv"
    static let channelName = "com.yubico.authenticator/\(channelSuffix)"

    static func register(with messenger: FlutterBinaryMessenger) {
        // TODO: register MethodChannel.
    }

    func processYubiKey(_ connection: any SmartCardConnection) async throws {
        // TODO: open PIVSession, refresh state.
    }

    func onPause() {
        // TODO.
    }
}
