import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../app/models.dart';
import '../../fido/models.dart';
import '../../fido/state.dart';
import '../models.dart';
import '../rpc.dart';
import '../state.dart';

final _log = Logger('desktop.fido.state');

final _sessionProvider =
    Provider.autoDispose.family<RpcNodeSession, DevicePath>(
  (ref, devicePath) =>
      RpcNodeSession(ref.watch(rpcProvider), devicePath, ['fido', 'ctap2']),
);

final desktopFidoState = StateNotifierProvider.autoDispose
    .family<FidoStateNotifier, ApplicationStateResult<FidoState>, DevicePath>(
  (ref, devicePath) {
    final session = ref.watch(_sessionProvider(devicePath));
    final notifier = _DesktopFidoStateNotifier(session);
    session.setErrorHandler('state-reset', (_) async {
      ref.refresh(_sessionProvider(devicePath));
    });
    ref.onDispose(() {
      session.unsetErrorHandler('state-reset');
    });
    return notifier..refresh();
  },
);

class _DesktopFidoStateNotifier extends FidoStateNotifier {
  final RpcNodeSession _session;
  _DesktopFidoStateNotifier(this._session) : super();

  Future<void> refresh() async {
    try {
      var result = await _session.command('get');
      _log.config('application status', jsonEncode(result));
      var fidoState = FidoState.fromJson(result['data']);
      setState(fidoState);
    } catch (error) {
      _log.severe('Unable to update FIDO state', jsonEncode(error));
      setFailure('Failed to update FIDO');
    }
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
        await refresh();
        await controller.sink.close();
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
      await refresh();
      return PinResult.success();
    } on RpcError catch (e) {
      if (e.status == 'pin-validation') {
        return PinResult.failed(e.body['retries'], e.body['auth_blocked']);
      }
      rethrow;
    }
    // TODO: Update state
  }

  @override
  Future<PinResult> unlock(String pin) async {
    try {
      await _session.command('verify_pin', params: {'pin': pin});
      setState(requireState().copyWith(locked: false));
      return PinResult.success();
    } on RpcError catch (e) {
      if (e.status == 'pin-validation') {
        return PinResult.failed(e.body['retries'], e.body['auth_blocked']);
      }
      rethrow;
    }
  }
}

final desktopFingerprintProvider = StateNotifierProvider.autoDispose
    .family<FidoFingerprintsNotifier, List<Fingerprint>?, DevicePath>(
        (ref, devicePath) {
  return _DesktopFidoFingerprintsNotifier(
    ref.watch(_sessionProvider(devicePath)),
    ref
        .watch(desktopFidoState(devicePath))
        .whenOrNull(success: (state) => state),
  )..refresh();
});

class _DesktopFidoFingerprintsNotifier extends FidoFingerprintsNotifier {
  final RpcNodeSession _session;
  final FidoState? fidoState;

  _DesktopFidoFingerprintsNotifier(this._session, this.fidoState);

  Future<void> refresh() async {
    if (fidoState?.locked != false) {
      state = null;
    }

    final result = await _session.command('fingerprints');
    if (mounted) {
      state = (result['children'] as Map<String, dynamic>)
          .entries
          .map((e) => Fingerprint(e.key, e.value['name']))
          .toList();
    }
  }

  @override
  Future<void> deleteFingerprint(Fingerprint fingerprint) async {
    await _session
        .command('delete', target: ['fingerprints', fingerprint.templateId]);
    await refresh();
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
        await refresh();
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
    await refresh();
    return renamed;
  }
}
