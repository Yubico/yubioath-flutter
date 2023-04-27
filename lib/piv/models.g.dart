// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$_PinMetadata _$$_PinMetadataFromJson(Map<String, dynamic> json) =>
    _$_PinMetadata(
      json['default_value'] as bool,
      json['total_attempts'] as int,
      json['attempts_remaining'] as int,
    );

Map<String, dynamic> _$$_PinMetadataToJson(_$_PinMetadata instance) =>
    <String, dynamic>{
      'default_value': instance.defaultValue,
      'total_attempts': instance.totalAttempts,
      'attempts_remaining': instance.attemptsRemaining,
    };

_$_ManagementKeyMetadata _$$_ManagementKeyMetadataFromJson(
        Map<String, dynamic> json) =>
    _$_ManagementKeyMetadata(
      $enumDecode(_$ManagementKeyTypeEnumMap, json['key_type']),
      json['default_value'] as bool,
      $enumDecode(_$TouchPolicyEnumMap, json['touch_policy']),
    );

Map<String, dynamic> _$$_ManagementKeyMetadataToJson(
        _$_ManagementKeyMetadata instance) =>
    <String, dynamic>{
      'key_type': _$ManagementKeyTypeEnumMap[instance.keyType]!,
      'default_value': instance.defaultValue,
      'touch_policy': _$TouchPolicyEnumMap[instance.touchPolicy]!,
    };

const _$ManagementKeyTypeEnumMap = {
  ManagementKeyType.tdes: 3,
  ManagementKeyType.aes128: 8,
  ManagementKeyType.aes192: 10,
  ManagementKeyType.aes256: 12,
};

const _$TouchPolicyEnumMap = {
  TouchPolicy.dfault: 0,
  TouchPolicy.never: 1,
  TouchPolicy.always: 2,
  TouchPolicy.cached: 3,
};

_$_SlotMetadata _$$_SlotMetadataFromJson(Map<String, dynamic> json) =>
    _$_SlotMetadata(
      $enumDecode(_$KeyTypeEnumMap, json['key_type']),
      $enumDecode(_$PinPolicyEnumMap, json['pin_policy']),
      $enumDecode(_$TouchPolicyEnumMap, json['touch_policy']),
      json['generated'] as bool,
      json['public_key_encoded'] as String,
    );

Map<String, dynamic> _$$_SlotMetadataToJson(_$_SlotMetadata instance) =>
    <String, dynamic>{
      'key_type': _$KeyTypeEnumMap[instance.keyType]!,
      'pin_policy': _$PinPolicyEnumMap[instance.pinPolicy]!,
      'touch_policy': _$TouchPolicyEnumMap[instance.touchPolicy]!,
      'generated': instance.generated,
      'public_key_encoded': instance.publicKeyEncoded,
    };

const _$KeyTypeEnumMap = {
  KeyType.rsa1024: 6,
  KeyType.rsa2048: 7,
  KeyType.eccp256: 17,
  KeyType.eccp384: 20,
};

const _$PinPolicyEnumMap = {
  PinPolicy.dfault: 0,
  PinPolicy.never: 1,
  PinPolicy.once: 2,
  PinPolicy.always: 3,
};

