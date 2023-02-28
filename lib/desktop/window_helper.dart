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

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:logging/logging.dart';
import 'package:platform_util/platform_util.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import 'package:yubico_authenticator/app/logging.dart';
import 'package:yubico_authenticator/desktop/state.dart';

final _log = Logger('window_helper');

class _ScreenRetrieverListener extends ScreenListener {
  final WindowHelper _windowHelper;

  _ScreenRetrieverListener(this._windowHelper);

  @override
  void onScreenEvent(String eventName) async {
    _log.debug('Screen event: $eventName');
    _windowHelper.save();
  }
}

class _WindowManagerListener extends WindowListener {
  final WindowHelper _windowHelper;

  _WindowManagerListener(this._windowHelper);

  @override
  void onWindowResized() async {
    _log.debug('onWindowResized');
    _windowHelper.save();
  }

  @override
  void onWindowMoved() async {
    _log.debug('onWindowMoved');
    _windowHelper.save();
  }

  @override
  void onWindowClose() async {
    if (Platform.isMacOS) {
      await windowManager.destroy();
    }
  }
}

class WindowHelper {
  final SharedPreferences _prefs;

  static const _defaultPosX = 10.0;
  static const _defaultPosY = 10.0;
  static const _defaultWidth = 400.0;
  static const _defaultHeight = 720.0;
  static const _minimumWidth = 270.0;
  static const _defaultWindowRect =
      Rect.fromLTWH(_defaultPosX, _defaultPosY, _defaultWidth, _defaultHeight);
  static const _keyWidth = 'DESKTOP_WINDOW_WIDTH';
  static const _keyHeight = 'DESKTOP_WINDOW_HEIGHT';
  static const _keyPosDisplay = 'DESKTOP_WINDOW_POS_DISPLAY';
  static const _keyPosX = 'DESKTOP_WINDOW_POS_X';
  static const _keyPosY = 'DESKTOP_WINDOW_POS_Y';
  static const _keyPrimaryScaleFactor = 'DESKTOP_PRIMARY_SCALE_FACTOR';
  static const _keyAllDisplaysValue = 'DESKTOP_SCREEN_SETUP';

  const WindowHelper(this._prefs);

  Future<String> _getAllDisplays() async {
    final allDisplays = await screenRetriever.getAllDisplays();
    return base64Encode(utf8.encode(jsonEncode(allDisplays)));
  }

  Future<bool> _displayConfigurationChanged(
      SharedPreferences sharedPreferences) async {
    final allDisplays =
        sharedPreferences.get(_keyAllDisplaysValue) as String? ?? '';
    return await _getAllDisplays() != allDisplays;
  }

  void save() async {
    if (Platform.isWindows) {
      _saveWindows();
    } else if (Platform.isMacOS) {
      _saveMacOs();
    } else if (Platform.isLinux) {
      _saveLinux();
    }
  }

  void initialize() async {

    final isHidden = _prefs.getBool(windowHidden) ?? false;

    unawaited(windowManager.waitUntilReadyToShow().then((_) async {
      if (Platform.isWindows) {
        _loadWindows();
      } else if (Platform.isMacOS) {
        _loadMacOs();
      } else if (Platform.isLinux) {
        _loadLinux();
      }

      await windowManager.setSkipTaskbar(isHidden);
      if (!isHidden) {
        await windowManager.show();
      }

      windowManager.addListener(_WindowManagerListener(this));
      screenRetriever.addListener(_ScreenRetrieverListener(this));
    }));
  }

  void _saveWindows() async {
    final windowRect = await platformUtil.getWindowRect();
    final primaryDisplay = await screenRetriever.getPrimaryDisplay();

    final dpi = window.devicePixelRatio * 96.0;

    final double pdFactor = primaryDisplay.scaleFactor?.toDouble() ?? 1.0;
    final double pWidth = windowRect.width * pdFactor / window.devicePixelRatio;
    final double pHeight =
        windowRect.height * pdFactor / window.devicePixelRatio;

    _log.debug('SharedPreferences saving window rect ['
        '${windowRect.left.toInt()},${windowRect.top.toInt()};'
        '${pWidth.toInt()}x${pHeight.toInt()}] '
        'windowDpi=$dpi windowScaleFactor=${window.devicePixelRatio}');
    await _prefs.setDouble(_keyPosX, windowRect.left);
    await _prefs.setDouble(_keyPosY, windowRect.top);
    await _prefs.setDouble(_keyWidth, pWidth);
    await _prefs.setDouble(_keyHeight, pHeight);
    await _prefs.setDouble(_keyPrimaryScaleFactor, pdFactor);
    final allDisplaysValue = await _getAllDisplays();
    _log.debug('AllDisplaysValue on save: $allDisplaysValue');
    await _prefs.setString(_keyAllDisplaysValue, allDisplaysValue);
  }

