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
import '../../piv/models.dart';
import '../../piv/state.dart';

const _channel = MethodChannel('com.yubico.authenticator/piv');
final _log = Logger('ios.piv');

class _Snapshot {
  final PivState piv;
  final List<PivSlot> slots;
  final Object? result;

  _Snapshot._(this.piv, this.slots, this.result);

  _Snapshot(Map<String, dynamic> json)
    : piv = PivState.fromJson(json['state'] as Map<String, dynamic>),
      slots = (json['slots'] as List)
          .map((slot) => PivSlot.fromJson(slot as Map<String, dynamic>))
          .toList(),
      result = json['result'];
}

Future<Map<String, dynamic>> _invoke(
  String method, [
  Map<String, Object?> arguments = const {},
]) async {
  try {
    final response = await _channel.invokeMethod<String>(method, arguments);
    if (response == null) throw const FormatException('Missing PIV response');
    return jsonDecode(response) as Map<String, dynamic>;
  } on PlatformException catch (error) {
    throw error.decode();
  }
}

final _sessionProvider = AsyncNotifierProvider.autoDispose
    .family<_PivSession, _Snapshot, DevicePath>(
      _PivSession.new,
      retry: (_, _) => null,
    );

class _PivSession extends AsyncNotifier<_Snapshot> {
  _PivSession(this.path);
  final DevicePath path;
  bool _busy = false;
  int _generation = 0;

  @override
  Future<_Snapshot> build() async {
    _generation++;
    final lifecycle = AppLifecycleListener(
      onPause: () {
        final current = state.value;
        if (ref.mounted && current != null) {
          state = AsyncData(
            _Snapshot._(
              current.piv.copyWith(authenticated: false),
              current.slots,
              current.result,
            ),
          );
        }
      },
    );
    ref.onDispose(lifecycle.dispose);
    final serial = ref.watch(
      currentDeviceDataProvider.select((data) => data.value?.info.serial),
    );
    try {
      return _Snapshot(await _invoke('get', {'serial': serial}));
    } catch (error, stack) {
      _log.error('Failed to read PIV state', error, stack);
      Error.throwWithStackTrace(PivStateReadException(error), stack);
    }
  }

  Future<Object?> execute(
    String method, [
    Map<String, Object?> arguments = const {},
  ]) async {
    if (_busy) {
      throw PlatformException(
        code: 'busy',
        message: 'A PIV operation is already in progress',
      );
    }
    _busy = true;
    final generation = _generation;
    final serial = ref.read(currentDeviceDataProvider).value?.info.serial;
    UserInteractionController? controller;
    try {
      final managementTouch =
          state.value?.piv.metadata?.managementKeyMetadata.touchPolicy;
      final mayAuthenticate = ![
        'get',
        'getSlot',
        'reset',
        'changePin',
        'changePuk',
        'unblockPin',
      ].contains(method);
      if (ref.read(currentDeviceProvider)?.transport == Transport.usb &&
          ((mayAuthenticate &&
                  [
                    TouchPolicy.always,
                    TouchPolicy.cached,
                  ].contains(managementTouch)) ||
              (method == 'generate' &&
                  [
                    TouchPolicy.always.value,
                    TouchPolicy.cached.value,
                  ].contains(arguments['touchPolicy'])))) {
        controller = await ref.read(withContextProvider)((context) async {
          final l10n = AppLocalizations.of(context);
          return promptUserInteraction(
            context,
            icon: const Icon(Symbols.touch_app),
            title: l10n.s_touch_required,
            description: l10n.l_touch_button_now,
          );
        });
      }
      final next = _Snapshot(
        await _invoke(method, {...arguments, 'serial': serial}),
      );
      if (ref.mounted && generation == _generation) state = AsyncData(next);
      return next.result;
    } finally {
      controller?.close();
      _busy = false;
    }
  }
}

class IosPivStateNotifier extends PivStateNotifier {
  IosPivStateNotifier(super.devicePath);

  _PivSession get _session => ref.read(_sessionProvider(devicePath).notifier);

  @override
  Future<PivState> build() async =>
      (await ref.watch(_sessionProvider(devicePath).future)).piv;

  @override
  Future<void> reset() async => await _session.execute('reset');

  @override
  Future<bool> authenticate(String managementKey) async =>
      await _session.execute('authenticate', {'key': managementKey}) == true;

  @override
  Future<void> setManagementKey(
    String managementKey, {
    ManagementKeyType managementKeyType = defaultManagementKeyType,
    bool storeKey = false,
  }) async {
    await _session.execute('setManagementKey', {
      'key': managementKey,
      'keyType': managementKeyType.value,
      'storeKey': storeKey,
    });
  }

