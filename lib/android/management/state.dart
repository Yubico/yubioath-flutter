/*
 * Copyright (C) 2022 Yubico.
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

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yubico_authenticator/management/models.dart';

import '../../app/models.dart';
import '../../app/state.dart';
import '../../management/state.dart';

final androidManagementState = AsyncNotifierProvider.autoDispose
    .family<ManagementStateNotifier, DeviceInfo, DevicePath>(
  _AndroidManagementStateNotifier.new,
);

class _AndroidManagementStateNotifier extends ManagementStateNotifier {
  @override
  FutureOr<DeviceInfo> build(DevicePath devicePath) {
    // Make sure to rebuild if currentDevice changes (as on reboot)
    ref.watch(currentDeviceProvider);

    return Completer<DeviceInfo>().future;
  }

  @override
  Future<void> setMode(
      {required int interfaces,
      int challengeResponseTimeout = 0,
      int? autoEjectTimeout}) async {}

  @override
  Future<void> writeConfig(DeviceConfig config,
      {String currentLockCode = '',
      String newLockCode = '',
      bool reboot = false}) async {
    if (reboot) {
      state = const AsyncValue.loading();
    }

    ref.read(attachedDevicesProvider.notifier).refresh();
  }
}
