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

final androidManagementState = StateNotifierProvider.autoDispose
    .family<ManagementStateNotifier, AsyncValue<DeviceInfo>, DevicePath>(
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

    _ref.read(attachedDevicesProvider.notifier).refresh();
  }
}
