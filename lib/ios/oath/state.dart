/*
 * Copyright (C) 2026 Yubico.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *       http://www.apache.org/licenses/LICENSE-2.0
 */

import 'dart:async';
import 'dart:convert';

import 'package:base32/base32.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app/logging.dart';
import '../../app/models.dart';
import '../../app/state.dart';
import '../../app/views/user_interaction.dart';
import '../../core/models.dart';
import '../../exception/platform_exception_decoder.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../oath/models.dart';
import '../../oath/state.dart';

const _channel = MethodChannel('com.yubico.authenticator/oath');
final _log = Logger('ios.oath.state');

class _Snapshot {
  final OathState oath;
  final List<OathPair> credentials;
  final Object? result;

  _Snapshot.fromJson(Map<String, dynamic> json)
    : oath = OathState.fromJson(json['state'] as Map<String, dynamic>),
      credentials = (json['credentials'] as List)
          .map((pair) => OathPair.fromJson(pair as Map<String, dynamic>))
          .toList(),
      result = json['result'];
}

final _sessionProvider = AsyncNotifierProvider.autoDispose
    .family<_IosOathSession, _Snapshot, DevicePath>(
      _IosOathSession.new,
      retry: (_, _) => null,
    );

class _IosOathSession extends AsyncNotifier<_Snapshot> {
  _IosOathSession(this.devicePath);

  final DevicePath devicePath;
  Timer? _timer;
  bool _busy = false;
  int _generation = 0;

  @override
  Future<_Snapshot> build() async {
    final generation = ++_generation;
    ref.watch(
      currentDeviceDataProvider.select((value) => value.value?.info.serial),
    );
    ref.onDispose(() {
      _generation++;
      _timer?.cancel();
    });
    final lifecycle = AppLifecycleListener(
      onStateChange: (_) => _scheduleRefresh(),
    );
    ref.onDispose(lifecycle.dispose);
    ref.listen(windowStateProvider, (_, _) => _scheduleRefresh());
    ref.listen(currentDeviceProvider, (_, _) => _scheduleRefresh());
    ref.listen(currentSectionProvider, (_, _) => _scheduleRefresh());
    try {
      final snapshot = await _call('get');
      if (ref.mounted && generation == _generation) {
        _scheduleRefresh(snapshot);
      }
      return snapshot;
    } catch (error, stack) {
      _log.error('Failed to read OATH state', error, stack);
      Error.throwWithStackTrace(OathStateReadException(error), stack);
    }
  }

  Future<_Snapshot> _call(
    String method, [
    Map<String, Object?> arguments = const {},
  ]) async {
    try {
      final response = await _channel.invokeMethod<String>(method, arguments);
      if (response == null) {
        throw const FormatException('Missing iOS OATH response');
      }
      return _Snapshot.fromJson(jsonDecode(response) as Map<String, dynamic>);
    } on PlatformException catch (error) {
      throw error.decode();
    }
  }

  Future<_Snapshot> execute(
    String method, [
    Map<String, Object?> arguments = const {},
  ]) async {
    if (_busy) {
      throw PlatformException(
        code: 'busy',
        message: 'An OATH operation is already in progress',
      );
    }
    final generation = _generation;
    final previous = state.requireValue;
    _busy = true;
    _timer?.cancel();
    try {
      final next = await _call(method, {
        ...arguments,
        'deviceId': previous.oath.deviceId,
      });
      if (next.oath.deviceId == previous.oath.deviceId) {
        final codes = {
          for (final pair in previous.credentials)
            pair.credential.id: pair.code,
        };
        for (var i = 0; i < next.credentials.length; i++) {
          final pair = next.credentials[i];
          if (pair.code == null) {
            next.credentials[i] = pair.copyWith(
              code: codes[pair.credential.id],
            );
          }
        }
      }
      if (ref.mounted && generation == _generation) state = AsyncData(next);
      return next;
    } finally {
      _busy = false;
      if (ref.mounted && generation == _generation) _scheduleRefresh();
    }
  }

