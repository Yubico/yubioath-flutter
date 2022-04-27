import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qrscanner_zxing/qrscanner_zxing_method_channel.dart';

void main() {
  MethodChannelQRScannerZxing platform = MethodChannelQRScannerZxing();
  const MethodChannel channel = MethodChannel('qrscanner_zxing');

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
