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

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:logging/logging.dart';

import '../../app/logging.dart';
import '../../app/models.dart';
import '../../app/state.dart';
import '../../core/models.dart';
import '../../fido/models.dart';
import '../../fido/state.dart';
import '../credential_cache.dart';
import '../models.dart';
import '../rpc.dart';
import '../state.dart';

final _log = Logger('desktop.fido.state');

final _pinProvider =
    StateNotifierProvider.family<CachedCredential, String?, DevicePath>((
      ref,
      _,
    ) {
      // Clear PIN if current device is changed
      ref.watch(currentDeviceProvider);
      return CachedCredential();
    });

void clearCachedFidoPins(Ref ref) => ref.invalidate(_pinProvider);

class _FidoRpcNodeSession extends RpcNodeSession {
  _FidoRpcNodeSession(super.rpc, super.devicePath, super.subpath);

  List<String> _subpath = [];

  Future<void> closeTransport() async {
    final path = await subpath();
    try {
      await super.command('close', params: {'child': path.first});
    } on RpcError catch (e) {
      if (e.status != 'invalid-command' ||
          e.message != 'No such node: ${devicePath.segments.last}') {
        rethrow;
      }
    }
  }

  Future<List<String>> subpath() async {
    // Ensure that the subpath is initialized
    if (_subpath.isNotEmpty) {
      return _subpath;
    }
    await super.command('get');

    for (final iface in [UsbInterface.fido, UsbInterface.ccid]) {
      final path = [iface.name, 'ctap2'];
      try {
        await super.command('get', target: path);
        _subpath = path;
        _log.debug('Using transport $iface for CTAP');
        return _subpath;
      } on RpcError catch (e) {
        _log.debug('Failed connecting to CTAP via $iface');
        if (e.status == 'fido-blocked-error') {
          rethrow;
        }
      }
    }
    throw 'Failed connecting to CTAP via all interfaces';
  }

  @override
  Future<Map<String, dynamic>> command(
    String action, {
    List<String> target = const [],
    Map? params,
    Signaler? signal,
  }) async {
    return super.command(
      action,
      target: await subpath() + target,
      params: params,
      signal: signal,
    );
  }
}

final _sessionProvider = Provider.autoDispose
    .family<_FidoRpcNodeSession, DevicePath>((ref, devicePath) {
      // Refresh state when PIN is changed
      ref.watch(_pinProvider(devicePath));
      return _FidoRpcNodeSession(
        ref.watch(rpcProvider).requireValue,
        devicePath,
        [],
      );
    });

class DesktopFidoStateNotifier extends FidoStateNotifier {
  late _FidoRpcNodeSession _session;
  late CachedCredential _pinController;

  DesktopFidoStateNotifier(super.devicePath);

  FutureOr<FidoState> _build(DevicePath devicePath) async {
    var result = await _session.command('get');
    FidoState fidoState = FidoState.fromJson(result['data']);
    if (fidoState.hasPin && !fidoState.unlocked) {
      final pin = ref.read(_pinProvider(devicePath).notifier).value;
      if (pin != null) {
        await _unlock(pin, refresh: false);
        result = await _session.command('get');
        fidoState = FidoState.fromJson(result['data']);
      }
    }

    _log.debug('application status', jsonEncode(fidoState));
    return fidoState;
  }

