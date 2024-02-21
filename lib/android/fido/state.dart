/*
 * Copyright (C) 2024 Yubico.
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
import '../../exception/cancellation_exception.dart';
import '../../exception/platform_exception_decoder.dart';
import '../../fido/models.dart';
import '../../fido/state.dart';

final _log = Logger('android.fido.state');

const _methods = MethodChannel('android.fido.methods');

final androidFidoStateProvider = AsyncNotifierProvider.autoDispose
    .family<FidoStateNotifier, FidoState, DevicePath>(_FidoStateNotifier.new);

class _FidoStateNotifier extends FidoStateNotifier {
  final _events = const EventChannel('android.fido.sessionState');
  late StreamSubscription _sub;

  @override
  FutureOr<FidoState> build(DevicePath devicePath) async {
    _sub = _events.receiveBroadcastStream().listen((event) {
      final json = jsonDecode(event);
      if (json == null) {
        state = const AsyncValue.loading();
      } else {
        final fidoState = FidoState.fromJson(json);
        state = AsyncValue.data(fidoState);
      }
    }, onError: (err, stackTrace) {
      state = AsyncValue.error(err, stackTrace);
    });

    ref.onDispose(_sub.cancel);

    return Completer<FidoState>().future;
  }

  @override
  Stream<InteractionEvent> reset() {
    final controller = StreamController<InteractionEvent>();
    const resetEvents = EventChannel('android.fido.reset');

    final resetSub =
        resetEvents.receiveBroadcastStream().skip(1).listen((event) {
      _log.debug('Received event: \'$event\'');
      if (event is String && event.isNotEmpty) {
        controller.sink.add(InteractionEvent.values
            .firstWhere((e) => '"${e.name}"' == event)); // TODO fix event form
      }
    });

    controller.onCancel = () async {
      await _methods.invokeMethod('cancelReset');
      if (!controller.isClosed) {
        await resetSub.cancel();
      }
    };

    controller.onListen = () async {
      try {
        // await ref
        //     .read(androidAppContextHandler)
        //     .switchAppContext(Application.passkeys);
        await _methods.invokeMethod('reset');
        _log.debug('Finished reset');
        await controller.sink.close();
        ref.invalidateSelf();
      } catch (e) {
        _log.debug('Received error: \'$e\'');
        controller.sink.addError(e);
      }
    };

    return controller.stream;
  }

  @override
  Future<PinResult> setPin(String newPin, {String? oldPin}) async {
    try {
      final setPinResponse = jsonDecode(await _methods.invokeMethod('set_pin', {
        'pin': oldPin,
        'new_pin': newPin,
      }));
      if (setPinResponse['success'] == true) {
        _log.debug('FIDO pin set/change successful');
        return PinResult.success();
      }

      _log.debug('FIDO pin set/change failed');
      return PinResult.failed(
          setPinResponse['pinRetries'], setPinResponse['authBlocked']);
    } on PlatformException catch (pe) {
      var decodedException = pe.decode();
      if (decodedException is CancellationException) {
        _log.debug('User cancelled Set/Change FIDO PIN operation');
      } else {
        _log.error('Set/Change FIDO PIN operation failed.', pe);
      }

      throw decodedException;
    }
  }

  @override
  Future<PinResult> unlock(String pin) async {
    try {
      final unlockResponse =
          jsonDecode(await _methods.invokeMethod('unlock', {'pin': pin}));

      if (unlockResponse['success'] == true) {
        _log.debug('FIDO applet unlocked');
        return PinResult.success();
      }

      _log.debug('FIDO applet unlock failed');
      return PinResult.failed(
          unlockResponse['pinRetries'], unlockResponse['authBlocked']);
    } on PlatformException catch (pe) {
      var decodedException = pe.decode();
      if (decodedException is CancellationException) {
        _log.debug('User cancelled unlock FIDO operation');
      } else {
        _log.error('Unlock FIDO operation failed.', pe);
      }

      throw decodedException;
    }
  }
}

final androidFingerprintProvider = AsyncNotifierProvider.autoDispose
    .family<FidoFingerprintsNotifier, List<Fingerprint>, DevicePath>(
        _FidoFingerprintsNotifier.new);

class _FidoFingerprintsNotifier extends FidoFingerprintsNotifier {
  @override
  FutureOr<List<Fingerprint>> build(DevicePath devicePath) async {
    return [];
  }

  @override
  Stream<FingerprintEvent> registerFingerprint({String? name}) {
    final controller = StreamController<FingerprintEvent>();

    return controller.stream;
  }

  @override
  Future<Fingerprint> renameFingerprint(
      Fingerprint fingerprint, String name) async {
    return fingerprint;
  }

  @override
  Future<void> deleteFingerprint(Fingerprint fingerprint) async {}
}

final androidCredentialProvider = AsyncNotifierProvider.autoDispose
    .family<FidoCredentialsNotifier, List<FidoCredential>, DevicePath>(
        _FidoCredentialsNotifier.new);

class _FidoCredentialsNotifier extends FidoCredentialsNotifier {
  final _events = const EventChannel('android.fido.credentials');
  late StreamSubscription _sub;

  @override
  FutureOr<List<FidoCredential>> build(DevicePath devicePath) async {
    _sub = _events.receiveBroadcastStream().listen((event) {
      final json = jsonDecode(event);
      if (json == null) {
        state = const AsyncValue.loading();
      } else {
        List<FidoCredential> newState = List.from(
            (json as List).map((e) => FidoCredential.fromJson(e)).toList());
        state = AsyncValue.data(newState);
      }
    }, onError: (err, stackTrace) {
      state = AsyncValue.error(err, stackTrace);
    });

    ref.onDispose(_sub.cancel);
    return Completer<List<FidoCredential>>().future;
  }

  @override
  Future<void> deleteCredential(FidoCredential credential) async {
    try {
      final deleteCredentialResponse = jsonDecode(await _methods.invokeMethod(
        'delete_credential',
        {
          'rp_id': credential.rpId,
          'credential_id': credential.credentialId,
        },
      ));

      if (deleteCredentialResponse['success'] == true) {
        _log.debug('FIDO delete credential succeeded');
      } else {
        _log.debug('FIDO delete credential failed');
      }
    } on PlatformException catch (pe) {
      var decodedException = pe.decode();
      if (decodedException is CancellationException) {
        _log.debug('User cancelled delete credential FIDO operation');
      } else {
        _log.error('Delete credential FIDO operation failed.', pe);
      }

      throw decodedException;
    }
  }
}
