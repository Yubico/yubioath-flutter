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
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app/logging.dart';
import '../../app/models.dart';
import '../../app/state.dart';
import '../../app/views/user_interaction.dart';
import '../../oath/models.dart';
import '../../oath/state.dart';
import '../rpc.dart';
import '../state.dart';

final _log = Logger('desktop.oath.state');

final _sessionProvider =
    Provider.autoDispose.family<RpcNodeSession, DevicePath>(
  (ref, devicePath) => RpcNodeSession(
      ref.watch(rpcProvider).requireValue, devicePath, ['ccid', 'oath']),
);

// This remembers the key for all devices for the duration of the process.
final _oathLockKeyProvider =
    StateNotifierProvider.family<_LockKeyNotifier, String?, DevicePath>(
        (ref, devicePath) => _LockKeyNotifier(null));

class _LockKeyNotifier extends StateNotifier<String?> {
  _LockKeyNotifier(super.state);

  setKey(String key) {
    state = key;
  }

  unsetKey() {
    state = null;
  }
}

final desktopOathState = AsyncNotifierProvider.autoDispose
    .family<OathStateNotifier, OathState, DevicePath>(
        _DesktopOathStateNotifier.new);

class _DesktopOathStateNotifier extends OathStateNotifier {
  late RpcNodeSession _session;

  @override
  FutureOr<OathState> build(DevicePath devicePath) async {
    _session = ref.watch(_sessionProvider(devicePath));
    _session
      ..setErrorHandler('state-reset', (_) async {
        ref.invalidate(_sessionProvider(devicePath));
      })
      ..setErrorHandler('auth-required', (e) async {
        final key = ref.read(_oathLockKeyProvider(_session.devicePath));
        if (key != null) {
          final result =
              await _session.command('validate', params: {'key': key});
          if (result['valid']) {
            ref.invalidateSelf();
            return;
          } else {
            ref
                .read(_oathLockKeyProvider(_session.devicePath).notifier)
                .unsetKey();
          }
        }
        throw e;
      });
    ref.onDispose(() {
      _session
        ..unsetErrorHandler('state-reset')
        ..unsetErrorHandler('auth-required');
    });
    final result = await _session.command('get');
    _log.debug('application status', jsonEncode(result));
    return OathState.fromJson(result['data']);
  }

  @override
  Future<void> reset() async {
    await _session.command('reset');
    ref.read(_oathLockKeyProvider(_session.devicePath).notifier).unsetKey();
    ref.invalidate(_sessionProvider(_session.devicePath));
  }

  @override
  Future<(bool, bool)> unlock(String password, {bool remember = false}) async {
    var derive =
        await _session.command('derive', params: {'password': password});
    var key = derive['key'];
    final validate = await _session
        .command('validate', params: {'key': key, 'remember': remember});
    final bool valid = validate['valid'];
    final bool remembered = validate['remembered'];
    if (valid) {
      _log.debug('applet unlocked');
      ref.read(_oathLockKeyProvider(_session.devicePath).notifier).setKey(key);
      setData(state.value!.copyWith(
        locked: false,
        remembered: remembered,
      ));
    }
    return (valid, remembered);
  }

  Future<bool> _checkPassword(String password) async {
    var result =
        await _session.command('validate', params: {'password': password});
    return result['valid'];
  }

  @override
  Future<bool> setPassword(String? current, String password) async {
    final oathState = state.value!;
    if (oathState.hasKey) {
      if (current != null) {
        if (!await _checkPassword(current)) {
          return false;
        }
      } else {
        return false;
      }
    }

    if (oathState.remembered) {
      // Remembered, keep remembering
      await _session
          .command('set_key', params: {'password': password, 'remember': true});
    } else {
      // Not remembered, keep in keyProvider
      var derive =
          await _session.command('derive', params: {'password': password});
      var key = derive['key'];
      await _session.command('set_key', params: {'key': key});
      ref.read(_oathLockKeyProvider(_session.devicePath).notifier).setKey(key);
    }
    _log.debug('OATH key set');

    if (!oathState.hasKey) {
      setData(oathState.copyWith(hasKey: true));
    }
    return true;
  }

