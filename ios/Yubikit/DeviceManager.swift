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

/// Tracks attached/available YubiKeys and dispatches connections to the
/// active `AppContextManager`.
///
/// Mirrors `android/.../device/DeviceManager.kt`. Stub for now.
///
/// Responsibilities to implement:
///  - observe `WiredSmartCardConnection` attachment/detachment via the
///    yubikit-swift connection-state stream (USB / Lightning / 5Ci)
///  - hold the currently active `AppContextManager` and forward
///    connections (USB always-on, NFC tap-driven)
///  - expose the current `DeviceInfo` to Dart via a dedicated channel
///    (analog of Android `DEVICE_INFO_CHANGED` events)
final class DeviceManager {
    // TODO: implement once basic per-app channels exist.
}