_$_PivStateMetadata _$$_PivStateMetadataFromJson(Map<String, dynamic> json) =>
    _$_PivStateMetadata(
      managementKeyMetadata: ManagementKeyMetadata.fromJson(
          json['management_key_metadata'] as Map<String, dynamic>),
      pinMetadata:
          PinMetadata.fromJson(json['pin_metadata'] as Map<String, dynamic>),
      pukMetadata:
          PinMetadata.fromJson(json['puk_metadata'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$_PivStateMetadataToJson(_$_PivStateMetadata instance) =>
    <String, dynamic>{
      'management_key_metadata': instance.managementKeyMetadata,
      'pin_metadata': instance.pinMetadata,
      'puk_metadata': instance.pukMetadata,
    };

_$_PivState _$$_PivStateFromJson(Map<String, dynamic> json) => _$_PivState(
      version: Version.fromJson(json['version'] as List<dynamic>),
      authenticated: json['authenticated'] as bool,
      derivedKey: json['derived_key'] as bool,
      storedKey: json['stored_key'] as bool,
      pinAttempts: json['pin_attempts'] as int,
      chuid: json['chuid'] as String?,
      ccc: json['ccc'] as String?,
      metadata: json['metadata'] == null
          ? null
          : PivStateMetadata.fromJson(json['metadata'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$_PivStateToJson(_$_PivState instance) =>
    <String, dynamic>{
      'version': instance.version,
      'authenticated': instance.authenticated,
      'derived_key': instance.derivedKey,
      'stored_key': instance.storedKey,
      'pin_attempts': instance.pinAttempts,
      'chuid': instance.chuid,
      'ccc': instance.ccc,
      'metadata': instance.metadata,
    };

_$_CertInfo _$$_CertInfoFromJson(Map<String, dynamic> json) => _$_CertInfo(
      subject: json['subject'] as String,
      issuer: json['issuer'] as String,
      serial: json['serial'] as String,
      notValidBefore: json['not_valid_before'] as String,
      notValidAfter: json['not_valid_after'] as String,
      fingerprint: json['fingerprint'] as String,
    );

Map<String, dynamic> _$$_CertInfoToJson(_$_CertInfo instance) =>
    <String, dynamic>{
      'subject': instance.subject,
      'issuer': instance.issuer,
      'serial': instance.serial,
      'not_valid_before': instance.notValidBefore,
      'not_valid_after': instance.notValidAfter,
      'fingerprint': instance.fingerprint,
    };

_$_PivSlot _$$_PivSlotFromJson(Map<String, dynamic> json) => _$_PivSlot(
      slot: SlotId.fromJson(json['slot'] as int),
      hasKey: json['has_key'] as bool?,
      certInfo: json['cert_info'] == null
          ? null
          : CertInfo.fromJson(json['cert_info'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$_PivSlotToJson(_$_PivSlot instance) =>
    <String, dynamic>{
      'slot': _$SlotIdEnumMap[instance.slot]!,
      'has_key': instance.hasKey,
      'cert_info': instance.certInfo,
    };

const _$SlotIdEnumMap = {
  SlotId.authentication: 'authentication',
  SlotId.signature: 'signature',
  SlotId.keyManagement: 'keyManagement',
  SlotId.cardAuth: 'cardAuth',
};

_$_ExamineResult _$$_ExamineResultFromJson(Map<String, dynamic> json) =>
    _$_ExamineResult(
      password: json['password'] as bool,
      privateKey: json['private_key'] as bool,
      certificates: json['certificates'] as int,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$_ExamineResultToJson(_$_ExamineResult instance) =>
    <String, dynamic>{
      'password': instance.password,
      'private_key': instance.privateKey,
      'certificates': instance.certificates,
      'runtimeType': instance.$type,
    };

_$_InvalidPassword _$$_InvalidPasswordFromJson(Map<String, dynamic> json) =>
    _$_InvalidPassword(
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$_InvalidPasswordToJson(_$_InvalidPassword instance) =>
    <String, dynamic>{
      'runtimeType': instance.$type,
    };

_$_PivGenerateResult _$$_PivGenerateResultFromJson(Map<String, dynamic> json) =>
    _$_PivGenerateResult(
      generateType: $enumDecode(_$GenerateTypeEnumMap, json['generate_type']),
      publicKey: json['public_key'] as String,
      result: json['result'] as String,
    );

Map<String, dynamic> _$$_PivGenerateResultToJson(
        _$_PivGenerateResult instance) =>
    <String, dynamic>{
      'generate_type': _$GenerateTypeEnumMap[instance.generateType]!,
      'public_key': instance.publicKey,
      'result': instance.result,
    };

const _$GenerateTypeEnumMap = {
  GenerateType.certificate: 'certificate',
  GenerateType.csr: 'csr',
};

_$_PivImportResult _$$_PivImportResultFromJson(Map<String, dynamic> json) =>
    _$_PivImportResult(
      metadata: json['metadata'] == null
          ? null
          : SlotMetadata.fromJson(json['metadata'] as Map<String, dynamic>),
      publicKey: json['public_key'] as String?,
      certificate: json['certificate'] as String?,
    );

Map<String, dynamic> _$$_PivImportResultToJson(_$_PivImportResult instance) =>
    <String, dynamic>{
      'metadata': instance.metadata,
      'public_key': instance.publicKey,
      'certificate': instance.certificate,
    };
