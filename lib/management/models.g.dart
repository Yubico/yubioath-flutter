// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DeviceConfigImpl _$$DeviceConfigImplFromJson(Map<String, dynamic> json) =>
    _$DeviceConfigImpl(
      (json['enabled_capabilities'] as Map<String, dynamic>).map(
        (k, e) =>
            MapEntry($enumDecode(_$TransportEnumMap, k), (e as num).toInt()),
      ),
      (json['auto_eject_timeout'] as num?)?.toInt(),
      (json['challenge_response_timeout'] as num?)?.toInt(),
      (json['device_flags'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$DeviceConfigImplToJson(_$DeviceConfigImpl instance) =>
    <String, dynamic>{
      'enabled_capabilities': instance.enabledCapabilities
          .map((k, e) => MapEntry(_$TransportEnumMap[k]!, e)),
      'auto_eject_timeout': instance.autoEjectTimeout,
      'challenge_response_timeout': instance.challengeResponseTimeout,
      'device_flags': instance.deviceFlags,
    };

const _$TransportEnumMap = {
  Transport.usb: 'usb',
  Transport.nfc: 'nfc',
};

_$DeviceInfoImpl _$$DeviceInfoImplFromJson(Map<String, dynamic> json) =>
    _$DeviceInfoImpl(
      DeviceConfig.fromJson(json['config'] as Map<String, dynamic>),
      (json['serial'] as num?)?.toInt(),
      Version.fromJson(json['version'] as List<dynamic>),
      $enumDecode(_$FormFactorEnumMap, json['form_factor']),
      (json['supported_capabilities'] as Map<String, dynamic>).map(
        (k, e) =>
            MapEntry($enumDecode(_$TransportEnumMap, k), (e as num).toInt()),
      ),
      json['is_locked'] as bool,
      json['is_fips'] as bool,
      json['is_sky'] as bool,
      json['pin_complexity'] as bool,
      (json['fips_capable'] as num).toInt(),
      (json['fips_approved'] as num).toInt(),
      (json['reset_blocked'] as num).toInt(),
    );

Map<String, dynamic> _$$DeviceInfoImplToJson(_$DeviceInfoImpl instance) =>
    <String, dynamic>{
      'config': instance.config,
      'serial': instance.serial,
      'version': instance.version,
      'form_factor': _$FormFactorEnumMap[instance.formFactor]!,
      'supported_capabilities': instance.supportedCapabilities
          .map((k, e) => MapEntry(_$TransportEnumMap[k]!, e)),
      'is_locked': instance.isLocked,
      'is_fips': instance.isFips,
      'is_sky': instance.isSky,
      'pin_complexity': instance.pinComplexity,
      'fips_capable': instance.fipsCapable,
      'fips_approved': instance.fipsApproved,
      'reset_blocked': instance.resetBlocked,
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
