/*
 * Copyright (C) 2022 Yubico.
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

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/models.dart';
import '../core/state.dart';
import 'models.dart';

final fidoStateProvider = AsyncNotifierProvider.autoDispose
    .family<FidoStateNotifier, FidoState, DevicePath>(
  () => throw UnimplementedError(),
);

abstract class FidoStateNotifier extends ApplicationStateNotifier<FidoState> {
  Stream<InteractionEvent> reset();
  Future<PinResult> setPin(String newPin, {String? oldPin});
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
