/*
 * Copyright (C) 2026 Yubico.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *       http://www.apache.org/licenses/LICENSE-2.0
 */

// iOS Management state providers. Mirrors `lib/android/management/state.dart`.
//
// Delegates to `com.yubico.authenticator/management` →
// `ios/Management/ManagementManager.swift`.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/state.dart';
import '../../management/models.dart';
import '../../management/state.dart';
import '../state.dart';

class IosManagementStateNotifier extends ManagementStateNotifier {
  IosManagementStateNotifier(super.devicePath);

  @override
  FutureOr<DeviceInfo> build() {
    // Rebuild whenever the active device changes.
    ref.watch(currentDeviceProvider);

    final info = ref.watch(
      currentDeviceDataProvider.select((s) => s.value?.info),
    );
    if (info != null) {
      return info;
    }
    throw 'Failed getting device info';
  }

  @override
  Future<void> writeConfig(
    DeviceConfig config, {
    String? currentLockCode,
    String? newLockCode,
    bool reboot = false,
  }) async {
    await managementChannel.invokeMethod('configure', {
      'config': config.toJson(),
      'currentLockCode': currentLockCode,
      'newLockCode': newLockCode,
      'reboot': reboot,
    });
    ref.read(attachedDevicesProvider.notifier).refresh();
  }

  @override
  Future<void> setMode({
    required int interfaces,
    int challengeResponseTimeout = 0,
    int? autoEjectTimeout,
  }) async {
    await managementChannel.invokeMethod('setMode', {
      'interfaces': interfaces,
      'challengeResponseTimeout': challengeResponseTimeout,
      'autoEjectTimeout': autoEjectTimeout,
    });
    ref.read(attachedDevicesProvider.notifier).refresh();
  }

  @override
  Future<void> deviceReset() async {
    await managementChannel.invokeMethod('deviceReset');
  }
}
