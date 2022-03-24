import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/models.dart';
import '../core/state.dart';
import 'models.dart';

final fidoStateProvider = StateNotifierProvider.autoDispose
    .family<FidoStateNotifier, AsyncValue<FidoState>, DevicePath>(
  (ref, devicePath) => throw UnimplementedError(),
);

abstract class FidoStateNotifier extends ApplicationStateNotifier<FidoState> {
  Stream<InteractionEvent> reset();
  Future<PinResult> setPin(String newPin, {String? oldPin});
}

final fidoPinProvider =
    StateNotifierProvider.autoDispose.family<PinNotifier, bool, DevicePath>(
  (ref, devicePath) => throw UnimplementedError(),
);

abstract class PinNotifier extends StateNotifier<bool> {
  PinNotifier(bool unlocked) : super(unlocked);
  Future<PinResult> unlock(String pin);
}

abstract class LockedCollectionNotifier<T>
    extends StateNotifier<AsyncValue<List<T>>> {
  LockedCollectionNotifier() : super(const AsyncValue.loading());

  @protected
  void setItems(List<T> items) {
    if (mounted) {
      state = AsyncValue.data(List.unmodifiable(items));
    }
  }
}

final fingerprintProvider = StateNotifierProvider.autoDispose.family<
    FidoFingerprintsNotifier, AsyncValue<List<Fingerprint>>, DevicePath>(
  (ref, arg) => throw UnimplementedError(),
);

abstract class FidoFingerprintsNotifier
    extends LockedCollectionNotifier<Fingerprint> {
  Stream<FingerprintEvent> registerFingerprint({String? name});
  Future<Fingerprint> renameFingerprint(Fingerprint fingerprint, String name);
  Future<void> deleteFingerprint(Fingerprint fingerprint);
}

final credentialProvider = StateNotifierProvider.autoDispose.family<
    FidoCredentialsNotifier, AsyncValue<List<FidoCredential>>, DevicePath>(
  (ref, arg) => throw UnimplementedError(),
);

abstract class FidoCredentialsNotifier
    extends LockedCollectionNotifier<FidoCredential> {
  Future<void> deleteCredential(FidoCredential credential);
}
