import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../oath/models.dart';

final androidStateProvider =
    StateNotifierProvider<_StateProvider, OathState?>((ref) {
  return _StateProvider(null);
});

class _StateProvider extends StateNotifier<OathState?> {
  _StateProvider(super.oathState);

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
  _CredentialsProvider(super.credentials);

  void setFromString(String input) {
    var result = jsonDecode(input);

    if (result is List) {
      state = result.map((e) => OathPair.fromJson(e)).toList();
    } else {
      state = [];
    }
  }
}
