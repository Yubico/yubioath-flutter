// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FidoState _$FidoStateFromJson(Map<String, dynamic> json) => _FidoState(
  info: json['info'] as Map<String, dynamic>,
  unlocked: json['unlocked'] as bool,
  unlockedRead: json['unlocked_read'] as bool? ?? false,
  pinRetries: (json['pin_retries'] as num?)?.toInt(),
);

Map<String, dynamic> _$FidoStateToJson(_FidoState instance) =>
    <String, dynamic>{
      'info': instance.info,
      'unlocked': instance.unlocked,
      'unlocked_read': instance.unlockedRead,
      'pin_retries': instance.pinRetries,
    };

_Fingerprint _$FingerprintFromJson(Map<String, dynamic> json) =>
    _Fingerprint(json['template_id'] as String, json['name'] as String?);

Map<String, dynamic> _$FingerprintToJson(_Fingerprint instance) =>
    <String, dynamic>{
      'template_id': instance.templateId,
      'name': instance.name,
    };

_FidoCredential _$FidoCredentialFromJson(Map<String, dynamic> json) =>
    _FidoCredential(
      rpId: json['rp_id'] as String,
      credentialId: json['credential_id'] as String,
      userId: json['user_id'] as String,
      userName: json['user_name'] as String,
      displayName: json['display_name'] as String?,
    );

Map<String, dynamic> _$FidoCredentialToJson(_FidoCredential instance) =>
    <String, dynamic>{
      'rp_id': instance.rpId,
      'credential_id': instance.credentialId,
      'user_id': instance.userId,
      'user_name': instance.userName,
      'display_name': instance.displayName,
    };
