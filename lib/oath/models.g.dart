// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$_OathCredential _$$_OathCredentialFromJson(Map<String, dynamic> json) =>
    _$_OathCredential(
      json['device_id'] as String,
      json['id'] as String,
      json['issuer'] as String?,
      json['name'] as String,
      $enumDecode(_$OathTypeEnumMap, json['oath_type']),
      json['period'] as int,
      json['touch_required'] as bool,
    );

Map<String, dynamic> _$$_OathCredentialToJson(_$_OathCredential instance) =>
    <String, dynamic>{
      'device_id': instance.deviceId,
      'id': instance.id,
      'issuer': instance.issuer,
      'name': instance.name,
      'oath_type': _$OathTypeEnumMap[instance.oathType],
      'period': instance.period,
      'touch_required': instance.touchRequired,
    };

const _$OathTypeEnumMap = {
  OathType.hotp: 16,
  OathType.totp: 32,
};

_$_OathCode _$$_OathCodeFromJson(Map<String, dynamic> json) => _$_OathCode(
      json['value'] as String,
      json['valid_from'] as int,
      json['valid_to'] as int,
    );

Map<String, dynamic> _$$_OathCodeToJson(_$_OathCode instance) =>
    <String, dynamic>{
      'value': instance.value,
      'valid_from': instance.validFrom,
      'valid_to': instance.validTo,
    };

_$_OathPair _$$_OathPairFromJson(Map<String, dynamic> json) => _$_OathPair(
      OathCredential.fromJson(json['credential'] as Map<String, dynamic>),
      json['code'] == null
          ? null
          : OathCode.fromJson(json['code'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$_OathPairToJson(_$_OathPair instance) =>
    <String, dynamic>{
      'credential': instance.credential,
      'code': instance.code,
    };

_$_OathState _$$_OathStateFromJson(Map<String, dynamic> json) => _$_OathState(
      json['device_id'] as String,
      Version.fromJson(json['version'] as List<dynamic>),
      hasKey: json['has_key'] as bool,
      remembered: json['remembered'] as bool,
      locked: json['locked'] as bool,
      keystore: $enumDecode(_$KeystoreStateEnumMap, json['keystore']),
    );

Map<String, dynamic> _$$_OathStateToJson(_$_OathState instance) =>
    <String, dynamic>{
      'device_id': instance.deviceId,
      'version': instance.version,
      'has_key': instance.hasKey,
      'remembered': instance.remembered,
      'locked': instance.locked,
      'keystore': _$KeystoreStateEnumMap[instance.keystore],
    };

const _$KeystoreStateEnumMap = {
  KeystoreState.unknown: 'unknown',
  KeystoreState.allowed: 'allowed',
  KeystoreState.failed: 'failed',
};

_$_CredentialData _$$_CredentialDataFromJson(Map<String, dynamic> json) =>
    _$_CredentialData(
      issuer: json['issuer'] as String?,
      name: json['name'] as String,
      secret: json['secret'] as String,
      oathType: $enumDecodeNullable(_$OathTypeEnumMap, json['oath_type']) ??
          defaultOathType,
      hashAlgorithm:
          $enumDecodeNullable(_$HashAlgorithmEnumMap, json['hash_algorithm']) ??
              defaultHashAlgorithm,
      digits: json['digits'] as int? ?? defaultDigits,
      period: json['period'] as int? ?? defaultPeriod,
      counter: json['counter'] as int? ?? defaultCounter,
    );

Map<String, dynamic> _$$_CredentialDataToJson(_$_CredentialData instance) =>
    <String, dynamic>{
      'issuer': instance.issuer,
      'name': instance.name,
      'secret': instance.secret,
      'oath_type': _$OathTypeEnumMap[instance.oathType],
      'hash_algorithm': _$HashAlgorithmEnumMap[instance.hashAlgorithm],
      'digits': instance.digits,
      'period': instance.period,
      'counter': instance.counter,
    };

const _$HashAlgorithmEnumMap = {
  HashAlgorithm.sha1: 1,
  HashAlgorithm.sha256: 2,
  HashAlgorithm.sha512: 3,
};
