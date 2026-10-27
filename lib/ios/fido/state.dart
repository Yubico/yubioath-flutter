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

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../app/logging.dart';
import '../../app/models.dart';
import '../../app/state.dart';
import '../../exception/platform_exception_decoder.dart';
import '../../fido/models.dart';
import '../../fido/state.dart';

const _fidoChannel = MethodChannel('com.yubico.authenticator/fido');
const _resetEvents = EventChannel('ios.fido.reset');
const _fingerprintEvents = EventChannel('ios.fido.registerFingerprint');
final _log = Logger('ios.fido.state');

Map<String, dynamic> _map(Object? value) {
  final map = _deepCast(value);
  if (map is! Map<String, dynamic>) {
    throw const FormatException('Expected a map from the iOS FIDO channel');
  }
  return map;
}

Object? _deepCast(Object? value) {
  if (value is Map) {
    return value.map<String, dynamic>(
      (key, value) => MapEntry(key as String, _deepCast(value)),
    );
  }
  if (value is List) {
    return value.map(_deepCast).toList();
  }
  return value;
}

List<Map<String, dynamic>> _list(Object? value) => (value! as List)
    .map((entry) => Map<String, dynamic>.from(entry as Map))
    .toList();

String _context(Ref ref, DevicePath path) {
  final serial = ref.read(currentDeviceDataProvider).value?.info.serial;
  return serial == null ? 'path:${path.key}' : 'serial:$serial';
}

Map<String, Object?> _arguments(
  Ref ref,
  DevicePath path, [
  Map<String, Object?>? values,
]) => {...?values, 'context': _context(ref, path)};

Future<T> _invoke<T>(String method, [Map<String, Object?>? arguments]) async {
  try {
    return await _fidoChannel.invokeMethod<T>(method, arguments) as T;
  } on PlatformException catch (error) {
    throw error.decode();
  }
}

class IosFidoStateNotifier extends FidoStateNotifier {
  IosFidoStateNotifier(super.devicePath);

  @override
  Future<FidoState> build() async {
    ref.onDispose(() => unawaited(_fidoChannel.invokeMethod<void>('clearPin')));
    try {
      return FidoState.fromJson(
        _map(await _invoke<Object?>('getState', _arguments(ref, devicePath))),
      );
    } catch (error, stackTrace) {
      _log.error('Failed to read FIDO state from YubiKey', error, stackTrace);
      Error.throwWithStackTrace(FidoStateLoadException(error), stackTrace);
    }
  }

  @override
  Stream<InteractionEvent> reset() {
    final controller = StreamController<InteractionEvent>();
    StreamSubscription<Object?>? subscription;
    var cancelled = false;

    controller.onListen = () async {
      subscription = _resetEvents.receiveBroadcastStream().listen(
        (event) {
          if (event is String && !controller.isClosed) {
            controller.add(InteractionEvent.values.byName(event));
          }
        },
        onError: (Object error, StackTrace stack) {
          if (!controller.isClosed) controller.addError(error, stack);
        },
      );
      try {
        await _invoke<Object?>('reset', _arguments(ref, devicePath));
        if (!controller.isClosed) {
          await controller.close();
          ref.invalidateSelf();
        }
      } catch (error, stack) {
        if (!controller.isClosed) controller.addError(error, stack);
      }
    };
    controller.onCancel = () async {
      cancelled = true;
      await _fidoChannel.invokeMethod<void>('cancelReset');
      await subscription?.cancel();
    };
    ref.onDispose(() {
      if (!cancelled) unawaited(_fidoChannel.invokeMethod<void>('cancelReset'));
    });
    return controller.stream;
  }

  @override
  Future<PinResult> setPin(String newPin, {String? oldPin}) async {
    final response = _map(
      await _invoke<Object?>(
        'setPin',
        _arguments(ref, devicePath, {'pin': oldPin, 'newPin': newPin}),
      ),
    );
    if (response['success'] == true) {
      state = AsyncData(
        state.requireValue.copyWith(
          unlocked: true,
          unlockedRead: true,
          pinRetries: null,
        ),
      );
      return PinResult.success();
    }
    if (response['pinViolation'] == true) {
      return PinResult.failed(const FidoPinFailureReason.weakPin());
    }
    final retries = response['pinRetries'] as int? ?? 0;
    state = AsyncData(state.requireValue.copyWith(pinRetries: retries));
    return PinResult.failed(
      FidoPinFailureReason.invalidPin(
        retries,
        response['authBlocked'] as bool? ?? false,
      ),
    );
  }