  @override
  Future<bool> unsetPassword(String current) async {
    final oathState = state.value!;
    if (oathState.hasKey) {
      if (!await _checkPassword(current)) {
        return false;
      }
    }
    await _session.command('unset_key');
    ref.read(_oathLockKeyProvider(_session.devicePath).notifier).unsetKey();
    setData(oathState.copyWith(hasKey: false, locked: false));
    return true;
  }

  @override
  Future<void> forgetPassword() async {
    await _session.command('forget');
    ref.read(_oathLockKeyProvider(_session.devicePath).notifier).unsetKey();
    setData(state.value!.copyWith(remembered: false));
  }
}

final desktopOathCredentialListProvider = StateNotifierProvider.autoDispose
    .family<DesktopCredentialListNotifier, List<OathPair>?, DevicePath>(
  (ref, devicePath) {
    var notifier = DesktopCredentialListNotifier(
      ref.watch(withContextProvider),
      ref.watch(_sessionProvider(devicePath)),
      ref.watch(oathStateProvider(devicePath)
          .select((r) => r.whenOrNull(data: (state) => state.locked) ?? true)),
    );
    ref.listen<WindowState>(windowStateProvider, (_, windowState) {
      notifier._rescheduleTimer(windowState.active);
    }, fireImmediately: true);
    ref.listen(currentSectionProvider, (_, section) {
      notifier._rescheduleTimer(section == Section.accounts);
    });

    return notifier;
  },
);

extension on OathCredential {
  bool get isSteam => issuer == 'Steam' && oathType == OathType.totp;
}

const String _steamCharTable = '23456789BCDFGHJKMNPQRTVWXY';

String _formatSteam(String response) {
  final offset = int.parse(response.substring(response.length - 1), radix: 16);
  var number =
      int.parse(response.substring(offset * 2, offset * 2 + 8), radix: 16) &
          0x7fffffff;
  var value = '';
  for (var i = 0; i < 5; i++) {
    value += _steamCharTable[number % _steamCharTable.length];
    number ~/= _steamCharTable.length;
  }
  return value;
}

class DesktopCredentialListNotifier extends OathCredentialListNotifier {
  final WithContext _withContext;
  final RpcNodeSession _session;
  final bool _locked;
  Timer? _timer;

  DesktopCredentialListNotifier(this._withContext, this._session, this._locked)
      : super();

  void _rescheduleTimer(bool active) {
    if (_locked) return;
    if (active) {
      _scheduleRefresh();
    } else {
      _timer?.cancel();
    }
  }

  @override
  void dispose() {
    _log.debug('OATH notifier discarded');
    _timer?.cancel();
    super.dispose();
  }

  @override
  Future<OathCode> calculate(OathCredential credential,
      {bool update = true, bool headless = false}) async {
    var now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if (update) {
      // Manually triggered, need to pad timer to avoid immediate expiration
      now += 10;
    }
    final OathCode code;
    final signaler = Signaler();
    UserInteractionController? controller;
    try {
      signaler.signals.listen((signal) async {
        if (signal.status == 'touch') {
          controller = await _withContext(
            (context) async {
              final l10n = AppLocalizations.of(context)!;
              return promptUserInteraction(
                context,
                icon: const Icon(Symbols.touch_app),
                title: l10n.s_touch_required,
                description: l10n.l_touch_button_now,
                headless: headless,
              );
            },
          );
        }
      });
      if (credential.isSteam) {
        final timeStep = now ~/ 30;
        var result = await _session.command('calculate',
            target: ['accounts', credential.id],
            params: {
              'challenge': timeStep.toRadixString(16).padLeft(16, '0'),
            },
            signal: signaler);
        code = OathCode(_formatSteam(result['response']), timeStep * 30,
            (timeStep + 1) * 30);
      } else {
        var result = await _session.command(
          'code',
          target: ['accounts', credential.id],
          params: {'timestamp': now},
          signal: signaler,
        );
        code = OathCode.fromJson(result);
      }
      _log.debug('Calculate', jsonEncode(code));
      if (update && mounted && state != null) {
        final creds = state!.toList();
        final i = creds.indexWhere((e) => e.credential.id == credential.id);
        state = creds..[i] = creds[i].copyWith(code: code);
      }
      return code;
    } finally {
      controller?.close();
    }
  }

