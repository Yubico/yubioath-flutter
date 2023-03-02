import 'dart:convert';
import 'dart:ui';

import 'package:screen_retriever/screen_retriever.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import 'window_manager_helper_default.dart';
import 'window_manager_helper_platform_interface.dart';

class WindowsImpl {
  static const _keyPrimaryScaleFactor = 'DESKTOP_PRIMARY_SCALE_FACTOR';
  static const _keyAllDisplaysValue = 'DESKTOP_SCREEN_SETUP';

  static Future<String?> getPlatformVersion() {
    return WindowManagerHelperPlatform.instance.getPlatformVersion();
  }

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

  static Future<void> setBounds(SharedPreferences prefs, Rect bounds) async {
    await WindowManagerHelperPlatform.instance.init();
    await windowManager.setMinimumSize(const Size(minimumWidth, 0));

    final primaryDisplay = await screenRetriever.getPrimaryDisplay();
    final double primaryScaleFactor =
        primaryDisplay.scaleFactor?.toDouble() ?? 1.0;

    final savedPrimaryScaleFactor =
        prefs.getDouble(_keyPrimaryScaleFactor) ?? 1.0;

    final configChanged = await _displayConfigurationChanged(prefs);
    final windowRect = (configChanged)
        ? defaultWindowBounds
        : Rect.fromLTWH(
            bounds.left,
            bounds.top,
            bounds.width / savedPrimaryScaleFactor * primaryScaleFactor,
            bounds.height / savedPrimaryScaleFactor * primaryScaleFactor,
          );

    await WindowManagerHelperPlatform.instance.setWindowBounds(windowRect);
  }

  static Future<Rect> getBounds(SharedPreferences prefs) async {
    final windowRect =
        await WindowManagerHelperPlatform.instance.getWindowBounds();
    final primaryDisplay = await screenRetriever.getPrimaryDisplay();

    final double pdFactor = primaryDisplay.scaleFactor?.toDouble() ?? 1.0;
    final double pWidth = windowRect.width * pdFactor / window.devicePixelRatio;
    final double pHeight =
        windowRect.height * pdFactor / window.devicePixelRatio;

    await prefs.setDouble(_keyPrimaryScaleFactor, pdFactor);

    final allDisplaysValue = await _getAllDisplays();
    await prefs.setString(_keyAllDisplaysValue, allDisplaysValue);

    return Rect.fromLTWH(windowRect.left, windowRect.top, pWidth, pHeight);
  }
}
