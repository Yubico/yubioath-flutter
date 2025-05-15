// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_OathCredential _$OathCredentialFromJson(Map<String, dynamic> json) =>
    _OathCredential(
      json['device_id'] as String,
      json['id'] as String,
      const _IssuerConverter().fromJson(json['issuer'] as String?),
      json['name'] as String,
      $enumDecode(_$OathTypeEnumMap, json['oath_type']),
      (json['period'] as num).toInt(),
      json['touch_required'] as bool,
    );

Map<String, dynamic> _$OathCredentialToJson(_OathCredential instance) =>
    <String, dynamic>{
      'device_id': instance.deviceId,
      'id': instance.id,
      'issuer': const _IssuerConverter().toJson(instance.issuer),
      'name': instance.name,
      'oath_type': _$OathTypeEnumMap[instance.oathType]!,
      'period': instance.period,
      'touch_required': instance.touchRequired,
    };

const _$OathTypeEnumMap = {OathType.hotp: 16, OathType.totp: 32};

_OathCode _$OathCodeFromJson(Map<String, dynamic> json) => _OathCode(
  json['value'] as String,
  (json['valid_from'] as num).toInt(),
  (json['valid_to'] as num).toInt(),
);

Map<String, dynamic> _$OathCodeToJson(_OathCode instance) => <String, dynamic>{
  'value': instance.value,
  'valid_from': instance.validFrom,
  'valid_to': instance.validTo,
};

_OathPair _$OathPairFromJson(Map<String, dynamic> json) => _OathPair(
  OathCredential.fromJson(json['credential'] as Map<String, dynamic>),
  json['code'] == null
      ? null
      : OathCode.fromJson(json['code'] as Map<String, dynamic>),
);

Map<String, dynamic> _$OathPairToJson(_OathPair instance) => <String, dynamic>{
  'credential': instance.credential,
  'code': instance.code,
};

_OathState _$OathStateFromJson(Map<String, dynamic> json) => _OathState(
  json['device_id'] as String,
  Version.fromJson(json['version'] as List<dynamic>),
  hasKey: json['has_key'] as bool,
  remembered: json['remembered'] as bool,
  locked: json['locked'] as bool,
  keystore: $enumDecode(_$KeystoreStateEnumMap, json['keystore']),
);

Map<String, dynamic> _$OathStateToJson(_OathState instance) =>
    <String, dynamic>{
      'device_id': instance.deviceId,
      'version': instance.version,
      'has_key': instance.hasKey,
      'remembered': instance.remembered,
      'locked': instance.locked,
      'keystore': _$KeystoreStateEnumMap[instance.keystore]!,
    };

const _$KeystoreStateEnumMap = {
  KeystoreState.unknown: 'unknown',
  KeystoreState.allowed: 'allowed',
  KeystoreState.failed: 'failed',
};

_CredentialData _$CredentialDataFromJson(Map<String, dynamic> json) =>
    _CredentialData(
      issuer: json['issuer'] as String?,
      name: json['name'] as String,
      secret: json['secret'] as String,
      oathType:
          $enumDecodeNullable(_$OathTypeEnumMap, json['oath_type']) ??
          defaultOathType,
      hashAlgorithm:
          $enumDecodeNullable(_$HashAlgorithmEnumMap, json['hash_algorithm']) ??
          defaultHashAlgorithm,
      digits: (json['digits'] as num?)?.toInt() ?? defaultDigits,
      period: (json['period'] as num?)?.toInt() ?? defaultPeriod,
      counter: (json['counter'] as num?)?.toInt() ?? defaultCounter,
    );

Map<String, dynamic> _$CredentialDataToJson(_CredentialData instance) =>
    <String, dynamic>{
      'issuer': instance.issuer,
      'name': instance.name,
      'secret': instance.secret,
      'oath_type': _$OathTypeEnumMap[instance.oathType]!,
      'hash_algorithm': _$HashAlgorithmEnumMap[instance.hashAlgorithm]!,
      'digits': instance.digits,
      'period': instance.period,
      'counter': instance.counter,
    };

const _$HashAlgorithmEnumMap = {
  HashAlgorithm.sha1: 1,
  HashAlgorithm.sha256: 2,
  HashAlgorithm.sha512: 3,
};
