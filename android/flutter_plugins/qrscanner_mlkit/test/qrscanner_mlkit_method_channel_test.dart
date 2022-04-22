import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qrscanner_mlkit/qrscanner_mlkit_method_channel.dart';

void main() {
  MethodChannelQRScannerMLKit platform = MethodChannelQRScannerMLKit();
  const MethodChannel channel = MethodChannel('qrscanner_mlkit');

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
