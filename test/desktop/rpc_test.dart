import 'package:flutter_test/flutter_test.dart';
import 'package:yubico_authenticator/app/models.dart';
import 'package:yubico_authenticator/desktop/models.dart';
import 'package:yubico_authenticator/desktop/rpc.dart';

class _RetryRpc extends RpcSession {
  final targets = <List<String>>[];

  _RetryRpc() : super('unused');

  @override
  Future<Map<String, dynamic>> command(
    String action,
    List<String>? target, {
    Map? params,
    Signaler? signal,
  }) async {
    targets.add(List.of(target ?? []));
    if (targets.length == 1) {
      throw RpcResponse.error('auth-required', 'Authentication required', {});
    }
    return {};
  }
}

class _PrefixedNodeSession extends RpcNodeSession {
  _PrefixedNodeSession(RpcSession rpc, DevicePath path) : super(rpc, path, []);

  @override
  Future<Map<String, dynamic>> command(
    String action, {
    List<String> target = const [],
    Map<dynamic, dynamic>? params,
    Signaler? signal,
  }) => super.command(
    action,
    target: ['fido', 'ctap2', ...target],
    params: params,
    signal: signal,
  );
}

void main() {
  test('auth recovery retries without duplicating a prefixed target', () async {
    final rpc = _RetryRpc();
    final session = _PrefixedNodeSession(
      rpc,
      DevicePath(['devices', '38997600']),
    );
    session.setErrorHandler('auth-required', (_) async {});

    await session.command('credentials', target: ['credentials']);

    expect(rpc.targets, [
      ['devices', '38997600', 'fido', 'ctap2', 'credentials'],
      ['devices', '38997600', 'fido', 'ctap2', 'credentials'],
    ]);
  });
}
