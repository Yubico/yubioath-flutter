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

import 'package:flutter/material.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import 'defaults.dart';

class WindowManagerHelperMacOs {
  static const _keyPosDisplay = 'DESKTOP_WINDOW_POS_DISPLAY';

  static Future<void> saveWindowManagerProperties(
    SharedPreferences prefs,
  ) async {
    final size = await windowManager.getSize();
    final offset = await windowManager.getPosition();
    var result = await _findCurrentDisplayAndLocalOffset(offset, size);
    if (result != null) {
      await prefs.setString(_keyPosDisplay, result.displayName);
    }
  }

  static Future<void> restoreWindowManagerProperties(
    SharedPreferences prefs,
    Rect bounds,
  ) async {
    await windowManager.setMinimumSize(WindowDefaults.minSize);

    final width = bounds.width;
    final height = bounds.height;
    final posX = bounds.left;
    final posY = bounds.top;

    final posDisplay = prefs.getString(_keyPosDisplay);

    if (posDisplay != null) {
      final displays = await screenRetriever.getAllDisplays();
      for (var d in displays) {
        if (d.name == posDisplay) {
          var globalPos = Offset(
            10 + d.visiblePosition!.dx,
            10 + d.visiblePosition!.dy,
          );
          if ((posX >= 0) &&
              (posX < d.visibleSize!.width) &&
              (posY >= 0) &&
              (posY < d.visibleSize!.height)) {
            // if the local position exists on the display, use it
            globalPos = Offset(
              posX + d.visiblePosition!.dx,
              posY + d.visiblePosition!.dy,
            );
          }

          await windowManager.setBounds(
            null,
            size: Size(width, height),
            position: Offset(globalPos.dx, globalPos.dy),
          );
        }
      }
    }
  }

  static Future<void> setBounds(SharedPreferences prefs, Rect bounds) async {
    await windowManager.setMinimumSize(WindowDefaults.minSize);

    final width = bounds.width;
    final height = bounds.height;
    final posX = bounds.left;
    final posY = bounds.top;

    final posDisplay = prefs.getString(_keyPosDisplay);

    if (posDisplay != null) {
      final displays = await screenRetriever.getAllDisplays();
      for (var d in displays) {
        if (d.name == posDisplay) {
          var globalPos = Offset(
            10 + d.visiblePosition!.dx,
            10 + d.visiblePosition!.dy,
          );
          if ((posX >= 0) &&
              (posX < d.visibleSize!.width) &&
              (posY >= 0) &&
              (posY < d.visibleSize!.height)) {
            // if the local position exists on the display, use it
            globalPos = Offset(
              posX + d.visiblePosition!.dx,
              posY + d.visiblePosition!.dy,
            );
          }

          await windowManager.setBounds(
            null,
            size: Size(width, height),
            position: Offset(globalPos.dx, globalPos.dy),
          );
        }
      }
    }
  }

  static Future<Rect> getBounds() async {
    final size = await windowManager.getSize();
    final offset = await windowManager.getPosition();
    var result = await _findCurrentDisplayAndLocalOffset(offset, size);
    if (result != null) {
      return Rect.fromLTWH(
        result.localOffset.dx,
        result.localOffset.dy,
        size.width,
        size.height,
      );
    }

    return WindowDefaults.bounds;
  }

  static Future<({String displayName, Offset localOffset})?>
  _findCurrentDisplayAndLocalOffset(
    Offset windowOffset,
    Size windowSize,
  ) async {
    final displays = await screenRetriever.getAllDisplays();
    for (var d in displays) {
      if (d.visiblePosition != null &&
          d.visibleSize != null &&
          d.name != null) {
        final windowCenter = Offset(
          windowOffset.dx + windowSize.width / 2.0,
          windowOffset.dy + windowSize.height / 2.0,
        );
        if ((windowCenter.dx >= d.visiblePosition!.dx) &&
            (windowCenter.dx <
                (d.visiblePosition!.dx + d.visibleSize!.width)) &&
            (windowCenter.dy >= d.visiblePosition!.dy) &&
            (windowCenter.dy <
                (d.visiblePosition!.dy + d.visibleSize!.height))) {
          final localOffset = Offset(
            windowOffset.dx - d.visiblePosition!.dx,
            windowOffset.dy - d.visiblePosition!.dy,
          );
          return (
            displayName: d.name ?? 'Unknown name',
            localOffset: localOffset,
          );
        }
      }
    }
    return null;
  }
}
