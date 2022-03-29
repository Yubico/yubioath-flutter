// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$_FidoState _$$_FidoStateFromJson(Map<String, dynamic> json) => _$_FidoState(
      info: json['info'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$$_FidoStateToJson(_$_FidoState instance) =>
    <String, dynamic>{
      'info': instance.info,
    };

_$_Fingerprint _$$_FingerprintFromJson(Map<String, dynamic> json) =>
    _$_Fingerprint(
      json['template_id'] as String,
      json['name'] as String?,
    );

Map<String, dynamic> _$$_FingerprintToJson(_$_Fingerprint instance) =>
    <String, dynamic>{
      'template_id': instance.templateId,
      'name': instance.name,
    };

_$_FidoCredential _$$_FidoCredentialFromJson(Map<String, dynamic> json) =>
    _$_FidoCredential(
      rpId: json['rp_id'] as String,
      credentialId: json['credential_id'] as String,
      userId: json['user_id'] as String,
      userName: json['user_name'] as String,
    );

Map<String, dynamic> _$$_FidoCredentialToJson(_$_FidoCredential instance) =>
    <String, dynamic>{
      'rp_id': instance.rpId,
      'credential_id': instance.credentialId,
      'user_id': instance.userId,
      'user_name': instance.userName,
    };
