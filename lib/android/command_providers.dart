import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../app/models.dart';
import '../core/models.dart';
import '../management/models.dart';

final log = Logger('yubikeyDataCommandProvider');

final yubikeyDataCommandProvider =
    StateNotifierProvider<YubikeyDataCommandProvider, YubiKeyData?>((ref) {
  return YubikeyDataCommandProvider(null);
});

class YubikeyDataCommandProvider extends StateNotifier<YubiKeyData?> {
  YubikeyDataCommandProvider(YubiKeyData? yubiKeyData) : super(yubiKeyData);

  void set(String input) {
    try {
      if (input.isEmpty) {
        log.info('Yubikey was detached.');
        state = null;
        return;
      }

      if (input == 'NO_FEATURE_DEVICE_INFO') {
        // empty data to show some general information in the app
        DeviceConfig config = DeviceConfig({}, 0, 0, 0);
        DeviceInfo deviceInfo = DeviceInfo(config, 0, const Version(1, 0, 0),
            FormFactor.unknown, {}, true, false, false);
        DeviceNode deviceNode =
            DeviceNode.nfcReader(DevicePath([]), 'Generic YubiKey');
        state = YubiKeyData(deviceNode, 'Generic Yubikey', deviceInfo);
        return;
      }

      var args = jsonDecode(input);

      DeviceInfo deviceInfo = DeviceInfo.fromJson(args);
      String name = args['name'];
      bool isNFC = args['isNFC'];

      DeviceNode deviceNode = isNFC
          ? DeviceNode.nfcReader(DevicePath([]), name)
          : DeviceNode.usbYubiKey(DevicePath([]), name, -1, deviceInfo);
      state = YubiKeyData(deviceNode, name, deviceInfo);
    } on Exception catch (e) {
      log.info('Invalid data for yubikey: $input. $e');
      state = null;
    }
  }
}
