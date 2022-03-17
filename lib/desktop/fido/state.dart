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
    final signaler = Signaler();
    final controller = StreamController<InteractionEvent>();

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
    controller.sink.addStream(signaler.signals
        .where((s) => s.status == 'reset')
        .map((signal) => InteractionEvent.values
            .firstWhere((e) => e.name == signal.body['state'])));

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
  Future<PinResult> unlock(String pin) {
    // TODO: implement unlock
    throw UnimplementedError();
  }
}
