/*
 * Copyright (C) 2026 Yubico.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *       http://www.apache.org/licenses/LICENSE-2.0
 */

// iOS FIDO state providers. Mirrors `lib/android/fido/state.dart`.
//
// Will provide:
//  - IosFidoStateNotifier           (overrides fidoStateProvider)
//  - IosFidoFingerprintsNotifier    (overrides fingerprintProvider)
//  - IosFidoCredentialsNotifier     (overrides credentialProvider)
//
// All delegate to `com.yubico.authenticator/fido` →
// `ios/Runner/Fido/FidoManager.swift`.
