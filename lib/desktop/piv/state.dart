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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:logging/logging.dart';

import '../../app/logging.dart';
import '../../app/models.dart';
import '../../app/state.dart';
import '../../app/views/user_interaction.dart';
import '../../core/models.dart';
import '../../piv/models.dart';
import '../../piv/state.dart';
import '../models.dart';
import '../rpc.dart';
import '../state.dart';

final _log = Logger('desktop.piv.state');

final _managementKeyProvider =
    StateProvider.autoDispose.family<String?, DevicePath>(
  (ref, _) => null,
);

final _pinProvider = StateProvider.autoDispose.family<String?, DevicePath>(
  (ref, _) => null,
);

final _sessionProvider =
    Provider.autoDispose.family<RpcNodeSession, DevicePath>(
  (ref, devicePath) {
    // Make sure the managementKey and PIN are held for the duration of the session.
    ref.watch(_managementKeyProvider(devicePath));
    ref.watch(_pinProvider(devicePath));
    return RpcNodeSession(
        ref.watch(rpcProvider).requireValue, devicePath, ['ccid', 'piv']);
  },
);

final desktopPivState = AsyncNotifierProvider.autoDispose
    .family<PivStateNotifier, PivState, DevicePath>(
        _DesktopPivStateNotifier.new);

class _DesktopPivStateNotifier extends PivStateNotifier {
  late RpcNodeSession _session;
  late DevicePath _devicePath;

  @override
  FutureOr<PivState> build(DevicePath devicePath) async {
    _session = ref.watch(_sessionProvider(devicePath));
    _session
      ..setErrorHandler('state-reset', (_) async {
        ref.invalidate(_sessionProvider(devicePath));
      })
      ..setErrorHandler('auth-required', (e) async {
        final String? mgmtKey;
        if (state.valueOrNull?.metadata?.managementKeyMetadata.defaultValue ==
            true) {
          mgmtKey = defaultManagementKey;
        } else {
          mgmtKey = ref.read(_managementKeyProvider(devicePath));
        }
        if (mgmtKey != null) {
          if (await authenticate(mgmtKey)) {
            ref.invalidateSelf();
          } else {
            ref.read(_managementKeyProvider(devicePath).notifier).state = null;
            ref.invalidateSelf();
            throw e;
          }
        } else {
          ref.invalidateSelf();
          throw e;
        }
      });
    ref.onDispose(() {
      _session
        ..unsetErrorHandler('state-reset')
        ..unsetErrorHandler('auth-required');
    });
    _devicePath = devicePath;

    final result = await _session.command('get');
    _log.debug('application status', jsonEncode(result));
    final pivState = PivState.fromJson(result['data']);

    return pivState;
  }

  @override
  Future<void> reset() async {
    await _session.command('reset');
    ref.read(_managementKeyProvider(_devicePath).notifier).state = null;
    ref.invalidate(_sessionProvider(_session.devicePath));
  }

  @override
  Future<bool> authenticate(String managementKey) async {
    final withContext = ref.watch(withContextProvider);

    final signaler = Signaler();
    UserInteractionController? controller;
    try {
      signaler.signals.listen((signal) async {
        if (signal.status == 'touch') {
          controller = await withContext(
            (context) async {
              final l10n = AppLocalizations.of(context)!;
              return promptUserInteraction(
                context,
                icon: const Icon(Icons.touch_app),
                title: l10n.s_touch_required,
                description: l10n.l_touch_button_now,
              );
            },
          );
        }
      });

      final result = await _session.command(
        'authenticate',
        params: {'key': managementKey},
        signal: signaler,
      );

      if (result['status']) {
        ref.read(_managementKeyProvider(_devicePath).notifier).state =
            managementKey;
        final oldState = state.valueOrNull;
        if (oldState != null) {
          state = AsyncData(oldState.copyWith(authenticated: true));
        }
        return true;
      } else {
        return false;
      }
    } finally {
      controller?.close();
    }
  }

  @override
  Future<PinVerificationStatus> verifyPin(String pin) async {
    final pivState = state.valueOrNull;

    final signaler = Signaler();
    UserInteractionController? controller;
    try {
      if (pivState?.protectedKey == true) {
        // Might require touch as this will also authenticate
        final withContext = ref.watch(withContextProvider);
        signaler.signals.listen((signal) async {
          if (signal.status == 'touch') {
            controller = await withContext(
              (context) async {
                final l10n = AppLocalizations.of(context)!;
                return promptUserInteraction(
                  context,
                  icon: const Icon(Icons.touch_app),
                  title: l10n.s_touch_required,
                  description: l10n.l_touch_button_now,
                );
              },
            );
          }
        });
      }
      await _session.command(
        'verify_pin',
        params: {'pin': pin},
        signal: signaler,
      );

      ref.read(_pinProvider(_devicePath).notifier).state = pin;

      return const PinVerificationStatus.success();
    } on RpcError catch (e) {
      if (e.status == 'invalid-pin') {
        return PinVerificationStatus.failure(e.body['attempts_remaining']);
      }
      rethrow;
    } finally {
      controller?.close();
      ref.invalidateSelf();
    }
  }

  @override
  Future<PinVerificationStatus> changePin(String pin, String newPin) async {
    try {
      await _session.command(
        'change_pin',
        params: {'pin': pin, 'new_pin': newPin},
      );
      ref.read(_pinProvider(_devicePath).notifier).state = null;
      return const PinVerificationStatus.success();
    } on RpcError catch (e) {
      if (e.status == 'invalid-pin') {
        return PinVerificationStatus.failure(e.body['attempts_remaining']);
      }
      rethrow;
    } finally {
      ref.invalidateSelf();
    }
  }

