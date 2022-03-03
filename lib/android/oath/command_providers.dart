import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../oath/models.dart';

final oathStateCommandProvider =
    StateNotifierProvider<OathStateCommandProvider, OathState?>((ref) {
  return OathStateCommandProvider(null);
});

class OathStateCommandProvider extends StateNotifier<OathState?> {
  OathStateCommandProvider(OathState? oathState) : super(oathState);

  void set(String input) {
    var resultJson = jsonDecode(input);
    state = OathState(resultJson['deviceId'],
        hasKey: resultJson['hasKey'],
        remembered: resultJson['remembered'],
        locked: resultJson['locked'],
        keystore: KeystoreState.unknown);
  }
}

final oathPairsCommandProvider =
    StateNotifierProvider<OathCredentialsCommandProvider, List<OathPair>>(
        (ref) {
  return OathCredentialsCommandProvider([]);
});

class OathCredentialsCommandProvider extends StateNotifier<List<OathPair>> {
  OathCredentialsCommandProvider(List<OathPair> credentials)
      : super(credentials);

  void set(String input) {
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
