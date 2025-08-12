// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_OtpState _$OtpStateFromJson(Map<String, dynamic> json) => _OtpState(
  slot1Configured: json['slot1_configured'] as bool,
  slot2Configured: json['slot2_configured'] as bool,
);

Map<String, dynamic> _$OtpStateToJson(_OtpState instance) => <String, dynamic>{
  'slot1_configured': instance.slot1Configured,
  'slot2_configured': instance.slot2Configured,
};

_SlotConfigurationOptions _$SlotConfigurationOptionsFromJson(
  Map<String, dynamic> json,
) => _SlotConfigurationOptions(
  digits8: json['digits8'] as bool?,
  requireTouch: json['require_touch'] as bool?,
  appendCr: json['append_cr'] as bool?,
);

Map<String, dynamic> _$SlotConfigurationOptionsToJson(
  _SlotConfigurationOptions instance,
) => <String, dynamic>{
  'digits8': ?instance.digits8,
  'require_touch': ?instance.requireTouch,
  'append_cr': ?instance.appendCr,
};

_SlotConfigurationHotp _$SlotConfigurationHotpFromJson(
  Map<String, dynamic> json,
) => _SlotConfigurationHotp(
  key: json['key'] as String,
  options: json['options'] == null
      ? null
      : SlotConfigurationOptions.fromJson(
          json['options'] as Map<String, dynamic>,
        ),
  $type: json['type'] as String?,
);

Map<String, dynamic> _$SlotConfigurationHotpToJson(
  _SlotConfigurationHotp instance,
) => <String, dynamic>{
  'key': instance.key,
  'options': ?instance.options?.toJson(),
  'type': instance.$type,
};

_SlotConfigurationHmacSha1 _$SlotConfigurationHmacSha1FromJson(
  Map<String, dynamic> json,
) => _SlotConfigurationHmacSha1(
  key: json['key'] as String,
  options: json['options'] == null
      ? null
      : SlotConfigurationOptions.fromJson(
          json['options'] as Map<String, dynamic>,
        ),
  $type: json['type'] as String?,
);

Map<String, dynamic> _$SlotConfigurationHmacSha1ToJson(
  _SlotConfigurationHmacSha1 instance,
) => <String, dynamic>{
  'key': instance.key,
  'options': ?instance.options?.toJson(),
  'type': instance.$type,
};

_SlotConfigurationStaticPassword _$SlotConfigurationStaticPasswordFromJson(
  Map<String, dynamic> json,
) => _SlotConfigurationStaticPassword(
  password: json['password'] as String,
  keyboardLayout: json['keyboard_layout'] as String,
  options: json['options'] == null
      ? null
      : SlotConfigurationOptions.fromJson(
          json['options'] as Map<String, dynamic>,
        ),
  $type: json['type'] as String?,
);

Map<String, dynamic> _$SlotConfigurationStaticPasswordToJson(
  _SlotConfigurationStaticPassword instance,
) => <String, dynamic>{
  'password': instance.password,
  'keyboard_layout': instance.keyboardLayout,
  'options': ?instance.options?.toJson(),
  'type': instance.$type,
};

_SlotConfigurationYubiOtp _$SlotConfigurationYubiOtpFromJson(
  Map<String, dynamic> json,
) => _SlotConfigurationYubiOtp(
  publicId: json['public_id'] as String,
  privateId: json['private_id'] as String,
  key: json['key'] as String,
  options: json['options'] == null
      ? null
      : SlotConfigurationOptions.fromJson(
          json['options'] as Map<String, dynamic>,
        ),
  $type: json['type'] as String?,
);

Map<String, dynamic> _$SlotConfigurationYubiOtpToJson(
  _SlotConfigurationYubiOtp instance,
) => <String, dynamic>{
  'public_id': instance.publicId,
  'private_id': instance.privateId,
  'key': instance.key,
  'options': ?instance.options?.toJson(),
  'type': instance.$type,
};