  @override
  Future<OathCredential> addAccount(Uri otpauth,
      {bool requireTouch = false}) async {
    var result = await _session.command('put', target: [
      'accounts'
    ], params: {
      'uri': otpauth.toString(),
      'require_touch': requireTouch,
    });
    refresh();
    return OathCredential.fromJson(result);
  }

  @override
  Future<OathCredential> renameAccount(
    OathCredential credential,
    String? issuer,
    String name,
  ) async {
    final result = await _session.command('rename', target: [
      'accounts',
      credential.id,
    ], params: {
      'issuer': issuer,
      'name': name,
    });
    String credentialId = result['credential_id'];
    final renamedCredential =
        credential.copyWith(id: credentialId, issuer: issuer, name: name);
    if (mounted) {
      final newState = state!.toList();
      final index = newState.indexWhere((e) => e.credential == credential);
      final oldPair = newState.removeAt(index);
      newState.add(OathPair(
        renamedCredential,
        oldPair.code,
      ));
      state = newState;
    }
    return renamedCredential;
  }

  @override
  Future<void> deleteAccount(OathCredential credential) async {
    await _session.command('delete', target: ['accounts', credential.id]);
    if (mounted) {
      state = state!.toList()..removeWhere((e) => e.credential == credential);
    }
  }

  refresh() async {
    if (_locked) return;
    _log.debug('refreshing credentials...');
    var result = await _session.command('calculate_all', target: ['accounts']);
    _log.debug('Entries', jsonEncode(result));

    final pairs = [];
    for (var e in result['entries']) {
      final credential = OathCredential.fromJson(e['credential']);
      final code = e['code'] == null
          ? null
          : credential.isSteam // Steam codes require a re-calculate
              ? await calculate(credential, update: false)
              : OathCode.fromJson(e['code']);
      pairs.add(OathPair(credential, code));
    }

    if (mounted) {
      final current = state?.toList() ?? [];
      for (var pair in pairs) {
        final i =
            current.indexWhere((e) => e.credential.id == pair.credential.id);
        if (i < 0) {
          current.add(pair);
        } else if (pair.code != null) {
          current[i] = current[i].copyWith(code: pair.code);
        }
      }
      state = current;
      _scheduleRefresh();
    }
  }

  _scheduleRefresh() {
    _timer?.cancel();
    if (_locked) return;
    if (state == null) {
      _log.debug('No OATH state, refresh immediately');
      refresh();
    } else if (mounted) {
      final expirations = (state ?? [])
          .where((pair) =>
              pair.credential.oathType == OathType.totp &&
              !pair.credential.touchRequired)
          .map((e) => e.code)
          .whereType<OathCode>()
          .map((e) => e.validTo);
      if (expirations.isEmpty) {
        _log.debug('No expirations, no refresh');
        _timer = null;
      } else {
        final earliest = expirations.reduce(min) * 1000;
        final now = DateTime.now().millisecondsSinceEpoch;
        if (earliest < now) {
          _log.debug('Already expired, refresh immediately');
          refresh();
        } else {
          _log.debug('Schedule refresh in ${earliest - now}ms');
          _timer = Timer(Duration(milliseconds: earliest - now), refresh);
        }
      }
    }
  }
}
