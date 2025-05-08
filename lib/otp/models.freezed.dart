// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$OtpState {

 bool get slot1Configured; bool get slot2Configured;
/// Create a copy of OtpState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OtpStateCopyWith<OtpState> get copyWith => _$OtpStateCopyWithImpl<OtpState>(this as OtpState, _$identity);

  /// Serializes this OtpState to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OtpState&&(identical(other.slot1Configured, slot1Configured) || other.slot1Configured == slot1Configured)&&(identical(other.slot2Configured, slot2Configured) || other.slot2Configured == slot2Configured));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,slot1Configured,slot2Configured);

@override
String toString() {
  return 'OtpState(slot1Configured: $slot1Configured, slot2Configured: $slot2Configured)';
}


}

/// @nodoc
abstract mixin class $OtpStateCopyWith<$Res>  {
  factory $OtpStateCopyWith(OtpState value, $Res Function(OtpState) _then) = _$OtpStateCopyWithImpl;
@useResult
$Res call({
 bool slot1Configured, bool slot2Configured
});




}
/// @nodoc
class _$OtpStateCopyWithImpl<$Res>
    implements $OtpStateCopyWith<$Res> {
  _$OtpStateCopyWithImpl(this._self, this._then);

  final OtpState _self;
  final $Res Function(OtpState) _then;

/// Create a copy of OtpState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? slot1Configured = null,Object? slot2Configured = null,}) {
  return _then(_self.copyWith(
slot1Configured: null == slot1Configured ? _self.slot1Configured : slot1Configured // ignore: cast_nullable_to_non_nullable
as bool,slot2Configured: null == slot2Configured ? _self.slot2Configured : slot2Configured // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _OtpState extends OtpState {
   _OtpState({required this.slot1Configured, required this.slot2Configured}): super._();
  factory _OtpState.fromJson(Map<String, dynamic> json) => _$OtpStateFromJson(json);

@override final  bool slot1Configured;
@override final  bool slot2Configured;

/// Create a copy of OtpState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OtpStateCopyWith<_OtpState> get copyWith => __$OtpStateCopyWithImpl<_OtpState>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OtpStateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OtpState&&(identical(other.slot1Configured, slot1Configured) || other.slot1Configured == slot1Configured)&&(identical(other.slot2Configured, slot2Configured) || other.slot2Configured == slot2Configured));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,slot1Configured,slot2Configured);

@override
String toString() {
  return 'OtpState(slot1Configured: $slot1Configured, slot2Configured: $slot2Configured)';
}


}

/// @nodoc
abstract mixin class _$OtpStateCopyWith<$Res> implements $OtpStateCopyWith<$Res> {
  factory _$OtpStateCopyWith(_OtpState value, $Res Function(_OtpState) _then) = __$OtpStateCopyWithImpl;
@override @useResult
$Res call({
 bool slot1Configured, bool slot2Configured
});




}
/// @nodoc
class __$OtpStateCopyWithImpl<$Res>
    implements _$OtpStateCopyWith<$Res> {
  __$OtpStateCopyWithImpl(this._self, this._then);

  final _OtpState _self;
  final $Res Function(_OtpState) _then;

/// Create a copy of OtpState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? slot1Configured = null,Object? slot2Configured = null,}) {
  return _then(_OtpState(
slot1Configured: null == slot1Configured ? _self.slot1Configured : slot1Configured // ignore: cast_nullable_to_non_nullable
as bool,slot2Configured: null == slot2Configured ? _self.slot2Configured : slot2Configured // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$OtpSlot {

 SlotId get slot; bool get isConfigured;
/// Create a copy of OtpSlot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OtpSlotCopyWith<OtpSlot> get copyWith => _$OtpSlotCopyWithImpl<OtpSlot>(this as OtpSlot, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OtpSlot&&(identical(other.slot, slot) || other.slot == slot)&&(identical(other.isConfigured, isConfigured) || other.isConfigured == isConfigured));
}


@override
int get hashCode => Object.hash(runtimeType,slot,isConfigured);

@override
String toString() {
  return 'OtpSlot(slot: $slot, isConfigured: $isConfigured)';
}


}

/// @nodoc
abstract mixin class $OtpSlotCopyWith<$Res>  {
  factory $OtpSlotCopyWith(OtpSlot value, $Res Function(OtpSlot) _then) = _$OtpSlotCopyWithImpl;
@useResult
$Res call({
 SlotId slot, bool isConfigured
});




}
/// @nodoc
class _$OtpSlotCopyWithImpl<$Res>
    implements $OtpSlotCopyWith<$Res> {
  _$OtpSlotCopyWithImpl(this._self, this._then);

  final OtpSlot _self;
  final $Res Function(OtpSlot) _then;

/// Create a copy of OtpSlot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? slot = null,Object? isConfigured = null,}) {
  return _then(_self.copyWith(
slot: null == slot ? _self.slot : slot // ignore: cast_nullable_to_non_nullable
as SlotId,isConfigured: null == isConfigured ? _self.isConfigured : isConfigured // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// @nodoc


class _OtpSlot implements OtpSlot {
   _OtpSlot({required this.slot, required this.isConfigured});
  

@override final  SlotId slot;
@override final  bool isConfigured;

/// Create a copy of OtpSlot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OtpSlotCopyWith<_OtpSlot> get copyWith => __$OtpSlotCopyWithImpl<_OtpSlot>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OtpSlot&&(identical(other.slot, slot) || other.slot == slot)&&(identical(other.isConfigured, isConfigured) || other.isConfigured == isConfigured));
}


@override
int get hashCode => Object.hash(runtimeType,slot,isConfigured);

@override
String toString() {
  return 'OtpSlot(slot: $slot, isConfigured: $isConfigured)';
}


}

/// @nodoc
abstract mixin class _$OtpSlotCopyWith<$Res> implements $OtpSlotCopyWith<$Res> {
  factory _$OtpSlotCopyWith(_OtpSlot value, $Res Function(_OtpSlot) _then) = __$OtpSlotCopyWithImpl;
@override @useResult
$Res call({
 SlotId slot, bool isConfigured
});




}
/// @nodoc
class __$OtpSlotCopyWithImpl<$Res>
    implements _$OtpSlotCopyWith<$Res> {
  __$OtpSlotCopyWithImpl(this._self, this._then);

  final _OtpSlot _self;
  final $Res Function(_OtpSlot) _then;

/// Create a copy of OtpSlot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? slot = null,Object? isConfigured = null,}) {
  return _then(_OtpSlot(
slot: null == slot ? _self.slot : slot // ignore: cast_nullable_to_non_nullable
as SlotId,isConfigured: null == isConfigured ? _self.isConfigured : isConfigured // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$SlotConfigurationOptions {

 bool? get digits8; bool? get requireTouch; bool? get appendCr;
/// Create a copy of SlotConfigurationOptions
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SlotConfigurationOptionsCopyWith<SlotConfigurationOptions> get copyWith => _$SlotConfigurationOptionsCopyWithImpl<SlotConfigurationOptions>(this as SlotConfigurationOptions, _$identity);

  /// Serializes this SlotConfigurationOptions to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SlotConfigurationOptions&&(identical(other.digits8, digits8) || other.digits8 == digits8)&&(identical(other.requireTouch, requireTouch) || other.requireTouch == requireTouch)&&(identical(other.appendCr, appendCr) || other.appendCr == appendCr));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,digits8,requireTouch,appendCr);

@override
String toString() {
  return 'SlotConfigurationOptions(digits8: $digits8, requireTouch: $requireTouch, appendCr: $appendCr)';
}


}

/// @nodoc
abstract mixin class $SlotConfigurationOptionsCopyWith<$Res>  {
  factory $SlotConfigurationOptionsCopyWith(SlotConfigurationOptions value, $Res Function(SlotConfigurationOptions) _then) = _$SlotConfigurationOptionsCopyWithImpl;
@useResult
$Res call({
 bool? digits8, bool? requireTouch, bool? appendCr
});




}
/// @nodoc
class _$SlotConfigurationOptionsCopyWithImpl<$Res>
    implements $SlotConfigurationOptionsCopyWith<$Res> {
  _$SlotConfigurationOptionsCopyWithImpl(this._self, this._then);

  final SlotConfigurationOptions _self;
  final $Res Function(SlotConfigurationOptions) _then;

/// Create a copy of SlotConfigurationOptions
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? digits8 = freezed,Object? requireTouch = freezed,Object? appendCr = freezed,}) {
  return _then(_self.copyWith(
digits8: freezed == digits8 ? _self.digits8 : digits8 // ignore: cast_nullable_to_non_nullable
as bool?,requireTouch: freezed == requireTouch ? _self.requireTouch : requireTouch // ignore: cast_nullable_to_non_nullable
as bool?,appendCr: freezed == appendCr ? _self.appendCr : appendCr // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

}


/// @nodoc

@JsonSerializable(includeIfNull: false)
class _SlotConfigurationOptions implements SlotConfigurationOptions {
   _SlotConfigurationOptions({this.digits8, this.requireTouch, this.appendCr});
  factory _SlotConfigurationOptions.fromJson(Map<String, dynamic> json) => _$SlotConfigurationOptionsFromJson(json);

@override final  bool? digits8;
@override final  bool? requireTouch;
@override final  bool? appendCr;

/// Create a copy of SlotConfigurationOptions
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SlotConfigurationOptionsCopyWith<_SlotConfigurationOptions> get copyWith => __$SlotConfigurationOptionsCopyWithImpl<_SlotConfigurationOptions>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SlotConfigurationOptionsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SlotConfigurationOptions&&(identical(other.digits8, digits8) || other.digits8 == digits8)&&(identical(other.requireTouch, requireTouch) || other.requireTouch == requireTouch)&&(identical(other.appendCr, appendCr) || other.appendCr == appendCr));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,digits8,requireTouch,appendCr);

@override
String toString() {
  return 'SlotConfigurationOptions(digits8: $digits8, requireTouch: $requireTouch, appendCr: $appendCr)';
}


}

/// @nodoc
abstract mixin class _$SlotConfigurationOptionsCopyWith<$Res> implements $SlotConfigurationOptionsCopyWith<$Res> {
  factory _$SlotConfigurationOptionsCopyWith(_SlotConfigurationOptions value, $Res Function(_SlotConfigurationOptions) _then) = __$SlotConfigurationOptionsCopyWithImpl;
@override @useResult
$Res call({
 bool? digits8, bool? requireTouch, bool? appendCr
});




}
/// @nodoc
class __$SlotConfigurationOptionsCopyWithImpl<$Res>
    implements _$SlotConfigurationOptionsCopyWith<$Res> {
  __$SlotConfigurationOptionsCopyWithImpl(this._self, this._then);

  final _SlotConfigurationOptions _self;
  final $Res Function(_SlotConfigurationOptions) _then;

/// Create a copy of SlotConfigurationOptions
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? digits8 = freezed,Object? requireTouch = freezed,Object? appendCr = freezed,}) {
  return _then(_SlotConfigurationOptions(
digits8: freezed == digits8 ? _self.digits8 : digits8 // ignore: cast_nullable_to_non_nullable
as bool?,requireTouch: freezed == requireTouch ? _self.requireTouch : requireTouch // ignore: cast_nullable_to_non_nullable
as bool?,appendCr: freezed == appendCr ? _self.appendCr : appendCr // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}


}

SlotConfiguration _$SlotConfigurationFromJson(
  Map<String, dynamic> json
) {
        switch (json['type']) {
                  case 'hotp':
          return _SlotConfigurationHotp.fromJson(
            json
          );
                case 'hmac_sha1':
          return _SlotConfigurationHmacSha1.fromJson(
            json
          );
                case 'static_password':
          return _SlotConfigurationStaticPassword.fromJson(
            json
          );
                case 'yubiotp':
          return _SlotConfigurationYubiOtp.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'type',
  'SlotConfiguration',
  'Invalid union type "${json['type']}"!'
);
        }
      
}

/// @nodoc
mixin _$SlotConfiguration {

 SlotConfigurationOptions? get options;
/// Create a copy of SlotConfiguration
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SlotConfigurationCopyWith<SlotConfiguration> get copyWith => _$SlotConfigurationCopyWithImpl<SlotConfiguration>(this as SlotConfiguration, _$identity);

  /// Serializes this SlotConfiguration to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SlotConfiguration&&(identical(other.options, options) || other.options == options));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,options);

@override
String toString() {
  return 'SlotConfiguration(options: $options)';
}


}

/// @nodoc
abstract mixin class $SlotConfigurationCopyWith<$Res>  {
  factory $SlotConfigurationCopyWith(SlotConfiguration value, $Res Function(SlotConfiguration) _then) = _$SlotConfigurationCopyWithImpl;
@useResult
$Res call({
 SlotConfigurationOptions? options
});


$SlotConfigurationOptionsCopyWith<$Res>? get options;

}
/// @nodoc
class _$SlotConfigurationCopyWithImpl<$Res>
    implements $SlotConfigurationCopyWith<$Res> {
  _$SlotConfigurationCopyWithImpl(this._self, this._then);

  final SlotConfiguration _self;
  final $Res Function(SlotConfiguration) _then;

/// Create a copy of SlotConfiguration
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? options = freezed,}) {
  return _then(_self.copyWith(
options: freezed == options ? _self.options : options // ignore: cast_nullable_to_non_nullable
as SlotConfigurationOptions?,
  ));
}
/// Create a copy of SlotConfiguration
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SlotConfigurationOptionsCopyWith<$Res>? get options {
    if (_self.options == null) {
    return null;
  }

  return $SlotConfigurationOptionsCopyWith<$Res>(_self.options!, (value) {
    return _then(_self.copyWith(options: value));
  });
}
}


/// @nodoc

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class _SlotConfigurationHotp extends SlotConfiguration {
  const _SlotConfigurationHotp({required this.key, this.options, final  String? $type}): $type = $type ?? 'hotp',super._();
  factory _SlotConfigurationHotp.fromJson(Map<String, dynamic> json) => _$SlotConfigurationHotpFromJson(json);

 final  String key;
@override final  SlotConfigurationOptions? options;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of SlotConfiguration
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SlotConfigurationHotpCopyWith<_SlotConfigurationHotp> get copyWith => __$SlotConfigurationHotpCopyWithImpl<_SlotConfigurationHotp>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SlotConfigurationHotpToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SlotConfigurationHotp&&(identical(other.key, key) || other.key == key)&&(identical(other.options, options) || other.options == options));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,key,options);

@override
String toString() {
  return 'SlotConfiguration.hotp(key: $key, options: $options)';
}


}

/// @nodoc
abstract mixin class _$SlotConfigurationHotpCopyWith<$Res> implements $SlotConfigurationCopyWith<$Res> {
  factory _$SlotConfigurationHotpCopyWith(_SlotConfigurationHotp value, $Res Function(_SlotConfigurationHotp) _then) = __$SlotConfigurationHotpCopyWithImpl;
@override @useResult
$Res call({
 String key, SlotConfigurationOptions? options
});


@override $SlotConfigurationOptionsCopyWith<$Res>? get options;

}
/// @nodoc
class __$SlotConfigurationHotpCopyWithImpl<$Res>
    implements _$SlotConfigurationHotpCopyWith<$Res> {
  __$SlotConfigurationHotpCopyWithImpl(this._self, this._then);

  final _SlotConfigurationHotp _self;
  final $Res Function(_SlotConfigurationHotp) _then;

/// Create a copy of SlotConfiguration
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? key = null,Object? options = freezed,}) {
  return _then(_SlotConfigurationHotp(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,options: freezed == options ? _self.options : options // ignore: cast_nullable_to_non_nullable
as SlotConfigurationOptions?,
  ));
}

/// Create a copy of SlotConfiguration
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SlotConfigurationOptionsCopyWith<$Res>? get options {
    if (_self.options == null) {
    return null;
  }

  return $SlotConfigurationOptionsCopyWith<$Res>(_self.options!, (value) {
    return _then(_self.copyWith(options: value));
  });
}
}