  @override
  Future<PinVerificationStatus> changePuk(String puk, String newPuk) async {
    try {
      await _session.command(
        'change_puk',
        params: {'puk': puk, 'new_puk': newPuk},
      );
      return const PinVerificationStatus.success();
    } on RpcError catch (e) {
      if (e.status == 'invalid-pin') {
        return PinVerificationStatus.failure(e.body['attempts_remaining']);
      }
      rethrow;
    } finally {
      ref.invalidateSelf();
    }
  }

  @override
  Future<void> setManagementKey(String managementKey,
      {ManagementKeyType managementKeyType = defaultManagementKeyType,
      bool storeKey = false}) async {
    await _session.command(
      'set_key',
      params: {
        'key': managementKey,
        'key_type': managementKeyType.value,
        'store_key': storeKey,
      },
    );
    ref.read(_managementKeyProvider(_devicePath).notifier).state =
        managementKey;
    ref.invalidateSelf();
  }

  @override
  Future<PinVerificationStatus> unblockPin(String puk, String newPin) async {
    try {
      await _session.command(
        'unblock_pin',
        params: {'puk': puk, 'new_pin': newPin},
      );
      return const PinVerificationStatus.success();
    } on RpcError catch (e) {
      if (e.status == 'invalid-pin') {
        return PinVerificationStatus.failure(e.body['attempts_remaining']);
      }
      rethrow;
    } finally {
      ref.invalidateSelf();
    }
  }
}

final _shownSlots = SlotId.values.map((slot) => slot.id).toList();

final desktopPivSlots = AsyncNotifierProvider.autoDispose
    .family<PivSlotsNotifier, List<PivSlot>, DevicePath>(
        _DesktopPivSlotsNotifier.new);

class _DesktopPivSlotsNotifier extends PivSlotsNotifier {
  late RpcNodeSession _session;

  @override
  FutureOr<List<PivSlot>> build(DevicePath devicePath) async {
    _session = ref.watch(_sessionProvider(devicePath));

    final result = await _session.command('get', target: ['slots']);
    return (result['children'] as Map<String, dynamic>)
        .values
        .where((e) => _shownSlots.contains(e['slot']))
        .map((e) => PivSlot.fromJson(e))
        .toList();
  }

  @override
  Future<void> delete(SlotId slot) async {
    await _session.command('delete', target: ['slots', slot.hexId]);
    ref.invalidateSelf();
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
    final withContext = ref.watch(withContextProvider);

    final signaler = Signaler();
    UserInteractionController? controller;
    try {
      signaler.signals.listen((signal) async {
        if (signal.status == 'touch') {
          controller = await withContext(
            (context) async {
              final l10n = AppLocalizations.of(context)!;
              return promptUserInteraction(
                context,
                icon: const Icon(Icons.touch_app),
                title: l10n.s_touch_required,
                description: l10n.l_touch_button_now,
              );
            },
          );
        }
      });

      final (type, subject, validFrom, validTo) = parameters.when(
        certificate: (subject, validFrom, validTo) => (
          GenerateType.certificate,
          subject,
          dateFormatter.format(validFrom),
          dateFormatter.format(validTo),
        ),
        csr: (subject) => (
          GenerateType.csr,
          subject,
          null,
          null,
        ),
      );

      final pin = ref.read(_pinProvider(_session.devicePath));

      final result = await _session.command(
        'generate',
        target: [
          'slots',
          slot.hexId,
        ],
        params: {
          'key_type': keyType.value,
          'pin_policy': pinPolicy.value,
          'touch_policy': touchPolicy.value,
          'subject': subject,
          'generate_type': type.name,
          'valid_from': validFrom,
          'valid_to': validTo,
          'pin': pin,
        },
        signal: signaler,
      );

      ref.invalidateSelf();

      return PivGenerateResult.fromJson(
          {'generate_type': type.name, ...result});
    } finally {
      controller?.close();
    }
  }

  @override
  Future<PivExamineResult> examine(String data, {String? password}) async {
    final result = await _session.command('examine_file', params: {
      'data': data,
      'password': password,
    });

    if (result['status']) {
      return PivExamineResult.fromJson({'runtimeType': 'result', ...result});
    } else {
      return PivExamineResult.invalidPassword();
    }
  }

  @override
  Future<bool> validateRfc4514(String value) async {
    final result = await _session.command('validate_rfc4514', params: {
      'data': value,
    });
    return result['status'];
  }

  @override
  Future<PivImportResult> import(SlotId slot, String data,
      {String? password,
      PinPolicy pinPolicy = PinPolicy.dfault,
      TouchPolicy touchPolicy = TouchPolicy.dfault}) async {
    final result = await _session.command('import_file', target: [
      'slots',
      slot.hexId,
    ], params: {
      'data': data,
      'password': password,
      'pin_policy': pinPolicy.value,
      'touch_policy': touchPolicy.value,
    });

    ref.invalidateSelf();
    return PivImportResult.fromJson(result);
  }

  @override
  Future<(SlotMetadata?, String?)> read(SlotId slot) async {
    final result = await _session.command('get', target: [
      'slots',
      slot.hexId,
    ]);
    final data = result['data'];
    final metadata = data['metadata'];
    return (
      metadata != null ? SlotMetadata.fromJson(metadata) : null,
      data['certificate'] as String?,
    );
  }
}
