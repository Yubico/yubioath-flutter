import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:yubico_authenticator/android/oath/command_providers.dart';

import '../app/models.dart';
import '../core/models.dart';
import '../management/models.dart';

final _log = Logger('yubikeyDataCommandProvider');

final androidYubikeyProvider =
    StateNotifierProvider<_YubikeyProvider, YubiKeyData?>((ref) {
  return _YubikeyProvider(null, ref);
});

class _YubikeyProvider extends StateNotifier<YubiKeyData?> {
  final Ref _ref;
  _YubikeyProvider(YubiKeyData? yubiKeyData, this._ref) : super(yubiKeyData);

  void setFromString(String input) {
    try {
      if (input.isEmpty) {
        _log.config('Yubikey was detached.');
        state = null;

        // reset other providers when YubiKey is removed
        _ref.refresh(androidStateProvider);
        _ref.refresh(androidCredentialsProvider);
        return;
      }

      var args = jsonDecode(input);

      DeviceInfo deviceInfo = DeviceInfo.fromJson(args);
      String name = args['name'];
      bool isNfc = args['is_nfc'];

      DeviceNode deviceNode = isNfc
          ? DeviceNode.nfcReader(DevicePath([]), name)
          : DeviceNode.usbYubiKey(
              DevicePath([]),
              name,
              /*TODO: replace with correct PID*/ UsbPid.yk4OtpFidoCcid,
              deviceInfo);
      state = YubiKeyData(deviceNode, name, deviceInfo);
    } on Exception catch (e) {
      _log.config('Invalid data for yubikey: $input. $e');
      state = null;
    }
  }
}
