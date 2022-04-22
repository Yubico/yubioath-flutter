import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'qrscanner_mlkit_platform_interface.dart';

/// An implementation of [QRScannerMLKitPlatform] that uses method channels.
class MethodChannelQRScannerMLKit extends QRScannerMLKitPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('qrscanner_mlkit');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
