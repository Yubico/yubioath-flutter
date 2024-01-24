// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$KeyCustomizationImpl _$$KeyCustomizationImplFromJson(
        Map<String, dynamic> json) =>
    _$KeyCustomizationImpl(
      serial: json['serial'] as String,
      name: json['name'] as String?,
      color: const _ColorConverter().fromJson(json['color'] as int?),
    );

Map<String, dynamic> _$$KeyCustomizationImplToJson(
        _$KeyCustomizationImpl instance) =>
    <String, dynamic>{
      'serial': instance.serial,
      'name': instance.name,
      'color': const _ColorConverter().toJson(instance.color),
    };
