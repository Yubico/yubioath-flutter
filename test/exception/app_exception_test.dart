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
