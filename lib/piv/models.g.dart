// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PinMetadataImpl _$$PinMetadataImplFromJson(Map<String, dynamic> json) =>
    _$PinMetadataImpl(
      json['default_value'] as bool,
      (json['total_attempts'] as num).toInt(),
      (json['attempts_remaining'] as num).toInt(),
    );

Map<String, dynamic> _$$PinMetadataImplToJson(_$PinMetadataImpl instance) =>
    <String, dynamic>{
      'default_value': instance.defaultValue,
      'total_attempts': instance.totalAttempts,
      'attempts_remaining': instance.attemptsRemaining,
    };

_$ManagementKeyMetadataImpl _$$ManagementKeyMetadataImplFromJson(
        Map<String, dynamic> json) =>
    _$ManagementKeyMetadataImpl(
      $enumDecode(_$ManagementKeyTypeEnumMap, json['key_type']),
      json['default_value'] as bool,
      $enumDecode(_$TouchPolicyEnumMap, json['touch_policy']),
    );

Map<String, dynamic> _$$ManagementKeyMetadataImplToJson(
        _$ManagementKeyMetadataImpl instance) =>
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

_$SlotMetadataImpl _$$SlotMetadataImplFromJson(Map<String, dynamic> json) =>
    _$SlotMetadataImpl(
      $enumDecode(_$KeyTypeEnumMap, json['key_type']),
      $enumDecode(_$PinPolicyEnumMap, json['pin_policy']),
      $enumDecode(_$TouchPolicyEnumMap, json['touch_policy']),
      json['generated'] as bool,
      json['public_key'] as String,
    );

Map<String, dynamic> _$$SlotMetadataImplToJson(_$SlotMetadataImpl instance) =>
    <String, dynamic>{
      'key_type': _$KeyTypeEnumMap[instance.keyType]!,
      'pin_policy': _$PinPolicyEnumMap[instance.pinPolicy]!,
      'touch_policy': _$TouchPolicyEnumMap[instance.touchPolicy]!,
      'generated': instance.generated,
      'public_key': instance.publicKey,
    };

const _$KeyTypeEnumMap = {
  KeyType.rsa1024: 6,
  KeyType.rsa2048: 7,
  KeyType.rsa3072: 5,
  KeyType.rsa4096: 22,
  KeyType.eccp256: 17,
  KeyType.eccp384: 20,
  KeyType.ed25519: 224,
  KeyType.x25519: 225,
};

const _$PinPolicyEnumMap = {
  PinPolicy.dfault: 0,
  PinPolicy.never: 1,
  PinPolicy.once: 2,
  PinPolicy.always: 3,
  PinPolicy.matchOnce: 4,
  PinPolicy.matchAlways: 5,
};

