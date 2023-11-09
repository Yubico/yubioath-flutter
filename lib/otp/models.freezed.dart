// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

OtpState _$OtpStateFromJson(Map<String, dynamic> json) {
  return _OtpState.fromJson(json);
}

/// @nodoc
mixin _$OtpState {
  bool get slot1Configured => throw _privateConstructorUsedError;
  bool get slot2Configured => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $OtpStateCopyWith<OtpState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OtpStateCopyWith<$Res> {
  factory $OtpStateCopyWith(OtpState value, $Res Function(OtpState) then) =
      _$OtpStateCopyWithImpl<$Res, OtpState>;
  @useResult
  $Res call({bool slot1Configured, bool slot2Configured});
}

/// @nodoc
class _$OtpStateCopyWithImpl<$Res, $Val extends OtpState>
    implements $OtpStateCopyWith<$Res> {
  _$OtpStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? slot1Configured = null,
    Object? slot2Configured = null,
  }) {
    return _then(_value.copyWith(
      slot1Configured: null == slot1Configured
          ? _value.slot1Configured
          : slot1Configured // ignore: cast_nullable_to_non_nullable
              as bool,
      slot2Configured: null == slot2Configured
          ? _value.slot2Configured
          : slot2Configured // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$_OtpStateCopyWith<$Res> implements $OtpStateCopyWith<$Res> {
  factory _$$_OtpStateCopyWith(
          _$_OtpState value, $Res Function(_$_OtpState) then) =
      __$$_OtpStateCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({bool slot1Configured, bool slot2Configured});
}

/// @nodoc
class __$$_OtpStateCopyWithImpl<$Res>
    extends _$OtpStateCopyWithImpl<$Res, _$_OtpState>
    implements _$$_OtpStateCopyWith<$Res> {
  __$$_OtpStateCopyWithImpl(
      _$_OtpState _value, $Res Function(_$_OtpState) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? slot1Configured = null,
    Object? slot2Configured = null,
  }) {
    return _then(_$_OtpState(
      slot1Configured: null == slot1Configured
          ? _value.slot1Configured
          : slot1Configured // ignore: cast_nullable_to_non_nullable
              as bool,
      slot2Configured: null == slot2Configured
          ? _value.slot2Configured
          : slot2Configured // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$_OtpState extends _OtpState {
  _$_OtpState({required this.slot1Configured, required this.slot2Configured})
      : super._();

  factory _$_OtpState.fromJson(Map<String, dynamic> json) =>
      _$$_OtpStateFromJson(json);

  @override
  final bool slot1Configured;
  @override
  final bool slot2Configured;

  @override
  String toString() {
    return 'OtpState(slot1Configured: $slot1Configured, slot2Configured: $slot2Configured)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_OtpState &&
            (identical(other.slot1Configured, slot1Configured) ||
                other.slot1Configured == slot1Configured) &&
            (identical(other.slot2Configured, slot2Configured) ||
                other.slot2Configured == slot2Configured));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, slot1Configured, slot2Configured);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_OtpStateCopyWith<_$_OtpState> get copyWith =>
      __$$_OtpStateCopyWithImpl<_$_OtpState>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_OtpStateToJson(
      this,
    );
  }
}

abstract class _OtpState extends OtpState {
  factory _OtpState(
      {required final bool slot1Configured,
      required final bool slot2Configured}) = _$_OtpState;
  _OtpState._() : super._();

  factory _OtpState.fromJson(Map<String, dynamic> json) = _$_OtpState.fromJson;

  @override
  bool get slot1Configured;
  @override
  bool get slot2Configured;
  @override
  @JsonKey(ignore: true)
  _$$_OtpStateCopyWith<_$_OtpState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$OtpSlot {
  SlotId get slot => throw _privateConstructorUsedError;
  bool get isConfigured => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $OtpSlotCopyWith<OtpSlot> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OtpSlotCopyWith<$Res> {
  factory $OtpSlotCopyWith(OtpSlot value, $Res Function(OtpSlot) then) =
      _$OtpSlotCopyWithImpl<$Res, OtpSlot>;
  @useResult
  $Res call({SlotId slot, bool isConfigured});
}

/// @nodoc
class _$OtpSlotCopyWithImpl<$Res, $Val extends OtpSlot>
    implements $OtpSlotCopyWith<$Res> {
  _$OtpSlotCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? slot = null,
    Object? isConfigured = null,
  }) {
    return _then(_value.copyWith(
      slot: null == slot
          ? _value.slot
          : slot // ignore: cast_nullable_to_non_nullable
              as SlotId,
      isConfigured: null == isConfigured
          ? _value.isConfigured
          : isConfigured // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$_OtpSlotCopyWith<$Res> implements $OtpSlotCopyWith<$Res> {
  factory _$$_OtpSlotCopyWith(
          _$_OtpSlot value, $Res Function(_$_OtpSlot) then) =
      __$$_OtpSlotCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({SlotId slot, bool isConfigured});
}

/// @nodoc
class __$$_OtpSlotCopyWithImpl<$Res>
    extends _$OtpSlotCopyWithImpl<$Res, _$_OtpSlot>
    implements _$$_OtpSlotCopyWith<$Res> {
  __$$_OtpSlotCopyWithImpl(_$_OtpSlot _value, $Res Function(_$_OtpSlot) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? slot = null,
    Object? isConfigured = null,
  }) {
    return _then(_$_OtpSlot(
      slot: null == slot
          ? _value.slot
          : slot // ignore: cast_nullable_to_non_nullable
              as SlotId,
      isConfigured: null == isConfigured
          ? _value.isConfigured
          : isConfigured // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$_OtpSlot implements _OtpSlot {
  _$_OtpSlot({required this.slot, required this.isConfigured});

  @override
  final SlotId slot;
  @override
  final bool isConfigured;

  @override
  String toString() {
    return 'OtpSlot(slot: $slot, isConfigured: $isConfigured)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_OtpSlot &&
            (identical(other.slot, slot) || other.slot == slot) &&
            (identical(other.isConfigured, isConfigured) ||
                other.isConfigured == isConfigured));
  }

  @override
  int get hashCode => Object.hash(runtimeType, slot, isConfigured);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_OtpSlotCopyWith<_$_OtpSlot> get copyWith =>
      __$$_OtpSlotCopyWithImpl<_$_OtpSlot>(this, _$identity);
}

abstract class _OtpSlot implements OtpSlot {
  factory _OtpSlot(
      {required final SlotId slot,
      required final bool isConfigured}) = _$_OtpSlot;

  @override
  SlotId get slot;
  @override
  bool get isConfigured;
  @override
  @JsonKey(ignore: true)
  _$$_OtpSlotCopyWith<_$_OtpSlot> get copyWith =>
      throw _privateConstructorUsedError;
}

SlotConfigurationOptions _$SlotConfigurationOptionsFromJson(
    Map<String, dynamic> json) {
  return _SlotConfigurationOptions.fromJson(json);
}

/// @nodoc
mixin _$SlotConfigurationOptions {
  bool? get digits8 => throw _privateConstructorUsedError;
  bool? get requireTouch => throw _privateConstructorUsedError;
  bool? get appendCr => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SlotConfigurationOptionsCopyWith<SlotConfigurationOptions> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SlotConfigurationOptionsCopyWith<$Res> {
  factory $SlotConfigurationOptionsCopyWith(SlotConfigurationOptions value,
          $Res Function(SlotConfigurationOptions) then) =
      _$SlotConfigurationOptionsCopyWithImpl<$Res, SlotConfigurationOptions>;
  @useResult
  $Res call({bool? digits8, bool? requireTouch, bool? appendCr});
}

/// @nodoc
class _$SlotConfigurationOptionsCopyWithImpl<$Res,
        $Val extends SlotConfigurationOptions>
    implements $SlotConfigurationOptionsCopyWith<$Res> {
  _$SlotConfigurationOptionsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? digits8 = freezed,
    Object? requireTouch = freezed,
    Object? appendCr = freezed,
  }) {
    return _then(_value.copyWith(
      digits8: freezed == digits8
          ? _value.digits8
          : digits8 // ignore: cast_nullable_to_non_nullable
              as bool?,
      requireTouch: freezed == requireTouch
          ? _value.requireTouch
          : requireTouch // ignore: cast_nullable_to_non_nullable
              as bool?,
      appendCr: freezed == appendCr
          ? _value.appendCr
          : appendCr // ignore: cast_nullable_to_non_nullable
              as bool?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$_SlotConfigurationOptionsCopyWith<$Res>
    implements $SlotConfigurationOptionsCopyWith<$Res> {
  factory _$$_SlotConfigurationOptionsCopyWith(
          _$_SlotConfigurationOptions value,
          $Res Function(_$_SlotConfigurationOptions) then) =
      __$$_SlotConfigurationOptionsCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({bool? digits8, bool? requireTouch, bool? appendCr});
}

/// @nodoc
class __$$_SlotConfigurationOptionsCopyWithImpl<$Res>
    extends _$SlotConfigurationOptionsCopyWithImpl<$Res,
        _$_SlotConfigurationOptions>
    implements _$$_SlotConfigurationOptionsCopyWith<$Res> {
  __$$_SlotConfigurationOptionsCopyWithImpl(_$_SlotConfigurationOptions _value,
      $Res Function(_$_SlotConfigurationOptions) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? digits8 = freezed,
    Object? requireTouch = freezed,
    Object? appendCr = freezed,
  }) {
    return _then(_$_SlotConfigurationOptions(
      digits8: freezed == digits8
          ? _value.digits8
          : digits8 // ignore: cast_nullable_to_non_nullable
              as bool?,
      requireTouch: freezed == requireTouch
          ? _value.requireTouch
          : requireTouch // ignore: cast_nullable_to_non_nullable
              as bool?,
      appendCr: freezed == appendCr
          ? _value.appendCr
          : appendCr // ignore: cast_nullable_to_non_nullable
              as bool?,
    ));
  }
}

/// @nodoc

@JsonSerializable(includeIfNull: false)
class _$_SlotConfigurationOptions implements _SlotConfigurationOptions {
  _$_SlotConfigurationOptions({this.digits8, this.requireTouch, this.appendCr});

  factory _$_SlotConfigurationOptions.fromJson(Map<String, dynamic> json) =>
      _$$_SlotConfigurationOptionsFromJson(json);

  @override
  final bool? digits8;
  @override
  final bool? requireTouch;
  @override
  final bool? appendCr;

  @override
  String toString() {
    return 'SlotConfigurationOptions(digits8: $digits8, requireTouch: $requireTouch, appendCr: $appendCr)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_SlotConfigurationOptions &&
            (identical(other.digits8, digits8) || other.digits8 == digits8) &&
            (identical(other.requireTouch, requireTouch) ||
                other.requireTouch == requireTouch) &&
            (identical(other.appendCr, appendCr) ||
                other.appendCr == appendCr));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, digits8, requireTouch, appendCr);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_SlotConfigurationOptionsCopyWith<_$_SlotConfigurationOptions>
      get copyWith => __$$_SlotConfigurationOptionsCopyWithImpl<
          _$_SlotConfigurationOptions>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_SlotConfigurationOptionsToJson(
      this,
    );
  }
}

abstract class _SlotConfigurationOptions implements SlotConfigurationOptions {
  factory _SlotConfigurationOptions(
      {final bool? digits8,
      final bool? requireTouch,
      final bool? appendCr}) = _$_SlotConfigurationOptions;

  factory _SlotConfigurationOptions.fromJson(Map<String, dynamic> json) =
      _$_SlotConfigurationOptions.fromJson;

  @override
  bool? get digits8;
  @override
  bool? get requireTouch;
  @override
  bool? get appendCr;
  @override
  @JsonKey(ignore: true)
  _$$_SlotConfigurationOptionsCopyWith<_$_SlotConfigurationOptions>
      get copyWith => throw _privateConstructorUsedError;
}

SlotConfiguration _$SlotConfigurationFromJson(Map<String, dynamic> json) {
  switch (json['type']) {
    case 'hotp':
      return _SlotConfigurationHotp.fromJson(json);
    case 'hmac_sha1':
      return _SlotConfigurationHmacSha1.fromJson(json);
    case 'static_password':
      return _SlotConfigurationStaticPassword.fromJson(json);
    case 'yubiotp':
      return _SlotConfigurationYubiOtp.fromJson(json);

    default:
      throw CheckedFromJsonException(json, 'type', 'SlotConfiguration',
          'Invalid union type "${json['type']}"!');
  }
}

/// @nodoc
mixin _$SlotConfiguration {
  SlotConfigurationOptions? get options => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String key, SlotConfigurationOptions? options)
        hotp,
    required TResult Function(String key, SlotConfigurationOptions? options)
        chalresp,
    required TResult Function(String password, String keyboardLayout,
            SlotConfigurationOptions? options)
        static,
    required TResult Function(String publicId, String privateId, String key,
            SlotConfigurationOptions? options)
        yubiotp,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String key, SlotConfigurationOptions? options)? hotp,
    TResult? Function(String key, SlotConfigurationOptions? options)? chalresp,
    TResult? Function(String password, String keyboardLayout,
            SlotConfigurationOptions? options)?
        static,
    TResult? Function(String publicId, String privateId, String key,
            SlotConfigurationOptions? options)?
        yubiotp,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String key, SlotConfigurationOptions? options)? hotp,
    TResult Function(String key, SlotConfigurationOptions? options)? chalresp,
    TResult Function(String password, String keyboardLayout,
            SlotConfigurationOptions? options)?
        static,
    TResult Function(String publicId, String privateId, String key,
            SlotConfigurationOptions? options)?
        yubiotp,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_SlotConfigurationHotp value) hotp,
    required TResult Function(_SlotConfigurationHmacSha1 value) chalresp,
    required TResult Function(_SlotConfigurationStaticPassword value) static,
    required TResult Function(_SlotConfigurationYubiOtp value) yubiotp,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_SlotConfigurationHotp value)? hotp,
    TResult? Function(_SlotConfigurationHmacSha1 value)? chalresp,
    TResult? Function(_SlotConfigurationStaticPassword value)? static,
    TResult? Function(_SlotConfigurationYubiOtp value)? yubiotp,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_SlotConfigurationHotp value)? hotp,
    TResult Function(_SlotConfigurationHmacSha1 value)? chalresp,
    TResult Function(_SlotConfigurationStaticPassword value)? static,
    TResult Function(_SlotConfigurationYubiOtp value)? yubiotp,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SlotConfigurationCopyWith<SlotConfiguration> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SlotConfigurationCopyWith<$Res> {
  factory $SlotConfigurationCopyWith(
          SlotConfiguration value, $Res Function(SlotConfiguration) then) =
      _$SlotConfigurationCopyWithImpl<$Res, SlotConfiguration>;
  @useResult
  $Res call({SlotConfigurationOptions? options});

  $SlotConfigurationOptionsCopyWith<$Res>? get options;
}

/// @nodoc
class _$SlotConfigurationCopyWithImpl<$Res, $Val extends SlotConfiguration>
    implements $SlotConfigurationCopyWith<$Res> {
  _$SlotConfigurationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? options = freezed,
  }) {
    return _then(_value.copyWith(
      options: freezed == options
          ? _value.options
          : options // ignore: cast_nullable_to_non_nullable
              as SlotConfigurationOptions?,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $SlotConfigurationOptionsCopyWith<$Res>? get options {
    if (_value.options == null) {
      return null;
    }

    return $SlotConfigurationOptionsCopyWith<$Res>(_value.options!, (value) {
      return _then(_value.copyWith(options: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$_SlotConfigurationHotpCopyWith<$Res>
    implements $SlotConfigurationCopyWith<$Res> {
  factory _$$_SlotConfigurationHotpCopyWith(_$_SlotConfigurationHotp value,
          $Res Function(_$_SlotConfigurationHotp) then) =
      __$$_SlotConfigurationHotpCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String key, SlotConfigurationOptions? options});

  @override
  $SlotConfigurationOptionsCopyWith<$Res>? get options;
}

/// @nodoc
class __$$_SlotConfigurationHotpCopyWithImpl<$Res>
    extends _$SlotConfigurationCopyWithImpl<$Res, _$_SlotConfigurationHotp>
    implements _$$_SlotConfigurationHotpCopyWith<$Res> {
  __$$_SlotConfigurationHotpCopyWithImpl(_$_SlotConfigurationHotp _value,
      $Res Function(_$_SlotConfigurationHotp) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? key = null,
    Object? options = freezed,
  }) {
    return _then(_$_SlotConfigurationHotp(
      key: null == key
          ? _value.key
          : key // ignore: cast_nullable_to_non_nullable
              as String,
      options: freezed == options
          ? _value.options
          : options // ignore: cast_nullable_to_non_nullable
              as SlotConfigurationOptions?,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class _$_SlotConfigurationHotp extends _SlotConfigurationHotp {
  const _$_SlotConfigurationHotp(
      {required this.key, this.options, final String? $type})
      : $type = $type ?? 'hotp',
        super._();

  factory _$_SlotConfigurationHotp.fromJson(Map<String, dynamic> json) =>
      _$$_SlotConfigurationHotpFromJson(json);

  @override
  final String key;
  @override
  final SlotConfigurationOptions? options;

  @JsonKey(name: 'type')
  final String $type;

  @override
  String toString() {
    return 'SlotConfiguration.hotp(key: $key, options: $options)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_SlotConfigurationHotp &&
            (identical(other.key, key) || other.key == key) &&
            (identical(other.options, options) || other.options == options));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, key, options);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_SlotConfigurationHotpCopyWith<_$_SlotConfigurationHotp> get copyWith =>
      __$$_SlotConfigurationHotpCopyWithImpl<_$_SlotConfigurationHotp>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String key, SlotConfigurationOptions? options)
        hotp,
    required TResult Function(String key, SlotConfigurationOptions? options)
        chalresp,
    required TResult Function(String password, String keyboardLayout,
            SlotConfigurationOptions? options)
        static,
    required TResult Function(String publicId, String privateId, String key,
            SlotConfigurationOptions? options)
        yubiotp,
  }) {
    return hotp(key, options);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String key, SlotConfigurationOptions? options)? hotp,
    TResult? Function(String key, SlotConfigurationOptions? options)? chalresp,
    TResult? Function(String password, String keyboardLayout,
            SlotConfigurationOptions? options)?
        static,
    TResult? Function(String publicId, String privateId, String key,
            SlotConfigurationOptions? options)?
        yubiotp,
  }) {
    return hotp?.call(key, options);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String key, SlotConfigurationOptions? options)? hotp,
    TResult Function(String key, SlotConfigurationOptions? options)? chalresp,
    TResult Function(String password, String keyboardLayout,
            SlotConfigurationOptions? options)?
        static,
    TResult Function(String publicId, String privateId, String key,
            SlotConfigurationOptions? options)?
        yubiotp,
    required TResult orElse(),
  }) {
    if (hotp != null) {
      return hotp(key, options);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_SlotConfigurationHotp value) hotp,
    required TResult Function(_SlotConfigurationHmacSha1 value) chalresp,
    required TResult Function(_SlotConfigurationStaticPassword value) static,
    required TResult Function(_SlotConfigurationYubiOtp value) yubiotp,
  }) {
    return hotp(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_SlotConfigurationHotp value)? hotp,
    TResult? Function(_SlotConfigurationHmacSha1 value)? chalresp,
    TResult? Function(_SlotConfigurationStaticPassword value)? static,
    TResult? Function(_SlotConfigurationYubiOtp value)? yubiotp,
  }) {
    return hotp?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_SlotConfigurationHotp value)? hotp,
    TResult Function(_SlotConfigurationHmacSha1 value)? chalresp,
    TResult Function(_SlotConfigurationStaticPassword value)? static,
    TResult Function(_SlotConfigurationYubiOtp value)? yubiotp,
    required TResult orElse(),
  }) {
    if (hotp != null) {
      return hotp(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$_SlotConfigurationHotpToJson(
      this,
    );
  }
}

abstract class _SlotConfigurationHotp extends SlotConfiguration {
  const factory _SlotConfigurationHotp(
      {required final String key,
      final SlotConfigurationOptions? options}) = _$_SlotConfigurationHotp;
  const _SlotConfigurationHotp._() : super._();

  factory _SlotConfigurationHotp.fromJson(Map<String, dynamic> json) =
      _$_SlotConfigurationHotp.fromJson;

  String get key;
  @override
  SlotConfigurationOptions? get options;
  @override
  @JsonKey(ignore: true)
  _$$_SlotConfigurationHotpCopyWith<_$_SlotConfigurationHotp> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$_SlotConfigurationHmacSha1CopyWith<$Res>
    implements $SlotConfigurationCopyWith<$Res> {
  factory _$$_SlotConfigurationHmacSha1CopyWith(
          _$_SlotConfigurationHmacSha1 value,
          $Res Function(_$_SlotConfigurationHmacSha1) then) =
      __$$_SlotConfigurationHmacSha1CopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String key, SlotConfigurationOptions? options});

  @override
  $SlotConfigurationOptionsCopyWith<$Res>? get options;
}

