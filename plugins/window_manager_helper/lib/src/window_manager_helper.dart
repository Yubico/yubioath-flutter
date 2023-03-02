import 'dart:io';
import 'dart:ui';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import 'window_manager_helper_windows.dart';
import 'window_manager_helper_macos.dart';

class WindowManagerHelper {
  final SharedPreferences sharedPreferences;

  factory WindowManagerHelper.withPreferences(SharedPreferences preferences) {
    return WindowManagerHelper._(preferences);
  }

  WindowManagerHelper._(this.sharedPreferences);

  Future<String?> getPlatformVersion() {
    if (Platform.isWindows) {
      return WindowsImpl.getPlatformVersion();
    } else {
      throw UnimplementedError(
          'This platform is not supported or expected to call this method');
    }
  }

  Future<Rect> getBounds() async {
    if (Platform.isMacOS) {
      return await MacOsImpl.getBounds(sharedPreferences);
    } else if (Platform.isWindows) {
      return await WindowsImpl.getBounds(sharedPreferences);
    } else {
      final size = await windowManager.getSize();
      return Rect.fromLTWH(10, 10, size.width, size.height);
    }
  }

  Future<void> setBounds(Rect r) async {
    if (Platform.isMacOS) {
      await MacOsImpl.setBounds(sharedPreferences, r);
    } else if (Platform.isWindows) {
      await WindowsImpl.setBounds(sharedPreferences, r);
    } else {
      await windowManager.setSize(r.size);
    }
  }
}
