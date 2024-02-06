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
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

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
abstract class _$$OtpStateImplCopyWith<$Res>
    implements $OtpStateCopyWith<$Res> {
  factory _$$OtpStateImplCopyWith(
          _$OtpStateImpl value, $Res Function(_$OtpStateImpl) then) =
      __$$OtpStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({bool slot1Configured, bool slot2Configured});
}

/// @nodoc
class __$$OtpStateImplCopyWithImpl<$Res>
    extends _$OtpStateCopyWithImpl<$Res, _$OtpStateImpl>
    implements _$$OtpStateImplCopyWith<$Res> {
  __$$OtpStateImplCopyWithImpl(
      _$OtpStateImpl _value, $Res Function(_$OtpStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? slot1Configured = null,
    Object? slot2Configured = null,
  }) {
    return _then(_$OtpStateImpl(
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
class _$OtpStateImpl extends _OtpState {
  _$OtpStateImpl({required this.slot1Configured, required this.slot2Configured})
      : super._();

  factory _$OtpStateImpl.fromJson(Map<String, dynamic> json) =>
      _$$OtpStateImplFromJson(json);

  @override
  final bool slot1Configured;
  @override
  final bool slot2Configured;

  @override
  String toString() {
    return 'OtpState(slot1Configured: $slot1Configured, slot2Configured: $slot2Configured)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OtpStateImpl &&
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
  _$$OtpStateImplCopyWith<_$OtpStateImpl> get copyWith =>
      __$$OtpStateImplCopyWithImpl<_$OtpStateImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OtpStateImplToJson(
      this,
    );
  }
}

abstract class _OtpState extends OtpState {
  factory _OtpState(
      {required final bool slot1Configured,
      required final bool slot2Configured}) = _$OtpStateImpl;
  _OtpState._() : super._();

  factory _OtpState.fromJson(Map<String, dynamic> json) =
      _$OtpStateImpl.fromJson;

  @override
  bool get slot1Configured;
  @override
  bool get slot2Configured;
  @override
  @JsonKey(ignore: true)
  _$$OtpStateImplCopyWith<_$OtpStateImpl> get copyWith =>
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
abstract class _$$OtpSlotImplCopyWith<$Res> implements $OtpSlotCopyWith<$Res> {
  factory _$$OtpSlotImplCopyWith(
          _$OtpSlotImpl value, $Res Function(_$OtpSlotImpl) then) =
      __$$OtpSlotImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({SlotId slot, bool isConfigured});
}

/// @nodoc
class __$$OtpSlotImplCopyWithImpl<$Res>
    extends _$OtpSlotCopyWithImpl<$Res, _$OtpSlotImpl>
    implements _$$OtpSlotImplCopyWith<$Res> {
  __$$OtpSlotImplCopyWithImpl(
      _$OtpSlotImpl _value, $Res Function(_$OtpSlotImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? slot = null,
    Object? isConfigured = null,
  }) {
    return _then(_$OtpSlotImpl(
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

class _$OtpSlotImpl implements _OtpSlot {
  _$OtpSlotImpl({required this.slot, required this.isConfigured});

  @override
  final SlotId slot;
  @override
  final bool isConfigured;

  @override
  String toString() {
    return 'OtpSlot(slot: $slot, isConfigured: $isConfigured)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OtpSlotImpl &&
            (identical(other.slot, slot) || other.slot == slot) &&
            (identical(other.isConfigured, isConfigured) ||
                other.isConfigured == isConfigured));
  }

  @override
  int get hashCode => Object.hash(runtimeType, slot, isConfigured);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$OtpSlotImplCopyWith<_$OtpSlotImpl> get copyWith =>
      __$$OtpSlotImplCopyWithImpl<_$OtpSlotImpl>(this, _$identity);
}

abstract class _OtpSlot implements OtpSlot {
  factory _OtpSlot(
      {required final SlotId slot,
      required final bool isConfigured}) = _$OtpSlotImpl;

  @override
  SlotId get slot;
  @override
  bool get isConfigured;
  @override
  @JsonKey(ignore: true)
  _$$OtpSlotImplCopyWith<_$OtpSlotImpl> get copyWith =>
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
abstract class _$$SlotConfigurationOptionsImplCopyWith<$Res>
    implements $SlotConfigurationOptionsCopyWith<$Res> {
  factory _$$SlotConfigurationOptionsImplCopyWith(
          _$SlotConfigurationOptionsImpl value,
          $Res Function(_$SlotConfigurationOptionsImpl) then) =
      __$$SlotConfigurationOptionsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({bool? digits8, bool? requireTouch, bool? appendCr});
}

/// @nodoc
class __$$SlotConfigurationOptionsImplCopyWithImpl<$Res>
    extends _$SlotConfigurationOptionsCopyWithImpl<$Res,
        _$SlotConfigurationOptionsImpl>
    implements _$$SlotConfigurationOptionsImplCopyWith<$Res> {
  __$$SlotConfigurationOptionsImplCopyWithImpl(
      _$SlotConfigurationOptionsImpl _value,
      $Res Function(_$SlotConfigurationOptionsImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? digits8 = freezed,
    Object? requireTouch = freezed,
    Object? appendCr = freezed,
  }) {
    return _then(_$SlotConfigurationOptionsImpl(
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
class _$SlotConfigurationOptionsImpl implements _SlotConfigurationOptions {
  _$SlotConfigurationOptionsImpl(
      {this.digits8, this.requireTouch, this.appendCr});

  factory _$SlotConfigurationOptionsImpl.fromJson(Map<String, dynamic> json) =>
      _$$SlotConfigurationOptionsImplFromJson(json);

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
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SlotConfigurationOptionsImpl &&
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
  _$$SlotConfigurationOptionsImplCopyWith<_$SlotConfigurationOptionsImpl>
      get copyWith => __$$SlotConfigurationOptionsImplCopyWithImpl<
          _$SlotConfigurationOptionsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SlotConfigurationOptionsImplToJson(
      this,
    );
  }
}

abstract class _SlotConfigurationOptions implements SlotConfigurationOptions {
  factory _SlotConfigurationOptions(
      {final bool? digits8,
      final bool? requireTouch,
      final bool? appendCr}) = _$SlotConfigurationOptionsImpl;

  factory _SlotConfigurationOptions.fromJson(Map<String, dynamic> json) =
      _$SlotConfigurationOptionsImpl.fromJson;

  @override
  bool? get digits8;
  @override
  bool? get requireTouch;
  @override
  bool? get appendCr;
  @override
  @JsonKey(ignore: true)
  _$$SlotConfigurationOptionsImplCopyWith<_$SlotConfigurationOptionsImpl>
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
abstract class _$$SlotConfigurationHotpImplCopyWith<$Res>
    implements $SlotConfigurationCopyWith<$Res> {
  factory _$$SlotConfigurationHotpImplCopyWith(
          _$SlotConfigurationHotpImpl value,
          $Res Function(_$SlotConfigurationHotpImpl) then) =
      __$$SlotConfigurationHotpImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String key, SlotConfigurationOptions? options});

  @override
  $SlotConfigurationOptionsCopyWith<$Res>? get options;
}

/// @nodoc
class __$$SlotConfigurationHotpImplCopyWithImpl<$Res>
    extends _$SlotConfigurationCopyWithImpl<$Res, _$SlotConfigurationHotpImpl>
    implements _$$SlotConfigurationHotpImplCopyWith<$Res> {
  __$$SlotConfigurationHotpImplCopyWithImpl(_$SlotConfigurationHotpImpl _value,
      $Res Function(_$SlotConfigurationHotpImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? key = null,
    Object? options = freezed,
  }) {
    return _then(_$SlotConfigurationHotpImpl(
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
class _$SlotConfigurationHotpImpl extends _SlotConfigurationHotp {
  const _$SlotConfigurationHotpImpl(
      {required this.key, this.options, final String? $type})
      : $type = $type ?? 'hotp',
        super._();

  factory _$SlotConfigurationHotpImpl.fromJson(Map<String, dynamic> json) =>
      _$$SlotConfigurationHotpImplFromJson(json);

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
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SlotConfigurationHotpImpl &&
            (identical(other.key, key) || other.key == key) &&
            (identical(other.options, options) || other.options == options));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, key, options);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SlotConfigurationHotpImplCopyWith<_$SlotConfigurationHotpImpl>
      get copyWith => __$$SlotConfigurationHotpImplCopyWithImpl<
          _$SlotConfigurationHotpImpl>(this, _$identity);

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
    return _$$SlotConfigurationHotpImplToJson(
      this,
    );
  }
}

abstract class _SlotConfigurationHotp extends SlotConfiguration {
  const factory _SlotConfigurationHotp(
      {required final String key,
      final SlotConfigurationOptions? options}) = _$SlotConfigurationHotpImpl;
  const _SlotConfigurationHotp._() : super._();

  factory _SlotConfigurationHotp.fromJson(Map<String, dynamic> json) =
      _$SlotConfigurationHotpImpl.fromJson;

  String get key;
  @override
  SlotConfigurationOptions? get options;
  @override
  @JsonKey(ignore: true)
  _$$SlotConfigurationHotpImplCopyWith<_$SlotConfigurationHotpImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SlotConfigurationHmacSha1ImplCopyWith<$Res>
    implements $SlotConfigurationCopyWith<$Res> {
  factory _$$SlotConfigurationHmacSha1ImplCopyWith(
          _$SlotConfigurationHmacSha1Impl value,
          $Res Function(_$SlotConfigurationHmacSha1Impl) then) =
      __$$SlotConfigurationHmacSha1ImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String key, SlotConfigurationOptions? options});

  @override
  $SlotConfigurationOptionsCopyWith<$Res>? get options;
}

/// @nodoc
class __$$SlotConfigurationHmacSha1ImplCopyWithImpl<$Res>
    extends _$SlotConfigurationCopyWithImpl<$Res,
        _$SlotConfigurationHmacSha1Impl>
    implements _$$SlotConfigurationHmacSha1ImplCopyWith<$Res> {
  __$$SlotConfigurationHmacSha1ImplCopyWithImpl(
      _$SlotConfigurationHmacSha1Impl _value,
      $Res Function(_$SlotConfigurationHmacSha1Impl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? key = null,
    Object? options = freezed,
  }) {
    return _then(_$SlotConfigurationHmacSha1Impl(
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
class _$SlotConfigurationHmacSha1Impl extends _SlotConfigurationHmacSha1 {
  const _$SlotConfigurationHmacSha1Impl(
      {required this.key, this.options, final String? $type})
      : $type = $type ?? 'hmac_sha1',
        super._();

  factory _$SlotConfigurationHmacSha1Impl.fromJson(Map<String, dynamic> json) =>
      _$$SlotConfigurationHmacSha1ImplFromJson(json);

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
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SlotConfigurationHmacSha1Impl &&
            (identical(other.key, key) || other.key == key) &&
            (identical(other.options, options) || other.options == options));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, key, options);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SlotConfigurationHmacSha1ImplCopyWith<_$SlotConfigurationHmacSha1Impl>
      get copyWith => __$$SlotConfigurationHmacSha1ImplCopyWithImpl<
          _$SlotConfigurationHmacSha1Impl>(this, _$identity);

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
    return _$$SlotConfigurationHmacSha1ImplToJson(
      this,
    );
  }
}

abstract class _SlotConfigurationHmacSha1 extends SlotConfiguration {
  const factory _SlotConfigurationHmacSha1(
          {required final String key,
          final SlotConfigurationOptions? options}) =
      _$SlotConfigurationHmacSha1Impl;
  const _SlotConfigurationHmacSha1._() : super._();

  factory _SlotConfigurationHmacSha1.fromJson(Map<String, dynamic> json) =
      _$SlotConfigurationHmacSha1Impl.fromJson;

  String get key;
  @override
  SlotConfigurationOptions? get options;
  @override
  @JsonKey(ignore: true)
  _$$SlotConfigurationHmacSha1ImplCopyWith<_$SlotConfigurationHmacSha1Impl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SlotConfigurationStaticPasswordImplCopyWith<$Res>
    implements $SlotConfigurationCopyWith<$Res> {
  factory _$$SlotConfigurationStaticPasswordImplCopyWith(
          _$SlotConfigurationStaticPasswordImpl value,
          $Res Function(_$SlotConfigurationStaticPasswordImpl) then) =
      __$$SlotConfigurationStaticPasswordImplCopyWithImpl<$Res>;
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
class __$$SlotConfigurationStaticPasswordImplCopyWithImpl<$Res>
    extends _$SlotConfigurationCopyWithImpl<$Res,
        _$SlotConfigurationStaticPasswordImpl>
    implements _$$SlotConfigurationStaticPasswordImplCopyWith<$Res> {
  __$$SlotConfigurationStaticPasswordImplCopyWithImpl(
      _$SlotConfigurationStaticPasswordImpl _value,
      $Res Function(_$SlotConfigurationStaticPasswordImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? password = null,
    Object? keyboardLayout = null,
    Object? options = freezed,
  }) {
    return _then(_$SlotConfigurationStaticPasswordImpl(
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
class _$SlotConfigurationStaticPasswordImpl
    extends _SlotConfigurationStaticPassword {
  const _$SlotConfigurationStaticPasswordImpl(
      {required this.password,
      required this.keyboardLayout,
      this.options,
      final String? $type})
      : $type = $type ?? 'static_password',
        super._();

  factory _$SlotConfigurationStaticPasswordImpl.fromJson(
          Map<String, dynamic> json) =>
      _$$SlotConfigurationStaticPasswordImplFromJson(json);

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
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SlotConfigurationStaticPasswordImpl &&
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
  _$$SlotConfigurationStaticPasswordImplCopyWith<
          _$SlotConfigurationStaticPasswordImpl>
      get copyWith => __$$SlotConfigurationStaticPasswordImplCopyWithImpl<
          _$SlotConfigurationStaticPasswordImpl>(this, _$identity);

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
    return _$$SlotConfigurationStaticPasswordImplToJson(
      this,
    );
  }
}

abstract class _SlotConfigurationStaticPassword extends SlotConfiguration {
  const factory _SlotConfigurationStaticPassword(
          {required final String password,
          required final String keyboardLayout,
          final SlotConfigurationOptions? options}) =
      _$SlotConfigurationStaticPasswordImpl;
  const _SlotConfigurationStaticPassword._() : super._();

  factory _SlotConfigurationStaticPassword.fromJson(Map<String, dynamic> json) =
      _$SlotConfigurationStaticPasswordImpl.fromJson;

  String get password;
  String get keyboardLayout;
  @override
  SlotConfigurationOptions? get options;
  @override
  @JsonKey(ignore: true)
  _$$SlotConfigurationStaticPasswordImplCopyWith<
          _$SlotConfigurationStaticPasswordImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SlotConfigurationYubiOtpImplCopyWith<$Res>
    implements $SlotConfigurationCopyWith<$Res> {
  factory _$$SlotConfigurationYubiOtpImplCopyWith(
          _$SlotConfigurationYubiOtpImpl value,
          $Res Function(_$SlotConfigurationYubiOtpImpl) then) =
      __$$SlotConfigurationYubiOtpImplCopyWithImpl<$Res>;
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
class __$$SlotConfigurationYubiOtpImplCopyWithImpl<$Res>
    extends _$SlotConfigurationCopyWithImpl<$Res,
        _$SlotConfigurationYubiOtpImpl>
    implements _$$SlotConfigurationYubiOtpImplCopyWith<$Res> {
  __$$SlotConfigurationYubiOtpImplCopyWithImpl(
      _$SlotConfigurationYubiOtpImpl _value,
      $Res Function(_$SlotConfigurationYubiOtpImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? publicId = null,
    Object? privateId = null,
    Object? key = null,
    Object? options = freezed,
  }) {
    return _then(_$SlotConfigurationYubiOtpImpl(
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
class _$SlotConfigurationYubiOtpImpl extends _SlotConfigurationYubiOtp {
  const _$SlotConfigurationYubiOtpImpl(
      {required this.publicId,
      required this.privateId,
      required this.key,
      this.options,
      final String? $type})
      : $type = $type ?? 'yubiotp',
        super._();

  factory _$SlotConfigurationYubiOtpImpl.fromJson(Map<String, dynamic> json) =>
      _$$SlotConfigurationYubiOtpImplFromJson(json);

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
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SlotConfigurationYubiOtpImpl &&
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
  _$$SlotConfigurationYubiOtpImplCopyWith<_$SlotConfigurationYubiOtpImpl>
      get copyWith => __$$SlotConfigurationYubiOtpImplCopyWithImpl<
          _$SlotConfigurationYubiOtpImpl>(this, _$identity);

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
    return _$$SlotConfigurationYubiOtpImplToJson(
      this,
    );
  }
}

abstract class _SlotConfigurationYubiOtp extends SlotConfiguration {
  const factory _SlotConfigurationYubiOtp(
          {required final String publicId,
          required final String privateId,
          required final String key,
          final SlotConfigurationOptions? options}) =
      _$SlotConfigurationYubiOtpImpl;
  const _SlotConfigurationYubiOtp._() : super._();

  factory _SlotConfigurationYubiOtp.fromJson(Map<String, dynamic> json) =
      _$SlotConfigurationYubiOtpImpl.fromJson;

  String get publicId;
  String get privateId;
  String get key;
  @override
  SlotConfigurationOptions? get options;
  @override
  @JsonKey(ignore: true)
  _$$SlotConfigurationYubiOtpImplCopyWith<_$SlotConfigurationYubiOtpImpl>
      get copyWith => throw _privateConstructorUsedError;
}
