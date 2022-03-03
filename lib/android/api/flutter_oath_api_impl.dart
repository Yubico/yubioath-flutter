import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../oath/command_providers.dart';
import 'impl.dart';

final _log = Logger('android.FOathApiImpl');

class FOathApiImpl extends FOathApi {
  final StateNotifierProviderRef _ref;

  FOathApiImpl(this._ref) : super();

  @override
  Future<void> updateOathCredentials(String credentialListJson) async {
    _log.info('Received: $credentialListJson');
    _ref.read(androidCredentialsProvider.notifier).set(credentialListJson);
  }

  @override
  Future<void> updateSession(String sessionJson) async {
    _log.info('Received: $sessionJson');
    _ref.read(androidStateProvider.notifier).set(sessionJson);
  }
}
