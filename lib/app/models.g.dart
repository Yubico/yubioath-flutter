// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$_DeviceNode _$$_DeviceNodeFromJson(Map<String, dynamic> json) =>
    _$_DeviceNode(
      (json['path'] as List<dynamic>).map((e) => e as String).toList(),
      json['pid'] as int,
      $enumDecode(_$TransportEnumMap, json['transport']),
      json['name'] as String,
      DeviceInfo.fromJson(json['info'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$_DeviceNodeToJson(_$_DeviceNode instance) =>
    <String, dynamic>{
      'path': instance.path,
      'pid': instance.pid,
      'transport': _$TransportEnumMap[instance.transport],
      'name': instance.name,
      'info': instance.info,
    };

const _$TransportEnumMap = {
  Transport.usb: 'usb',
  Transport.nfc: 'nfc',
};
