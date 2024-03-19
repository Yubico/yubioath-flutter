// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FidoStateImpl _$$FidoStateImplFromJson(Map<String, dynamic> json) =>
    _$FidoStateImpl(
      info: json['info'] as Map<String, dynamic>,
      unlocked: json['unlocked'] as bool,
    );

Map<String, dynamic> _$$FidoStateImplToJson(_$FidoStateImpl instance) =>
    <String, dynamic>{
      'info': instance.info,
      'unlocked': instance.unlocked,
    };

_$FingerprintImpl _$$FingerprintImplFromJson(Map<String, dynamic> json) =>
    _$FingerprintImpl(
      json['template_id'] as String,
      json['name'] as String?,
    );

Map<String, dynamic> _$$FingerprintImplToJson(_$FingerprintImpl instance) =>
    <String, dynamic>{
      'template_id': instance.templateId,
      'name': instance.name,
    };

_$FidoCredentialImpl _$$FidoCredentialImplFromJson(Map<String, dynamic> json) =>
    _$FidoCredentialImpl(
      rpId: json['rp_id'] as String,
      credentialId: json['credential_id'] as String,
      userId: json['user_id'] as String,
      userName: json['user_name'] as String,
    );

Map<String, dynamic> _$$FidoCredentialImplToJson(
        _$FidoCredentialImpl instance) =>
    <String, dynamic>{
      'rp_id': instance.rpId,
      'credential_id': instance.credentialId,
      'user_id': instance.userId,
      'user_name': instance.userName,
    };
