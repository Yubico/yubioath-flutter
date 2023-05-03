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
import 'package:logging/logging.dart';
import 'package:yubico_authenticator/app/logging.dart';
import 'package:yubico_authenticator/management/models.dart';

import '../../app/models.dart';
import '../../app/state.dart';
import '../../core/models.dart';
import '../../management/state.dart';
import '../rpc.dart';
import '../state.dart';

final _log = Logger('desktop.management.state');

final _sessionProvider =
    Provider.autoDispose.family<RpcNodeSession, DevicePath>(
  (ref, devicePath) =>
      RpcNodeSession(ref.watch(rpcProvider).requireValue, devicePath, []),
);

final desktopManagementState = AsyncNotifierProvider.autoDispose
    .family<ManagementStateNotifier, DeviceInfo, DevicePath>(
        _DesktopManagementStateNotifier.new);

class _DesktopManagementStateNotifier extends ManagementStateNotifier {
  late RpcNodeSession _session;
  List<String> _subpath = [];
  _DesktopManagementStateNotifier() : super();

  @override
  FutureOr<DeviceInfo> build(DevicePath devicePath) async {
    // Make sure to rebuild if currentDevice changes (as on reboot)
    ref.watch(currentDeviceProvider);

    _session = ref.watch(_sessionProvider(devicePath));
    _session.setErrorHandler('state-reset', (_) async {
      ref.invalidate(_sessionProvider(devicePath));
    });
    ref.onDispose(() {
      _session.unsetErrorHandler('state-reset');
    });

    final result = await _session.command('get');
    final info = DeviceInfo.fromJson(result['data']['info']);
    final interfaces = (result['children'] as Map).keys.toSet();
    for (final iface in [
      // This is the preferred order
      UsbInterface.ccid,
      UsbInterface.otp,
      UsbInterface.fido,
    ]) {
      if (interfaces.contains(iface.name)) {
        final path = [iface.name, 'management'];
        try {
          await _session.command('get', target: path);
          _subpath = path;
          _log.debug('Using transport $iface for management');
          return info;
        } catch (e) {
          _log.warning('Failed connecting to management via $iface');
        }
      }
    }
    throw 'Failed connection over all interfaces';
  }

  @override
  Future<void> setMode(
      {required int interfaces,
      int challengeResponseTimeout = 0,
      int? autoEjectTimeout}) async {
    await _session.command('set_mode', target: _subpath, params: {
      'interfaces': interfaces,
      'challenge_response_timeout': challengeResponseTimeout,
      'auto_eject_timeout': autoEjectTimeout,
    });
    ref.read(attachedDevicesProvider.notifier).refresh();
  }

  @override
  Future<void> writeConfig(DeviceConfig config,
      {String currentLockCode = '',
      String newLockCode = '',
      bool reboot = false}) async {
    if (reboot) {
      state = const AsyncValue.loading();
    }
    await _session.command('configure', target: _subpath, params: {
      ...config.toJson(),
      'cur_lock_code': currentLockCode,
      'new_lock_code': newLockCode,
      'reboot': reboot,
    });
    ref.read(attachedDevicesProvider.notifier).refresh();
  }
}
