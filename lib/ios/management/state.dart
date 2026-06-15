/*
 * Copyright (C) 2026 Yubico.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *       http://www.apache.org/licenses/LICENSE-2.0
 */

// iOS Management state providers. Mirrors `lib/android/management/state.dart`.
//
// Will provide:
//  - IosManagementStateNotifier     (overrides managementStateProvider)
//
// Delegates to `com.yubico.authenticator/management` →
// `ios/Runner/Management/ManagementManager.swift`.
