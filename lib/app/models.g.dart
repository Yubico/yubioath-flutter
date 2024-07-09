// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$KeyCustomizationImpl _$$KeyCustomizationImplFromJson(
        Map<String, dynamic> json) =>
    _$KeyCustomizationImpl(
      serial: (json['serial'] as num).toInt(),
      name: json['name'] as String?,
      color: const _ColorConverter().fromJson((json['color'] as num?)?.toInt()),
    );

Map<String, dynamic> _$$KeyCustomizationImplToJson(
    _$KeyCustomizationImpl instance) {
  final val = <String, dynamic>{
    'serial': instance.serial,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('name', instance.name);
  writeNotNull('color', const _ColorConverter().toJson(instance.color));
  return val;
}
