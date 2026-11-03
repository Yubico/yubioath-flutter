/*
 * Copyright (C) 2022-2026 Yubico.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *       http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/// Platform-agnostic failures reported by a YubiKey backend.
///
/// Every backend (the desktop helper, the Android and iOS native code)
/// reports errors as `{status, message, body}` using the status names listed
/// in `doc/Error_Contract.adoc`. Each platform layer decodes that once with
/// [AppException.fromWire], so code outside `lib/desktop` and `lib/android`
/// only ever handles these types.
sealed class AppException implements Exception {
  /// Backend-provided text. Useful in logs and as a last-resort message, but
  /// prefer a localized string chosen by exception type for the UI.
  final String message;

  const AppException(this.message);

  factory AppException.fromWire(
    String status,
    String? message, [
    Map<String, dynamic> body = const {},
  ]) {
    final text = message ?? status;
    return switch (status) {
      'cancelled' => CancellationException(text),
      'auth-required' => AuthRequiredException(text),
      'password-required' => PasswordRequiredException(text),
      'not-supported' => NotSupportedException(text),
      'already-exists' => AlreadyExistsException(text),
      'connection-error' => ConnectionException(
        text,
        connection: body['connection'] as String?,
      ),
      'invalid-image' => InvalidImageException(text),
      'pin-validation' => InvalidPinException(
        text,
        retries: body['retries'] as int?,
        authBlocked: body['auth_blocked'] as bool? ?? false,
      ),
      'pin-complexity' => PinComplexityException(text),
      'user-action-timeout' => UserActionTimeoutException(text),
      'not-allowed' => NotAllowedException(text),
      'key-mismatch' => KeyMismatchException(text),
      'reinsert-required' => ReinsertRequiredException(text),
      'fido-blocked-error' => FidoBlockedException(text),
      'device-error' => DeviceException(
        text,
        sw: body['sw'] as int?,
        ctapError: body['ctap'] as int?,
      ),
      _ => UnknownException(status, text),
    };
  }

  @override
  String toString() => '$runtimeType: $message';
}

/// The user cancelled the operation, for example by dismissing the NFC
/// prompt. Callers normally swallow this silently.
final class CancellationException extends AppException {
  const CancellationException([super.message = 'Operation cancelled']);
}

/// The application is locked and must be unlocked first.
final class AuthRequiredException extends AppException {
  const AuthRequiredException(super.message);
}

/// The operation requires a password to be configured first.
final class PasswordRequiredException extends AppException {
  const PasswordRequiredException(super.message);
}

/// The YubiKey does not support, or has disabled, the needed functionality.
final class NotSupportedException extends AppException {
  const NotSupportedException(super.message);
}

/// The item being created already exists on the YubiKey.
final class AlreadyExistsException extends AppException {
  const AlreadyExistsException(super.message);
}

/// Opening or keeping a connection to the YubiKey failed.
final class ConnectionException extends AppException {
  /// The interface that failed, such as `ccid`, `fido`, `otp` or `nfc`.
  final String? connection;

  const ConnectionException(super.message, {this.connection});
}

/// An image passed for QR scanning could not be decoded.
final class InvalidImageException extends AppException {
  const InvalidImageException(super.message);
}

/// A wrong PIN was entered.
final class InvalidPinException extends AppException {
  /// Attempts left before the PIN is blocked, when known.
  final int? retries;

  /// Too many wrong attempts in a row; the YubiKey must be reinserted before
  /// trying again.
  final bool authBlocked;

  const InvalidPinException(
    super.message, {
    this.retries,
    this.authBlocked = false,
  });
}

/// A new PIN does not meet the YubiKey's complexity requirements.
final class PinComplexityException extends AppException {
  const PinComplexityException(super.message);
}

/// The user did not touch the YubiKey, or present a fingerprint, in time.
final class UserActionTimeoutException extends AppException {
  const UserActionTimeoutException(super.message);
}

/// The YubiKey does not allow the operation right now, such as a FIDO reset
/// that was not started soon enough after the YubiKey was powered on.
final class NotAllowedException extends AppException {
  const NotAllowedException(super.message);
}

/// A different YubiKey was inserted than the one the operation started with.
final class KeyMismatchException extends AppException {
  const KeyMismatchException(super.message);
}

/// The YubiKey must be removed and inserted again before retrying.
final class ReinsertRequiredException extends AppException {
  const ReinsertRequiredException(super.message);
}

/// The operating system blocks access to FIDO, as Windows does without
/// administrator privileges.
final class FidoBlockedException extends AppException {
  const FidoBlockedException(super.message);
}

/// The YubiKey rejected a command.
final class DeviceException extends AppException {
  /// ISO 7816 status word, when the backend reports one.
  final int? sw;

  /// CTAP error code, when the backend reports one.
  final int? ctapError;

  const DeviceException(super.message, {this.sw, this.ctapError});
}

/// A status this version of the app does not recognize.
final class UnknownException extends AppException {
  final String status;

  const UnknownException(this.status, super.message);

  @override
  String toString() => 'UnknownException[$status]: $message';
}