  void _saveMacOs() async {
    final size = await windowManager.getSize();
    final offset = await windowManager.getPosition();
    final displays = await screenRetriever.getAllDisplays();

    for (var d in displays) {
      if (d.visiblePosition != null &&
          d.visibleSize != null &&
          d.name != null) {
        final windowCenter =
            Offset(offset.dx + size.width / 2.0, offset.dy + size.height / 2.0);
        if ((windowCenter.dx >= d.visiblePosition!.dx) &&
            (windowCenter.dx <
                (d.visiblePosition!.dx + d.visibleSize!.width)) &&
            (windowCenter.dy >= d.visiblePosition!.dy) &&
            (windowCenter.dy <
                (d.visiblePosition!.dy + d.visibleSize!.height))) {
          final localOffset = Offset(offset.dx - d.visiblePosition!.dx,
              offset.dy - d.visiblePosition!.dy);
          _log.debug('Window moved to ${d.name}: '
              'global offset = $offset / local offset = $localOffset');
          await _prefs.setString(_keyPosDisplay, d.name!);
          await _prefs.setDouble(_keyPosX, localOffset.dx);
          await _prefs.setDouble(_keyPosY, localOffset.dy);
          await _prefs.setDouble(_keyWidth, size.width);
          await _prefs.setDouble(_keyHeight, size.height);
        }
      }
    }
  }

  void _saveLinux() async {
    final size = await windowManager.getSize();
    await _prefs.setDouble(_keyWidth, size.width);
    await _prefs.setDouble(_keyHeight, size.height);
  }

  void _loadWindows() async {
    await platformUtil.init();
    await windowManager.setMinimumSize(const Size(_minimumWidth, 0));

    final posX = _prefs.getDouble(_keyPosX) ?? _defaultPosX;
    final posY = _prefs.getDouble(_keyPosY) ?? _defaultPosY;
    final width = _prefs.getDouble(_keyWidth) ?? _defaultWidth;
    final height = _prefs.getDouble(_keyHeight) ?? _defaultHeight;

    final primaryDisplay = await screenRetriever.getPrimaryDisplay();
    final double primaryScaleFactor =
        primaryDisplay.scaleFactor?.toDouble() ?? 1.0;

    final savedPrimaryScaleFactor =
        _prefs.getDouble(_keyPrimaryScaleFactor) ?? 1.0;

    _log.debug(
        'SharedPreferences window position: [${posX.toInt()},${posY.toInt()}:'
        '${width.toInt()}x${height.toInt()}]');

    final configChanged = await _displayConfigurationChanged(_prefs);
    final windowRect = (configChanged)
        ? _defaultWindowRect
        : Rect.fromLTWH(
            posX,
            posY,
            width / savedPrimaryScaleFactor * primaryScaleFactor,
            height / savedPrimaryScaleFactor * primaryScaleFactor,
          );

    _log.debug(
        'Placing window to: [${windowRect.left.toInt()},${windowRect.top.toInt()}:'
        '${windowRect.width.toInt()}x${windowRect.height.toInt()}] '
        '(display configuration changed: $configChanged)');

    await platformUtil.setWindowRect(windowRect);
  }

  void _loadMacOs() async {
    await windowManager.setMinimumSize(const Size(_minimumWidth, 0));

    final width = _prefs.getDouble(_keyWidth) ?? _defaultWidth;
    final height = _prefs.getDouble(_keyHeight) ?? _defaultHeight;

    final posDisplay = _prefs.getString(_keyPosDisplay);
    final posX = _prefs.getDouble(_keyPosX);
    final posY = _prefs.getDouble(_keyPosY);

    _log.debug('Target display: $posDisplay');

    if (posDisplay != null && posX != null && posY != null) {
      final displays = await screenRetriever.getAllDisplays();
      for (var d in displays) {
        if (d.name == posDisplay) {
          _log.debug('Target display properties: ${d.id} ${d.name} '
              '${d.visiblePosition} ${d.visibleSize} '
              '${d.scaleFactor} ${d.size}');

          var globalPos =
              Offset(10 + d.visiblePosition!.dx, 10 + d.visiblePosition!.dy);
          if ((posX >= 0) &&
              (posX < d.visibleSize!.width) &&
              (posY >= 0) &&
              (posY < d.visibleSize!.height)) {
            // if the local position exists on the display, use it
            globalPos = Offset(
                posX + d.visiblePosition!.dx, posY + d.visiblePosition!.dy);
          }

          _log.debug('Setting window to ${d.name} on local pos '
              '$posX, $posY, global: $globalPos');
          await windowManager.setBounds(null,
              size: Size(width, height),
              position: Offset(globalPos.dx, globalPos.dy));
        }
      }
    }
  }

  void _loadLinux() async {
    // currently only window size is persisted
    await windowManager.setMinimumSize(const Size(_minimumWidth, 0));
    final width = _prefs.getDouble(_keyWidth) ?? _defaultWidth;
    final height = _prefs.getDouble(_keyHeight) ?? _defaultHeight;
    await windowManager.setSize(Size(width, height));
  }
}
