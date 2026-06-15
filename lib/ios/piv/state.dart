/*
 * Copyright (C) 2026 Yubico.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *       http://www.apache.org/licenses/LICENSE-2.0
 */

// iOS PIV state providers. Mirrors `lib/android/piv/state.dart`.
//
// Will provide:
//  - IosPivStateNotifier            (overrides pivStateProvider)
//  - IosPivSlotsNotifier            (overrides pivSlotsProvider)
//
// Delegates to `com.yubico.authenticator/piv` →
// `ios/Runner/Piv/PivManager.swift`.
