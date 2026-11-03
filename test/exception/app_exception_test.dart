import 'package:flutter_test/flutter_test.dart';
import 'package:yubico_authenticator/exception/app_exception.dart';

/// Pins how the statuses in doc/Error_Contract.adoc are decoded. The Android
/// half of the contract is covered by `OathChannelErrorMapperTest.kt`.
void main() {
  group('AppException.fromWire', () {
    final expected = <String, Type>{
      'cancelled': CancellationException,
      'auth-required': AuthRequiredException,
      'password-required': PasswordRequiredException,
      'not-supported': NotSupportedException,
      'already-exists': AlreadyExistsException,
      'connection-error': ConnectionException,
      'invalid-image': InvalidImageException,
      'device-error': DeviceException,
      'pin-validation': InvalidPinException,
      'invalid-pin': InvalidPinException,
      'pin-complexity': PinComplexityException,
      'user-action-timeout': UserActionTimeoutException,
      'not-allowed': NotAllowedException,
      'key-mismatch': KeyMismatchException,
      'reinsert-required': ReinsertRequiredException,
      'fido-blocked-error': FidoBlockedException,
    };

    for (final MapEntry(key: status, value: type) in expected.entries) {
      test('decodes $status', () {
        final e = AppException.fromWire(status, 'message');
        expect(e.runtimeType, type);
        expect(e.message, 'message');
      });
    }

    test('keeps the failed connection', () {
      final e = AppException.fromWire('connection-error', 'failed', {
        'connection': 'ccid',
      });
      expect(e, isA<ConnectionException>());
      expect((e as ConnectionException).connection, 'ccid');
    });

    test('keeps the status word', () {
      final e = AppException.fromWire('device-error', 'failed', {'sw': 0x6a82});
      expect((e as DeviceException).sw, 0x6a82);
    });

    test('keeps the CTAP error', () {
      final e = AppException.fromWire('device-error', 'failed', {'ctap': 0x31});
      expect((e as DeviceException).ctapError, 0x31);
    });

    test('keeps PIN retries and whether auth is blocked', () {
      final e = AppException.fromWire('pin-validation', 'wrong PIN', {
        'retries': 5,
        'auth_blocked': true,
      });
      expect((e as InvalidPinException).retries, 5);
      expect(e.authBlocked, isTrue);
    });

    test('keeps the PIV attempts remaining', () {
      final e = AppException.fromWire('invalid-pin', 'Wrong PIN', {
        'attempts_remaining': 2,
      });
      expect((e as InvalidPinException).retries, 2);
      expect(e.authBlocked, isFalse);
    });

    test('auth is not blocked unless reported', () {
      final e = AppException.fromWire('pin-validation', 'wrong PIN', {
        'retries': 7,
      });
      expect((e as InvalidPinException).authBlocked, isFalse);
    });

    test('unknown statuses keep the status for diagnostics', () {
      final e = AppException.fromWire('something-new', 'details');
      expect(e, isA<UnknownException>());
      expect((e as UnknownException).status, 'something-new');
      expect(e.message, 'details');
    });

    test('falls back to the status when there is no message', () {
      expect(AppException.fromWire('exception', null).message, 'exception');
    });
  });
}
