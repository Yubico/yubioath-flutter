/*
 * Copyright (C) 2024-2025 Yubico.
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
import '../../app/state.dart';
import '../../desktop/models.dart';
import '../../exception/cancellation_exception.dart';
import '../../exception/no_data_exception.dart';
import '../../exception/platform_exception_decoder.dart';
import '../../fido/models.dart';
import '../../fido/state.dart';
import '../overlay/nfc/method_channel_notifier.dart';

final _log = Logger('android.fido.state');

class AndroidFidoStateNotifier extends FidoStateNotifier {
  AndroidFidoStateNotifier(super.devicePath);
  final _events = const EventChannel('android.fido.sessionState');
  late StreamSubscription _sub;
  late final AndroidFidoMethodChannelNotifier fido = ref.read(
    _fidoMethodsProvider.notifier,
  );

  @override
  FutureOr<FidoState> build() async {
    _sub = _events.receiveBroadcastStream().listen(
      (event) {
        final json = jsonDecode(event);
        if (json == null) {
          state = AsyncValue.error(const NoDataException(), StackTrace.current);
        } else if (json == 'loading') {
          state = const AsyncValue.loading();
        } else {
          final fidoState = FidoState.fromJson(json);
          state = AsyncValue.data(fidoState);
        }
      },
      onError: (err, stackTrace) {
        state = AsyncValue.error(err, stackTrace);
      },
    );

    ref.onDispose(_sub.cancel);

    return Completer<FidoState>().future;
  }

  @override
  Stream<InteractionEvent> reset() {
    final controller = StreamController<InteractionEvent>();
    const resetEvents = EventChannel('android.fido.reset');

    final subscription = resetEvents.receiveBroadcastStream().skip(1).listen((
      event,
    ) {
      if (event is String && event.isNotEmpty) {
        controller.sink.add(
          InteractionEvent.values.firstWhere((e) => '"${e.name}"' == event),
        );
      }
    });

    controller.onCancel = () async {
      await fido.invoke('cancelReset');
      if (!controller.isClosed) {
        await subscription.cancel();
      }
    };

    controller.onListen = () async {
      try {
        await fido.invoke('reset');
        await controller.sink.close();
        ref.invalidateSelf();
      } on PlatformException catch (pe) {
        final decoded = pe.decode();
        if (decoded is! CancellationException) {
          _log.debug('PlatformException during reset: \'$pe\'');
        }
        controller.sink.addError(decoded);
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
      final response = jsonDecode(
        await fido.invoke('setPin', {'pin': oldPin, 'newPin': newPin}),
      );
      if (response['success'] == true) {
        _log.debug('FIDO PIN set/change successful');
        return PinResult.success();
      }

      if (response['pinViolation'] == true) {
        _log.debug('FIDO PIN violation');
        return PinResult.failed(const FidoPinFailureReason.weakPin());
      }

      _log.debug('FIDO PIN set/change failed');
      return PinResult.failed(
        FidoPinFailureReason.invalidPin(
          response['pinRetries'],
          response['authBlocked'],
        ),
      );
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
      final response = jsonDecode(await fido.invoke('unlock', {'pin': pin}));

      if (response['success'] == true) {
        _log.debug('FIDO applet unlocked');
        return PinResult.success();
      }

      _log.debug('FIDO applet unlock failed');
      return PinResult.failed(
        FidoPinFailureReason.invalidPin(
          response['pinRetries'],
          response['authBlocked'],
        ),
      );
    } on PlatformException catch (pe) {
      var decodedException = pe.decode();
      if (decodedException is! CancellationException) {
        // non pin failure
        // simulate cancellation but show an error
        await ref.read(withContextProvider)(
          (context) async => showMessage(
            context,
            ref.watch(l10nProvider).p_operation_failed_try_again,
          ),
        );
        throw CancellationException();
      }

      _log.debug('User cancelled unlock FIDO operation');
      throw decodedException;
    }
  }

  @override
  Future<void> enableEnterpriseAttestation() async {
    try {
      final response = jsonDecode(
        await fido.invoke('enableEnterpriseAttestation'),
      );

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
        'Platform exception during enable enterprise attestation: $pe',
      );
      rethrow;
    }
  }
}

class AndroidFidoFingerprintsNotifier extends FidoFingerprintsNotifier {
  final _events = const EventChannel('android.fido.fingerprints');
  late StreamSubscription _sub;
  late final AndroidFidoMethodChannelNotifier fido = ref.read(
    _fidoMethodsProvider.notifier,
  );

  AndroidFidoFingerprintsNotifier(super.devicePath);

  @override
  FutureOr<List<Fingerprint>> build() async {
    _sub = _events.receiveBroadcastStream().listen(
      (event) {
        final json = jsonDecode(event);
        if (json == null) {
          state = const AsyncValue.loading();
        } else {
          List<Fingerprint> newState = List.from(
            (json as List)
                .map((e) => Fingerprint.fromJson(e))
                .sortedBy<String>((f) => f.label.toLowerCase())
                .toList(),
          );
          state = AsyncValue.data(newState);
        }
      },
      onError: (err, stackTrace) {
        state = AsyncValue.error(err, stackTrace);
      },
    );

    ref.onDispose(_sub.cancel);
    return Completer<List<Fingerprint>>().future;
  }

  @override
  Stream<FingerprintEvent> registerFingerprint({String? name}) {
    final controller = StreamController<FingerprintEvent>();
    const registerEvents = EventChannel('android.fido.registerFp');

    final registerFpSub = registerEvents
        .receiveBroadcastStream()
        .skip(1)
        .listen((event) {
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
              final other => throw UnimplementedError(other),
            });
          }
        });

    controller.onCancel = () async {
      if (!controller.isClosed) {
        _log.debug('Cancelling fingerprint registration');
        await fido.invoke('cancelRegisterFingerprint');
        await registerFpSub.cancel();
      }
    };

    controller.onListen = () async {
      try {
        final registerFpResult = await fido.invoke('registerFingerprint', {
          'name': name,
        });

        _log.debug('Finished registerFingerprint with: $registerFpResult');

        final resultJson = jsonDecode(registerFpResult);

        if (resultJson['success'] == true) {
          controller.sink.add(
            FingerprintEvent.complete(Fingerprint.fromJson(resultJson)),
          );
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
    Fingerprint fingerprint,
    String name,
  ) async {
    try {
      final renameFingerprintResponse = jsonDecode(
        await fido.invoke('renameFingerprint', {
          'templateId': fingerprint.templateId,
          'name': name,
        }),
      );

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
      final deleteFingerprintResponse = jsonDecode(
        await fido.invoke('deleteFingerprint', {
          'templateId': fingerprint.templateId,
        }),
      );

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

class AndroidFidoCredentialsNotifier extends FidoCredentialsNotifier {
  final _events = const EventChannel('android.fido.credentials');
  late StreamSubscription _sub;
  late final AndroidFidoMethodChannelNotifier fido = ref.read(
    _fidoMethodsProvider.notifier,
  );

  AndroidFidoCredentialsNotifier(super.devicePath);

  @override
  FutureOr<List<FidoCredential>> build() async {
    _sub = _events.receiveBroadcastStream().listen(
      (event) {
        final json = jsonDecode(event);
        if (json == null) {
          state = const AsyncValue.loading();
        } else {
          List<FidoCredential> newState = List.from(
            (json as List).map((e) => FidoCredential.fromJson(e)).toList(),
          );
          state = AsyncValue.data(newState);
        }
      },
      onError: (err, stackTrace) {
        state = AsyncValue.error(err, stackTrace);
      },
    );

    ref.onDispose(_sub.cancel);
    return Completer<List<FidoCredential>>().future;
  }

  @override
  Future<void> deleteCredential(FidoCredential credential) async {
    try {
      await fido.invoke('deleteCredential', {
        'rpId': credential.rpId,
        'credentialId': credential.credentialId,
      });
    } on PlatformException catch (pe) {
      var decodedException = pe.decode();
      if (decodedException is CancellationException) {
        _log.debug('User cancelled delete credential FIDO operation');
      }
      throw decodedException;
    }
  }
}

final _fidoMethodsProvider =
    NotifierProvider<AndroidFidoMethodChannelNotifier, void>(
      () => AndroidFidoMethodChannelNotifier(),
    );

class AndroidFidoMethodChannelNotifier extends MethodChannelNotifier {
  AndroidFidoMethodChannelNotifier()
    : super(const MethodChannel('android.fido.methods'));
}
