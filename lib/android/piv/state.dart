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
import 'package:logging/logging.dart';

import '../../app/logging.dart';
import '../../app/models.dart';
import '../../core/models.dart';
import '../../exception/cancellation_exception.dart';
import '../../exception/no_data_exception.dart';
import '../../exception/platform_exception_decoder.dart';
import '../../piv/models.dart';
import '../../piv/state.dart';
import '../app_methods.dart';
import '../overlay/nfc/method_channel_notifier.dart' show MethodChannelNotifier;

final _log = Logger('android.piv.state');

final androidPivState = AsyncNotifierProvider.autoDispose
    .family<PivStateNotifier, PivState, DevicePath>(
      AndroidPivStateNotifier.new,
    );

class AndroidPivStateNotifier extends PivStateNotifier {
  AndroidPivStateNotifier(super.devicePath);
  final _events = const EventChannel('android.piv.state');
  late StreamSubscription _sub;
  late PivMethodChannelNotifier piv = ref.watch(_pivMethodsProvider.notifier);

  @override
  FutureOr<PivState> build() async {
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
  }

  @override
  Future<void> reset() async {
    await piv.invoke('reset');
  }

  @override
  Future<bool> authenticate(String managementKey) async {
    final result = jsonDecode(
      await piv.invoke('authenticate', {'key': managementKey}),
    );

    if (result['status']) {
      final oldState = state.value;
      if (oldState != null) {
        state = AsyncData(oldState.copyWith(authenticated: true));
      }
      return true;
    } else {
      return false;
    }
  }

  @override
  Future<PinVerificationStatus> verifyPin(String pin) async {
    try {
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
      AndroidPivSlotsNotifier.new,
    );

class AndroidPivSlotsNotifier extends PivSlotsNotifier {
  AndroidPivSlotsNotifier(super.devicePath);
  final _events = const EventChannel('android.piv.slots');
  late StreamSubscription _sub;
  late PivMethodChannelNotifier piv = ref.watch(_pivMethodsProvider.notifier);

  @override
  FutureOr<List<PivSlot>> build() async {
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
    try {
      await piv.invoke('delete', {
        'slot': slot.hexId,
        'deleteCert': deleteCert,
        'deleteKey': deleteKey,
      });
      ref.invalidateSelf();
    } on PlatformException catch (pe) {
      throw pe.decode();
    }
  }

  @override
  Future<void> moveKey(
    SlotId source,
    SlotId destination,
    bool overwriteKey,
    bool includeCertificate,
  ) async {
    try {
      await piv.invoke('moveKey', {
        'slot': source.hexId,
        'destination': destination.hexId,
        'overwriteKey': overwriteKey,
        'includeCertificate': includeCertificate,
      });
      ref.invalidateSelf();
    } on PlatformException catch (pe) {
      throw pe.decode();
    }
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
    try {
      await preserveConnectedDeviceWhenPaused();
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

      final result = jsonDecode(
        await piv.invoke('generate', {
          'slot': slot.hexId,
          'keyType': keyType.value,
          'pinPolicy': pinPolicy.value,
          'touchPolicy': touchPolicy.value,
          'subject': subject,
          'generateType': type.name,
          'validFrom': validFrom,
          'validTo': validTo,
        }),
      );

      return PivGenerateResult.fromJson({
        'generate_type': type.name,
        ...result,
      });
    } on PlatformException catch (pe) {
      var decodedException = pe.decode();
      if (decodedException is CancellationException) {
        _log.debug('User cancelled generate key PIV operation');
      } else {
        _log.error('Generate key PIV operation failed.', pe);
      }

      throw decodedException;
    }
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
    try {
      await preserveConnectedDeviceWhenPaused();
      final result = jsonDecode(
        await piv.invoke('getSlot', {'slot': slot.hexId}),
      );
      final metadata = result['metadata'];
      return (
        metadata != null ? SlotMetadata.fromJson(metadata) : null,
        result['certificate'] as String?,
      );
    } on PlatformException catch (pe) {
      throw pe.decode();
    }
  }
}

final _pivMethodsProvider = NotifierProvider<PivMethodChannelNotifier, void>(
  () => PivMethodChannelNotifier(),
);

class PivMethodChannelNotifier extends MethodChannelNotifier {
  PivMethodChannelNotifier()
    : super(const MethodChannel('android.piv.methods'));
}
