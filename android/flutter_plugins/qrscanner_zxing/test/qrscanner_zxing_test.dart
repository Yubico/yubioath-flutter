import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:qrscanner_zxing/qrscanner_zxing.dart';
import 'package:qrscanner_zxing/qrscanner_zxing_method_channel.dart';
import 'package:qrscanner_zxing/qrscanner_zxing_platform_interface.dart';

class MockQRScannerZxingPlatform
    with MockPlatformInterfaceMixin
    implements QRScannerZxingPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final QRScannerZxingPlatform initialPlatform =
      QRScannerZxingPlatform.instance;

  test('$MethodChannelQRScannerZxing is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelQRScannerZxing>());
  });

  test('getPlatformVersion', () async {
    QRScannerZxing qrscannerZxingPlugin = QRScannerZxing();
    MockQRScannerZxingPlatform fakePlatform = MockQRScannerZxingPlatform();
    QRScannerZxingPlatform.instance = fakePlatform;

    expect(await qrscannerZxingPlugin.getPlatformVersion(), '42');
  });
}
