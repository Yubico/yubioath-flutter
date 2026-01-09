/*
 * Copyright (C) 2023-2025 Yubico.
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

import 'dart:io';
import 'dart:ui';

import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import '../../app/logging.dart';
import '_wm_helper_macos_impl.dart';
import '_wm_helper_windows_impl.dart';
import 'defaults.dart';

final _log = Logger('window_manager_helper.init');

const String _keyLeft = 'DESKTOP_WINDOW_LEFT';
const String _keyTop = 'DESKTOP_WINDOW_TOP';
const String _keyWidth = 'DESKTOP_WINDOW_WIDTH';
const String _keyHeight = 'DESKTOP_WINDOW_HEIGHT';

extension RectLogging on Rect {
  String get pretty =>
      'Rect(left: $left, top: $top, width: $width, height: $height)';
}

class WindowManagerHelper {
  final SharedPreferences sharedPreferences;

  factory WindowManagerHelper.withPreferences(SharedPreferences preferences) {
    return WindowManagerHelper._(preferences);
  }

  WindowManagerHelper._(this.sharedPreferences);

  /// Persist the current window state to preferences
  Future<void> saveWindowManagerProperties() async {
    final bounds = _clampSize(await getBounds());
    await writeBounds(bounds);

    if (Platform.isMacOS) {
      await WindowManagerHelperMacOs.saveWindowManagerProperties(
        sharedPreferences,
      );
    } else if (Platform.isWindows) {
      await WindowManagerHelperWindows.saveWindowManagerProperties(
        sharedPreferences,
      );
    }

    _log.debug('Window manager properties saved.');
  }

  /// Load and apply the saved window state from preferences
  Future<void> restoreWindowManagerProperties() async {
    final savedBounds = Rect.fromLTWH(
      sharedPreferences.getDouble(_keyLeft) ?? WindowDefaults.bounds.left,
      sharedPreferences.getDouble(_keyTop) ?? WindowDefaults.bounds.top,
      sharedPreferences.getDouble(_keyWidth) ?? WindowDefaults.bounds.width,
      sharedPreferences.getDouble(_keyHeight) ?? WindowDefaults.bounds.height,
    );
    final bounds = _clampSize(savedBounds);

    if (bounds != savedBounds) {
      _log.warning(
        'Preference value for window bounds was invalid, overwriting with fixed value',
      );
      await writeBounds(bounds);
    }

    _log.debug('Using saved window bounds (or defaults): ${bounds.pretty}');

    if (Platform.isMacOS) {
      await WindowManagerHelperMacOs.restoreWindowManagerProperties(
        sharedPreferences,
        bounds,
      );
    } else if (Platform.isWindows) {
      await WindowManagerHelperWindows.restoreWindowManagerProperties(
        sharedPreferences,
        bounds,
      );
    }
  }

  /// Get current bounds
  Future<Rect> getBounds() async {
    if (Platform.isMacOS) {
      return await WindowManagerHelperMacOs.getBounds();
    } else if (Platform.isWindows) {
      return await WindowManagerHelperWindows.getBounds();
    } else {
      final size = await windowManager.getSize();
      return Rect.fromLTWH(
        WindowDefaults.bounds.left,
        WindowDefaults.bounds.top,
        size.width,
        size.height,
      );
    }
  }

  /// Set rect as the window bounds
  Future<void> setBounds(Rect rect) async {
    if (Platform.isMacOS) {
      await WindowManagerHelperMacOs.setBounds(sharedPreferences, rect);
    } else if (Platform.isWindows) {
      await WindowManagerHelperWindows.setBounds(sharedPreferences, rect);
    } else {
      await windowManager.setSize(rect.size);
    }
  }

  Future<void> writeBounds(Rect bounds) async {
    if (await sharedPreferences.setDouble(_keyWidth, bounds.width) &&
        await sharedPreferences.setDouble(_keyHeight, bounds.height) &&
        await sharedPreferences.setDouble(_keyLeft, bounds.left) &&
        await sharedPreferences.setDouble(_keyTop, bounds.top) != true) {
      _log.warning('Failed to write bounds');
    } else {
      _log.debug('Wrote window bounds: ${bounds.pretty}');
    }
  }

  /// Restrict the values
  static Rect _clampSize(Rect rect) {
    final width = rect.width < WindowDefaults.minWidth
        ? WindowDefaults.minWidth
        : rect.width > WindowDefaults.maxWidth
        ? WindowDefaults.defaultWidth
        : rect.width;
    final height = rect.height < WindowDefaults.minHeight
        ? WindowDefaults.minHeight
        : rect.height > WindowDefaults.maxHeight
        ? WindowDefaults.defaultHeight
        : rect.height;
    final clamped = Rect.fromLTWH(rect.left, rect.top, width, height);
    _log.debug('Clamped ${rect.pretty} to ${clamped.pretty}');

    return clamped;
  }
}
