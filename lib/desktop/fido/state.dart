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
import '../../app/state.dart';
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

  FutureOr<FidoState> _build(DevicePath devicePath) async {
    var result = await _session.command('get');
    FidoState fidoState = FidoState.fromJson(result['data']);
    if (fidoState.hasPin && !fidoState.unlocked) {
      final pin = ref.read(_pinProvider(devicePath));
      if (pin != null) {
        await unlock(pin);
        result = await _session.command('get');
        fidoState = FidoState.fromJson(result['data']);
      }
    }

    _log.debug('application status', jsonEncode(fidoState));
    return fidoState;
  }

  @override
  FutureOr<FidoState> build(DevicePath devicePath) async {
    _session = ref.watch(_sessionProvider(devicePath));
    if (Platform.isWindows) {
      // Make sure to rebuild if isAdmin changes
      ref.watch(asyncRpcStateProvider.select((state) => state.isAdmin));
    }

    ref.listen<WindowState>(
      windowStateProvider,
      (prev, next) async {
        if (prev?.active == false && next.active) {
          // Refresh state on active
          final newState = await _build(devicePath);
          if (state.valueOrNull != newState) {
            state = AsyncValue.data(newState);
          }
        }
      },
    );

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

    return _build(devicePath);
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

final desktopFingerprintProvider = AsyncNotifierProvider.autoDispose
    .family<FidoFingerprintsNotifier, List<Fingerprint>, DevicePath>(
        _DesktopFidoFingerprintsNotifier.new);

class _DesktopFidoFingerprintsNotifier extends FidoFingerprintsNotifier {
  late RpcNodeSession _session;

  @override
  FutureOr<List<Fingerprint>> build(DevicePath devicePath) async {
    _session = ref.watch(_sessionProvider(devicePath));
    ref.watch(fidoStateProvider(devicePath));

    // Refresh on active
    ref.listen<WindowState>(
      windowStateProvider,
      (prev, next) async {
        if (prev?.active == false && next.active) {
          // Refresh state on active
          final newState = await _build(devicePath);
          if (state.valueOrNull != newState) {
            state = AsyncValue.data(newState);
          }
        }
      },
    );

    return _build(devicePath);
  }

  FutureOr<List<Fingerprint>> _build(DevicePath devicePath) async {
    final result = await _session.command('fingerprints');
    return List.unmodifiable((result['children'] as Map<String, dynamic>)
        .entries
        .map((e) => Fingerprint(e.key, e.value['name']))
        .toList());
  }

  @override
  Future<void> deleteFingerprint(Fingerprint fingerprint) async {
    await _session
        .command('delete', target: ['fingerprints', fingerprint.templateId]);
    ref.invalidate(fidoStateProvider(_session.devicePath));
  }

  @override
  Stream<FingerprintEvent> registerFingerprint({String? name}) {
    final controller = StreamController<FingerprintEvent>();
    final signaler = Signaler();
    signaler.signals.listen((signal) {
      controller.sink.add(switch (signal.status) {
        'capture' => FingerprintEvent.capture(signal.body['remaining']),
        'capture-error' => FingerprintEvent.error(signal.body['code']),
        final other => throw UnimplementedError(other),
      });
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
        ref.invalidate(fidoStateProvider(_session.devicePath));
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
    ref.invalidate(fidoStateProvider(_session.devicePath));
    return renamed;
  }
}

final desktopCredentialProvider = AsyncNotifierProvider.autoDispose
    .family<FidoCredentialsNotifier, List<FidoCredential>, DevicePath>(
        _DesktopFidoCredentialsNotifier.new);

class _DesktopFidoCredentialsNotifier extends FidoCredentialsNotifier {
  late RpcNodeSession _session;

  @override
  FutureOr<List<FidoCredential>> build(DevicePath devicePath) async {
    _session = ref.watch(_sessionProvider(devicePath));
    ref.watch(fidoStateProvider(devicePath));

    // Refresh on active
    ref.listen<WindowState>(
      windowStateProvider,
      (prev, next) async {
        if (prev?.active == false && next.active) {
          // Refresh state on active
          final newState = await _build(devicePath);
          if (state.valueOrNull != newState) {
            state = AsyncValue.data(newState);
          }
        }
      },
    );

    return _build(devicePath);
  }

  FutureOr<List<FidoCredential>> _build(DevicePath devicePath) async {
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
    return List.unmodifiable(creds);
  }

  @override
  Future<void> deleteCredential(FidoCredential credential) async {
    await _session.command('delete', target: [
      'credentials',
      credential.rpId,
      credential.credentialId,
    ]);
    ref.invalidate(fidoStateProvider(_session.devicePath));
  }
}
