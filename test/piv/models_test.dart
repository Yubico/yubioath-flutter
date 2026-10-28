import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:yubico_authenticator/piv/models.dart';

void main() {
  for (final storedKey in [false, true]) {
    test('PIV state round-trips with stored_key=$storedKey', () {
      final json = <String, dynamic>{
        'version': [5, 7, 0],
        'authenticated': false,
        'stored_key': storedKey,
        'pin_attempts': 3,
        'supports_bio': false,
        'chuid': null,
        'ccc': null,
        'metadata': null,
      };

      final state = PivState.fromJson(json);

      expect(state.storedKey, storedKey);
      expect(jsonDecode(jsonEncode(state)), json);
      expect(state.copyWith(storedKey: !storedKey).storedKey, !storedKey);
    });
  }
}