/// @nodoc
class __$$_SlotConfigurationHmacSha1CopyWithImpl<$Res>
    extends _$SlotConfigurationCopyWithImpl<$Res, _$_SlotConfigurationHmacSha1>
    implements _$$_SlotConfigurationHmacSha1CopyWith<$Res> {
  __$$_SlotConfigurationHmacSha1CopyWithImpl(
      _$_SlotConfigurationHmacSha1 _value,
      $Res Function(_$_SlotConfigurationHmacSha1) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? key = null,
    Object? options = freezed,
  }) {
    return _then(_$_SlotConfigurationHmacSha1(
      key: null == key
          ? _value.key
          : key // ignore: cast_nullable_to_non_nullable
              as String,
      options: freezed == options
          ? _value.options
          : options // ignore: cast_nullable_to_non_nullable
              as SlotConfigurationOptions?,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class _$_SlotConfigurationHmacSha1 extends _SlotConfigurationHmacSha1 {
  const _$_SlotConfigurationHmacSha1(
      {required this.key, this.options, final String? $type})
      : $type = $type ?? 'hmac_sha1',
        super._();

  factory _$_SlotConfigurationHmacSha1.fromJson(Map<String, dynamic> json) =>
      _$$_SlotConfigurationHmacSha1FromJson(json);

  @override
  final String key;
  @override
  final SlotConfigurationOptions? options;

  @JsonKey(name: 'type')
  final String $type;

  @override
  String toString() {
    return 'SlotConfiguration.chalresp(key: $key, options: $options)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_SlotConfigurationHmacSha1 &&
            (identical(other.key, key) || other.key == key) &&
            (identical(other.options, options) || other.options == options));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, key, options);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_SlotConfigurationHmacSha1CopyWith<_$_SlotConfigurationHmacSha1>
      get copyWith => __$$_SlotConfigurationHmacSha1CopyWithImpl<
          _$_SlotConfigurationHmacSha1>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String key, SlotConfigurationOptions? options)
        hotp,
    required TResult Function(String key, SlotConfigurationOptions? options)
        chalresp,
    required TResult Function(String password, String keyboardLayout,
            SlotConfigurationOptions? options)
        static,
    required TResult Function(String publicId, String privateId, String key,
            SlotConfigurationOptions? options)
        yubiotp,
  }) {
    return chalresp(key, options);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String key, SlotConfigurationOptions? options)? hotp,
    TResult? Function(String key, SlotConfigurationOptions? options)? chalresp,
    TResult? Function(String password, String keyboardLayout,
            SlotConfigurationOptions? options)?
        static,
    TResult? Function(String publicId, String privateId, String key,
            SlotConfigurationOptions? options)?
        yubiotp,
  }) {
    return chalresp?.call(key, options);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String key, SlotConfigurationOptions? options)? hotp,
    TResult Function(String key, SlotConfigurationOptions? options)? chalresp,
    TResult Function(String password, String keyboardLayout,
            SlotConfigurationOptions? options)?
        static,
    TResult Function(String publicId, String privateId, String key,
            SlotConfigurationOptions? options)?
        yubiotp,
    required TResult orElse(),
  }) {
    if (chalresp != null) {
      return chalresp(key, options);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_SlotConfigurationHotp value) hotp,
    required TResult Function(_SlotConfigurationHmacSha1 value) chalresp,
    required TResult Function(_SlotConfigurationStaticPassword value) static,
    required TResult Function(_SlotConfigurationYubiOtp value) yubiotp,
  }) {
    return chalresp(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_SlotConfigurationHotp value)? hotp,
    TResult? Function(_SlotConfigurationHmacSha1 value)? chalresp,
    TResult? Function(_SlotConfigurationStaticPassword value)? static,
    TResult? Function(_SlotConfigurationYubiOtp value)? yubiotp,
  }) {
    return chalresp?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_SlotConfigurationHotp value)? hotp,
    TResult Function(_SlotConfigurationHmacSha1 value)? chalresp,
    TResult Function(_SlotConfigurationStaticPassword value)? static,
    TResult Function(_SlotConfigurationYubiOtp value)? yubiotp,
    required TResult orElse(),
  }) {
    if (chalresp != null) {
      return chalresp(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$_SlotConfigurationHmacSha1ToJson(
      this,
    );
  }
}

abstract class _SlotConfigurationHmacSha1 extends SlotConfiguration {
  const factory _SlotConfigurationHmacSha1(
      {required final String key,
      final SlotConfigurationOptions? options}) = _$_SlotConfigurationHmacSha1;
  const _SlotConfigurationHmacSha1._() : super._();

  factory _SlotConfigurationHmacSha1.fromJson(Map<String, dynamic> json) =
      _$_SlotConfigurationHmacSha1.fromJson;

  String get key;
  @override
  SlotConfigurationOptions? get options;
  @override
  @JsonKey(ignore: true)
  _$$_SlotConfigurationHmacSha1CopyWith<_$_SlotConfigurationHmacSha1>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$_SlotConfigurationStaticPasswordCopyWith<$Res>
    implements $SlotConfigurationCopyWith<$Res> {
  factory _$$_SlotConfigurationStaticPasswordCopyWith(
          _$_SlotConfigurationStaticPassword value,
          $Res Function(_$_SlotConfigurationStaticPassword) then) =
      __$$_SlotConfigurationStaticPasswordCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String password,
      String keyboardLayout,
      SlotConfigurationOptions? options});

  @override
  $SlotConfigurationOptionsCopyWith<$Res>? get options;
}

