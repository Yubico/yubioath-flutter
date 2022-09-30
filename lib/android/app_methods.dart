import 'package:flutter/services.dart';

const appMethodsChannel = MethodChannel('app.methods');

Future<int> getAndroidSdkVersion() async {
  return await appMethodsChannel.invokeMethod('getAndroidSdkVersion');
}

Future<void> setPrimaryClip(String toClipboard, bool isSensitive) async {
  await appMethodsChannel.invokeMethod('setPrimaryClip',
      {'toClipboard': toClipboard, 'isSensitive': isSensitive});
}
