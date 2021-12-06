import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'rpc.dart';

// This must be initialized before use, in main.dart.
final prefProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

// This must be initialized before use, in main.dart.
final rpcProvider = Provider<RpcSession>((ref) {
  throw UnimplementedError();
});

final rpcStateProvider = StateNotifierProvider<RpcStateNotifier, RpcState>(
    (ref) => RpcStateNotifier(ref.watch(rpcProvider)));

class RpcStateNotifier extends StateNotifier<RpcState> {
  final RpcSession rpc;
  RpcStateNotifier(this.rpc) : super(const RpcState('unknown')) {
    _init();
  }

  _init() async {
    final response = await rpc.command('get', []);
    if (mounted) {
      state = state.copyWith(version: response['data']['version']);
    }
  }
}

final logLevelProvider = StateNotifierProvider<LogLevelNotifier, Level>(
    (ref) => LogLevelNotifier(ref.watch(rpcProvider), Logger.root.level));

class LogLevelNotifier extends StateNotifier<Level> {
  final RpcSession rpc;
  LogLevelNotifier(this.rpc, Level state) : super(state);

  setLevel(Level level) {
    Logger.root.level = level;
    rpc.setLogLevel(level);
    state = level;
  }
}

typedef ErrorHandler = Future<void> Function(RpcError e);

class RpcNodeSession {
  final RpcSession _rpc;
  final List<String> devicePath;
  final List<String> subPath;
  final Map<String, ErrorHandler> _errorHandlers = {};

  RpcNodeSession(this._rpc, this.devicePath, this.subPath);

  void setErrorHandler(String status, ErrorHandler handler) {
    _errorHandlers[status] = handler;
  }

  void unserErrorHandler(String status) {
    _errorHandlers.remove(status);
  }

  Future<Map<String, dynamic>> command(
    String action, {
    List<String> target = const [],
    Map<dynamic, dynamic>? params,
    Signaler? signal,
  }) async {
    try {
      return await _rpc.command(
        action,
        devicePath + subPath + target,
        params: params,
        signal: signal,
      );
    } on RpcError catch (e) {
      final handler = _errorHandlers[e.status];
      if (handler != null) {
        log.info('Attempting recovery on "${e.status}"');
        await handler(e);
        return command(action, target: target, params: params, signal: signal);
      }
      rethrow;
    }
  }
}
