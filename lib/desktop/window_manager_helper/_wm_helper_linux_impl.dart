/*
 * Copyright (C) 2026 Yubico.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *       http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:ui';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import 'defaults.dart';

/// Linux-specific window manager implementation.
///
/// IMPORTANT: Linux (especially Wayland) does NOT support window position APIs:
/// - Wayland: gtk_window_get_position() always returns (0, 0)
/// - X11: Position is unreliable due to window manager decorations
///
/// Therefore, this implementation only handles window SIZE, not position.
/// Window positioning is controlled by the window manager on Linux.
class WindowManagerHelperLinux {
  static Future<void> saveWindowManagerProperties(
    SharedPreferences prefs,
  ) async {
    // Linux: Currently no additional properties to save
  }

  static Future<void> restoreWindowManagerProperties(
    SharedPreferences prefs,
    Rect bounds,
  ) async {
    await setBounds(prefs, bounds);
  }

  static Future<void> setBounds(SharedPreferences prefs, Rect bounds) async {
    await windowManager.setMinimumSize(WindowDefaults.minSize);
    // Only set size - position is controlled by window manager
    await windowManager.setSize(bounds.size);
  }

  static Future<Rect> getBounds() async {
    final size = await windowManager.getSize();

    // Return size with default position (position not retrievable on Linux)
    // See: https://docs.gtk.org/gtk3/method.Window.get_position.html
    // "This function returns the position you need to pass to gtk_window_move()
    // to keep window in its current position...On Wayland, this function always
    // returns (0, 0)."
    final bounds = Rect.fromLTWH(
      WindowDefaults.bounds.left,
      WindowDefaults.bounds.top,
      size.width,
      size.height,
    );

    return bounds;
  }
}
