import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:yubico_authenticator/app/logging.dart';

import '../app/models.dart';
import '../core/models.dart';
import '../management/models.dart';

final _log = Logger('android.devices');

const _channel = MethodChannel('com.yubico.authenticator.channel.device');

final androidYubikeyProvider =
    StateNotifierProvider<_YubikeyProvider, AsyncValue<YubiKeyData>>((ref) {
  return _YubikeyProvider(const AsyncValue.loading());
});

class _YubikeyProvider extends StateNotifier<AsyncValue<YubiKeyData>> {
  _YubikeyProvider(super.yubiKeyData) {
    _channel.setMethodCallHandler((call) async {
      final json = jsonDecode(call.arguments);
      switch (call.method) {
        case 'setDevice':
          await _setDevice(json);
          break;
        default:
          throw PlatformException(
            code: 'NotImplemented',
            message: 'Method ${call.method} is not implemented',
          );
      }
    });
  }

  @override
  void dispose() {
    _channel.setMethodCallHandler(null);
    super.dispose();
  }

  Future<void> _setDevice(Map<String, dynamic>? json) async {
    if (json == null) {
      _log.debug('Yubikey was detached.');
      state = const AsyncValue.loading();
      return;
    }

    state = await AsyncValue.guard(() async {
      DeviceInfo deviceInfo = DeviceInfo.fromJson(json);
      String name = json['name'];
      bool isNfc = json['is_nfc'];
      int? usbPid = json['usb_pid'];

      DeviceNode deviceNode = isNfc
          ? DeviceNode.nfcReader(DevicePath([]), name)
          : DeviceNode.usbYubiKey(
              DevicePath([]),
              name,
              usbPid != null ? UsbPid.fromValue(usbPid) : UsbPid.yk4OtpFidoCcid,
              deviceInfo);

      return YubiKeyData(deviceNode, name, deviceInfo);
    });
  }
}
