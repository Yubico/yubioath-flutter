// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$KeyCustomizationImpl _$$KeyCustomizationImplFromJson(
        Map<String, dynamic> json) =>
    _$KeyCustomizationImpl(
      serial: json['serial'] as String,
      customName: json['custom_name'] as String?,
      customColor:
          const _ColorConverter().fromJson(json['custom_color'] as int?),
    );

Map<String, dynamic> _$$KeyCustomizationImplToJson(
        _$KeyCustomizationImpl instance) =>
    <String, dynamic>{
      'serial': instance.serial,
      'custom_name': instance.customName,
      'custom_color': const _ColorConverter().toJson(instance.customColor),
    };
