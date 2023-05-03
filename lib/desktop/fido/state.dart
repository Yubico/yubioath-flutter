/*
 * Copyright (C) 2022 Yubico.
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
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:yubico_authenticator/app/logging.dart';

import '../../app/models.dart';
import '../../fido/models.dart';
import '../../fido/state.dart';
import '../models.dart';
import '../rpc.dart';
import '../state.dart';

final _log = Logger('desktop.fido.state');

final _pinProvider = StateProvider.autoDispose.family<String?, DevicePath>(
  (ref, _) => null,
);

final _sessionProvider =
    Provider.autoDispose.family<RpcNodeSession, DevicePath>(
  (ref, devicePath) {
    // Make sure the pinProvider is held for the duration of the session.
    ref.watch(_pinProvider(devicePath));
    return RpcNodeSession(
        ref.watch(rpcProvider).requireValue, devicePath, ['fido', 'ctap2']);
  },
);

final desktopFidoState = AsyncNotifierProvider.autoDispose
    .family<FidoStateNotifier, FidoState, DevicePath>(
        _DesktopFidoStateNotifier.new);

class _DesktopFidoStateNotifier extends FidoStateNotifier {
  late RpcNodeSession _session;
  late StateController<String?> _pinController;

  @override
  FutureOr<FidoState> build(DevicePath devicePath) async {
    _session = ref.watch(_sessionProvider(devicePath));
    if (Platform.isWindows) {
      // Make sure to rebuild if isAdmin changes
      ref.watch(rpcStateProvider.select((state) => state.isAdmin));
    }
    _pinController = ref.watch(_pinProvider(devicePath).notifier);
    _session.setErrorHandler('state-reset', (_) async {
      ref.invalidate(_sessionProvider(devicePath));
    });
    _session.setErrorHandler('auth-required', (_) async {
      final pin = ref.read(_pinProvider(devicePath));
      if (pin != null) {
        await unlock(pin);
      }
    });
    ref.onDispose(() {
      _session.unsetErrorHandler('auth-required');
    });
    ref.onDispose(() {
      _session.unsetErrorHandler('state-reset');
    });

    final result = await _session.command('get');
    _log.debug('application status', jsonEncode(result));
    return FidoState.fromJson(result['data']);
  }

  @override
  Stream<InteractionEvent> reset() {
    final controller = StreamController<InteractionEvent>();
    final signaler = Signaler();
    signaler.signals
        .where((s) => s.status == 'reset')
        .map((signal) => InteractionEvent.values
            .firstWhere((e) => e.name == signal.body['state']))
        .listen(controller.sink.add);

    controller.onCancel = () {
      if (!controller.isClosed) {
        signaler.cancel();
      }
    };
    controller.onListen = () async {
      try {
        await _session.command('reset', signal: signaler);
        await controller.sink.close();
        ref.invalidateSelf();
      } catch (e) {
        controller.sink.addError(e);
      }
    };

    return controller.stream;
  }

  @override
  Future<PinResult> setPin(String newPin, {String? oldPin}) async {
    try {
      await _session.command('set_pin', params: {
        'pin': oldPin,
        'new_pin': newPin,
      });
      return unlock(newPin);
    } on RpcError catch (e) {
      if (e.status == 'pin-validation') {
        return PinResult.failed(e.body['retries'], e.body['auth_blocked']);
      }
      rethrow;
    }
  }

  @override
  Future<PinResult> unlock(String pin) async {
    try {
      await _session.command(
        'unlock',
        params: {'pin': pin},
      );
      _pinController.state = pin;

      return PinResult.success();
    } on RpcError catch (e) {
      if (e.status == 'pin-validation') {
        _pinController.state = null;
        return PinResult.failed(e.body['retries'], e.body['auth_blocked']);
      }
      rethrow;
    }
  }
}

final desktopFingerprintProvider = StateNotifierProvider.autoDispose.family<
        FidoFingerprintsNotifier, AsyncValue<List<Fingerprint>>, DevicePath>(
    (ref, devicePath) => _DesktopFidoFingerprintsNotifier(
          ref.watch(_sessionProvider(devicePath)),
          ref,
        ));

class _DesktopFidoFingerprintsNotifier extends FidoFingerprintsNotifier {
  final RpcNodeSession _session;
  final Ref _ref;

  _DesktopFidoFingerprintsNotifier(this._session, this._ref) {
    _refresh();
  }

  Future<void> _refresh() async {
    _ref.invalidate(fidoStateProvider(_session.devicePath));
    final result = await _session.command('fingerprints');
    setItems((result['children'] as Map<String, dynamic>)
        .entries
        .map((e) => Fingerprint(e.key, e.value['name']))
        .toList());
  }

  @override
  Future<void> deleteFingerprint(Fingerprint fingerprint) async {
    await _session
        .command('delete', target: ['fingerprints', fingerprint.templateId]);
    await _refresh();
  }

  @override
  Stream<FingerprintEvent> registerFingerprint({String? name}) {
    final controller = StreamController<FingerprintEvent>();
    final signaler = Signaler();
    signaler.signals.listen((signal) {
      switch (signal.status) {
        case 'capture':
          controller.sink
              .add(FingerprintEvent.capture(signal.body['remaining']));
          break;
        case 'capture-error':
          controller.sink.add(FingerprintEvent.error(signal.body['code']));
          break;
      }
    });

    controller.onCancel = () {
      if (!controller.isClosed) {
        signaler.cancel();
      }
    };
    controller.onListen = () async {
      try {
        final result = await _session.command(
          'add',
          target: ['fingerprints'],
          params: {'name': name},
          signal: signaler,
        );
        controller.sink
            .add(FingerprintEvent.complete(Fingerprint.fromJson(result)));
        await _refresh();
        await controller.sink.close();
      } catch (e) {
        controller.sink.addError(e);
      }
    };

    return controller.stream;
  }

  @override
  Future<Fingerprint> renameFingerprint(
      Fingerprint fingerprint, String name) async {
    await _session.command('rename',
        target: ['fingerprints', fingerprint.templateId],
        params: {'name': name});
    final renamed = fingerprint.copyWith(name: name);
    await _refresh();
    return renamed;
  }
}

final desktopCredentialProvider = StateNotifierProvider.autoDispose.family<
        FidoCredentialsNotifier, AsyncValue<List<FidoCredential>>, DevicePath>(
    (ref, devicePath) => _DesktopFidoCredentialsNotifier(
          ref.watch(_sessionProvider(devicePath)),
          ref,
        ));

class _DesktopFidoCredentialsNotifier extends FidoCredentialsNotifier {
  final RpcNodeSession _session;
  final Ref _ref;

  _DesktopFidoCredentialsNotifier(this._session, this._ref) {
    _refresh();
  }

  Future<void> _refresh() async {
    final List<FidoCredential> creds = [];
    final rps = await _session.command('credentials');
    for (final rpId in (rps['children'] as Map<String, dynamic>).keys) {
      final result = await _session.command(rpId, target: ['credentials']);
      for (final e in (result['children'] as Map<String, dynamic>).entries) {
        creds.add(FidoCredential(
            rpId: rpId,
            credentialId: e.key,
            userId: e.value['user_id'],
            userName: e.value['user_name']));
      }
    }
    setItems(creds);
    _ref.invalidate(fidoStateProvider(_session.devicePath));
  }

  @override
  Future<void> deleteCredential(FidoCredential credential) async {
    await _session.command('delete', target: [
      'credentials',
      credential.rpId,
      credential.credentialId,
    ]);
    await _refresh();
  }
}
