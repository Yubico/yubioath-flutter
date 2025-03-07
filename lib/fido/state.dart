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

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/models.dart';
import '../core/state.dart';
import '../widgets/flex_box.dart';
import 'models.dart';

final passkeysSearchProvider =
    StateNotifierProvider<PasskeysSearchNotifier, String>(
        (ref) => PasskeysSearchNotifier());

class PasskeysSearchNotifier extends StateNotifier<String> {
  PasskeysSearchNotifier() : super('');

  void setFilter(String value) {
    state = value;
  }
}

final passkeysLayoutProvider =
    StateNotifierProvider<LayoutNotifier, FlexLayout>(
  (ref) => LayoutNotifier('FIDO_PASSKEYS_LAYOUT', ref.watch(prefProvider)),
);

final fidoStateProvider = AsyncNotifierProvider.autoDispose
    .family<FidoStateNotifier, FidoState, DevicePath>(
  () => throw UnimplementedError(),
);

abstract class FidoStateNotifier extends ApplicationStateNotifier<FidoState> {
  Stream<InteractionEvent> reset();
  Future<PinResult> setPin(String newPin, {String? oldPin});
  Future<PinResult> unlock(String pin);
  Future<void> enableEnterpriseAttestation();
}

final fingerprintProvider = AsyncNotifierProvider.autoDispose
    .family<FidoFingerprintsNotifier, List<Fingerprint>, DevicePath>(
  () => throw UnimplementedError(),
);

abstract class FidoFingerprintsNotifier
    extends AutoDisposeFamilyAsyncNotifier<List<Fingerprint>, DevicePath> {
  Stream<FingerprintEvent> registerFingerprint({String? name});
  Future<Fingerprint> renameFingerprint(Fingerprint fingerprint, String name);
  Future<void> deleteFingerprint(Fingerprint fingerprint);
}

final credentialProvider = AsyncNotifierProvider.autoDispose
    .family<FidoCredentialsNotifier, List<FidoCredential>, DevicePath>(
  () => throw UnimplementedError(),
);

abstract class FidoCredentialsNotifier
    extends AutoDisposeFamilyAsyncNotifier<List<FidoCredential>, DevicePath> {
  Future<void> deleteCredential(FidoCredential credential);
}

final filteredFidoCredentialsProvider = StateNotifierProvider.autoDispose
    .family<FilteredFidoCredentialsNotifier, List<FidoCredential>,
        List<FidoCredential>>(
  (ref, full) {
    return FilteredFidoCredentialsNotifier(
        full, ref.watch(passkeysSearchProvider));
  },
);

class FilteredFidoCredentialsNotifier
    extends StateNotifier<List<FidoCredential>> {
  final String query;
  FilteredFidoCredentialsNotifier(List<FidoCredential> full, this.query)
      : super(full
            .where((credential) =>
                credential.rpId.toLowerCase().contains(query.toLowerCase()) ||
                credential.userName.toLowerCase().contains(query.toLowerCase()))
            .toList());
}
