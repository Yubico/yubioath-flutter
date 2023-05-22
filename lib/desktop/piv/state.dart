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
import 'package:yubico_authenticator/desktop/models.dart';

import '../../app/logging.dart';
import '../../app/models.dart';
import '../../app/state.dart';
import '../../app/views/user_interaction.dart';
import '../../piv/models.dart';
import '../../piv/state.dart';
import '../rpc.dart';
import '../state.dart';

final _log = Logger('desktop.piv.state');

final _sessionProvider =
    Provider.autoDispose.family<RpcNodeSession, DevicePath>(
  (ref, devicePath) => RpcNodeSession(
      ref.watch(rpcProvider).requireValue, devicePath, ['ccid', 'piv']),
);

final desktopPivState = AsyncNotifierProvider.autoDispose
    .family<PivStateNotifier, PivState, DevicePath>(
        _DesktopPivStateNotifier.new);

class _DesktopPivStateNotifier extends PivStateNotifier {
  late RpcNodeSession _session;

  @override
  FutureOr<PivState> build(DevicePath devicePath) async {
    _session = ref.watch(_sessionProvider(devicePath));
    _session
      ..setErrorHandler('state-reset', (_) async {
        ref.invalidate(_sessionProvider(devicePath));
      })
      ..setErrorHandler('auth-required', (_) async {
        ref.invalidateSelf();
      });
    ref.onDispose(() {
      _session
        ..unsetErrorHandler('state-reset')
        ..unsetErrorHandler('auth-required');
    });
    final result = await _session.command('get');
    _log.debug('application status', jsonEncode(result));
    return PivState.fromJson(result['data']);
  }

  @override
  Future<void> reset() async {
    await _session.command('reset');
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

      return result['status'];
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
        'key_type': managementKeyType,
        'store_key': storeKey,
      },
    );
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

extension on SlotId {
  String get node => id.toRadixString(16).padLeft(2, '0');
}

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
    await _session.command('delete', target: ['slots', slot.node]);
    ref.invalidateSelf();
  }

  @override
  Future<PivGenerateResult> generate(
    SlotId slot,
    KeyType keyType,
    String subject, {
    GenerateType generateType = GenerateType.certificate,
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

      final result = await _session.command(
        'generate',
        target: [
          'slots',
          slot.node,
        ],
        params: {
          'key_type': keyType.value,
          'pin_policy': pinPolicy.value,
          'touch_policy': touchPolicy.value,
          'subject': subject,
          'generate_type': generateType.name,
          'pin': pin,
        },
        signal: signaler,
      );

      ref.invalidateSelf();

      return PivGenerateResult.fromJson(result);
    } finally {
      controller?.close();
    }
  }

  @override
  Future<PivImportResult> import(SlotId slot, String data,
      {String? password,
      PinPolicy pinPolicy = PinPolicy.dfault,
      TouchPolicy touchPolicy = TouchPolicy.dfault}) async {
    final result = await _session.command('import_file', target: [
      'slots',
      slot.node,
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
      slot.node,
    ]);
    final metadata = result['metadata'];
    return (
      metadata != null ? SlotMetadata.fromJson(metadata) : null,
      result['certificate'] as String?,
    );
  }
}
