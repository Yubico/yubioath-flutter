import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../app/logging.dart';
import '../app/models.dart';
import '../core/models.dart';
import '../management/models.dart';

final _log = Logger('android.devices');

final androidYubikeyProvider =
    StateNotifierProvider<_YubikeyProvider, AsyncValue<YubiKeyData>>((ref) {
  return _YubikeyProvider();
});

class _YubikeyProvider extends StateNotifier<AsyncValue<YubiKeyData>> {
  final _events = const EventChannel('android.devices.deviceInfo');
  late StreamSubscription sub;
  _YubikeyProvider() : super(const AsyncValue.loading()) {
    sub = _events.receiveBroadcastStream().listen((event) {
      _setDevice(jsonDecode(event));
    });
  }

  @override
  void dispose() {
    sub.cancel();
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
