// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$_DeviceConfig _$$_DeviceConfigFromJson(Map<String, dynamic> json) =>
    _$_DeviceConfig(
      (json['enabled_capabilities'] as Map<String, dynamic>).map(
        (k, e) => MapEntry($enumDecode(_$TransportEnumMap, k), e as int),
      ),
      json['auto_eject_timeout'] as int?,
      json['challenge_response_timeout'] as int?,
      json['device_flags'] as int?,
    );

Map<String, dynamic> _$$_DeviceConfigToJson(_$_DeviceConfig instance) =>
    <String, dynamic>{
      'enabled_capabilities': instance.enabledCapabilities
          .map((k, e) => MapEntry(_$TransportEnumMap[k], e)),
      'auto_eject_timeout': instance.autoEjectTimeout,
      'challenge_response_timeout': instance.challengeResponseTimeout,
      'device_flags': instance.deviceFlags,
    };

const _$TransportEnumMap = {
  Transport.usb: 'usb',
  Transport.nfc: 'nfc',
};

_$_DeviceInfo _$$_DeviceInfoFromJson(Map<String, dynamic> json) =>
    _$_DeviceInfo(
      DeviceConfig.fromJson(json['config'] as Map<String, dynamic>),
      json['serial'] as int?,
      Version.fromJson(json['version'] as List<dynamic>),
      $enumDecode(_$FormFactorEnumMap, json['form_factor']),
      (json['supported_capabilities'] as Map<String, dynamic>).map(
        (k, e) => MapEntry($enumDecode(_$TransportEnumMap, k), e as int),
      ),
      json['is_locked'] as bool,
      json['is_fips'] as bool,
      json['is_sky'] as bool,
    );

Map<String, dynamic> _$$_DeviceInfoToJson(_$_DeviceInfo instance) =>
    <String, dynamic>{
      'config': instance.config,
      'serial': instance.serial,
      'version': instance.version,
      'form_factor': _$FormFactorEnumMap[instance.formFactor],
      'supported_capabilities': instance.supportedCapabilities
          .map((k, e) => MapEntry(_$TransportEnumMap[k], e)),
      'is_locked': instance.isLocked,
      'is_fips': instance.isFips,
      'is_sky': instance.isSky,
    };

const _$FormFactorEnumMap = {
  FormFactor.unknown: 0,
  FormFactor.usbAKeychain: 1,
  FormFactor.usbANano: 2,
  FormFactor.usbCKeychain: 3,
  FormFactor.usbCNano: 4,
  FormFactor.usbCLightning: 5,
  FormFactor.usbABio: 6,
  FormFactor.usbCBio: 7,
};
