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

import 'package:collection/collection.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../app/logging.dart';
import '../../app/message.dart';
import '../../app/models.dart';
import '../../app/state.dart';
import '../../desktop/models.dart';
import '../../exception/cancellation_exception.dart';
import '../../exception/no_data_exception.dart';
import '../../exception/platform_exception_decoder.dart';
import '../../fido/models.dart';
import '../../fido/state.dart';
import '../overlay/nfc/method_channel_notifier.dart';

final _log = Logger('android.fido.state');

final androidFidoStateProvider = AsyncNotifierProvider.autoDispose
    .family<FidoStateNotifier, FidoState, DevicePath>(_FidoStateNotifier.new);

class _FidoStateNotifier extends FidoStateNotifier {
  final _events = const EventChannel('android.fido.sessionState');
  late StreamSubscription _sub;
  late final _FidoMethodChannelNotifier fido =
      ref.read(_fidoMethodsProvider.notifier);

  @override
  FutureOr<FidoState> build(DevicePath devicePath) async {
    _sub = _events.receiveBroadcastStream().listen((event) {
      final json = jsonDecode(event);
      if (json == null) {
        state = AsyncValue.error(const NoDataException(), StackTrace.current);
      } else if (json == 'loading') {
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

    final subscription =
        resetEvents.receiveBroadcastStream().skip(1).listen((event) {
      if (event is String && event.isNotEmpty) {
        controller.sink.add(
            InteractionEvent.values.firstWhere((e) => '"${e.name}"' == event));
      }
    });

    controller.onCancel = () async {
      await fido.cancelReset();
      if (!controller.isClosed) {
        await subscription.cancel();
      }
    };

    controller.onListen = () async {
      try {
        await fido.reset();
        await controller.sink.close();
        ref.invalidateSelf();
      } catch (e) {
        _log.debug('Error during reset: \'$e\'');
        controller.sink.addError(e);
      }
    };

    return controller.stream;
  }

  @override
  Future<PinResult> setPin(String newPin, {String? oldPin}) async {
    try {
      final response = jsonDecode(await fido.setPin(newPin, oldPin: oldPin));
      if (response['success'] == true) {
        _log.debug('FIDO PIN set/change successful');
        return PinResult.success();
      }

      if (response['pinViolation'] == true) {
        _log.debug('FIDO PIN violation');
        return PinResult.failed(const FidoPinFailureReason.weakPin());
      }

      _log.debug('FIDO PIN set/change failed');
      return PinResult.failed(FidoPinFailureReason.invalidPin(
          response['pinRetries'], response['authBlocked']));
    } on PlatformException catch (pe) {
      var decodedException = pe.decode();
      if (decodedException is CancellationException) {
        _log.debug('User cancelled set/change FIDO PIN operation');
      }
      throw decodedException;
    }
  }

  @override
  Future<PinResult> unlock(String pin) async {
    try {
      final response = jsonDecode(await fido.unlock(pin));

      if (response['success'] == true) {
        _log.debug('FIDO applet unlocked');
        return PinResult.success();
      }

      _log.debug('FIDO applet unlock failed');
      return PinResult.failed(FidoPinFailureReason.invalidPin(
          response['pinRetries'], response['authBlocked']));
    } on PlatformException catch (pe) {
      var decodedException = pe.decode();
      if (decodedException is! CancellationException) {
        // non pin failure
        // simulate cancellation but show an error
        await ref.read(withContextProvider)((context) async => showMessage(
            context, ref.watch(l10nProvider).p_operation_failed_try_again));
        throw CancellationException();
      }

      _log.debug('User cancelled unlock FIDO operation');
      throw decodedException;
    }
  }

  @override
  Future<void> enableEnterpriseAttestation() async {
    try {
      final response = jsonDecode(await fido.enableEnterpriseAttestation());

      if (response['success'] == true) {
        _log.debug('Enterprise attestation enabled');
      }
    } on PlatformException catch (pe) {
      var decodedException = pe.decode();
      if (decodedException is CancellationException) {
        _log.debug('User cancelled unlock FIDO operation');
        throw decodedException;
      }

      _log.debug(
          'Platform exception during enable enterprise attestation: $pe');
      rethrow;
    }
  }
}

final androidFingerprintProvider = AsyncNotifierProvider.autoDispose
    .family<FidoFingerprintsNotifier, List<Fingerprint>, DevicePath>(
        _FidoFingerprintsNotifier.new);

class _FidoFingerprintsNotifier extends FidoFingerprintsNotifier {
  final _events = const EventChannel('android.fido.fingerprints');
  late StreamSubscription _sub;
  late final _FidoMethodChannelNotifier fido =
      ref.read(_fidoMethodsProvider.notifier);

  @override
  FutureOr<List<Fingerprint>> build(DevicePath devicePath) async {
    _sub = _events.receiveBroadcastStream().listen((event) {
      final json = jsonDecode(event);
      if (json == null) {
        state = const AsyncValue.loading();
      } else {
        List<Fingerprint> newState = List.from((json as List)
            .map((e) => Fingerprint.fromJson(e))
            .sortedBy<String>((f) => f.label.toLowerCase())
            .toList());
        state = AsyncValue.data(newState);
      }
    }, onError: (err, stackTrace) {
      state = AsyncValue.error(err, stackTrace);
    });

    ref.onDispose(_sub.cancel);
    return Completer<List<Fingerprint>>().future;
  }

  @override
  Stream<FingerprintEvent> registerFingerprint({String? name}) {
    final controller = StreamController<FingerprintEvent>();
    const registerEvents = EventChannel('android.fido.registerFp');

    final registerFpSub =
        registerEvents.receiveBroadcastStream().skip(1).listen((event) {
      if (controller.isClosed) {
        _log.debug('Controller already closed, ignoring: $event');
      }
      _log.debug('Received register fingerprint event: $event');
      if (event is String && event.isNotEmpty) {
        final e = jsonDecode(event);
        _log.debug('Received register fingerprint event: $e');

        final status = e['status'];

        controller.sink.add(switch (status) {
          'capture' => FingerprintEvent.capture(e['remaining']),
          'capture-error' => FingerprintEvent.error(e['code']),
          final other => throw UnimplementedError(other)
        });
      }
    });

    controller.onCancel = () async {
      if (!controller.isClosed) {
        _log.debug('Cancelling fingerprint registration');
        await fido.cancelFingerprintRegistration();
        await registerFpSub.cancel();
      }
    };

    controller.onListen = () async {
      try {
        final registerFpResult = await fido.registerFingerprint(name);

        _log.debug('Finished registerFingerprint with: $registerFpResult');

        final resultJson = jsonDecode(registerFpResult);

        if (resultJson['success'] == true) {
          controller.sink
              .add(FingerprintEvent.complete(Fingerprint.fromJson(resultJson)));
        } else {
          // TODO abstract platform errors
          final errorStatus = resultJson['status'];
          if (errorStatus != 'user-cancelled') {
            throw RpcError(errorStatus, 'Platform error: $errorStatus', {});
          }
        }
      } on PlatformException catch (pe) {
        _log.debug('Received platform exception: \'$pe\'');
        final decoded = pe.decode();
        controller.sink.addError(decoded);
      } catch (e) {
        _log.debug('Received error: \'$e\'');
        controller.sink.addError(e);
      } finally {
        await controller.sink.close();
      }
    };

    return controller.stream;
  }

  @override
  Future<Fingerprint> renameFingerprint(
      Fingerprint fingerprint, String name) async {
    try {
      final renameFingerprintResponse =
          jsonDecode(await fido.renameFingerprint(fingerprint, name));

      if (renameFingerprintResponse['success'] == true) {
        _log.debug('FIDO rename fingerprint succeeded');
        return Fingerprint(fingerprint.templateId, name);
      } else {
        _log.debug('FIDO rename fingerprint failed');
        return fingerprint;
      }
    } on PlatformException catch (pe) {
      var decodedException = pe.decode();
      if (decodedException is CancellationException) {
        _log.debug('User cancelled rename fingerprint FIDO operation');
      } else {
        _log.error('Rename fingerprint FIDO operation failed.', pe);
      }

      throw decodedException;
    }
  }

  @override
  Future<void> deleteFingerprint(Fingerprint fingerprint) async {
    try {
      final deleteFingerprintResponse =
          jsonDecode(await fido.deleteFingerprint(fingerprint));

      if (deleteFingerprintResponse['success'] == true) {
        _log.debug('FIDO delete fingerprint succeeded');
      } else {
        _log.debug('FIDO delete fingerprint failed');
      }
    } on PlatformException catch (pe) {
      var decodedException = pe.decode();
      if (decodedException is CancellationException) {
        _log.debug('User cancelled delete fingerprint FIDO operation');
      } else {
        _log.error('Delete fingerprint FIDO operation failed.', pe);
      }

      throw decodedException;
    }
  }
}

final androidCredentialProvider = AsyncNotifierProvider.autoDispose
    .family<FidoCredentialsNotifier, List<FidoCredential>, DevicePath>(
        _FidoCredentialsNotifier.new);

class _FidoCredentialsNotifier extends FidoCredentialsNotifier {
  final _events = const EventChannel('android.fido.credentials');
  late StreamSubscription _sub;
  late final _FidoMethodChannelNotifier fido =
      ref.read(_fidoMethodsProvider.notifier);

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
      await fido.deleteCredential(credential);
    } on PlatformException catch (pe) {
      var decodedException = pe.decode();
      if (decodedException is CancellationException) {
        _log.debug('User cancelled delete credential FIDO operation');
      } else {
        throw decodedException;
      }
    }
  }
}

final _fidoMethodsProvider = NotifierProvider<_FidoMethodChannelNotifier, void>(
    () => _FidoMethodChannelNotifier());

class _FidoMethodChannelNotifier extends MethodChannelNotifier {
  _FidoMethodChannelNotifier()
      : super(const MethodChannel('android.fido.methods'));
  late final l10n = ref.read(l10nProvider);

