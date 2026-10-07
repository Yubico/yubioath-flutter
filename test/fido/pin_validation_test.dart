import 'package:flutter_test/flutter_test.dart';
import 'package:yubico_authenticator/fido/validation.dart';

void main() {
  test('validates existing PINs independently of new-PIN policy', () {
    for (final pin in ['', '1', '123', '1' * 64]) {
      expect(isValidFidoPinLength(pin), isFalse);
    }
    for (final pin in ['1234', '123456', '1' * 63]) {
      expect(isValidFidoPinLength(pin), isTrue);
    }
  });

  test('measures PIN length in UTF-8 bytes', () {
    expect(isValidFidoPinLength('\u00e9'), isFalse);
    expect(isValidFidoPinLength('\u00e9\u00e9'), isTrue);
    expect(isValidFidoPinLength('\u00e9' * 31), isTrue);
    expect(isValidFidoPinLength('\u00e9' * 32), isFalse);
  });
}
