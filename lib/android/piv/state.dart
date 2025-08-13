/*
 * Copyright (C) 2025 Yubico.
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

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// TODO import 'package:logging/logging.dart';

import '../../app/models.dart';
// TODO import '../../app/state.dart';
// TODO import '../../app/views/user_interaction.dart';
import '../../core/models.dart';
import '../../exception/no_data_exception.dart';
import '../../piv/models.dart';
import '../../piv/state.dart';
import '../overlay/nfc/method_channel_notifier.dart' show MethodChannelNotifier;

// TODO final _log = Logger('android.piv.state');

// final _managementKeyProvider = StateProvider.autoDispose
//     .family<String?, DevicePath>((ref, _) => null);

// TODO
// final _pinProvider = StateProvider.autoDispose.family<String?, DevicePath>(
//   (ref, _) => null,
// );

final androidPivState = AsyncNotifierProvider.autoDispose
    .family<PivStateNotifier, PivState, DevicePath>(
      _AndroidPivStateNotifier.new,
    );

class _AndroidPivStateNotifier extends PivStateNotifier {
  //late DevicePath _devicePath;

  final _events = const EventChannel('android.piv.state');
  late StreamSubscription _sub;
  late _PivMethodChannelNotifier piv = ref.watch(_pivMethodsProvider.notifier);

  @override
  FutureOr<PivState> build(DevicePath devicePath) async {
    _sub = _events.receiveBroadcastStream().listen(
      (event) {
        final json = jsonDecode(event);
        if (json == null) {
          state = AsyncValue.error(const NoDataException(), StackTrace.current);
        } else if (json == 'loading') {
          state = const AsyncValue.loading();
        } else {
          final pivState = PivState.fromJson(json);
          state = AsyncValue.data(pivState);
        }
      },
      onError: (err, stackTrace) {
        state = AsyncValue.error(err, stackTrace);
      },
    );

    ref.onDispose(_sub.cancel);

    return Completer<PivState>().future;

    // _session = ref.watch(_sessionProvider(devicePath));
    // _session
    //   ..setErrorHandler('state-reset', (_) async {
    //     ref.invalidate(_sessionProvider(devicePath));
    //   })
    //   ..setErrorHandler('auth-required', (e) async {
    //     try {
    //       if (state.valueOrNull?.protectedKey == true) {
    //         final String? pin;
    //         if (state.valueOrNull?.metadata?.pinMetadata.defaultValue == true) {
    //           pin = defaultPin;
    //         } else {
    //           pin = ref.read(_pinProvider(devicePath));
    //         }
    //         if (pin != null) {
    //           if (await verifyPin(pin) is PinSuccess) {
    //             return;
    //           } else {
    //             ref.read(_pinProvider(devicePath).notifier).state = null;
    //           }
    //         }
    //       } else {
    //         final String? mgmtKey;
    //         if (state
    //                 .valueOrNull
    //                 ?.metadata
    //                 ?.managementKeyMetadata
    //                 .defaultValue ==
    //             true) {
    //           mgmtKey = defaultManagementKey;
    //         } else {
    //           mgmtKey = ref.read(_managementKeyProvider(devicePath));
    //         }
    //         if (mgmtKey != null) {
    //           if (await authenticate(mgmtKey)) {
    //             return;
    //           } else {
    //             ref.read(_managementKeyProvider(devicePath).notifier).state =
    //                 null;
    //           }
    //         }
    //       }
    //       throw e;
    //     } finally {
    //       ref.invalidateSelf();
    //     }
    //   });
    // ref.onDispose(() {
    //   _session
    //     ..unsetErrorHandler('state-reset')
    //     ..unsetErrorHandler('auth-required');
    // });
    // _devicePath = devicePath;
    //
    // final result = await _session.command('get');
    // _log.debug('application status', jsonEncode(result));
    //final pivState = PivState.fromJson({});

    //return pivState;
  }

  @override
  Future<void> reset() async {
    await piv.invoke('reset');
    //ref.read(_managementKeyProvider(_devicePath).notifier).state = null;
    //ref.invalidate(_sessionProvider(_session.devicePath));
  }

  @override
  Future<bool> authenticate(String managementKey) async {
    // TODO final withContext = ref.watch(withContextProvider);

    //    final signaler = Signaler();
    // TODO UserInteractionController? controller;
    try {
      // signaler.signals.listen((signal) async {
      //   if (signal.status == 'touch') {
      //     controller = await withContext((context) async {
      //       final l10n = AppLocalizations.of(context);
      //       return promptUserInteraction(
      //         context,
      //         icon: const Icon(Symbols.touch_app),
      //         title: l10n.s_touch_required,
      //         description: l10n.l_touch_button_now,
      //       );
      //     });
      //   }
      //});

      final result = jsonDecode(
        await piv.invoke(
          'authenticate',
          {'key': managementKey},
          //signal: signaler,
        ),
      );

      if (result['status']) {
        // ref.read(_managementKeyProvider(_devicePath).notifier).state =
        //     managementKey;
        final oldState = state.valueOrNull;
        if (oldState != null) {
          state = AsyncData(oldState.copyWith(authenticated: true));
        }
        return true;
      } else {
        return false;
      }
    } finally {
      // TODO controller?.close();
    }
  }

  @override
  Future<PinVerificationStatus> verifyPin(String pin) async {
    // TODO final pivState = state.valueOrNull;

    // final signaler = Signaler();
    // TODO UserInteractionController? controller;
    try {
      //   if (pivState?.protectedKey == true) {
      //     // Might require touch as this will also authenticate
      //     final withContext = ref.watch(withContextProvider);
      //     signaler.signals.listen((signal) async {
      //       if (signal.status == 'touch') {
      //         controller = await withContext((context) async {
      //           final l10n = AppLocalizations.of(context);
      //           return promptUserInteraction(
      //             context,
      //             icon: const Icon(Symbols.touch_app),
      //             title: l10n.s_touch_required,
      //             description: l10n.l_touch_button_now,
      //           );
      //         });
      //       }
      //     });
      //   }
      var result = jsonDecode(await piv.invoke('verifyPin', {'pin': pin}));

      return switch (result['status']) {
        'success' => const PinVerificationStatus.success(),
        'invalid-pin' => PinVerificationStatus.failure(
          PivPinFailureReason.invalidPin(result['attemptsRemaining']),
        ),
        _ => throw 'Invalid response',
      };
    } on PlatformException catch (_) {
      rethrow;
    } finally {
      // TODO controller?.close();
      ref.invalidateSelf();
    }
  }

  @override
  Future<PinVerificationStatus> changePin(String pin, String newPin) async {
    try {
      final result = jsonDecode(
        await piv.invoke('changePin', {'pin': pin, 'newPin': newPin}),
      );

      return switch (result['status']) {
        'success' => const PinVerificationStatus.success(),
        'invalid-pin' => PinVerificationStatus.failure(
          PivPinFailureReason.invalidPin(result['attemptsRemaining']),
        ),
        'pin-complexity' => PinVerificationStatus.failure(
          const PivPinFailureReason.weakPin(),
        ),
        _ => throw 'Invalid response',
      };
    } on PlatformException catch (_) {
      rethrow;
    } finally {
      ref.invalidateSelf();
    }
  }

  @override
  Future<PinVerificationStatus> changePuk(String puk, String newPuk) async {
    try {
      final result = jsonDecode(
        await piv.invoke('changePuk', {'puk': puk, 'newPuk': newPuk}),
      );
      return switch (result['status']) {
        'success' => const PinVerificationStatus.success(),
        'invalid-pin' => PinVerificationStatus.failure(
          PivPinFailureReason.invalidPin(result['attemptsRemaining']),
        ),
        'pin-complexity' => PinVerificationStatus.failure(
          const PivPinFailureReason.weakPin(),
        ),
        _ => throw 'Invalid response',
      };
    } on PlatformException catch (_) {
      rethrow;
    } finally {
      ref.invalidateSelf();
    }
  }

  @override
  Future<void> setManagementKey(
    String managementKey, {
    ManagementKeyType managementKeyType = defaultManagementKeyType,
    bool storeKey = false,
  }) async {
    await piv.invoke('setManagementKey', {
      'key': managementKey,
      'keyType': managementKeyType.value,
      'storeKey': storeKey,
    });
    // ref.read(_managementKeyProvider(_devicePath).notifier).state =
    //     managementKey;
    ref.invalidateSelf();
  }

  @override
  Future<PinVerificationStatus> unblockPin(String puk, String newPin) async {
    try {
      final result = jsonDecode(
        await piv.invoke('unblockPin', {'puk': puk, 'newPin': newPin}),
      );
      return switch (result['status']) {
        'success' => const PinVerificationStatus.success(),
        'invalid-pin' => PinVerificationStatus.failure(
          PivPinFailureReason.invalidPin(result['attemptsRemaining']),
        ),
        'pin-complexity' => PinVerificationStatus.failure(
          const PivPinFailureReason.weakPin(),
        ),
        _ => throw 'Invalid response',
      };
    } on PlatformException catch (_) {
      rethrow;
    } finally {
      ref.invalidateSelf();
    }
  }
}

final _shownSlots = SlotId.values.map((slot) => slot.id).toList();

final androidPivSlots = AsyncNotifierProvider.autoDispose
    .family<PivSlotsNotifier, List<PivSlot>, DevicePath>(
      _AndroidPivSlotsNotifier.new,
    );

class _AndroidPivSlotsNotifier extends PivSlotsNotifier {
  final _events = const EventChannel('android.piv.slots');
  late StreamSubscription _sub;
  late _PivMethodChannelNotifier piv = ref.watch(_pivMethodsProvider.notifier);

  @override
  FutureOr<List<PivSlot>> build(DevicePath devicePath) async {
    _sub = _events.receiveBroadcastStream().listen(
      (event) {
        final json = jsonDecode(event);
        if (json == null) {
          state = AsyncValue.error(const NoDataException(), StackTrace.current);
        } else if (json == 'loading') {
          state = const AsyncValue.loading();
        } else {
          final json = jsonDecode(event);
          List<PivSlot>? slots = json != null
              ? List.from(
                  (json as List)
                      .where((e) => _shownSlots.contains(e['slot']))
                      .map((e) => PivSlot.fromJson(e))
                      .toList(growable: false),
                )
              : [];

          state = AsyncValue.data(slots);
        }
      },
      onError: (err, stackTrace) {
        state = AsyncValue.error(err, stackTrace);
      },
    );

    ref.onDispose(_sub.cancel);

    return Completer<List<PivSlot>>().future;
  }

  @override
  Future<void> delete(SlotId slot, bool deleteCert, bool deleteKey) async {
    await piv.invoke('delete', {
      'slot': slot.hexId,
      'deleteCert': deleteCert,
      'deleteKey': deleteKey,
    });
    ref.invalidateSelf();
  }

  @override
  Future<void> moveKey(
    SlotId source,
    SlotId destination,
    bool overwriteKey,
    bool includeCertificate,
  ) async {
    await piv.invoke('moveKey', {
      'slot': source.hexId,
      'destination': destination.hexId,
      'overwriteKey': overwriteKey,
      'includeCertificate': includeCertificate,
    });
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
    // final withContext = ref.watch(withContextProvider);
    //
    // final signaler = Signaler();
    // UserInteractionController? controller;
    try {
      //   signaler.signals.listen((signal) async {
      //     if (signal.status == 'touch') {
      //       controller = await withContext((context) async {
      //         final l10n = AppLocalizations.of(context);
      //         return promptUserInteraction(
      //           context,
      //           icon: const Icon(Symbols.touch_app),
      //           title: l10n.s_touch_required,
      //           description: l10n.l_touch_button_now,
      //         );
      //       });
      //     }
      //   });
      //
      final (type, subject, validFrom, validTo) = switch (parameters) {
        PivGeneratePublicKeyParameters() => (
          GenerateType.publicKey,
          null,
          null,
          null,
        ),

        PivGenerateCertificateParameters(
          :final subject,
          :final validFrom,
          :final validTo,
        ) =>
          (
            GenerateType.certificate,
            subject,
            dateFormatter.format(validFrom),
            dateFormatter.format(validTo),
          ),

        PivGenerateCsrParameters(:final subject) => (
          GenerateType.csr,
          subject,
          null,
          null,
        ),
      };

      //final pin = ref.read(_pinProvider(_session.devicePath));

      final result = jsonDecode(
        await piv.invoke(
          'generate',
          {
            'slot': slot.hexId,
            'keyType': keyType.value,
            'pinPolicy': pinPolicy.value,
            'touchPolicy': touchPolicy.value,
            'subject': subject,
            'generateType': type.name,
            'validFrom': validFrom,
            'validTo': validTo,
          },
          //signal: signaler,
        ),
      );

      ref.invalidateSelf();

      return PivGenerateResult.fromJson({
        'generate_type': type.name,
        ...result,
      });
    } finally {
      //controller?.close();
    }
    //return PivGenerateResult.fromJson({});
  }

  @override
  Future<PivExamineResult> examine(
    SlotId slot,
    String data, {
    String? password,
  }) async {
    final result = jsonDecode(
      await piv.invoke('examineFile', {
        'slot': slot.hexId,
        'data': data,
        'password': password,
      }),
    );

    if (result['status']) {
      return PivExamineResult.fromJson({'runtimeType': 'result', ...result});
    } else {
      return PivExamineResult.invalidPassword();
    }
  }

  @override
  Future<bool> validateRfc4514(String value) async {
    final result = jsonDecode(
      await piv.invoke('validateRfc4514', {'data': value}),
    );
    return result['status'];
  }

  @override
  Future<PivImportResult> import(
    SlotId slot,
    String data, {
    String? password,
    PinPolicy pinPolicy = PinPolicy.dfault,
    TouchPolicy touchPolicy = TouchPolicy.dfault,
  }) async {
    final result = jsonDecode(
      await piv.invoke('importFile', {
        'slot': slot.hexId,
        'data': data,
        'password': password,
        'pinPolicy': pinPolicy.value,
        'touchPolicy': touchPolicy.value,
      }),
    );

    ref.invalidateSelf();
    return PivImportResult.fromJson(result);
  }

  @override
  Future<(SlotMetadata?, String?)> read(SlotId slot) async {
    final result = jsonDecode(
      await piv.invoke('getSlot', {'slot': slot.hexId}),
    );
    final metadata = result['metadata'];
    return (
      metadata != null ? SlotMetadata.fromJson(metadata) : null,
      result['certificate'] as String?,
    );
  }
}

final _pivMethodsProvider = NotifierProvider<_PivMethodChannelNotifier, void>(
  () => _PivMethodChannelNotifier(),
);

class _PivMethodChannelNotifier extends MethodChannelNotifier {
  _PivMethodChannelNotifier()
    : super(const MethodChannel('android.piv.methods'));
}
