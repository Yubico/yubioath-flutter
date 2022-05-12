import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:yubico_authenticator/android/oath/command_providers.dart';
import 'package:yubico_authenticator/app/logging.dart';

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
  _YubikeyProvider(super.yubiKeyData, this._ref);

  void setFromString(String input) {
    try {
      if (input.isEmpty) {
        _log.debug('Yubikey was detached.');
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

      // reset oath providers on key change
      var yubiKeyData = YubiKeyData(deviceNode, name, deviceInfo);
      if (state != yubiKeyData && state != null) {
        _ref.refresh(androidStateProvider);
        _ref.refresh(androidCredentialsProvider);
      }

      state = yubiKeyData;
    } on Exception catch (e) {
      _log.debug('Invalid data for yubikey: $input. $e');
      state = null;
    }
  }
}
