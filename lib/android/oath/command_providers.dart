import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../oath/models.dart';

final androidStateProvider =
    StateNotifierProvider<_StateProvider, OathState?>((ref) {
  return _StateProvider(null);
});

class _StateProvider extends StateNotifier<OathState?> {
  _StateProvider(OathState? oathState) : super(oathState);

  void setFromString(String input) {
    var resultJson = jsonDecode(input);
    state = OathState(resultJson['deviceId'],
        hasKey: resultJson['hasKey'],
        remembered: resultJson['remembered'],
        locked: resultJson['locked'],
        keystore: KeystoreState.unknown);
  }
}

final androidCredentialsProvider =
    StateNotifierProvider<_CredentialsProvider, List<OathPair>?>((ref) {
  return _CredentialsProvider(null);
});

class _CredentialsProvider extends StateNotifier<List<OathPair>?> {
  _CredentialsProvider(List<OathPair>? credentials) : super(credentials);

  void setFromString(String input) {
    var result = jsonDecode(input);

    final List<OathPair> pairs = [];
    for (var e in result['entries']) {
      final credential = OathCredential.fromJson(e['credential']);
      final code = e['code'] == null ? null : OathCode.fromJson(e['code']);
      pairs.add(OathPair(credential, code));
    }

    state = pairs;
  }
}
