import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yubico_authenticator/management/models.dart';

import '../app/models.dart';
import '../core/state.dart';

final managementStateProvider = StateNotifierProvider.autoDispose
    .family<ManagementStateNotifier, AsyncValue<DeviceInfo>, DevicePath>(
  (ref, devicePath) => throw UnimplementedError(),
);

abstract class ManagementStateNotifier
    extends ApplicationStateNotifier<DeviceInfo> {
  Future<void> writeConfig(DeviceConfig config,
      {String currentLockCode = '',
      String newLockCode = '',
      bool reboot = false});

  Future<void> setMode(int mode,
      {int challengeResponseTimeout = 0, int autoEjectTimeout = 0});
}
