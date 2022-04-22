import 'qrscanner_mlkit_platform_interface.dart';

class QRScannerMLKit {
  Future<String?> getPlatformVersion() {
    return QRScannerMLKitPlatform.instance.getPlatformVersion();
  }
}
