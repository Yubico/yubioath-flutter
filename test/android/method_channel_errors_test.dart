import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yubico_authenticator/android/method_channel_errors.dart';
import 'package:yubico_authenticator/exception/app_exception.dart';

void main() {
  test('uses the code as status and the details as body', () {
    final e = PlatformException(
      code: 'connection-error',
      message: 'NFC communication issue',
      details: {'connection': 'nfc'},
    ).toAppException();

    expect(e, isA<ConnectionException>());
    expect((e as ConnectionException).connection, 'nfc');
    expect(e.message, 'NFC communication issue');
  });

  test('ignores details that are not a map', () {
    final e = PlatformException(
      code: 'auth-required',
      message: 'Authentication is required',
      details: 'Cause: null',
    ).toAppException();

    expect(e, isA<AuthRequiredException>());
  });

  test('legacy class-name codes are not mistaken for known statuses', () {
    final e = PlatformException(
      code: 'ApduException',
      message: 'APDU error: 0x6982',
    ).toAppException();

    expect(e, isA<UnknownException>());
  });
}
