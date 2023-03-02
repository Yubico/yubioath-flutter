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

import 'dart:io';
import 'dart:ui';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import '_wm_helper_macos_impl.dart';
import '_wm_helper_windows_impl.dart';
import 'defaults.dart';

class WindowManagerHelper {
  final SharedPreferences sharedPreferences;

  factory WindowManagerHelper.withPreferences(SharedPreferences preferences) {
    return WindowManagerHelper._(preferences);
  }

  WindowManagerHelper._(this.sharedPreferences);

  Future<Rect> getBounds() async {
    if (Platform.isMacOS) {
      return await WindowManagerHelperMacOs.getBounds(sharedPreferences);
    } else if (Platform.isWindows) {
      return await WindowManagerHelperWindows.getBounds(sharedPreferences);
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

  Future<void> setBounds(Rect rect) async {
    if (Platform.isMacOS) {
      await WindowManagerHelperMacOs.setBounds(sharedPreferences, rect);
    } else if (Platform.isWindows) {
      await WindowManagerHelperWindows.setBounds(sharedPreferences, rect);
    } else {
      await windowManager.setSize(rect.size);
    }
  }
}