/// @nodoc

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class _SlotConfigurationHmacSha1 extends SlotConfiguration {
  const _SlotConfigurationHmacSha1({required this.key, this.options, final  String? $type}): $type = $type ?? 'hmac_sha1',super._();
  factory _SlotConfigurationHmacSha1.fromJson(Map<String, dynamic> json) => _$SlotConfigurationHmacSha1FromJson(json);

 final  String key;
@override final  SlotConfigurationOptions? options;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of SlotConfiguration
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SlotConfigurationHmacSha1CopyWith<_SlotConfigurationHmacSha1> get copyWith => __$SlotConfigurationHmacSha1CopyWithImpl<_SlotConfigurationHmacSha1>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SlotConfigurationHmacSha1ToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SlotConfigurationHmacSha1&&(identical(other.key, key) || other.key == key)&&(identical(other.options, options) || other.options == options));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,key,options);

@override
String toString() {
  return 'SlotConfiguration.chalresp(key: $key, options: $options)';
}


}

/// @nodoc
abstract mixin class _$SlotConfigurationHmacSha1CopyWith<$Res> implements $SlotConfigurationCopyWith<$Res> {
  factory _$SlotConfigurationHmacSha1CopyWith(_SlotConfigurationHmacSha1 value, $Res Function(_SlotConfigurationHmacSha1) _then) = __$SlotConfigurationHmacSha1CopyWithImpl;
@override @useResult
$Res call({
 String key, SlotConfigurationOptions? options
});


@override $SlotConfigurationOptionsCopyWith<$Res>? get options;

}
/// @nodoc
class __$SlotConfigurationHmacSha1CopyWithImpl<$Res>
    implements _$SlotConfigurationHmacSha1CopyWith<$Res> {
  __$SlotConfigurationHmacSha1CopyWithImpl(this._self, this._then);

  final _SlotConfigurationHmacSha1 _self;
  final $Res Function(_SlotConfigurationHmacSha1) _then;

/// Create a copy of SlotConfiguration
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? key = null,Object? options = freezed,}) {
  return _then(_SlotConfigurationHmacSha1(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,options: freezed == options ? _self.options : options // ignore: cast_nullable_to_non_nullable
as SlotConfigurationOptions?,
  ));
}

