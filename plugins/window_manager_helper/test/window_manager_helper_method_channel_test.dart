import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:window_manager_helper/src/window_manager_helper_method_channel.dart';

void main() {
  MethodChannelWindowManagerHelper platform = MethodChannelWindowManagerHelper();
  const MethodChannel channel = MethodChannel('window_manager_helper');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