/// @nodoc
class __$$_SlotConfigurationStaticPasswordCopyWithImpl<$Res>
    extends _$SlotConfigurationCopyWithImpl<$Res,
        _$_SlotConfigurationStaticPassword>
    implements _$$_SlotConfigurationStaticPasswordCopyWith<$Res> {
  __$$_SlotConfigurationStaticPasswordCopyWithImpl(
      _$_SlotConfigurationStaticPassword _value,
      $Res Function(_$_SlotConfigurationStaticPassword) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? password = null,
    Object? keyboardLayout = null,
    Object? options = freezed,
  }) {
    return _then(_$_SlotConfigurationStaticPassword(
      password: null == password
          ? _value.password
          : password // ignore: cast_nullable_to_non_nullable
              as String,
      keyboardLayout: null == keyboardLayout
          ? _value.keyboardLayout
          : keyboardLayout // ignore: cast_nullable_to_non_nullable
              as String,
      options: freezed == options
          ? _value.options
          : options // ignore: cast_nullable_to_non_nullable
              as SlotConfigurationOptions?,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class _$_SlotConfigurationStaticPassword
    extends _SlotConfigurationStaticPassword {
  const _$_SlotConfigurationStaticPassword(
      {required this.password,
      required this.keyboardLayout,
      this.options,
      final String? $type})
      : $type = $type ?? 'static_password',
        super._();

  factory _$_SlotConfigurationStaticPassword.fromJson(
          Map<String, dynamic> json) =>
      _$$_SlotConfigurationStaticPasswordFromJson(json);

  @override
  final String password;
  @override
  final String keyboardLayout;
  @override
  final SlotConfigurationOptions? options;

  @JsonKey(name: 'type')
  final String $type;

  @override
  String toString() {
    return 'SlotConfiguration.static(password: $password, keyboardLayout: $keyboardLayout, options: $options)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_SlotConfigurationStaticPassword &&
            (identical(other.password, password) ||
                other.password == password) &&
            (identical(other.keyboardLayout, keyboardLayout) ||
                other.keyboardLayout == keyboardLayout) &&
            (identical(other.options, options) || other.options == options));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, password, keyboardLayout, options);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_SlotConfigurationStaticPasswordCopyWith<
          _$_SlotConfigurationStaticPassword>
      get copyWith => __$$_SlotConfigurationStaticPasswordCopyWithImpl<
          _$_SlotConfigurationStaticPassword>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String key, SlotConfigurationOptions? options)
        hotp,
    required TResult Function(String key, SlotConfigurationOptions? options)
        chalresp,
    required TResult Function(String password, String keyboardLayout,
            SlotConfigurationOptions? options)
        static,
    required TResult Function(String publicId, String privateId, String key,
            SlotConfigurationOptions? options)
        yubiotp,
  }) {
    return static(password, keyboardLayout, options);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String key, SlotConfigurationOptions? options)? hotp,
    TResult? Function(String key, SlotConfigurationOptions? options)? chalresp,
    TResult? Function(String password, String keyboardLayout,
            SlotConfigurationOptions? options)?
        static,
    TResult? Function(String publicId, String privateId, String key,
            SlotConfigurationOptions? options)?
        yubiotp,
  }) {
    return static?.call(password, keyboardLayout, options);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String key, SlotConfigurationOptions? options)? hotp,
    TResult Function(String key, SlotConfigurationOptions? options)? chalresp,
    TResult Function(String password, String keyboardLayout,
            SlotConfigurationOptions? options)?
        static,
    TResult Function(String publicId, String privateId, String key,
            SlotConfigurationOptions? options)?
        yubiotp,
    required TResult orElse(),
  }) {
    if (static != null) {
      return static(password, keyboardLayout, options);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_SlotConfigurationHotp value) hotp,
    required TResult Function(_SlotConfigurationHmacSha1 value) chalresp,
    required TResult Function(_SlotConfigurationStaticPassword value) static,
    required TResult Function(_SlotConfigurationYubiOtp value) yubiotp,
  }) {
    return static(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_SlotConfigurationHotp value)? hotp,
    TResult? Function(_SlotConfigurationHmacSha1 value)? chalresp,
    TResult? Function(_SlotConfigurationStaticPassword value)? static,
    TResult? Function(_SlotConfigurationYubiOtp value)? yubiotp,
  }) {
    return static?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_SlotConfigurationHotp value)? hotp,
    TResult Function(_SlotConfigurationHmacSha1 value)? chalresp,
    TResult Function(_SlotConfigurationStaticPassword value)? static,
    TResult Function(_SlotConfigurationYubiOtp value)? yubiotp,
    required TResult orElse(),
  }) {
    if (static != null) {
      return static(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$_SlotConfigurationStaticPasswordToJson(
      this,
    );
  }
}

abstract class _SlotConfigurationStaticPassword extends SlotConfiguration {
  const factory _SlotConfigurationStaticPassword(
          {required final String password,
          required final String keyboardLayout,
          final SlotConfigurationOptions? options}) =
      _$_SlotConfigurationStaticPassword;
  const _SlotConfigurationStaticPassword._() : super._();

  factory _SlotConfigurationStaticPassword.fromJson(Map<String, dynamic> json) =
      _$_SlotConfigurationStaticPassword.fromJson;

  String get password;
  String get keyboardLayout;
  @override
  SlotConfigurationOptions? get options;
  @override
  @JsonKey(ignore: true)
  _$$_SlotConfigurationStaticPasswordCopyWith<
          _$_SlotConfigurationStaticPassword>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$_SlotConfigurationYubiOtpCopyWith<$Res>
    implements $SlotConfigurationCopyWith<$Res> {
  factory _$$_SlotConfigurationYubiOtpCopyWith(
          _$_SlotConfigurationYubiOtp value,
          $Res Function(_$_SlotConfigurationYubiOtp) then) =
      __$$_SlotConfigurationYubiOtpCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String publicId,
      String privateId,
      String key,
      SlotConfigurationOptions? options});

  @override
  $SlotConfigurationOptionsCopyWith<$Res>? get options;
}

