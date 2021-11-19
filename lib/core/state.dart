import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models.dart';
import 'rpc.dart';

// This must be initialized before use, in main.dart.
final rpcProvider = Provider<RpcSession>((ref) {
  throw UnimplementedError();
});

class RpcNodeSession {
  final RpcSession _rpc;
  final List<String> devicePath;
  final List<String> subPath;
  final Function _reset;

  RpcNodeSession(this._rpc, this.devicePath, this.subPath, this._reset);

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
      if (e.status == "state-reset") {
        _reset();
      }
      rethrow;
    }
  }
}