_$PivStateMetadataImpl _$$PivStateMetadataImplFromJson(
        Map<String, dynamic> json) =>
    _$PivStateMetadataImpl(
      managementKeyMetadata: ManagementKeyMetadata.fromJson(
          json['management_key_metadata'] as Map<String, dynamic>),
      pinMetadata:
          PinMetadata.fromJson(json['pin_metadata'] as Map<String, dynamic>),
      pukMetadata:
          PinMetadata.fromJson(json['puk_metadata'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$PivStateMetadataImplToJson(
        _$PivStateMetadataImpl instance) =>
    <String, dynamic>{
      'management_key_metadata': instance.managementKeyMetadata,
      'pin_metadata': instance.pinMetadata,
      'puk_metadata': instance.pukMetadata,
    };

_$PivStateImpl _$$PivStateImplFromJson(Map<String, dynamic> json) =>
    _$PivStateImpl(
      version: Version.fromJson(json['version'] as List<dynamic>),
      authenticated: json['authenticated'] as bool,
      derivedKey: json['derived_key'] as bool,
      storedKey: json['stored_key'] as bool,
      pinAttempts: (json['pin_attempts'] as num).toInt(),
      supportsBio: json['supports_bio'] as bool,
      chuid: json['chuid'] as String?,
      ccc: json['ccc'] as String?,
      metadata: json['metadata'] == null
          ? null
          : PivStateMetadata.fromJson(json['metadata'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$PivStateImplToJson(_$PivStateImpl instance) =>
    <String, dynamic>{
      'version': instance.version,
      'authenticated': instance.authenticated,
      'derived_key': instance.derivedKey,
      'stored_key': instance.storedKey,
      'pin_attempts': instance.pinAttempts,
      'supports_bio': instance.supportsBio,
      'chuid': instance.chuid,
      'ccc': instance.ccc,
      'metadata': instance.metadata,
    };

_$CertInfoImpl _$$CertInfoImplFromJson(Map<String, dynamic> json) =>
    _$CertInfoImpl(
      keyType: $enumDecodeNullable(_$KeyTypeEnumMap, json['key_type']),
      subject: json['subject'] as String,
      issuer: json['issuer'] as String,
      serial: json['serial'] as String,
      notValidBefore: json['not_valid_before'] as String,
      notValidAfter: json['not_valid_after'] as String,
      fingerprint: json['fingerprint'] as String,
    );

Map<String, dynamic> _$$CertInfoImplToJson(_$CertInfoImpl instance) =>
    <String, dynamic>{
      'key_type': _$KeyTypeEnumMap[instance.keyType],
      'subject': instance.subject,
      'issuer': instance.issuer,
      'serial': instance.serial,
      'not_valid_before': instance.notValidBefore,
      'not_valid_after': instance.notValidAfter,
      'fingerprint': instance.fingerprint,
    };

_$PivSlotImpl _$$PivSlotImplFromJson(Map<String, dynamic> json) =>
    _$PivSlotImpl(
      slot: SlotId.fromJson((json['slot'] as num).toInt()),
      metadata: json['metadata'] == null
          ? null
          : SlotMetadata.fromJson(json['metadata'] as Map<String, dynamic>),
      certInfo: json['cert_info'] == null
          ? null
          : CertInfo.fromJson(json['cert_info'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$PivSlotImplToJson(_$PivSlotImpl instance) =>
    <String, dynamic>{
      'slot': _$SlotIdEnumMap[instance.slot]!,
      'metadata': instance.metadata,
      'cert_info': instance.certInfo,
    };

const _$SlotIdEnumMap = {
  SlotId.authentication: 'authentication',
  SlotId.signature: 'signature',
  SlotId.keyManagement: 'keyManagement',
  SlotId.cardAuth: 'cardAuth',
  SlotId.retired1: 'retired1',
  SlotId.retired2: 'retired2',
  SlotId.retired3: 'retired3',
  SlotId.retired4: 'retired4',
  SlotId.retired5: 'retired5',
  SlotId.retired6: 'retired6',
  SlotId.retired7: 'retired7',
  SlotId.retired8: 'retired8',
  SlotId.retired9: 'retired9',
  SlotId.retired10: 'retired10',
  SlotId.retired11: 'retired11',
  SlotId.retired12: 'retired12',
  SlotId.retired13: 'retired13',
  SlotId.retired14: 'retired14',
  SlotId.retired15: 'retired15',
  SlotId.retired16: 'retired16',
  SlotId.retired17: 'retired17',
  SlotId.retired18: 'retired18',
  SlotId.retired19: 'retired19',
  SlotId.retired20: 'retired20',
};

_$ExamineResultImpl _$$ExamineResultImplFromJson(Map<String, dynamic> json) =>
    _$ExamineResultImpl(
      password: json['password'] as bool,
      keyType: $enumDecodeNullable(_$KeyTypeEnumMap, json['key_type']),
      certInfo: json['cert_info'] == null
          ? null
          : CertInfo.fromJson(json['cert_info'] as Map<String, dynamic>),
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$ExamineResultImplToJson(_$ExamineResultImpl instance) =>
    <String, dynamic>{
      'password': instance.password,
      'key_type': _$KeyTypeEnumMap[instance.keyType],
      'cert_info': instance.certInfo,
      'runtimeType': instance.$type,
    };

_$InvalidPasswordImpl _$$InvalidPasswordImplFromJson(
        Map<String, dynamic> json) =>
    _$InvalidPasswordImpl(
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$InvalidPasswordImplToJson(
        _$InvalidPasswordImpl instance) =>
    <String, dynamic>{
      'runtimeType': instance.$type,
    };

_$PivGenerateResultImpl _$$PivGenerateResultImplFromJson(
        Map<String, dynamic> json) =>
    _$PivGenerateResultImpl(
      generateType: $enumDecode(_$GenerateTypeEnumMap, json['generate_type']),
      publicKey: json['public_key'] as String,
      result: json['result'] as String?,
    );

Map<String, dynamic> _$$PivGenerateResultImplToJson(
        _$PivGenerateResultImpl instance) =>
    <String, dynamic>{
      'generate_type': _$GenerateTypeEnumMap[instance.generateType]!,
      'public_key': instance.publicKey,
      'result': instance.result,
    };

const _$GenerateTypeEnumMap = {
  GenerateType.publicKey: 'publicKey',
  GenerateType.certificate: 'certificate',
  GenerateType.csr: 'csr',
};

_$PivImportResultImpl _$$PivImportResultImplFromJson(
        Map<String, dynamic> json) =>
    _$PivImportResultImpl(
      metadata: json['metadata'] == null
          ? null
          : SlotMetadata.fromJson(json['metadata'] as Map<String, dynamic>),
      publicKey: json['public_key'] as String?,
      certificate: json['certificate'] as String?,
    );

Map<String, dynamic> _$$PivImportResultImplToJson(
        _$PivImportResultImpl instance) =>
    <String, dynamic>{
      'metadata': instance.metadata,
      'public_key': instance.publicKey,
      'certificate': instance.certificate,
    };