  Future<PinVerificationStatus> _pin(
    String method,
    Map<String, Object?> arguments,
  ) async {
    final json =
        await _session.execute(method, arguments) as Map<String, dynamic>;
    return switch (json['status']) {
      'success' => const PinVerificationStatus.success(),
      'invalid-pin' => PinVerificationStatus.failure(
        PivPinFailureReason.invalidPin(json['attemptsRemaining'] as int),
      ),
      'pin-complexity' => PinVerificationStatus.failure(
        const PivPinFailureReason.weakPin(),
      ),
      _ => throw const FormatException('Invalid PIV PIN response'),
    };
  }

  @override
  Future<PinVerificationStatus> verifyPin(String pin) =>
      _pin('verifyPin', {'pin': pin});

  @override
  Future<PinVerificationStatus> changePin(String pin, String newPin) =>
      _pin('changePin', {'pin': pin, 'newPin': newPin});

  @override
  Future<PinVerificationStatus> changePuk(String puk, String newPuk) =>
      _pin('changePuk', {'puk': puk, 'newPuk': newPuk});

  @override
  Future<PinVerificationStatus> unblockPin(String puk, String newPin) =>
      _pin('unblockPin', {'puk': puk, 'newPin': newPin});
}

class IosPivSlotsNotifier extends PivSlotsNotifier {
  IosPivSlotsNotifier(super.devicePath);

  _PivSession get _session => ref.read(_sessionProvider(devicePath).notifier);

  @override
  Future<List<PivSlot>> build() async =>
      (await ref.watch(_sessionProvider(devicePath).future)).slots;

  @override
  Future<PivExamineResult> examine(
    SlotId slot,
    String data, {
    String? password,
  }) async => PivExamineResult.fromJson(
    await _invoke('examineFile', {
      'slot': slot.hexId,
      'data': data,
      'password': password,
    }),
  );

  @override
  Future<bool> validateRfc4514(String value) async =>
      (await _invoke('validateRfc4514', {'data': value}))['status'] as bool;

  @override
  Future<(SlotMetadata?, String?)> read(SlotId slot) async {
    final result =
        await _session.execute('getSlot', {'slot': slot.hexId})
            as Map<String, dynamic>;
    return (
      result['metadata'] == null
          ? null
          : SlotMetadata.fromJson(result['metadata'] as Map<String, dynamic>),
      result['certificate'] as String?,
    );
  }

  @override
  Future<PivGenerateResult> generate(
    SlotId slot,
    KeyType keyType, {
    required PivGenerateParameters parameters,
    PinPolicy pinPolicy = PinPolicy.dfault,
    TouchPolicy touchPolicy = TouchPolicy.dfault,
    String? pin,
  }) async {
    final Map<String, Object?> document = switch (parameters) {
      PivGeneratePublicKeyParameters() => {'generateType': 'publicKey'},
      PivGenerateCsrParameters(:final subject) => {
        'generateType': 'csr',
        'subject': subject,
      },
      PivGenerateCertificateParameters(
        :final subject,
        :final validFrom,
        :final validTo,
      ) =>
        {
          'generateType': 'certificate',
          'subject': subject,
          'validFrom': validFrom.toUtc().toIso8601String(),
          'validTo': validTo.toUtc().toIso8601String(),
        },
    };
    final result = await _session.execute('generate', {
      'slot': slot.hexId,
      'keyType': keyType.value,
      'pinPolicy': pinPolicy.value,
      'touchPolicy': touchPolicy.value,
      'pin': pin,
      ...document,
    });
    return PivGenerateResult.fromJson(result as Map<String, dynamic>);
  }

  @override
  Future<PivImportResult> import(
    SlotId slot,
    String data, {
    String? password,
    PinPolicy pinPolicy = PinPolicy.dfault,
    TouchPolicy touchPolicy = TouchPolicy.dfault,
  }) async => PivImportResult.fromJson(
    await _session.execute('importFile', {
          'slot': slot.hexId,
          'data': data,
          'password': password,
          'pinPolicy': pinPolicy.value,
          'touchPolicy': touchPolicy.value,
        })
        as Map<String, dynamic>,
  );

  @override
  Future<void> delete(SlotId slot, bool deleteCert, bool deleteKey) async {
    await _session.execute('delete', {
      'slot': slot.hexId,
      'deleteCert': deleteCert,
      'deleteKey': deleteKey,
    });
  }

  @override
  Future<void> moveKey(
    SlotId source,
    SlotId destination,
    bool overwriteKey,
    bool includeCertificate,
  ) async {
    await _session.execute('moveKey', {
      'slot': source.hexId,
      'destination': destination.hexId,
      'overwriteKey': overwriteKey,
      'includeCertificate': includeCertificate,
    });
  }
}
