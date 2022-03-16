import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yubico_authenticator/management/models.dart';

import '../../app/models.dart';
import '../../app/state.dart';
import '../../management/state.dart';

final androidManagementState = StateNotifierProvider.autoDispose.family<
    ManagementStateNotifier, ApplicationStateResult<DeviceInfo>, DevicePath>(
  (ref, devicePath) {
    // Make sure to rebuild if currentDevice changes (as on reboot)
    ref.watch(currentDeviceProvider);
    final notifier = _AndroidManagementStateNotifier(ref);
    return notifier..refresh();
  },
);

class _AndroidManagementStateNotifier extends ManagementStateNotifier {
  final Ref _ref;

  _AndroidManagementStateNotifier(this._ref) : super();

  void refresh() async {}

  @override
  Future<void> setMode(int mode,
      {int challengeResponseTimeout = 0, int autoEjectTimeout = 0}) async {}

  @override
  Future<void> writeConfig(DeviceConfig config,
      {String currentLockCode = '',
      String newLockCode = '',
      bool reboot = false}) async {
    if (reboot) {
      unsetState();
    }

    _ref.read(attachedDevicesProvider.notifier).refresh();
  }
}
