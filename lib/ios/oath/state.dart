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
import 'package:flutter_riverpod/legacy.dart';
import 'package:logging/logging.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app/logging.dart';
import '../../app/models.dart';
import '../../app/state.dart';
import '../../app/views/user_interaction.dart';
import '../../core/models.dart';
import '../../exception/cancellation_exception.dart';
import '../../exception/platform_exception_decoder.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../oath/models.dart';
import '../../oath/state.dart';
import '../state.dart';

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

/// Whether the user has asked to read OATH over NFC for a device.
///
/// NFC reads are only started by the user, never automatically.
final iosOathNfcReadRequestedProvider = StateProvider.autoDispose
    .family<bool, DevicePath>((ref, _) => false);

final _sessionProvider = AsyncNotifierProvider.autoDispose
    .family<_IosOathSession, _Snapshot, DevicePath>(
      _IosOathSession.new,
      retry: (_, _) => null,
    );

/// Loading/error/data state of the OATH session, without exposing its data.
final iosOathSessionStatusProvider = Provider.autoDispose
    .family<AsyncValue<void>, DevicePath>(
      (ref, devicePath) =>
          ref.watch(_sessionProvider(devicePath)).whenData((_) {}),
    );

/// Reads OATH again, starting the first NFC read if none was requested yet.
///
/// The caller must watch [iosOathSessionStatusProvider] for [devicePath].
/// Errors from the first read are left in the session state, cancelling it
/// returns to the not-requested state.
Future<void> refreshIosOath(WidgetRef ref, DevicePath devicePath) async {
  final requested = ref.read(iosOathNfcReadRequestedProvider(devicePath));
  final session = ref.read(_sessionProvider(devicePath));
  if (!requested || session.isLoading) {
    ref.read(iosOathNfcReadRequestedProvider(devicePath).notifier).state = true;
    try {
      await ref.read(_sessionProvider(devicePath).future);
    } on OathStateReadException catch (error) {
      if (error.cause is CancellationException && ref.context.mounted) {
        ref.read(iosOathNfcReadRequestedProvider(devicePath).notifier).state =
            false;
      }
    }
    return;
  }
  await ref.read(_sessionProvider(devicePath).notifier).execute('get');
}

class _IosOathSession extends AsyncNotifier<_Snapshot> {
  _IosOathSession(this.devicePath);

  final DevicePath devicePath;
  Timer? _timer;
  Future<void> _queue = Future.value();
  int _pending = 0;
  int _generation = 0;

  @override
  Future<_Snapshot> build() async {
    final generation = ++_generation;
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
      if (_device().node.transport == Transport.nfc &&
          !ref.watch(iosOathNfcReadRequestedProvider(devicePath))) {
        // Stay loading until the user starts an NFC read.
        return await Completer<_Snapshot>().future;
      }
      final snapshot = await _call('get');
      if (ref.mounted && generation == _generation) {
        _scheduleRefresh(snapshot);
      }
      return snapshot;
    } catch (error, stack) {
      if (error is! CancellationException) {
        _log.error('Failed to read OATH state', error, stack);
      }
      Error.throwWithStackTrace(OathStateReadException(error), stack);
    }
  }

  YubiKeyData _device() {
    final data = ref.read(currentDeviceDataProvider).value;
    if (data == null || data.node.path != devicePath) {
      throw PlatformException(
        code: 'device_changed',
        message: 'The displayed YubiKey has changed.',
      );
    }
    return data;
  }

  Future<_Snapshot> _call(
    String method, [
    Map<String, Object?> arguments = const {},
  ]) async {
    try {
      final response = await _channel.invokeMethod<String>(method, {
        ...arguments,
        'expectedDevice': iosExpectedDevice(_device()),
      });
      if (response == null) {
        throw const FormatException('Missing iOS OATH response');
      }
      return _Snapshot.fromJson(jsonDecode(response) as Map<String, dynamic>);
    } on PlatformException catch (error) {
      if (error.code == 'cancelled') throw CancellationException();
      throw error.decode();
    }
  }

  /// Runs [method] after any operation already started by this session.
  Future<_Snapshot> execute(
    String method, [
    Map<String, Object?> arguments = const {},
  ]) {
    final generation = _generation;
    _pending++;
    _timer?.cancel();
    final operation = _queue.then((_) => _execute(method, arguments));
    _queue = operation.then<void>((_) {}, onError: (_) {});
    return operation.whenComplete(() {
      _pending--;
      if (ref.mounted && generation == _generation) _scheduleRefresh();
    });
  }

  Future<_Snapshot> _execute(
    String method,
    Map<String, Object?> arguments,
  ) async {
    final generation = _generation;
    final previous = state.value;
    // A plain read must accept a new OATH device ID, e.g. after the OATH
    // application was reset elsewhere, so the state can recover.
    final next = await _call(method, {
      ...arguments,
      if (previous != null && method != 'get')
        'deviceId': previous.oath.deviceId,
    });
    if (previous != null && next.oath.deviceId == previous.oath.deviceId) {
      final codes = {
        for (final pair in previous.credentials) pair.credential.id: pair.code,
      };
      for (var i = 0; i < next.credentials.length; i++) {
        final pair = next.credentials[i];
        if (pair.code == null) {
          next.credentials[i] = pair.copyWith(code: codes[pair.credential.id]);
        }
      }
    }
    if (ref.mounted && generation == _generation) state = AsyncData(next);
    return next;
  }

  void _scheduleRefresh([_Snapshot? snapshot]) {
    _timer?.cancel();
    final current = snapshot ?? state.value;
    if (_pending > 0 ||
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
        _log.error('Failed to refresh OATH codes', error, stack);
        if (ref.mounted) {
          _timer?.cancel();
          state = AsyncError(OathStateReadException(error), stack);
        }
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