  void _scheduleRefresh([_Snapshot? snapshot]) {
    _timer?.cancel();
    final current = snapshot ?? state.value;
    if (_busy ||
        current == null ||
        current.oath.locked ||
        (WidgetsBinding.instance.lifecycleState != null &&
            WidgetsBinding.instance.lifecycleState !=
                AppLifecycleState.resumed) ||
        ref.read(currentDeviceProvider)?.transport != Transport.usb ||
        ref.read(currentSectionProvider) != Section.accounts ||
        !ref.read(windowStateProvider).active) {
      return;
    }
    final expiries = current.credentials
        .where(
          (pair) =>
              pair.credential.oathType == OathType.totp &&
              !pair.credential.touchRequired &&
              pair.code != null,
        )
        .map((pair) => pair.code!.validTo)
        .toList();
    if (expiries.isEmpty) return;
    expiries.sort();
    final delay = Duration(
      milliseconds:
          (expiries.first * 1000 - DateTime.now().millisecondsSinceEpoch + 100)
              .clamp(100, 60000),
    );
    _timer = Timer(delay, () async {
      try {
        await execute('get');
      } catch (error, stack) {
        if (ref.mounted) {
          _timer?.cancel();
          state = AsyncError(OathStateReadException(error), stack);
        }
        _log.error('Failed to refresh OATH codes', error, stack);
      }
    });
  }
}

class IosOathStateNotifier extends OathStateNotifier {
  IosOathStateNotifier(super.devicePath);

  _IosOathSession get _session =>
      ref.read(_sessionProvider(devicePath).notifier);

  @override
  Future<OathState> build() async =>
      (await ref.watch(_sessionProvider(devicePath).future)).oath;

  @override
  Future<void> reset() async {
    await _session.execute('reset');
  }

  @override
  Future<(bool, bool)> unlock(String password, {bool remember = false}) async {
    final next = await _session.execute('unlock', {
      'password': password,
      'remember': remember,
    });
    return (next.result == true, next.oath.remembered);
  }

  @override
  Future<bool> setPassword(String? current, String password) async =>
      (await _session.execute('setPassword', {
        'current': current,
        'password': password,
      })).result ==
      true;

  @override
  Future<bool> unsetPassword(String current) async =>
      (await _session.execute('unsetPassword', {'current': current})).result ==
      true;

  @override
  Future<void> forgetPassword() async {
    await _session.execute('forgetPassword');
  }
}

IosCredentialListNotifier buildIosCredentialList(
  Ref ref,
  DevicePath devicePath,
) {
  final notifier = IosCredentialListNotifier._(
    ref,
    ref.watch(_sessionProvider(devicePath).notifier),
  );
  ref.listen(
    _sessionProvider(devicePath),
    (_, next) => notifier.updateCredentials(next.value?.credentials),
    fireImmediately: true,
  );
  return notifier;
}

class IosCredentialListNotifier extends OathCredentialListNotifier {
  IosCredentialListNotifier._(this._ref, this._session);
  final Ref _ref;
  final _IosOathSession _session;

  void updateCredentials(List<OathPair>? pairs) {
    if (mounted) state = pairs?.toList();
  }

  @override
  Future<OathCode> calculate(
    OathCredential credential, {
    bool update = true,
    bool headless = false,
  }) async {
    UserInteractionController? controller;
    try {
      if (credential.touchRequired &&
          _ref.read(currentDeviceProvider)?.transport == Transport.usb) {
        controller = await _ref.read(withContextProvider)((context) async {
          final l10n = AppLocalizations.of(context);
          return promptUserInteraction(
            context,
            icon: const Icon(Symbols.touch_app),
            title: l10n.s_touch_required,
            description: l10n.l_touch_button_now,
          );
        });
      }
      final next = await _session.execute('calculate', {
        'credentialId': credential.id,
      });
      return OathCode.fromJson(next.result as Map<String, dynamic>);
    } finally {
      controller?.close();
    }
  }

  @override
  Future<OathCredential> addAccount(
    Uri otpauth, {
    bool requireTouch = false,
  }) async {
    final credential = CredentialData.fromOtpauth(otpauth);
    final next = await _session.execute('addAccount', {
      'credential': {
        ...credential.toJson(),
        'secret': Uint8List.fromList(
          base32.decode(credential.secret.replaceAll(' ', '').toUpperCase()),
        ),
      },
      'requireTouch': requireTouch,
    });
    return OathCredential.fromJson(next.result as Map<String, dynamic>);
  }

  @override
  Future<OathCredential> renameAccount(
    OathCredential credential,
    String? issuer,
    String name,
  ) async {
    final next = await _session.execute('renameAccount', {
      'credentialId': credential.id,
      'issuer': issuer,
      'name': name,
    });
    return OathCredential.fromJson(next.result as Map<String, dynamic>);
  }

  @override
  Future<void> deleteAccount(OathCredential credential) async {
    await _session.execute('deleteAccount', {'credentialId': credential.id});
  }
}