/// Create a copy of SlotConfiguration
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SlotConfigurationOptionsCopyWith<$Res>? get options {
    if (_self.options == null) {
    return null;
  }

  return $SlotConfigurationOptionsCopyWith<$Res>(_self.options!, (value) {
    return _then(_self.copyWith(options: value));
  });
}
}

/// @nodoc

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class _SlotConfigurationStaticPassword extends SlotConfiguration {
  const _SlotConfigurationStaticPassword({required this.password, required this.keyboardLayout, this.options, final  String? $type}): $type = $type ?? 'static_password',super._();
  factory _SlotConfigurationStaticPassword.fromJson(Map<String, dynamic> json) => _$SlotConfigurationStaticPasswordFromJson(json);

 final  String password;
 final  String keyboardLayout;
@override final  SlotConfigurationOptions? options;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of SlotConfiguration
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SlotConfigurationStaticPasswordCopyWith<_SlotConfigurationStaticPassword> get copyWith => __$SlotConfigurationStaticPasswordCopyWithImpl<_SlotConfigurationStaticPassword>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SlotConfigurationStaticPasswordToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SlotConfigurationStaticPassword&&(identical(other.password, password) || other.password == password)&&(identical(other.keyboardLayout, keyboardLayout) || other.keyboardLayout == keyboardLayout)&&(identical(other.options, options) || other.options == options));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,password,keyboardLayout,options);

