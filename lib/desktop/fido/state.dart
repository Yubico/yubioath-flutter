import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../app/models.dart';
import '../../core/models.dart';
import '../../fido/models.dart';
import '../../fido/state.dart';
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
  Future<void> reset() {
    // TODO: implement reset
    throw UnimplementedError();
  }

  @override
  Future<void> setPin(String newPin, {String? oldPin}) {
    // TODO: implement setPin
    throw UnimplementedError();
  }

  @override
  Future<void> unlock(String pin) {
    // TODO: implement unlock
    throw UnimplementedError();
  }
}
