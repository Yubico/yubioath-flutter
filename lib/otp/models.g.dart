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
    _$SlotConfigurationOptionsImpl instance) {
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
    _$SlotConfigurationHotpImpl instance) {
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
    _$SlotConfigurationHmacSha1Impl instance) {
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
    _$SlotConfigurationStaticPasswordImpl instance) {
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
    _$SlotConfigurationYubiOtpImpl instance) {
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
