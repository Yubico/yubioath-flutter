import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager_helper/src/window_manager_helper_platform_interface.dart';
import 'package:window_manager_helper/src/window_manager_helper_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:window_manager_helper/window_manager_helper.dart';

class MockWindowManagerHelperPlatform
    with MockPlatformInterfaceMixin
    implements WindowManagerHelperPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<Rect> getWindowBounds() async => Future.value(const Rect.fromLTWH(0, 0, 10, 10));

  @override
  Future<bool> setWindowBounds(Rect r) async => true;

  @override
  Future<bool> init() async => true;
}

void main() {
  final WindowManagerHelperPlatform initialPlatform = WindowManagerHelperPlatform.instance;

  test('$MethodChannelWindowManagerHelper is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelWindowManagerHelper>());
  });

  test('getPlatformVersion', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    WindowManagerHelper windowManagerHelperPlugin = WindowManagerHelper.withPreferences(prefs);
    MockWindowManagerHelperPlatform fakePlatform = MockWindowManagerHelperPlatform();
    WindowManagerHelperPlatform.instance = fakePlatform;

    expect(await windowManagerHelperPlugin.getPlatformVersion(), '42');
  });
}
