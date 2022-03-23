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
  Future<PinResult> setPin(String newPin, {String? oldPin});
}

abstract class LockedCollectionNotifier<T>
    extends StateNotifier<LockedCollection<T>> {
  LockedCollectionNotifier() : super(LockedCollection.unknown());
  Future<PinResult> unlock(String pin);

  @protected
  void setItems(List<T> items) {
    if (mounted) {
      state = LockedCollection.opened(List.unmodifiable(items));
    }
  }
}

final fingerprintProvider = StateNotifierProvider.autoDispose.family<
    FidoFingerprintsNotifier, LockedCollection<Fingerprint>, DevicePath>(
  (ref, arg) => throw UnimplementedError(),
);

abstract class FidoFingerprintsNotifier
    extends LockedCollectionNotifier<Fingerprint> {
  Stream<FingerprintEvent> registerFingerprint({String? name});
  Future<Fingerprint> renameFingerprint(Fingerprint fingerprint, String name);
  Future<void> deleteFingerprint(Fingerprint fingerprint);
}

final credentialProvider = StateNotifierProvider.autoDispose.family<
    FidoCredentialsNotifier, LockedCollection<FidoCredential>, DevicePath>(
  (ref, arg) => throw UnimplementedError(),
);

abstract class FidoCredentialsNotifier
    extends LockedCollectionNotifier<FidoCredential> {
  Future<FidoCredential> renameCredential(
      FidoCredential credential, String label);
  Future<void> deleteCredential(FidoCredential credential);
}
