import 'dart:io';
import 'dart:ui';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import '_wm_helper_windows_impl.dart';
import '_wm_helper_macos_impl.dart';

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
      return Rect.fromLTWH(10, 10, size.width, size.height);
    }
  }

  Future<void> setBounds(Rect r) async {
    if (Platform.isMacOS) {
      await WindowManagerHelperMacOs.setBounds(sharedPreferences, r);
    } else if (Platform.isWindows) {
      await WindowManagerHelperWindows.setBounds(sharedPreferences, r);
    } else {
      await windowManager.setSize(r.size);
    }
  }
}