@override
String toString() {
  return 'SlotConfiguration.static(password: $password, keyboardLayout: $keyboardLayout, options: $options)';
}


}

/// @nodoc
abstract mixin class _$SlotConfigurationStaticPasswordCopyWith<$Res> implements $SlotConfigurationCopyWith<$Res> {
  factory _$SlotConfigurationStaticPasswordCopyWith(_SlotConfigurationStaticPassword value, $Res Function(_SlotConfigurationStaticPassword) _then) = __$SlotConfigurationStaticPasswordCopyWithImpl;
@override @useResult
$Res call({
 String password, String keyboardLayout, SlotConfigurationOptions? options
});


@override $SlotConfigurationOptionsCopyWith<$Res>? get options;

}
/// @nodoc
class __$SlotConfigurationStaticPasswordCopyWithImpl<$Res>
    implements _$SlotConfigurationStaticPasswordCopyWith<$Res> {
  __$SlotConfigurationStaticPasswordCopyWithImpl(this._self, this._then);

  final _SlotConfigurationStaticPassword _self;
  final $Res Function(_SlotConfigurationStaticPassword) _then;

/// Create a copy of SlotConfiguration
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? password = null,Object? keyboardLayout = null,Object? options = freezed,}) {
  return _then(_SlotConfigurationStaticPassword(
password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,keyboardLayout: null == keyboardLayout ? _self.keyboardLayout : keyboardLayout // ignore: cast_nullable_to_non_nullable
as String,options: freezed == options ? _self.options : options // ignore: cast_nullable_to_non_nullable
as SlotConfigurationOptions?,
  ));
}

