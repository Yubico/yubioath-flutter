import 'dart:ui';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'window_manager_helper_method_channel.dart';

abstract class WindowManagerHelperPlatform extends PlatformInterface {
  /// Constructs a WindowManagerHelperPlatform.
  WindowManagerHelperPlatform() : super(token: _token);

  static final Object _token = Object();

  static WindowManagerHelperPlatform _instance = MethodChannelWindowManagerHelper();

  /// The default instance of [WindowManagerHelperPlatform] to use.
  ///
  /// Defaults to [MethodChannelWindowManagerHelper].
  static WindowManagerHelperPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [WindowManagerHelperPlatform] when
  /// they register themselves.
  static set instance(WindowManagerHelperPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<Rect> getWindowBounds() {
    throw UnimplementedError('getWindowRect() has not been implemented.');
  }

  Future<bool?> setWindowBounds(Rect rect) {
    throw UnimplementedError('setWindowRect() has not been implemented.');
  }

  Future<bool?> init() {
    throw UnimplementedError('init() has not been implemented.');
  }

}
