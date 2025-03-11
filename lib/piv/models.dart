/*
 * Copyright (C) 2023-2025 Yubico.
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

import '../core/models.dart';
import '../generated/l10n/app_localizations.dart';

part 'models.freezed.dart';
part 'models.g.dart';

const defaultManagementKey = '010203040506070801020304050607080102030405060708';
const defaultManagementKeyType = ManagementKeyType.tdes;
const defaultKeyType = KeyType.eccp256;
const defaultGenerateType = GenerateType.certificate;
const defaultPin = '123456';
const defaultPuk = '12345678';

enum GenerateType {
  publicKey,
  certificate,
  csr;

  String getDisplayName(AppLocalizations l10n) {
    return switch (this) {
      GenerateType.publicKey => l10n.s_public_key,
      GenerateType.certificate => l10n.l_self_signed_certificate,
      GenerateType.csr => l10n.l_certificate_signing_request,
    };
  }
}

enum SlotId {
  authentication(0x9a),
  signature(0x9c),
  keyManagement(0x9d),
  cardAuth(0x9e),
  retired1(0x82, true),
  retired2(0x83, true),
  retired3(0x84, true),
  retired4(0x85, true),
  retired5(0x86, true),
  retired6(0x87, true),
  retired7(0x88, true),
  retired8(0x89, true),
  retired9(0x8a, true),
  retired10(0x8b, true),
  retired11(0x8c, true),
  retired12(0x8d, true),
  retired13(0x8e, true),
  retired14(0x8f, true),
  retired15(0x90, true),
  retired16(0x91, true),
  retired17(0x92, true),
  retired18(0x93, true),
  retired19(0x94, true),
  retired20(0x95, true);

  final int id;
  final bool isRetired;
  const SlotId(this.id, [this.isRetired = false]);

  String get hexId => id.toRadixString(16).padLeft(2, '0');

  String getSlotName(AppLocalizations l10n) {
    return switch (this) {
      SlotId.authentication => l10n.s_slot_9a,
      SlotId.signature => l10n.s_slot_9c,
      SlotId.keyManagement => l10n.s_slot_9d,
      SlotId.cardAuth => l10n.s_slot_9e,
      _ => l10n.s_retired_slot,
    };
  }

  String getDisplayName(AppLocalizations l10n) {
    return l10n.s_slot_display_name(getSlotName(l10n), hexId);
  }

  factory SlotId.fromJson(int value) =>
      SlotId.values.firstWhere((e) => e.id == value);
}

@JsonEnum(alwaysCreate: true)
enum PinPolicy {
  @JsonValue(0x00)
  dfault,
  @JsonValue(0x01)
  never,
  @JsonValue(0x02)
  once,
  @JsonValue(0x03)
  always,
  @JsonValue(0x04)
  matchOnce,
  @JsonValue(0x05)
  matchAlways;

  const PinPolicy();

  int get value => _$PinPolicyEnumMap[this]!;

  String getDisplayName(AppLocalizations l10n) {
    return switch (this) {
      // TODO:
      _ => name,
    };
  }
}

@JsonEnum(alwaysCreate: true)
enum TouchPolicy {
  @JsonValue(0x00)
  dfault,
  @JsonValue(0x01)
  never,
  @JsonValue(0x02)
  always,
  @JsonValue(0x03)
  cached;

  const TouchPolicy();

  int get value => _$TouchPolicyEnumMap[this]!;

  String getDisplayName(AppLocalizations l10n) {
    return switch (this) {
      // TODO:
      _ => name,
    };
  }
}

@JsonEnum(alwaysCreate: true)
enum KeyType {
  @JsonValue(0x06)
  rsa1024,
  @JsonValue(0x07)
  rsa2048,
  @JsonValue(0x05)
  rsa3072,
  @JsonValue(0x16)
  rsa4096,
  @JsonValue(0x11)
  eccp256,
  @JsonValue(0x14)
  eccp384,
  @JsonValue(0xe0)
  ed25519,
  @JsonValue(0xe1)
  x25519;

  const KeyType();

  int get value => _$KeyTypeEnumMap[this]!;

  String getDisplayName(AppLocalizations l10n) {
    return switch (this) {
      // TODO: Should these be translatable?
      _ => name.toUpperCase(),
    };
  }
}

enum ManagementKeyType {
  @JsonValue(0x03)
  tdes(24),
  @JsonValue(0x08)
  aes128(16),
  @JsonValue(0x0A)
  aes192(24),
  @JsonValue(0x0C)
  aes256(32);

  const ManagementKeyType(this.keyLength);
  final int keyLength;

  int get value => _$ManagementKeyTypeEnumMap[this]!;

  String getDisplayName(AppLocalizations l10n) {
    return switch (this) {
      // TODO: Should these be translatable?
      _ => name.toUpperCase(),
    };
  }
}

@freezed
class PinMetadata with _$PinMetadata {
  factory PinMetadata(
    bool defaultValue,
    int totalAttempts,
    int attemptsRemaining,
  ) = _PinMetadata;

  factory PinMetadata.fromJson(Map<String, dynamic> json) =>
      _$PinMetadataFromJson(json);
}

@freezed
class PinVerificationStatus with _$PinVerificationStatus {
  const factory PinVerificationStatus.success() = PinSuccess;
  factory PinVerificationStatus.failure(PivPinFailureReason reason) =
      PinFailure;
}

@freezed
class PivPinFailureReason with _$PivPinFailureReason {
  factory PivPinFailureReason.invalidPin(int attemptsRemaining) = PivInvalidPin;
  const factory PivPinFailureReason.weakPin() = PivWeakPin;
}

@freezed
class ManagementKeyMetadata with _$ManagementKeyMetadata {
  factory ManagementKeyMetadata(
    ManagementKeyType keyType,
    bool defaultValue,
    TouchPolicy touchPolicy,
  ) = _ManagementKeyMetadata;

  factory ManagementKeyMetadata.fromJson(Map<String, dynamic> json) =>
      _$ManagementKeyMetadataFromJson(json);
}

@freezed
class SlotMetadata with _$SlotMetadata {
  factory SlotMetadata(
    KeyType keyType,
    PinPolicy pinPolicy,
    TouchPolicy touchPolicy,
    bool generated,
    String publicKey,
  ) = _SlotMetadata;

  factory SlotMetadata.fromJson(Map<String, dynamic> json) =>
      _$SlotMetadataFromJson(json);
}

@freezed
class PivStateMetadata with _$PivStateMetadata {
  factory PivStateMetadata({
    required ManagementKeyMetadata managementKeyMetadata,
    required PinMetadata pinMetadata,
    required PinMetadata pukMetadata,
  }) = _PivStateMetadata;

  factory PivStateMetadata.fromJson(Map<String, dynamic> json) =>
      _$PivStateMetadataFromJson(json);
}

@freezed
class PivState with _$PivState {
  const PivState._();

  factory PivState({
    required Version version,
    required bool authenticated,
    required bool derivedKey,
    required bool storedKey,
    required int pinAttempts,
    required bool supportsBio,
    String? chuid,
    String? ccc,
    PivStateMetadata? metadata,
  }) = _PivState;

  bool get protectedKey => derivedKey || storedKey;
  bool get needsAuth =>
      !authenticated && metadata?.managementKeyMetadata.defaultValue != true;
  bool get supportsMetadata => version.isAtLeast(5, 3);

  factory PivState.fromJson(Map<String, dynamic> json) =>
      _$PivStateFromJson(json);
}

@freezed
class CertInfo with _$CertInfo {
  factory CertInfo({
    required KeyType? keyType,
    required String subject,
    required String issuer,
    required String serial,
    required String notValidBefore,
    required String notValidAfter,
    required String fingerprint,
  }) = _CertInfo;

  factory CertInfo.fromJson(Map<String, dynamic> json) =>
      _$CertInfoFromJson(json);
}

@freezed
class PivSlot with _$PivSlot {
  factory PivSlot({
    required SlotId slot,
    SlotMetadata? metadata,
    CertInfo? certInfo,
    bool? publicKeyMatch,
  }) = _PivSlot;

  factory PivSlot.fromJson(Map<String, dynamic> json) =>
      _$PivSlotFromJson(json);
}

@freezed
class PivExamineResult with _$PivExamineResult {
  factory PivExamineResult.result({
    required bool password,
    required KeyType? keyType,
    required CertInfo? certInfo,
    bool? publicKeyMatch,
  }) = _ExamineResult;
  factory PivExamineResult.invalidPassword() = _InvalidPassword;

  factory PivExamineResult.fromJson(Map<String, dynamic> json) =>
      _$PivExamineResultFromJson(json);
}

@freezed
class PivGenerateParameters with _$PivGenerateParameters {
  factory PivGenerateParameters.publicKey() = _GeneratePublicKey;

  factory PivGenerateParameters.certificate({
    required String subject,
    required DateTime validFrom,
    required DateTime validTo,
  }) = _GenerateCertificate;

  factory PivGenerateParameters.csr({required String subject}) = _GenerateCsr;
}

@freezed
class PivGenerateResult with _$PivGenerateResult {
  factory PivGenerateResult({
    required GenerateType generateType,
    required String publicKey,
    String? result,
  }) = _PivGenerateResult;

  factory PivGenerateResult.fromJson(Map<String, dynamic> json) =>
      _$PivGenerateResultFromJson(json);
}

@freezed
class PivImportResult with _$PivImportResult {
  factory PivImportResult({
    required SlotMetadata? metadata,
    required String? publicKey,
    required String? certificate,
  }) = _PivImportResult;

  factory PivImportResult.fromJson(Map<String, dynamic> json) =>
      _$PivImportResultFromJson(json);
}