  @override
  void build() {}

  Future<dynamic> deleteCredential(FidoCredential credential) async =>
      invoke('deleteCredential', {
        'callArgs': {
          'rpId': credential.rpId,
          'credentialId': credential.credentialId
        }
      });

  Future<dynamic> cancelReset() async => invoke('cancelReset');

  Future<dynamic> reset() async => invoke('reset');

  Future<dynamic> setPin(String newPin, {String? oldPin}) async =>
      invoke('setPin', {
        'callArgs': {'pin': oldPin, 'newPin': newPin},
      });

  Future<dynamic> unlock(String pin) async => invoke('unlock', {
        'callArgs': {'pin': pin},
      });

  Future<dynamic> enableEnterpriseAttestation() async =>
      invoke('enableEnterpriseAttestation');

  Future<dynamic> registerFingerprint(String? name) async =>
      invoke('registerFingerprint', {
        'callArgs': {'name': name}
      });

  Future<dynamic> cancelFingerprintRegistration() async =>
      invoke('cancelRegisterFingerprint');

  Future<dynamic> renameFingerprint(
          Fingerprint fingerprint, String name) async =>
      invoke('renameFingerprint', {
        'callArgs': {'templateId': fingerprint.templateId, 'name': name},
      });

  Future<dynamic> deleteFingerprint(Fingerprint fingerprint) async =>
      invoke('deleteFingerprint', {
        'callArgs': {'templateId': fingerprint.templateId},
      });
}