  @override
  FutureOr<FidoState> build() async {
    _session = ref.watch(_sessionProvider(devicePath));

    ref.listen<WindowState>(windowStateProvider, (prev, next) async {
      if (prev?.active == false && next.active) {
        // Refresh state on active
        final newState = await _build(devicePath);
        if (state.value != newState) {
          state = AsyncValue.data(newState);
        }
      }
    });

    _pinController = ref.watch(_pinProvider(devicePath).notifier);
    _session.setErrorHandler('state-reset', (_) async {
      ref.invalidate(_sessionProvider(devicePath));
    });
    _session.setErrorHandler('auth-required', (e) async {
      final pin = ref.read(_pinProvider(devicePath).notifier).value;
      if (pin != null) {
        await _unlock(pin, refresh: false);
      } else {
        throw e;
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
    final session = _session;
    final resetRef = ref;
    final keepAlive = resetRef.keepAlive();
    final controller = StreamController<InteractionEvent>();
    final signaler = Signaler();
    var running = true;
    var cancelled = false;
    final signals = signaler.signals
        .where((s) => s.status == 'reset')
        .map(
          (signal) => InteractionEvent.values.firstWhere(
            (e) => e.name == signal.body['state'],
          ),
        )
        .listen((event) {
          if (!cancelled && !controller.isClosed) controller.add(event);
        });

    controller.onCancel = () {
      if (running) {
        cancelled = true;
        signaler.cancel();
      }
    };
    controller.onListen = () async {
      try {
        await session.command('reset', signal: signaler);
      } catch (e, stack) {
        try {
          await session.closeTransport();
        } catch (cleanupError, cleanupStack) {
          _log.error(
            'Failed closing FIDO transport after reset',
            cleanupError,
            cleanupStack,
          );
        }
        if (!cancelled && !controller.isClosed && controller.hasListener) {
          controller.addError(e, stack);
        } else if (e is! RpcError || e.status != 'cancelled') {
          _log.error('FIDO reset failed after cancellation', e);
        }
      } finally {
        running = false;
        await signals.cancel();
        if (resetRef.mounted) resetRef.invalidate(_sessionProvider(devicePath));
        if (!controller.isClosed) unawaited(controller.close());
        keepAlive.close();
      }
    };

    return controller.stream;
  }

  @override
  Future<PinResult> setPin(String newPin, {String? oldPin}) async {
    try {
      await _session.command(
        'set_pin',
        params: {'pin': oldPin, 'new_pin': newPin},
      );
      final result = await _unlock(newPin, refresh: false);
      ref.invalidateSelf();
      return result;
    } on RpcError catch (e) {
      if (e.status == 'pin-validation') {
        _pinController.value = null;
        ref.invalidateSelf();
        return PinResult.failed(
          FidoPinFailureReason.invalidPin(
            e.body['retries'],
            e.body['auth_blocked'],
          ),
        );
      }
      if (e.status == 'pin-complexity') {
        return PinResult.failed(const FidoPinFailureReason.weakPin());
      }
      rethrow;
    }
  }

  @override
  Future<PinResult> unlock(String pin, {bool remember = false}) =>
      _unlock(pin, remember: remember, refresh: true);

  Future<PinResult> _unlock(
    String pin, {
    bool remember = false,
    required bool refresh,
  }) async {
    try {
      await _session.command(
        'unlock',
        params: {'pin': pin, 'remember': remember},
      );
      _pinController.value = pin;
      if (refresh) ref.invalidateSelf();

      return PinResult.success();
    } on RpcError catch (e) {
      if (e.status == 'pin-validation') {
        _pinController.value = null;
        ref.invalidateSelf();
        return PinResult.failed(
          FidoPinFailureReason.invalidPin(
            e.body['retries'],
            e.body['auth_blocked'],
          ),
        );
      }
      rethrow;
    }
  }

  @override
  Future<void> enableEnterpriseAttestation() async {
    await _session.command('enable_ep_attestation');
    ref.invalidateSelf();
  }
}

class DesktopFidoFingerprintsNotifier extends FidoFingerprintsNotifier {
  late _FidoRpcNodeSession _session;

  DesktopFidoFingerprintsNotifier(super.devicePath);

  @override
  FutureOr<List<Fingerprint>> build() async {
    _session = ref.watch(_sessionProvider(devicePath));
    ref.watch(fidoStateProvider(devicePath));

    // Refresh on active
    ref.listen<WindowState>(windowStateProvider, (prev, next) async {
      if (prev?.active == false && next.active) {
        // Refresh state on active
        final newState = await _build(devicePath);
        if (state.value != newState) {
          state = AsyncValue.data(newState);
        }
      }
    });

    return _build(devicePath);
  }

  FutureOr<List<Fingerprint>> _build(DevicePath devicePath) async {
    final result = await _session.command('fingerprints');
    return List.unmodifiable(
      (result['children'] as Map<String, dynamic>).entries
          .map((e) => Fingerprint(e.key, e.value['name']))
          .toList(),
    );
  }

  @override
  Future<void> deleteFingerprint(Fingerprint fingerprint) async {
    await _session.command(
      'delete',
      target: ['fingerprints', fingerprint.templateId],
    );
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
        controller.sink.add(
          FingerprintEvent.complete(Fingerprint.fromJson(result)),
        );
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
    Fingerprint fingerprint,
    String name,
  ) async {
    await _session.command(
      'rename',
      target: ['fingerprints', fingerprint.templateId],
      params: {'name': name},
    );
    final renamed = fingerprint.copyWith(name: name);
    ref.invalidate(fidoStateProvider(_session.devicePath));
    return renamed;
  }
}

class DesktopFidoCredentialsNotifier extends FidoCredentialsNotifier {
  late _FidoRpcNodeSession _session;

  DesktopFidoCredentialsNotifier(super.devicePath);

  @override
  FutureOr<List<FidoCredential>> build() async {
    _session = ref.watch(_sessionProvider(devicePath));
    ref.watch(fidoStateProvider(devicePath));

    // Refresh on active
    ref.listen<WindowState>(windowStateProvider, (prev, next) async {
      if (prev?.active == false && next.active) {
        // Refresh state on active
        final newState = await _build(devicePath);
        if (state.value != newState) {
          state = AsyncValue.data(newState);
        }
      }
    });

    return _build(devicePath);
  }

  FutureOr<List<FidoCredential>> _build(DevicePath devicePath) async {
    final List<FidoCredential> creds = [];
    final rps = await _session.command('credentials');
    for (final rpId in (rps['children'] as Map<String, dynamic>).keys) {
      final result = await _session.command(rpId, target: ['credentials']);
      for (final e in (result['children'] as Map<String, dynamic>).entries) {
        creds.add(
          FidoCredential(
            rpId: rpId,
            credentialId: e.key,
            userId: e.value['user_id'],
            userName: e.value['user_name'],
            displayName: e.value['display_name'],
          ),
        );
      }
    }
    return List.unmodifiable(creds);
  }

  @override
  Future<void> deleteCredential(FidoCredential credential) async {
    await _session.command(
      'delete',
      target: ['credentials', credential.rpId, credential.credentialId],
    );
    await _session.command('close', params: {'child': 'credentials'});
    ref.invalidate(fidoStateProvider(_session.devicePath));
    ref.invalidateSelf();
  }
}
