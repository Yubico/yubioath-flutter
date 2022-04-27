import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'qrscanner_zxing_platform_interface.dart';

/// An implementation of [QRScannerZxingPlatform] that uses method channels.
class MethodChannelQRScannerZxing extends QRScannerZxingPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('qrscanner_zxing');

  @override
  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
