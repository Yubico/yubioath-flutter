/*
 * Copyright (C) 2023 Yubico.
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
import 'models.dart';

final pivStateProvider = AsyncNotifierProvider.autoDispose
    .family<PivStateNotifier, PivState, DevicePath>(
  () => throw UnimplementedError(),
);

abstract class PivStateNotifier extends ApplicationStateNotifier<PivState> {
  Future<void> reset();

  Future<bool> authenticate(String managementKey);
  Future<void> setManagementKey(
    String managementKey, {
    ManagementKeyType managementKeyType = defaultManagementKeyType,
    bool storeKey = false,
  });

  Future<PinVerificationStatus> verifyPin(
      String pin); //TODO: Maybe return authenticated?
  Future<PinVerificationStatus> changePin(String pin, String newPin);
  Future<PinVerificationStatus> changePuk(String puk, String newPuk);
  Future<PinVerificationStatus> unblockPin(String puk, String newPin);
}

final pivSlotsProvider = AsyncNotifierProvider.autoDispose
    .family<PivSlotsNotifier, List<PivSlot>, DevicePath>(
  () => throw UnimplementedError(),
);

abstract class PivSlotsNotifier
    extends AutoDisposeFamilyAsyncNotifier<List<PivSlot>, DevicePath> {
  Future<PivExamineResult> examine(String data, {String? password});
  Future<bool> validateRfc4514(String value);
  Future<(SlotMetadata?, String?)> read(SlotId slot);
  Future<PivGenerateResult> generate(
    SlotId slot,
    KeyType keyType, {
    required PivGenerateParameters parameters,
    PinPolicy pinPolicy = PinPolicy.dfault,
    TouchPolicy touchPolicy = TouchPolicy.dfault,
    String? pin,
  });
  Future<PivImportResult> import(
    SlotId slot,
    String data, {
    String? password,
    PinPolicy pinPolicy = PinPolicy.dfault,
    TouchPolicy touchPolicy = TouchPolicy.dfault,
  });
  Future<void> delete(SlotId slot);
}
