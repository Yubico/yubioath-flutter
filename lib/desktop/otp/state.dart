/*
 * Copyright (C) 2023 Yubico.
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
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../app/logging.dart';
import '../../app/models.dart';
import '../../otp/models.dart';
import '../../otp/state.dart';
import '../rpc.dart';
import '../state.dart';

final _log = Logger('desktop.otp.state');

final _sessionProvider =
    Provider.autoDispose.family<RpcNodeSession, DevicePath>(
  (ref, devicePath) => RpcNodeSession(
      ref.watch(rpcProvider).requireValue, devicePath, ['ccid', 'yubiotp']),
);

final desktopOtpState = AsyncNotifierProvider.autoDispose
    .family<OtpStateNotifier, OtpState, DevicePath>(
        _DesktopOtpStateNotifier.new);

class _DesktopOtpStateNotifier extends OtpStateNotifier {
  late RpcNodeSession _session;

  @override
  FutureOr<OtpState> build(DevicePath devicePath) async {
    _session = ref.watch(_sessionProvider(devicePath));
    _session.setErrorHandler('state-reset', (_) async {
      ref.invalidate(_sessionProvider(devicePath));
    });
    ref.onDispose(() {
      _session.unsetErrorHandler('state-reset');
    });

    final result = await _session.command('get');
    _log.debug('application status', jsonEncode(result));
    return OtpState.fromJson(result['data']);
  }

  @override
  Future<void> swapSlots() async {
    await _session.command('swap');
    ref.invalidate(_sessionProvider(_session.devicePath));
  }

  @override
  Future<String> generateStaticPassword(int length, String layout) async {
    final result = await _session.command('generate_static',
        params: {'length': length, 'layout': layout});
    return result['password'];
  }

  @override
  Future<String> modhexEncodeSerial(int serial) async {
    final result =
        await _session.command('serial_modhex', params: {'serial': serial});
    return result['encoded'];
  }

  @override
  Future<Map<String, List<String>>> getKeyboardLayouts() async {
    final result = await _session.command('keyboard_layouts');
    return Map<String, List<String>>.from(result.map((key, value) =>
        MapEntry(key, (value as List<dynamic>).cast<String>().toList())));
  }

  @override
  Future<void> deleteSlot(SlotId slot) async {
    await _session.command('delete', target: [slot.id]);
    ref.invalidateSelf();
  }

  @override
  Future<void> configureSlot(SlotId slot,
      {required SlotConfiguration configuration}) async {
    await _session.command('put',
        target: [slot.id], params: configuration.toJson());
    ref.invalidateSelf();
  }
}