/// @nodoc
class __$$_SlotConfigurationYubiOtpCopyWithImpl<$Res>
    extends _$SlotConfigurationCopyWithImpl<$Res, _$_SlotConfigurationYubiOtp>
    implements _$$_SlotConfigurationYubiOtpCopyWith<$Res> {
  __$$_SlotConfigurationYubiOtpCopyWithImpl(_$_SlotConfigurationYubiOtp _value,
      $Res Function(_$_SlotConfigurationYubiOtp) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? publicId = null,
    Object? privateId = null,
    Object? key = null,
    Object? options = freezed,
  }) {
    return _then(_$_SlotConfigurationYubiOtp(
      publicId: null == publicId
          ? _value.publicId
          : publicId // ignore: cast_nullable_to_non_nullable
              as String,
      privateId: null == privateId
          ? _value.privateId
          : privateId // ignore: cast_nullable_to_non_nullable
              as String,
      key: null == key
          ? _value.key
          : key // ignore: cast_nullable_to_non_nullable
              as String,
      options: freezed == options
          ? _value.options
          : options // ignore: cast_nullable_to_non_nullable
              as SlotConfigurationOptions?,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class _$_SlotConfigurationYubiOtp extends _SlotConfigurationYubiOtp {
  const _$_SlotConfigurationYubiOtp(
      {required this.publicId,
      required this.privateId,
      required this.key,
      this.options,
      final String? $type})
      : $type = $type ?? 'yubiotp',
        super._();

  factory _$_SlotConfigurationYubiOtp.fromJson(Map<String, dynamic> json) =>
      _$$_SlotConfigurationYubiOtpFromJson(json);

  @override
  final String publicId;
  @override
  final String privateId;
  @override
  final String key;
  @override
  final SlotConfigurationOptions? options;

  @JsonKey(name: 'type')
  final String $type;

  @override
  String toString() {
    return 'SlotConfiguration.yubiotp(publicId: $publicId, privateId: $privateId, key: $key, options: $options)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_SlotConfigurationYubiOtp &&
            (identical(other.publicId, publicId) ||
                other.publicId == publicId) &&
            (identical(other.privateId, privateId) ||
                other.privateId == privateId) &&
            (identical(other.key, key) || other.key == key) &&
            (identical(other.options, options) || other.options == options));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, publicId, privateId, key, options);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_SlotConfigurationYubiOtpCopyWith<_$_SlotConfigurationYubiOtp>
      get copyWith => __$$_SlotConfigurationYubiOtpCopyWithImpl<
          _$_SlotConfigurationYubiOtp>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String key, SlotConfigurationOptions? options)
        hotp,
    required TResult Function(String key, SlotConfigurationOptions? options)
        chalresp,
    required TResult Function(String password, String keyboardLayout,
            SlotConfigurationOptions? options)
        static,
    required TResult Function(String publicId, String privateId, String key,
            SlotConfigurationOptions? options)
        yubiotp,
  }) {
    return yubiotp(publicId, privateId, key, options);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String key, SlotConfigurationOptions? options)? hotp,
    TResult? Function(String key, SlotConfigurationOptions? options)? chalresp,
    TResult? Function(String password, String keyboardLayout,
            SlotConfigurationOptions? options)?
        static,
    TResult? Function(String publicId, String privateId, String key,
            SlotConfigurationOptions? options)?
        yubiotp,
  }) {
    return yubiotp?.call(publicId, privateId, key, options);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String key, SlotConfigurationOptions? options)? hotp,
    TResult Function(String key, SlotConfigurationOptions? options)? chalresp,
    TResult Function(String password, String keyboardLayout,
            SlotConfigurationOptions? options)?
        static,
    TResult Function(String publicId, String privateId, String key,
            SlotConfigurationOptions? options)?
        yubiotp,
    required TResult orElse(),
  }) {
    if (yubiotp != null) {
      return yubiotp(publicId, privateId, key, options);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_SlotConfigurationHotp value) hotp,
    required TResult Function(_SlotConfigurationHmacSha1 value) chalresp,
    required TResult Function(_SlotConfigurationStaticPassword value) static,
    required TResult Function(_SlotConfigurationYubiOtp value) yubiotp,
  }) {
    return yubiotp(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_SlotConfigurationHotp value)? hotp,
    TResult? Function(_SlotConfigurationHmacSha1 value)? chalresp,
    TResult? Function(_SlotConfigurationStaticPassword value)? static,
    TResult? Function(_SlotConfigurationYubiOtp value)? yubiotp,
  }) {
    return yubiotp?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_SlotConfigurationHotp value)? hotp,
    TResult Function(_SlotConfigurationHmacSha1 value)? chalresp,
    TResult Function(_SlotConfigurationStaticPassword value)? static,
    TResult Function(_SlotConfigurationYubiOtp value)? yubiotp,
    required TResult orElse(),
  }) {
    if (yubiotp != null) {
      return yubiotp(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$_SlotConfigurationYubiOtpToJson(
      this,
    );
  }
}

abstract class _SlotConfigurationYubiOtp extends SlotConfiguration {
  const factory _SlotConfigurationYubiOtp(
      {required final String publicId,
      required final String privateId,
      required final String key,
      final SlotConfigurationOptions? options}) = _$_SlotConfigurationYubiOtp;
  const _SlotConfigurationYubiOtp._() : super._();

  factory _SlotConfigurationYubiOtp.fromJson(Map<String, dynamic> json) =
      _$_SlotConfigurationYubiOtp.fromJson;

  String get publicId;
  String get privateId;
  String get key;
  @override
  SlotConfigurationOptions? get options;
  @override
  @JsonKey(ignore: true)
  _$$_SlotConfigurationYubiOtpCopyWith<_$_SlotConfigurationYubiOtp>
      get copyWith => throw _privateConstructorUsedError;
}
