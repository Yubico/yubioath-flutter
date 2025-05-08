// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PinMetadata _$PinMetadataFromJson(Map<String, dynamic> json) => _PinMetadata(
  json['default_value'] as bool,
  (json['total_attempts'] as num).toInt(),
  (json['attempts_remaining'] as num).toInt(),
);

Map<String, dynamic> _$PinMetadataToJson(_PinMetadata instance) =>
    <String, dynamic>{
      'default_value': instance.defaultValue,
      'total_attempts': instance.totalAttempts,
      'attempts_remaining': instance.attemptsRemaining,
    };

_ManagementKeyMetadata _$ManagementKeyMetadataFromJson(
  Map<String, dynamic> json,
) => _ManagementKeyMetadata(
  $enumDecode(_$ManagementKeyTypeEnumMap, json['key_type']),
  json['default_value'] as bool,
  $enumDecode(_$TouchPolicyEnumMap, json['touch_policy']),
);

Map<String, dynamic> _$ManagementKeyMetadataToJson(
  _ManagementKeyMetadata instance,
) => <String, dynamic>{
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

_SlotMetadata _$SlotMetadataFromJson(Map<String, dynamic> json) =>
    _SlotMetadata(
      $enumDecode(_$KeyTypeEnumMap, json['key_type']),
      $enumDecode(_$PinPolicyEnumMap, json['pin_policy']),
      $enumDecode(_$TouchPolicyEnumMap, json['touch_policy']),
      json['generated'] as bool,
      json['public_key'] as String,
    );

Map<String, dynamic> _$SlotMetadataToJson(_SlotMetadata instance) =>
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

_PivStateMetadata _$PivStateMetadataFromJson(Map<String, dynamic> json) =>
    _PivStateMetadata(
      managementKeyMetadata: ManagementKeyMetadata.fromJson(
        json['management_key_metadata'] as Map<String, dynamic>,
      ),
      pinMetadata: PinMetadata.fromJson(
        json['pin_metadata'] as Map<String, dynamic>,
      ),
      pukMetadata: PinMetadata.fromJson(
        json['puk_metadata'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$PivStateMetadataToJson(_PivStateMetadata instance) =>
    <String, dynamic>{
      'management_key_metadata': instance.managementKeyMetadata,
      'pin_metadata': instance.pinMetadata,
      'puk_metadata': instance.pukMetadata,
    };

_PivState _$PivStateFromJson(Map<String, dynamic> json) => _PivState(
  version: Version.fromJson(json['version'] as List<dynamic>),
  authenticated: json['authenticated'] as bool,
  derivedKey: json['derived_key'] as bool,
  storedKey: json['stored_key'] as bool,
  pinAttempts: (json['pin_attempts'] as num).toInt(),
  supportsBio: json['supports_bio'] as bool,
  chuid: json['chuid'] as String?,
  ccc: json['ccc'] as String?,
  metadata:
      json['metadata'] == null
          ? null
          : PivStateMetadata.fromJson(json['metadata'] as Map<String, dynamic>),
);

Map<String, dynamic> _$PivStateToJson(_PivState instance) => <String, dynamic>{
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

_CertInfo _$CertInfoFromJson(Map<String, dynamic> json) => _CertInfo(
  keyType: $enumDecodeNullable(_$KeyTypeEnumMap, json['key_type']),
  subject: json['subject'] as String,
  issuer: json['issuer'] as String,
  serial: json['serial'] as String,
  notValidBefore: json['not_valid_before'] as String,
  notValidAfter: json['not_valid_after'] as String,
  fingerprint: json['fingerprint'] as String,
);

Map<String, dynamic> _$CertInfoToJson(_CertInfo instance) => <String, dynamic>{
  'key_type': _$KeyTypeEnumMap[instance.keyType],
  'subject': instance.subject,
  'issuer': instance.issuer,
  'serial': instance.serial,
  'not_valid_before': instance.notValidBefore,
  'not_valid_after': instance.notValidAfter,
  'fingerprint': instance.fingerprint,
};

_PivSlot _$PivSlotFromJson(Map<String, dynamic> json) => _PivSlot(
  slot: SlotId.fromJson((json['slot'] as num).toInt()),
  metadata:
      json['metadata'] == null
          ? null
          : SlotMetadata.fromJson(json['metadata'] as Map<String, dynamic>),
  certInfo:
      json['cert_info'] == null
          ? null
          : CertInfo.fromJson(json['cert_info'] as Map<String, dynamic>),
  publicKeyMatch: json['public_key_match'] as bool?,
);

Map<String, dynamic> _$PivSlotToJson(_PivSlot instance) => <String, dynamic>{
  'slot': _$SlotIdEnumMap[instance.slot]!,
  'metadata': instance.metadata,
  'cert_info': instance.certInfo,
  'public_key_match': instance.publicKeyMatch,
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

PivExamineResultResult _$PivExamineResultResultFromJson(
  Map<String, dynamic> json,
) => PivExamineResultResult(
  password: json['password'] as bool,
  keyType: $enumDecodeNullable(_$KeyTypeEnumMap, json['key_type']),
  certInfo:
      json['cert_info'] == null
          ? null
          : CertInfo.fromJson(json['cert_info'] as Map<String, dynamic>),
  publicKeyMatch: json['public_key_match'] as bool?,
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$PivExamineResultResultToJson(
  PivExamineResultResult instance,
) => <String, dynamic>{
  'password': instance.password,
  'key_type': _$KeyTypeEnumMap[instance.keyType],
  'cert_info': instance.certInfo,
  'public_key_match': instance.publicKeyMatch,
  'runtimeType': instance.$type,
};

PivExamineResultInvalidPassword _$PivExamineResultInvalidPasswordFromJson(
  Map<String, dynamic> json,
) => PivExamineResultInvalidPassword($type: json['runtimeType'] as String?);

Map<String, dynamic> _$PivExamineResultInvalidPasswordToJson(
  PivExamineResultInvalidPassword instance,
) => <String, dynamic>{'runtimeType': instance.$type};

_PivGenerateResult _$PivGenerateResultFromJson(Map<String, dynamic> json) =>
    _PivGenerateResult(
      generateType: $enumDecode(_$GenerateTypeEnumMap, json['generate_type']),
      publicKey: json['public_key'] as String,
      result: json['result'] as String?,
    );

Map<String, dynamic> _$PivGenerateResultToJson(_PivGenerateResult instance) =>
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

_PivImportResult _$PivImportResultFromJson(Map<String, dynamic> json) =>
    _PivImportResult(
      metadata:
          json['metadata'] == null
              ? null
              : SlotMetadata.fromJson(json['metadata'] as Map<String, dynamic>),
      publicKey: json['public_key'] as String?,
      certificate: json['certificate'] as String?,
    );

Map<String, dynamic> _$PivImportResultToJson(_PivImportResult instance) =>
    <String, dynamic>{
      'metadata': instance.metadata,
      'public_key': instance.publicKey,
      'certificate': instance.certificate,
    };
