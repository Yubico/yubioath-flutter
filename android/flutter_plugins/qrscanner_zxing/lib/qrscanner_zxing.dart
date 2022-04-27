import 'qrscanner_zxing_platform_interface.dart';

class QRScannerZxing {
  Future<String?> getPlatformVersion() {
    return QRScannerZxingPlatform.instance.getPlatformVersion();
  }
}
