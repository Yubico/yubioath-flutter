import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../app/models.dart';
import '../core/models.dart';
import '../management/models.dart';

final _log = Logger('yubikeyDataCommandProvider');

final androidYubikeyProvider =
    StateNotifierProvider<_YubikeyProvider, YubiKeyData?>((ref) {
  return _YubikeyProvider(null);
});

class _YubikeyProvider extends StateNotifier<YubiKeyData?> {
  _YubikeyProvider(YubiKeyData? yubiKeyData) : super(yubiKeyData);

  void set(String input) {
    try {
      if (input.isEmpty) {
        _log.info('Yubikey was detached.');
        state = null;
        return;
      }

      /// a workaround for yubikeys without DEVICE_INFO
      /// once we have support functionality implemented,
      /// the following block will not be needed
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
      _log.info('Invalid data for yubikey: $input. $e');
      state = null;
    }
  }
}