/// Create a copy of SlotConfiguration
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SlotConfigurationOptionsCopyWith<$Res>? get options {
    if (_self.options == null) {
    return null;
  }

  return $SlotConfigurationOptionsCopyWith<$Res>(_self.options!, (value) {
    return _then(_self.copyWith(options: value));
  });
}
}

/// @nodoc

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class _SlotConfigurationYubiOtp extends SlotConfiguration {
  const _SlotConfigurationYubiOtp({required this.publicId, required this.privateId, required this.key, this.options, final  String? $type}): $type = $type ?? 'yubiotp',super._();
  factory _SlotConfigurationYubiOtp.fromJson(Map<String, dynamic> json) => _$SlotConfigurationYubiOtpFromJson(json);

 final  String publicId;
 final  String privateId;
 final  String key;
@override final  SlotConfigurationOptions? options;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of SlotConfiguration
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SlotConfigurationYubiOtpCopyWith<_SlotConfigurationYubiOtp> get copyWith => __$SlotConfigurationYubiOtpCopyWithImpl<_SlotConfigurationYubiOtp>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SlotConfigurationYubiOtpToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SlotConfigurationYubiOtp&&(identical(other.publicId, publicId) || other.publicId == publicId)&&(identical(other.privateId, privateId) || other.privateId == privateId)&&(identical(other.key, key) || other.key == key)&&(identical(other.options, options) || other.options == options));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,publicId,privateId,key,options);

