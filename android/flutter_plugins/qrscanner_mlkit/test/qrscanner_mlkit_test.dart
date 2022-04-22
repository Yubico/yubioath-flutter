import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:qrscanner_mlkit/qrscanner_mlkit.dart';
import 'package:qrscanner_mlkit/qrscanner_mlkit_method_channel.dart';
import 'package:qrscanner_mlkit/qrscanner_mlkit_platform_interface.dart';

class MockQRScannerMLKitPlatform with MockPlatformInterfaceMixin implements QRScannerMLKitPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final QRScannerMLKitPlatform initialPlatform = QRScannerMLKitPlatform.instance;

  test('$MethodChannelQRScannerMLKit is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelQRScannerMLKit>());
  });

  test('getPlatformVersion', () async {
    QRScannerMLKit qrscannerMlkitPlugin = QRScannerMLKit();
    MockQRScannerMLKitPlatform fakePlatform = MockQRScannerMLKitPlatform();
    QRScannerMLKitPlatform.instance = fakePlatform;

    expect(await qrscannerMlkitPlugin.getPlatformVersion(), '42');
  });
}
