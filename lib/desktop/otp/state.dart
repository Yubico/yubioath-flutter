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
import '../../core/models.dart';
import '../../otp/models.dart';
import '../../otp/state.dart';
import '../rpc.dart';
import '../state.dart';

final _log = Logger('desktop.otp.state');

final _sessionProvider = Provider.autoDispose
    .family<RpcNodeSession, DevicePath>(
      (ref, devicePath) =>
          RpcNodeSession(ref.watch(rpcProvider).requireValue, devicePath, []),
    );

final desktopOtpState = AsyncNotifierProvider.autoDispose
    .family<OtpStateNotifier, OtpState, DevicePath>(
      _DesktopOtpStateNotifier.new,
    );

class _DesktopOtpStateNotifier extends OtpStateNotifier {
  late RpcNodeSession _session;
  List<String> _subpath = [];

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
    final interfaces = (result['children'] as Map).keys.toSet();

    // Will try to connect over ccid first
    for (final iface in [UsbInterface.otp, UsbInterface.ccid]) {
      if (interfaces.contains(iface.name)) {
        final path = [iface.name, 'yubiotp'];
        try {
          final otpStateResult = await _session.command('get', target: path);
          _subpath = path;
          _log.debug('Using transport $iface for yubiotp');
          _log.debug('application status', jsonEncode(result));
          return OtpState.fromJson(otpStateResult['data']);
        } catch (e) {
          _log.warning('Failed connecting to yubiotp via $iface');
        }
      }
    }
    throw 'Failed connecting over ${UsbInterface.ccid.name} and ${UsbInterface.otp.name}';
  }

  @override
  Future<void> swapSlots() async {
    await _session.command('swap', target: _subpath);
    ref.invalidate(_sessionProvider(_session.devicePath));
  }

  @override
  Future<String> generateStaticPassword(int length, String layout) async {
    final result = await _session.command(
      'generate_static',
      target: _subpath,
      params: {'length': length, 'layout': layout},
    );
    return result['password'];
  }

  @override
  Future<String> modhexEncodeSerial(int serial) async {
    final result = await _session.command(
      'serial_modhex',
      target: _subpath,
      params: {'serial': serial},
    );
    return result['encoded'];
  }

  @override
  Future<Map<String, List<String>>> getKeyboardLayouts() async {
    final result = await _session.command('keyboard_layouts', target: _subpath);
    return Map<String, List<String>>.from(
      result.map(
        (key, value) =>
            MapEntry(key, (value as List<dynamic>).cast<String>().toList()),
      ),
    );
  }

  @override
  Future<String> formatYubiOtpCsv(
    int serial,
    String publicId,
    String privateId,
    String key,
  ) async {
    final result = await _session.command(
      'format_yubiotp_csv',
      target: _subpath,
      params: {
        'serial': serial,
        'public_id': publicId,
        'private_id': privateId,
        'key': key,
      },
    );
    return result['csv'];
  }

  @override
  Future<void> deleteSlot(SlotId slot, {String? accessCode}) async {
    await _session.command(
      'delete',
      target: [..._subpath, slot.id],
      params: accessCode != null ? {'curr_acc_code': accessCode} : null,
    );
    ref.invalidateSelf();
  }

  @override
  Future<void> configureSlot(
    SlotId slot, {
    required SlotConfiguration configuration,
    String? accessCode,
  }) async {
    await _session.command(
      'put',
      target: [..._subpath, slot.id],
      params: accessCode != null
          ? {...configuration.toJson(), 'curr_acc_code': accessCode}
          : configuration.toJson(),
    );
    ref.invalidateSelf();
  }
}