@override
String toString() {
  return 'SlotConfiguration.yubiotp(publicId: $publicId, privateId: $privateId, key: $key, options: $options)';
}


}

/// @nodoc
abstract mixin class _$SlotConfigurationYubiOtpCopyWith<$Res> implements $SlotConfigurationCopyWith<$Res> {
  factory _$SlotConfigurationYubiOtpCopyWith(_SlotConfigurationYubiOtp value, $Res Function(_SlotConfigurationYubiOtp) _then) = __$SlotConfigurationYubiOtpCopyWithImpl;
@override @useResult
$Res call({
 String publicId, String privateId, String key, SlotConfigurationOptions? options
});


@override $SlotConfigurationOptionsCopyWith<$Res>? get options;

}
/// @nodoc
class __$SlotConfigurationYubiOtpCopyWithImpl<$Res>
    implements _$SlotConfigurationYubiOtpCopyWith<$Res> {
  __$SlotConfigurationYubiOtpCopyWithImpl(this._self, this._then);

  final _SlotConfigurationYubiOtp _self;
  final $Res Function(_SlotConfigurationYubiOtp) _then;

/// Create a copy of SlotConfiguration
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? publicId = null,Object? privateId = null,Object? key = null,Object? options = freezed,}) {
  return _then(_SlotConfigurationYubiOtp(
publicId: null == publicId ? _self.publicId : publicId // ignore: cast_nullable_to_non_nullable
as String,privateId: null == privateId ? _self.privateId : privateId // ignore: cast_nullable_to_non_nullable
as String,key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,options: freezed == options ? _self.options : options // ignore: cast_nullable_to_non_nullable
as SlotConfigurationOptions?,
  ));
}

/// Create a copy of SlotConfiguration
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SlotConfigurationOptionsCopyWith<$Res>? get options {
    if (_self.options == null) {
    return null;
  }

  return $SlotConfigurationOptionsCopyWith<$Res>(_self.options!, (value) {
    return _then(_self.copyWith(options: value));
  });
}
}

// dart format on
