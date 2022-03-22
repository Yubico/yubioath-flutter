import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/models.dart';
import '../core/state.dart';
import 'models.dart';

final fidoStateProvider = StateNotifierProvider.autoDispose
    .family<FidoStateNotifier, ApplicationStateResult<FidoState>, DevicePath>(
  (ref, devicePath) => throw UnimplementedError(),
);

abstract class FidoStateNotifier extends ApplicationStateNotifier<FidoState> {
  Stream<InteractionEvent> reset();
  Future<PinResult> unlock(String pin);
  Future<PinResult> setPin(String newPin, {String? oldPin});
}

final fingerprintProvider = StateNotifierProvider.autoDispose
    .family<FidoFingerprintsNotifier, List<Fingerprint>?, DevicePath>(
  (ref, arg) => throw UnimplementedError(),
);

abstract class FidoFingerprintsNotifier
    extends StateNotifier<List<Fingerprint>?> {
  FidoFingerprintsNotifier() : super(null);

  @override
  @protected
  set state(List<Fingerprint>? value) {
    super.state = value != null ? List.unmodifiable(value) : null;
  }

  Stream<FingerprintEvent> registerFingerprint(String label);
  Future<Fingerprint> renameFingerprint(Fingerprint fingerprint, String label);
  Future<void> deleteFingerprint(Fingerprint fingerprint);
}

final credentialProvider = StateNotifierProvider.autoDispose
    .family<FidoCredentialsNotifier, List<FidoCredential>?, DevicePath>(
  (ref, arg) => throw UnimplementedError(),
);

abstract class FidoCredentialsNotifier
    extends StateNotifier<List<FidoCredential>?> {
  FidoCredentialsNotifier() : super(null);

  @override
  @protected
  set state(List<FidoCredential>? value) {
    super.state = value != null ? List.unmodifiable(value) : null;
  }

  Future<FidoCredential> renameCredential(
      FidoCredential credential, String label);
  Future<void> deleteCredential(FidoCredential credential);
}
