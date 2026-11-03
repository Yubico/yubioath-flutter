import 'package:flutter_test/flutter_test.dart';
import 'package:yubico_authenticator/app/models.dart';
import 'package:yubico_authenticator/desktop/models.dart';
import 'package:yubico_authenticator/desktop/rpc.dart';
import 'package:yubico_authenticator/exception/app_exception.dart';

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

class _FailingRpc extends RpcSession {
  final RpcError error;

  _FailingRpc(this.error) : super('unused');

  @override
  Future<Map<String, dynamic>> command(
    String action,
    List<String>? target, {
    Map? params,
    Signaler? signal,
  }) async => throw error;
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

  group('throwAppExceptions', () {
    final path = DevicePath(['devices', '38997600']);
    final error = RpcResponse.error('connection-error', 'Error connecting', {
      'connection': 'ccid',
    }) as RpcError;

    test('is off by default and rethrows the RpcError', () async {
      final session = RpcNodeSession(_FailingRpc(error), path, []);
      await expectLater(session.command('get'), throwsA(same(error)));
    });

    test('throws the matching AppException when on', () async {
      final session = RpcNodeSession(
        _FailingRpc(error),
        path,
        [],
        throwAppExceptions: true,
      );
      await expectLater(
        session.command('get'),
        throwsA(
          isA<ConnectionException>().having(
            (e) => e.connection,
            'connection',
            'ccid',
          ),
        ),
      );
    });

    test('error handlers still see the RpcError', () async {
      final authRequired = RpcResponse.error(
        'auth-required',
        'Authentication required',
        {},
      ) as RpcError;
      final session = RpcNodeSession(
        _FailingRpc(authRequired),
        path,
        [],
        throwAppExceptions: true,
      );
      RpcError? seen;
      session.setErrorHandler('auth-required', (e) async {
        seen = e;
        throw e;
      });

      await expectLater(
        session.command('get'),
        throwsA(isA<AuthRequiredException>()),
      );
      expect(seen, same(authRequired));
    });
  });
}
