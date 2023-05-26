/*
 * Copyright (C) 2023 Yubico.
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

import 'package:screen_retriever/screen_retriever.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import 'defaults.dart';

class WindowManagerHelperWindows {
  static const _keyPrimaryScaleFactor = 'DESKTOP_PRIMARY_SCALE_FACTOR';
  static const _keyAllDisplaysValue = 'DESKTOP_SCREEN_SETUP';

  static Future<String> _getAllDisplays() async {
    final allDisplays = await screenRetriever.getAllDisplays();
    return base64Encode(utf8.encode(jsonEncode(allDisplays)));
  }

  static Future<bool> _displayConfigurationChanged(
      SharedPreferences sharedPreferences) async {
    final allDisplays =
        sharedPreferences.get(_keyAllDisplaysValue) as String? ?? '';
    return await _getAllDisplays() != allDisplays;
  }

  static bool _displayContainsBounds(Display d, Rect rect) {
    final displayRect = Rect.fromLTWH(
        d.visiblePosition?.dx ?? 0.0,
        d.visiblePosition?.dy ?? 0.0,
        d.visibleSize?.width ?? 0.0,
        d.visibleSize?.height ?? 0.0);

    // validate top bounds of the rectangle
    // the translations limit amount of minimum vertical and horizontal distance
    // which needs to be present to allow mouse interaction
    return displayRect.contains(rect.topLeft.translate(48.0, 48.0)) ||
        displayRect.contains(rect.topCenter.translate(0.0, 48.0));
  }

  static Future<void> setBounds(SharedPreferences prefs, Rect bounds) async {
    await windowManager.setMinimumSize(WindowDefaults.minSize);

    final primaryDisplay = await screenRetriever.getPrimaryDisplay();
    final primaryScaleFactor = primaryDisplay.scaleFactor?.toDouble() ?? 1.0;
    final savedScaleFactor = prefs.getDouble(_keyPrimaryScaleFactor) ?? 1.0;

    final savedBounds = Rect.fromLTWH(
      bounds.left,
      bounds.top,
      bounds.width / savedScaleFactor * primaryScaleFactor,
      bounds.height / savedScaleFactor * primaryScaleFactor,
    );

    final configChanged = await _displayConfigurationChanged(prefs);
    final windowRect =
        !configChanged || _displayContainsBounds(primaryDisplay, savedBounds)
            ? savedBounds
            : WindowDefaults.bounds;

    await windowManager.setBounds(windowRect);
  }

  static Future<Rect> getBounds(SharedPreferences prefs) async {
    final primaryDisplay = await screenRetriever.getPrimaryDisplay();
    final primaryScaleFactor = primaryDisplay.scaleFactor?.toDouble() ?? 1.0;
    final windowPixelRatio =
        PlatformDispatcher.instance.views.first.devicePixelRatio;

    final rect = await windowManager.getBounds();

    final windowRect = Rect.fromLTWH(
        rect.left / primaryScaleFactor * windowPixelRatio,
        rect.top / primaryScaleFactor * windowPixelRatio,
        rect.width,
        rect.height);

    await prefs.setDouble(_keyPrimaryScaleFactor, primaryScaleFactor);

    final allDisplaysValue = await _getAllDisplays();
    await prefs.setString(_keyAllDisplaysValue, allDisplaysValue);

    return windowRect;
  }
}
