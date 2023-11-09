// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$_OtpState _$$_OtpStateFromJson(Map<String, dynamic> json) => _$_OtpState(
      slot1Configured: json['slot1_configured'] as bool,
      slot2Configured: json['slot2_configured'] as bool,
    );

Map<String, dynamic> _$$_OtpStateToJson(_$_OtpState instance) =>
    <String, dynamic>{
      'slot1_configured': instance.slot1Configured,
      'slot2_configured': instance.slot2Configured,
    };

_$_SlotConfigurationOptions _$$_SlotConfigurationOptionsFromJson(
        Map<String, dynamic> json) =>
    _$_SlotConfigurationOptions(
      digits8: json['digits8'] as bool?,
      requireTouch: json['require_touch'] as bool?,
      appendCr: json['append_cr'] as bool?,
    );

Map<String, dynamic> _$$_SlotConfigurationOptionsToJson(
    _$_SlotConfigurationOptions instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('digits8', instance.digits8);
  writeNotNull('require_touch', instance.requireTouch);
  writeNotNull('append_cr', instance.appendCr);
  return val;
}

_$_SlotConfigurationHotp _$$_SlotConfigurationHotpFromJson(
        Map<String, dynamic> json) =>
    _$_SlotConfigurationHotp(
      key: json['key'] as String,
      options: json['options'] == null
          ? null
          : SlotConfigurationOptions.fromJson(
              json['options'] as Map<String, dynamic>),
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$$_SlotConfigurationHotpToJson(
    _$_SlotConfigurationHotp instance) {
  final val = <String, dynamic>{
    'key': instance.key,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('options', instance.options?.toJson());
  val['type'] = instance.$type;
  return val;
}

_$_SlotConfigurationHmacSha1 _$$_SlotConfigurationHmacSha1FromJson(
        Map<String, dynamic> json) =>
    _$_SlotConfigurationHmacSha1(
      key: json['key'] as String,
      options: json['options'] == null
          ? null
          : SlotConfigurationOptions.fromJson(
              json['options'] as Map<String, dynamic>),
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$$_SlotConfigurationHmacSha1ToJson(
    _$_SlotConfigurationHmacSha1 instance) {
  final val = <String, dynamic>{
    'key': instance.key,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('options', instance.options?.toJson());
  val['type'] = instance.$type;
  return val;
}

_$_SlotConfigurationStaticPassword _$$_SlotConfigurationStaticPasswordFromJson(
        Map<String, dynamic> json) =>
    _$_SlotConfigurationStaticPassword(
      password: json['password'] as String,
      keyboardLayout: json['keyboard_layout'] as String,
      options: json['options'] == null
          ? null
          : SlotConfigurationOptions.fromJson(
              json['options'] as Map<String, dynamic>),
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$$_SlotConfigurationStaticPasswordToJson(
    _$_SlotConfigurationStaticPassword instance) {
  final val = <String, dynamic>{
    'password': instance.password,
    'keyboard_layout': instance.keyboardLayout,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('options', instance.options?.toJson());
  val['type'] = instance.$type;
  return val;
}

_$_SlotConfigurationYubiOtp _$$_SlotConfigurationYubiOtpFromJson(
        Map<String, dynamic> json) =>
    _$_SlotConfigurationYubiOtp(
      publicId: json['public_id'] as String,
      privateId: json['private_id'] as String,
      key: json['key'] as String,
      options: json['options'] == null
          ? null
          : SlotConfigurationOptions.fromJson(
              json['options'] as Map<String, dynamic>),
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$$_SlotConfigurationYubiOtpToJson(
    _$_SlotConfigurationYubiOtp instance) {
  final val = <String, dynamic>{
    'public_id': instance.publicId,
    'private_id': instance.privateId,
    'key': instance.key,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('options', instance.options?.toJson());
  val['type'] = instance.$type;
  return val;
}
