import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:window_manager_helper/src/window_manager_helper_default.dart';

import 'window_manager_helper_platform_interface.dart';

/// An implementation of [WindowManagerHelperPlatform] that uses method channels.
class MethodChannelWindowManagerHelper extends WindowManagerHelperPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('window_manager_helper');

  @override
  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<bool?> init() async {
    return await methodChannel.invokeMethod<bool>('init');
  }

  @override
  Future<bool?> setWindowBounds(Rect rect) async {
    final Map<String, dynamic> arguments = {
      'left': rect.left,
      'top': rect.top,
      'width': rect.width,
      'height': rect.height,
    }..removeWhere((key, value) => value == null);
    return await methodChannel.invokeMethod<bool>('setWindowBounds', arguments);
  }

  @override
  Future<Rect> getWindowBounds() async {
    final windowBounds =
        await methodChannel.invokeMethod('getWindowBounds', {});
    return Rect.fromLTWH(
      windowBounds['left'] ?? defaultWindowBounds.left,
      windowBounds['top'] ?? defaultWindowBounds.top,
      windowBounds['width'] ?? defaultWindowBounds.width,
      windowBounds['height'] ?? defaultWindowBounds.height,
    );
  }
}