  @override
  Future<PinResult> unlock(String pin, {bool remember = false}) async {
    final response = _map(
      await _invoke<Object?>(
        'unlock',
        _arguments(ref, devicePath, {'pin': pin}),
      ),
    );
    if (response['success'] == true) {
      state = AsyncData(
        state.requireValue.copyWith(
          unlocked: true,
          unlockedRead: true,
          pinRetries: null,
        ),
      );
      return PinResult.success();
    }
    final retries = response['pinRetries'] as int? ?? 0;
    state = AsyncData(state.requireValue.copyWith(pinRetries: retries));
    return PinResult.failed(
      FidoPinFailureReason.invalidPin(
        retries,
        response['authBlocked'] as bool? ?? false,
      ),
    );
  }

  @override
  Future<void> enableEnterpriseAttestation() async {
    await _invoke<Object?>(
      'enableEnterpriseAttestation',
      _arguments(ref, devicePath),
    );
    ref.invalidateSelf();
  }
}

class IosFidoFingerprintsNotifier extends FidoFingerprintsNotifier {
  IosFidoFingerprintsNotifier(super.devicePath);

  @override
  Future<List<Fingerprint>> build() async => _list(
    await _invoke<Object?>('getFingerprints', _arguments(ref, devicePath)),
  ).map(Fingerprint.fromJson).toList();

  @override
  Stream<FingerprintEvent> registerFingerprint({String? name}) {
    final controller = StreamController<FingerprintEvent>();
    StreamSubscription<Object?>? subscription;

    controller.onListen = () async {
      subscription = _fingerprintEvents.receiveBroadcastStream().listen(
        (event) {
          if (event is Map && !controller.isClosed) {
            final item = Map<String, dynamic>.from(event);
            switch (item['status']) {
              case 'capture':
                controller.add(
                  FingerprintEvent.capture(item['remaining'] as int),
                );
                break;
              case 'capture-error':
                controller.add(FingerprintEvent.error(item['code'] as int));
                break;
            }
          }
        },
        onError: (Object error, StackTrace stack) {
          if (!controller.isClosed) controller.addError(error, stack);
        },
      );
      try {
        final fingerprint = Fingerprint.fromJson(
          _map(
            await _invoke<Object?>(
              'registerFingerprint',
              _arguments(ref, devicePath, {'name': name}),
            ),
          ),
        );
        if (!controller.isClosed) {
          controller.add(FingerprintEvent.complete(fingerprint));
        }
      } catch (error, stack) {
        if (!controller.isClosed) controller.addError(error, stack);
      } finally {
        await subscription?.cancel();
        if (!controller.isClosed) await controller.close();
      }
    };
    controller.onCancel = () async {
      await _fidoChannel.invokeMethod<void>('cancelRegisterFingerprint');
      await subscription?.cancel();
    };
    return controller.stream;
  }

  @override
  Future<Fingerprint> renameFingerprint(
    Fingerprint fingerprint,
    String name,
  ) async {
    final renamed = Fingerprint.fromJson(
      _map(
        await _invoke<Object?>(
          'renameFingerprint',
          _arguments(ref, devicePath, {
            'templateId': fingerprint.templateId,
            'name': name,
          }),
        ),
      ),
    );
    state = AsyncData([
      for (final item in state.requireValue)
        if (item.templateId == fingerprint.templateId) renamed else item,
    ]);
    return renamed;
  }

  @override
  Future<void> deleteFingerprint(Fingerprint fingerprint) async {
    await _invoke<Object?>(
      'deleteFingerprint',
      _arguments(ref, devicePath, {'templateId': fingerprint.templateId}),
    );
    state = AsyncData(
      state.requireValue
          .where((item) => item.templateId != fingerprint.templateId)
          .toList(),
    );
  }
}

class IosFidoCredentialsNotifier extends FidoCredentialsNotifier {
  IosFidoCredentialsNotifier(super.devicePath);

  @override
  Future<List<FidoCredential>> build() async => _list(
    await _invoke<Object?>('getCredentials', _arguments(ref, devicePath)),
  ).map(FidoCredential.fromJson).toList();

  @override
  Future<void> deleteCredential(FidoCredential credential) async {
    await _invoke<Object?>(
      'deleteCredential',
      _arguments(ref, devicePath, {
        'rpId': credential.rpId,
        'credentialId': credential.credentialId,
      }),
    );
    state = AsyncData(
      state.requireValue
          .where((item) => item.credentialId != credential.credentialId)
          .toList(),
    );
  }
}
