// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$KeyCustomizationImpl _$$KeyCustomizationImplFromJson(
  Map<String, dynamic> json,
) => _$KeyCustomizationImpl(
  serial: (json['serial'] as num).toInt(),
  name: json['name'] as String?,
  color: const _ColorConverter().fromJson((json['color'] as num?)?.toInt()),
);

Map<String, dynamic> _$$KeyCustomizationImplToJson(
  _$KeyCustomizationImpl instance,
) => <String, dynamic>{
  'serial': instance.serial,
  if (instance.name case final value?) 'name': value,
  if (const _ColorConverter().toJson(instance.color) case final value?)
    'color': value,
};

_$LocaleStatusImpl _$$LocaleStatusImplFromJson(Map<String, dynamic> json) =>
    _$LocaleStatusImpl(
      translated: (json['translated'] as num).toInt(),
      proofread: (json['proofread'] as num).toInt(),
    );

Map<String, dynamic> _$$LocaleStatusImplToJson(_$LocaleStatusImpl instance) =>
    <String, dynamic>{
      'translated': instance.translated,
      'proofread': instance.proofread,
    };
