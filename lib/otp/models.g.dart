// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$OtpStateImpl _$$OtpStateImplFromJson(Map<String, dynamic> json) =>
    _$OtpStateImpl(
      slot1Configured: json['slot1_configured'] as bool,
      slot2Configured: json['slot2_configured'] as bool,
    );

Map<String, dynamic> _$$OtpStateImplToJson(_$OtpStateImpl instance) =>
    <String, dynamic>{
      'slot1_configured': instance.slot1Configured,
      'slot2_configured': instance.slot2Configured,
    };

_$SlotConfigurationOptionsImpl _$$SlotConfigurationOptionsImplFromJson(
        Map<String, dynamic> json) =>
    _$SlotConfigurationOptionsImpl(
      digits8: json['digits8'] as bool?,
      requireTouch: json['require_touch'] as bool?,
      appendCr: json['append_cr'] as bool?,
    );

Map<String, dynamic> _$$SlotConfigurationOptionsImplToJson(
        _$SlotConfigurationOptionsImpl instance) =>
    <String, dynamic>{
      if (instance.digits8 case final value?) 'digits8': value,
      if (instance.requireTouch case final value?) 'require_touch': value,
      if (instance.appendCr case final value?) 'append_cr': value,
    };

_$SlotConfigurationHotpImpl _$$SlotConfigurationHotpImplFromJson(
        Map<String, dynamic> json) =>
    _$SlotConfigurationHotpImpl(
      key: json['key'] as String,
      options: json['options'] == null
          ? null
          : SlotConfigurationOptions.fromJson(
              json['options'] as Map<String, dynamic>),
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$$SlotConfigurationHotpImplToJson(
        _$SlotConfigurationHotpImpl instance) =>
    <String, dynamic>{
      'key': instance.key,
      if (instance.options?.toJson() case final value?) 'options': value,
      'type': instance.$type,
    };

_$SlotConfigurationHmacSha1Impl _$$SlotConfigurationHmacSha1ImplFromJson(
        Map<String, dynamic> json) =>
    _$SlotConfigurationHmacSha1Impl(
      key: json['key'] as String,
      options: json['options'] == null
          ? null
          : SlotConfigurationOptions.fromJson(
              json['options'] as Map<String, dynamic>),
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$$SlotConfigurationHmacSha1ImplToJson(
        _$SlotConfigurationHmacSha1Impl instance) =>
    <String, dynamic>{
      'key': instance.key,
      if (instance.options?.toJson() case final value?) 'options': value,
      'type': instance.$type,
    };

_$SlotConfigurationStaticPasswordImpl
    _$$SlotConfigurationStaticPasswordImplFromJson(Map<String, dynamic> json) =>
        _$SlotConfigurationStaticPasswordImpl(
          password: json['password'] as String,
          keyboardLayout: json['keyboard_layout'] as String,
          options: json['options'] == null
              ? null
              : SlotConfigurationOptions.fromJson(
                  json['options'] as Map<String, dynamic>),
          $type: json['type'] as String?,
        );

Map<String, dynamic> _$$SlotConfigurationStaticPasswordImplToJson(
        _$SlotConfigurationStaticPasswordImpl instance) =>
    <String, dynamic>{
      'password': instance.password,
      'keyboard_layout': instance.keyboardLayout,
      if (instance.options?.toJson() case final value?) 'options': value,
      'type': instance.$type,
    };

_$SlotConfigurationYubiOtpImpl _$$SlotConfigurationYubiOtpImplFromJson(
        Map<String, dynamic> json) =>
    _$SlotConfigurationYubiOtpImpl(
      publicId: json['public_id'] as String,
      privateId: json['private_id'] as String,
      key: json['key'] as String,
      options: json['options'] == null
          ? null
          : SlotConfigurationOptions.fromJson(
              json['options'] as Map<String, dynamic>),
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$$SlotConfigurationYubiOtpImplToJson(
        _$SlotConfigurationYubiOtpImpl instance) =>
    <String, dynamic>{
      'public_id': instance.publicId,
      'private_id': instance.privateId,
      'key': instance.key,
      if (instance.options?.toJson() case final value?) 'options': value,
      'type': instance.$type,
    };
