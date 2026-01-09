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
      'size=[${d.size.width}, ${d.size.height}],'
      'visiblePosition=[${d.visiblePosition?.dx},${d.visiblePosition?.dy}],'
      'visibleSize=[${d.visibleSize?.width}, ${d.visibleSize?.height}],'
      'scaleFactor=${d.scaleFactor}';

  static String _encodeDisplayList(List<Display> displays) {
    for (var d in displays) {
      _log.debug('Display found: ${_displayInfo(d)}');
    }
    return base64Encode(utf8.encode(jsonEncode(displays)));
  }

  static Future<bool> _displayConfigurationChanged(
    SharedPreferences sharedPreferences,
    List<Display> displays,
  ) async {
    final persistedDisplayList =
        sharedPreferences.get(_keyAllDisplaysValue) as String? ?? '';
    final encodedDisplayList = _encodeDisplayList(displays);
    var changed = encodedDisplayList != persistedDisplayList;
    _log.debug('Display configuration changed: $changed');
    if (changed) {
      _log.debug('Prefs value  : $persistedDisplayList');
      _log.debug('Current value: $encodedDisplayList');
    }
    return changed;
  }

  /// Returns true if the rect coordinates are present in any of the displays.
  static bool _isRectOnAnyDisplay(List<Display> allDisplays, Rect rect) =>
      allDisplays.any((d) => _isRectOnDisplay(d, rect));

  /// Returns true if the rect coordinates are present in the display.
  /// Validates the top left and adjusted top center points for mouse interaction.
  static bool _isRectOnDisplay(Display d, Rect rect) {
    final displayRect = Rect.fromLTWH(
      d.visiblePosition?.dx ?? 0.0,
      d.visiblePosition?.dy ?? 0.0,
      d.visibleSize?.width ?? 0.0,
      d.visibleSize?.height ?? 0.0,
    );

    bool isWithinBounds =
        displayRect.contains(rect.topLeft.translate(48.0, 48.0)) ||
        displayRect.contains(rect.topCenter.translate(0.0, 48.0));

    _log.debug('Display        : ${_displayInfo(d)}');
    _log.debug('Rect           : ${rect.pretty}');
    _log.debug('Rect on display: $isWithinBounds');
    return isWithinBounds;
  }

  static Future<void> saveWindowManagerProperties(
    SharedPreferences prefs,
  ) async {
    final primaryDisplay = await screenRetriever.getPrimaryDisplay();
    final allDisplays = await screenRetriever.getAllDisplays();
    final primaryScaleFactor = primaryDisplay.scaleFactor?.toDouble() ?? 1.0;
    await prefs.setDouble(_keyPrimaryScaleFactor, primaryScaleFactor);
    final allDisplaysValue = _encodeDisplayList(allDisplays);
    await prefs.setString(_keyAllDisplaysValue, allDisplaysValue);
  }

  static Future<void> restoreWindowManagerProperties(
    SharedPreferences prefs,
    Rect bounds,
  ) async {
    await setBounds(prefs, bounds);
  }

  static Future<void> setBounds(SharedPreferences prefs, Rect bounds) async {
    await windowManager.setMinimumSize(WindowDefaults.minSize);

    final savedScaleFactor = prefs.getDouble(_keyPrimaryScaleFactor);
    final hasSavedScaleFactor = savedScaleFactor != null;
    final windowPixelRatio =
        PlatformDispatcher.instance.views.first.devicePixelRatio;

    var height = hasSavedScaleFactor
        ? bounds.height / savedScaleFactor * windowPixelRatio
        : bounds.height;
    var width = hasSavedScaleFactor
        ? bounds.width / savedScaleFactor * windowPixelRatio
        : bounds.width;

    final savedBounds = Rect.fromLTWH(bounds.left, bounds.top, width, height);
    final allDisplays = await screenRetriever.getAllDisplays();
    final configChanged = await _displayConfigurationChanged(
      prefs,
      allDisplays,
    );
    final windowRect =
        (!configChanged && _isRectOnAnyDisplay(allDisplays, savedBounds))
        ? savedBounds
        : Rect.fromLTWH(
            WindowDefaults.bounds.left,
            WindowDefaults.bounds.top,
            width,
            height,
          );

    _log.debug('setBounds: ${windowRect.pretty}');
    await windowManager.setBounds(windowRect);
  }

  static Future<Rect> getBounds() async {
    final primaryDisplay = await screenRetriever.getPrimaryDisplay();
    final primaryScaleFactor = primaryDisplay.scaleFactor?.toDouble() ?? 1.0;
    final pixelRatio = PlatformDispatcher.instance.views.first.devicePixelRatio;

    final rect = await windowManager.getBounds();
    final windowRect = Rect.fromLTWH(
      rect.left / primaryScaleFactor * pixelRatio,
      rect.top / primaryScaleFactor * pixelRatio,
      rect.width,
      rect.height,
    );

    _log.debug('getBounds: ${windowRect.pretty}');
    return windowRect;
  }
}
