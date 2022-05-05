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
    state = OathState.fromJson(resultJson);
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

    /// structure of data in the json object is:
    /// [credential1, code1, credential2, code2, ...]

    final List<OathPair> pairs = [];
    if (result is List<dynamic>) {
      for (var index = 0; index < result.length / 2; index++) {
        final credential = result[index * 2];
        final code = result[index * 2 + 1];
        pairs.add(
          OathPair(
            OathCredential.fromJson(credential),
            code == null ? null : OathCode.fromJson(code),
          ),
        );
      }
    }

    state = pairs;
  }
}
