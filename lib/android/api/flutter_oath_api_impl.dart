import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../oath/command_providers.dart';
import 'impl.dart';

class FOathApiImpl extends FOathApi {
  final StateNotifierProviderRef _ref;

  FOathApiImpl(this._ref) : super();

  @override
  Future<void> updateOathCredentials(String credentialListJson) async {
    _ref
        .read(androidCredentialsProvider.notifier)
        .setFromString(credentialListJson);
  }

  @override
  Future<void> updateSession(String sessionJson) async {
    _ref.read(androidStateProvider.notifier).setFromString(sessionJson);
  }
}
