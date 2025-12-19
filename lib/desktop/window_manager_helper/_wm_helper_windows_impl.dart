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

import 'dart:convert';
import 'dart:ui';

import 'package:logging/logging.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import '../../app/logging.dart';
import 'defaults.dart';
import 'window_manager_helper.dart';

final _log = Logger('wm_helper_windows');

class WindowManagerHelperWindows {
  static const _keyPrimaryScaleFactor = 'DESKTOP_PRIMARY_SCALE_FACTOR';
  static const _keyAllDisplaysValue = 'DESKTOP_SCREEN_SETUP';

  static String _displayInfo(Display d) =>
      '[id=${d.id},name=${d.name},'
      'size=${d.size},visiblePosition=${d.visiblePosition},'
      'visibleSize=${d.visibleSize},scaleFactor=${d.scaleFactor}';

  static Future<String> _getAllDisplays() async {
    final allDisplays = await screenRetriever.getAllDisplays();
    for (var d in allDisplays) {
      _log.debug('Display found: ${_displayInfo(d)}');
    }
    return base64Encode(utf8.encode(jsonEncode(allDisplays)));
  }

  static Future<bool> _displayConfigurationChanged(
    SharedPreferences sharedPreferences,
  ) async {
    final allDisplays =
        sharedPreferences.get(_keyAllDisplaysValue) as String? ?? '';
    var displayConfigurationChanged = await _getAllDisplays() != allDisplays;
    _log.debug('Display configuration changed: $displayConfigurationChanged');
    return displayConfigurationChanged;
  }

  static bool _displayContainsBounds(Display d, Rect rect) {
    final displayRect = Rect.fromLTWH(
      d.visiblePosition?.dx ?? 0.0,
      d.visiblePosition?.dy ?? 0.0,
      d.visibleSize?.width ?? 0.0,
      d.visibleSize?.height ?? 0.0,
    );

    _log.debug('Checking displayContainsBounds');
    _log.debug('Display:         ${_displayInfo(d)}');
    _log.debug('Bounds:          ${rect.pretty}');

    // validate top bounds of the rectangle
    // the translations limit amount of minimum vertical and horizontal distance
    // which needs to be present to allow mouse interaction
    var containsBounds =
        displayRect.contains(rect.topLeft.translate(48.0, 48.0)) ||
        displayRect.contains(rect.topCenter.translate(0.0, 48.0));
    _log.debug('Contains bounds: $containsBounds');
    return containsBounds;
  }

  static Future<void> saveWindowManagerProperties(
    SharedPreferences prefs,
  ) async {
    final primaryDisplay = await screenRetriever.getPrimaryDisplay();
    final primaryScaleFactor = primaryDisplay.scaleFactor?.toDouble() ?? 1.0;
    await prefs.setDouble(_keyPrimaryScaleFactor, primaryScaleFactor);
    final allDisplaysValue = await _getAllDisplays();
    await prefs.setString(_keyAllDisplaysValue, allDisplaysValue);
  }

  static Future<void> restoreWindowManagerProperties(
    SharedPreferences prefs,
    Rect bounds,
  ) async {
    await windowManager.setMinimumSize(WindowDefaults.minSize);

    final primaryDisplay = await screenRetriever.getPrimaryDisplay();
    final primaryScaleFactor = primaryDisplay.scaleFactor?.toDouble() ?? 1.0;
    final savedScaleFactor = prefs.getDouble(_keyPrimaryScaleFactor);
    final hasSavedScaleFactor = savedScaleFactor != null;

    var height = hasSavedScaleFactor
        ? bounds.height / savedScaleFactor * primaryScaleFactor
        : bounds.height;
    var width = hasSavedScaleFactor
        ? bounds.width / savedScaleFactor * primaryScaleFactor
        : bounds.width;

    final savedBounds = Rect.fromLTWH(bounds.left, bounds.top, width, height);

    final configChanged = await _displayConfigurationChanged(prefs);
    final windowRect =
        !configChanged || _displayContainsBounds(primaryDisplay, savedBounds)
        ? savedBounds
        : WindowDefaults.bounds;

    await windowManager.setBounds(windowRect);
  }

  static Future<void> setBounds(SharedPreferences prefs, Rect bounds) async {
    await windowManager.setMinimumSize(WindowDefaults.minSize);

    final primaryDisplay = await screenRetriever.getPrimaryDisplay();
    final primaryScaleFactor = primaryDisplay.scaleFactor?.toDouble() ?? 1.0;
    final savedScaleFactor = prefs.getDouble(_keyPrimaryScaleFactor);
    final hasSavedScaleFactor = savedScaleFactor != null;

    var height = hasSavedScaleFactor
        ? bounds.height / savedScaleFactor * primaryScaleFactor
        : bounds.height;
    var width = hasSavedScaleFactor
        ? bounds.width / savedScaleFactor * primaryScaleFactor
        : bounds.width;

    final savedBounds = Rect.fromLTWH(bounds.left, bounds.top, width, height);

    final configChanged = await _displayConfigurationChanged(prefs);
    final windowRect =
        !configChanged || _displayContainsBounds(primaryDisplay, savedBounds)
        ? savedBounds
        : WindowDefaults.bounds;

    await windowManager.setBounds(windowRect);
  }

  static Future<Rect> getBounds() async {
    final primaryDisplay = await screenRetriever.getPrimaryDisplay();
    final primaryScaleFactor = primaryDisplay.scaleFactor?.toDouble() ?? 1.0;
    final windowPixelRatio =
        PlatformDispatcher.instance.views.first.devicePixelRatio;

    final rect = await windowManager.getBounds();

    final windowRect = Rect.fromLTWH(
      rect.left / primaryScaleFactor * windowPixelRatio,
      rect.top / primaryScaleFactor * windowPixelRatio,
      rect.width,
      rect.height,
    );
    return windowRect;
  }
}
