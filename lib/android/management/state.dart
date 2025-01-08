/*
 * Copyright (C) 2022-2025 Yubico.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *       http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/models.dart';
import '../../app/state.dart';
import '../../management/models.dart';
import '../../management/state.dart';
import '../overlay/nfc/method_channel_notifier.dart';

final _managementMethodsProvider =
    NotifierProvider<_ManagementMethodChannelNotifier, void>(
        () => _ManagementMethodChannelNotifier());

class _ManagementMethodChannelNotifier extends MethodChannelNotifier {
  _ManagementMethodChannelNotifier()
      : super(const MethodChannel('android.management.methods'));
}

final androidManagementState = AsyncNotifierProvider.autoDispose
    .family<ManagementStateNotifier, DeviceInfo, DevicePath>(
  _AndroidManagementStateNotifier.new,
);

class _AndroidManagementStateNotifier extends ManagementStateNotifier {
  late final _ManagementMethodChannelNotifier management =
      ref.read(_managementMethodsProvider.notifier);

  @override
  FutureOr<DeviceInfo> build(DevicePath devicePath) {
    // Make sure to rebuild if currentDevice changes (as on reboot)
    ref.watch(currentDeviceProvider);

    final deviceInfo =
        ref.watch(currentDeviceDataProvider.select((s) => s.valueOrNull?.info));

    if (deviceInfo != null) {
      return deviceInfo;
    }

    throw 'Failed getting device info';
  }

  @override
  Future<void> setMode(
      {required int interfaces,
      int challengeResponseTimeout = 0,
      int? autoEjectTimeout}) async {
    await management.invoke('setMode', {
      'interfaces': interfaces,
      'challengeResponseTimeout': challengeResponseTimeout,
      'autoEjectTimeout': autoEjectTimeout
    });
    ref.read(attachedDevicesProvider.notifier).refresh();
  }

  @override
  Future<void> writeConfig(DeviceConfig config,
      {String? currentLockCode,
      String? newLockCode,
      bool reboot = false}) async {
    await management.invoke('configure', {
      'config': config.toJson(),
      'currentLockCode': currentLockCode,
      'newLockCode': newLockCode,
      'reboot': reboot
    });
    ref.read(attachedDevicesProvider.notifier).refresh();
  }

  @override
  Future<void> deviceReset() async {
    await management.invoke('deviceReset');
  }
}
