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

import 'package:freezed_annotation/freezed_annotation.dart';

part 'models.freezed.dart';
part 'models.g.dart';

enum InteractionEvent { remove, insert, touch }

@freezed
class FidoState with _$FidoState {
  const FidoState._();

  factory FidoState(
      {required Map<String, dynamic> info,
      required bool unlocked}) = _FidoState;

  factory FidoState.fromJson(Map<String, dynamic> json) =>
      _$FidoStateFromJson(json);

  bool get hasPin => info['options']['clientPin'] == true;

  int get minPinLength => info['min_pin_length'] as int;

  bool get credMgmt =>
      info['options']['credMgmt'] == true ||
      info['options']['credentialMgmtPreview'] == true;

  bool? get bioEnroll => info['options']['bioEnroll'];

  bool get alwaysUv => info['options']['alwaysUv'] == true;

  bool get forcePinChange => info['force_pin_change'] == true;
}

@freezed
class PinResult with _$PinResult {
  factory PinResult.success() = _PinSuccess;
  factory PinResult.failed(int retries, bool authBlocked) = _PinFailure;
}

@freezed
class Fingerprint with _$Fingerprint {
  const Fingerprint._();
  factory Fingerprint(String templateId, String? name) = _Fingerprint;

  factory Fingerprint.fromJson(Map<String, dynamic> json) =>
      _$FingerprintFromJson(json);

  String get label => name ?? 'Unnamed (ID: $templateId)';
}

@freezed
class FingerprintEvent with _$FingerprintEvent {
  factory FingerprintEvent.capture(int remaining) = _EventCapture;
  factory FingerprintEvent.complete(Fingerprint fingerprint) = _EventComplete;
  factory FingerprintEvent.error(int code) = _EventError;
}

@freezed
class FidoCredential with _$FidoCredential {
  factory FidoCredential({
    required String rpId,
    required String credentialId,
    required String userId,
    required String userName,
  }) = _FidoCredential;

  factory FidoCredential.fromJson(Map<String, dynamic> json) =>
      _$FidoCredentialFromJson(json);
}
