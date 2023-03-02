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

  static Future<void> setBounds(SharedPreferences prefs, Rect bounds) async {
    await windowManager.setMinimumSize(WindowDefaults.minSize);

    final primaryDisplay = await screenRetriever.getPrimaryDisplay();
    final primaryScaleFactor = primaryDisplay.scaleFactor?.toDouble() ?? 1.0;
    final savedScaleFactor = prefs.getDouble(_keyPrimaryScaleFactor) ?? 1.0;

    final configChanged = await _displayConfigurationChanged(prefs);
    final windowRect = configChanged
        ? WindowDefaults.bounds
        : Rect.fromLTWH(
            bounds.left,
            bounds.top,
            bounds.width / savedScaleFactor * primaryScaleFactor,
            bounds.height / savedScaleFactor * primaryScaleFactor,
          );

    await windowManager.setBounds(windowRect);
  }

  static Future<Rect> getBounds(SharedPreferences prefs) async {
    final primaryDisplay = await screenRetriever.getPrimaryDisplay();
    final primaryScaleFactor = primaryDisplay.scaleFactor?.toDouble() ?? 1.0;
    final windowPixelRatio = window.devicePixelRatio;

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
