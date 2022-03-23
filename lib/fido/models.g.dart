// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$_FidoState _$$_FidoStateFromJson(Map<String, dynamic> json) => _$_FidoState(
      info: json['info'] as Map<String, dynamic>,
      locked: json['locked'] as bool,
    );

Map<String, dynamic> _$$_FidoStateToJson(_$_FidoState instance) =>
    <String, dynamic>{
      'info': instance.info,
      'locked': instance.locked,
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
