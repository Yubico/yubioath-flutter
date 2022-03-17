import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../app/models.dart';
import '../management/models.dart';

final _log = Logger('yubikeyDataCommandProvider');

final androidYubikeyProvider =
    StateNotifierProvider<_YubikeyProvider, YubiKeyData?>((ref) {
  return _YubikeyProvider(null);
});

class _YubikeyProvider extends StateNotifier<YubiKeyData?> {
  _YubikeyProvider(YubiKeyData? yubiKeyData) : super(yubiKeyData);

  void setFromString(String input) {
    try {
      if (input.isEmpty) {
        _log.config('Yubikey was detached.');
        state = null;
        return;
      }

      var args = jsonDecode(input);

      DeviceInfo deviceInfo = DeviceInfo.fromJson(args);
      String name = args['name'];
      bool isNfc = args['is_nfc'];

      DeviceNode deviceNode = isNfc
          ? DeviceNode.nfcReader(DevicePath([]), name)
          : DeviceNode.usbYubiKey(DevicePath([]), name, -1, deviceInfo);
      state = YubiKeyData(deviceNode, name, deviceInfo);
    } on Exception catch (e) {
      _log.config('Invalid data for yubikey: $input. $e');
      state = null;
    }
  }
}
