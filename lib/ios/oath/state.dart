/*
 * Copyright (C) 2026 Yubico.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *       http://www.apache.org/licenses/LICENSE-2.0
 */

// iOS OATH state providers. Mirrors `lib/android/oath/state.dart`.
//
// Will provide:
//  - IosOathStateNotifier           (overrides oathStateProvider)
//  - IosCredentialListNotifier      (overrides credentialListProvider)
//
// Both delegate to the `com.yubico.authenticator/oath` MethodChannel
// implemented by `ios/Runner/Oath/OathManager.swift`.
