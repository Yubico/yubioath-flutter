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

FidoState _$FidoStateFromJson(Map<String, dynamic> json) {
  return _FidoState.fromJson(json);
}

/// @nodoc
mixin _$FidoState {
  Map<String, dynamic> get info => throw _privateConstructorUsedError;
  bool get unlocked => throw _privateConstructorUsedError;
  int? get pinRetries => throw _privateConstructorUsedError;

  /// Serializes this FidoState to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FidoState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FidoStateCopyWith<FidoState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FidoStateCopyWith<$Res> {
  factory $FidoStateCopyWith(FidoState value, $Res Function(FidoState) then) =
      _$FidoStateCopyWithImpl<$Res, FidoState>;
  @useResult
  $Res call({Map<String, dynamic> info, bool unlocked, int? pinRetries});
}

/// @nodoc
class _$FidoStateCopyWithImpl<$Res, $Val extends FidoState>
    implements $FidoStateCopyWith<$Res> {
  _$FidoStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FidoState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? info = null,
    Object? unlocked = null,
    Object? pinRetries = freezed,
  }) {
    return _then(_value.copyWith(
      info: null == info
          ? _value.info
          : info // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      unlocked: null == unlocked
          ? _value.unlocked
          : unlocked // ignore: cast_nullable_to_non_nullable
              as bool,
      pinRetries: freezed == pinRetries
          ? _value.pinRetries
          : pinRetries // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FidoStateImplCopyWith<$Res>
    implements $FidoStateCopyWith<$Res> {
  factory _$$FidoStateImplCopyWith(
          _$FidoStateImpl value, $Res Function(_$FidoStateImpl) then) =
      __$$FidoStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({Map<String, dynamic> info, bool unlocked, int? pinRetries});
}

/// @nodoc
class __$$FidoStateImplCopyWithImpl<$Res>
    extends _$FidoStateCopyWithImpl<$Res, _$FidoStateImpl>
    implements _$$FidoStateImplCopyWith<$Res> {
  __$$FidoStateImplCopyWithImpl(
      _$FidoStateImpl _value, $Res Function(_$FidoStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of FidoState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? info = null,
    Object? unlocked = null,
    Object? pinRetries = freezed,
  }) {
    return _then(_$FidoStateImpl(
      info: null == info
          ? _value._info
          : info // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      unlocked: null == unlocked
          ? _value.unlocked
          : unlocked // ignore: cast_nullable_to_non_nullable
              as bool,
      pinRetries: freezed == pinRetries
          ? _value.pinRetries
          : pinRetries // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FidoStateImpl extends _FidoState {
  _$FidoStateImpl(
      {required final Map<String, dynamic> info,
      required this.unlocked,
      this.pinRetries})
      : _info = info,
        super._();

  factory _$FidoStateImpl.fromJson(Map<String, dynamic> json) =>
      _$$FidoStateImplFromJson(json);

  final Map<String, dynamic> _info;
  @override
  Map<String, dynamic> get info {
    if (_info is EqualUnmodifiableMapView) return _info;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_info);
  }

  @override
  final bool unlocked;
  @override
  final int? pinRetries;

  @override
  String toString() {
    return 'FidoState(info: $info, unlocked: $unlocked, pinRetries: $pinRetries)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FidoStateImpl &&
            const DeepCollectionEquality().equals(other._info, _info) &&
            (identical(other.unlocked, unlocked) ||
                other.unlocked == unlocked) &&
            (identical(other.pinRetries, pinRetries) ||
                other.pinRetries == pinRetries));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType,
      const DeepCollectionEquality().hash(_info), unlocked, pinRetries);

  /// Create a copy of FidoState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FidoStateImplCopyWith<_$FidoStateImpl> get copyWith =>
      __$$FidoStateImplCopyWithImpl<_$FidoStateImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FidoStateImplToJson(
      this,
    );
  }
}

abstract class _FidoState extends FidoState {
  factory _FidoState(
      {required final Map<String, dynamic> info,
      required final bool unlocked,
      final int? pinRetries}) = _$FidoStateImpl;
  _FidoState._() : super._();

  factory _FidoState.fromJson(Map<String, dynamic> json) =
      _$FidoStateImpl.fromJson;

  @override
  Map<String, dynamic> get info;
  @override
  bool get unlocked;
  @override
  int? get pinRetries;

  /// Create a copy of FidoState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FidoStateImplCopyWith<_$FidoStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$PinResult {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() success,
    required TResult Function(FidoPinFailureReason reason) failed,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? success,
    TResult? Function(FidoPinFailureReason reason)? failed,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? success,
    TResult Function(FidoPinFailureReason reason)? failed,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_PinSuccess value) success,
    required TResult Function(_PinFailure value) failed,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_PinSuccess value)? success,
    TResult? Function(_PinFailure value)? failed,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_PinSuccess value)? success,
    TResult Function(_PinFailure value)? failed,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PinResultCopyWith<$Res> {
  factory $PinResultCopyWith(PinResult value, $Res Function(PinResult) then) =
      _$PinResultCopyWithImpl<$Res, PinResult>;
}

/// @nodoc
class _$PinResultCopyWithImpl<$Res, $Val extends PinResult>
    implements $PinResultCopyWith<$Res> {
  _$PinResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PinResult
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$PinSuccessImplCopyWith<$Res> {
  factory _$$PinSuccessImplCopyWith(
          _$PinSuccessImpl value, $Res Function(_$PinSuccessImpl) then) =
      __$$PinSuccessImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$PinSuccessImplCopyWithImpl<$Res>
    extends _$PinResultCopyWithImpl<$Res, _$PinSuccessImpl>
    implements _$$PinSuccessImplCopyWith<$Res> {
  __$$PinSuccessImplCopyWithImpl(
      _$PinSuccessImpl _value, $Res Function(_$PinSuccessImpl) _then)
      : super(_value, _then);

  /// Create a copy of PinResult
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$PinSuccessImpl implements _PinSuccess {
  _$PinSuccessImpl();

  @override
  String toString() {
    return 'PinResult.success()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$PinSuccessImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() success,
    required TResult Function(FidoPinFailureReason reason) failed,
  }) {
    return success();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? success,
    TResult? Function(FidoPinFailureReason reason)? failed,
  }) {
    return success?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? success,
    TResult Function(FidoPinFailureReason reason)? failed,
    required TResult orElse(),
  }) {
    if (success != null) {
      return success();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_PinSuccess value) success,
    required TResult Function(_PinFailure value) failed,
  }) {
    return success(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_PinSuccess value)? success,
    TResult? Function(_PinFailure value)? failed,
  }) {
    return success?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_PinSuccess value)? success,
    TResult Function(_PinFailure value)? failed,
    required TResult orElse(),
  }) {
    if (success != null) {
      return success(this);
    }
    return orElse();
  }
}

abstract class _PinSuccess implements PinResult {
  factory _PinSuccess() = _$PinSuccessImpl;
}

/// @nodoc
abstract class _$$PinFailureImplCopyWith<$Res> {
  factory _$$PinFailureImplCopyWith(
          _$PinFailureImpl value, $Res Function(_$PinFailureImpl) then) =
      __$$PinFailureImplCopyWithImpl<$Res>;
  @useResult
  $Res call({FidoPinFailureReason reason});

  $FidoPinFailureReasonCopyWith<$Res> get reason;
}

/// @nodoc
class __$$PinFailureImplCopyWithImpl<$Res>
    extends _$PinResultCopyWithImpl<$Res, _$PinFailureImpl>
    implements _$$PinFailureImplCopyWith<$Res> {
  __$$PinFailureImplCopyWithImpl(
      _$PinFailureImpl _value, $Res Function(_$PinFailureImpl) _then)
      : super(_value, _then);

  /// Create a copy of PinResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? reason = null,
  }) {
    return _then(_$PinFailureImpl(
      null == reason
          ? _value.reason
          : reason // ignore: cast_nullable_to_non_nullable
              as FidoPinFailureReason,
    ));
  }

  /// Create a copy of PinResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $FidoPinFailureReasonCopyWith<$Res> get reason {
    return $FidoPinFailureReasonCopyWith<$Res>(_value.reason, (value) {
      return _then(_value.copyWith(reason: value));
    });
  }
}

/// @nodoc

class _$PinFailureImpl implements _PinFailure {
  _$PinFailureImpl(this.reason);

  @override
  final FidoPinFailureReason reason;

  @override
  String toString() {
    return 'PinResult.failed(reason: $reason)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PinFailureImpl &&
            (identical(other.reason, reason) || other.reason == reason));
  }

  @override
  int get hashCode => Object.hash(runtimeType, reason);

  /// Create a copy of PinResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PinFailureImplCopyWith<_$PinFailureImpl> get copyWith =>
      __$$PinFailureImplCopyWithImpl<_$PinFailureImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() success,
    required TResult Function(FidoPinFailureReason reason) failed,
  }) {
    return failed(reason);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? success,
    TResult? Function(FidoPinFailureReason reason)? failed,
  }) {
    return failed?.call(reason);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? success,
    TResult Function(FidoPinFailureReason reason)? failed,
    required TResult orElse(),
  }) {
    if (failed != null) {
      return failed(reason);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_PinSuccess value) success,
    required TResult Function(_PinFailure value) failed,
  }) {
    return failed(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_PinSuccess value)? success,
    TResult? Function(_PinFailure value)? failed,
  }) {
    return failed?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_PinSuccess value)? success,
    TResult Function(_PinFailure value)? failed,
    required TResult orElse(),
  }) {
    if (failed != null) {
      return failed(this);
    }
    return orElse();
  }
}

abstract class _PinFailure implements PinResult {
  factory _PinFailure(final FidoPinFailureReason reason) = _$PinFailureImpl;

  FidoPinFailureReason get reason;

  /// Create a copy of PinResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PinFailureImplCopyWith<_$PinFailureImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$FidoPinFailureReason {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int retries, bool authBlocked) invalidPin,
    required TResult Function() weakPin,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(int retries, bool authBlocked)? invalidPin,
    TResult? Function()? weakPin,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int retries, bool authBlocked)? invalidPin,
    TResult Function()? weakPin,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(FidoInvalidPin value) invalidPin,
    required TResult Function(FidoWeakPin value) weakPin,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(FidoInvalidPin value)? invalidPin,
    TResult? Function(FidoWeakPin value)? weakPin,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(FidoInvalidPin value)? invalidPin,
    TResult Function(FidoWeakPin value)? weakPin,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FidoPinFailureReasonCopyWith<$Res> {
  factory $FidoPinFailureReasonCopyWith(FidoPinFailureReason value,
          $Res Function(FidoPinFailureReason) then) =
      _$FidoPinFailureReasonCopyWithImpl<$Res, FidoPinFailureReason>;
}

/// @nodoc
class _$FidoPinFailureReasonCopyWithImpl<$Res,
        $Val extends FidoPinFailureReason>
    implements $FidoPinFailureReasonCopyWith<$Res> {
  _$FidoPinFailureReasonCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FidoPinFailureReason
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$FidoInvalidPinImplCopyWith<$Res> {
  factory _$$FidoInvalidPinImplCopyWith(_$FidoInvalidPinImpl value,
          $Res Function(_$FidoInvalidPinImpl) then) =
      __$$FidoInvalidPinImplCopyWithImpl<$Res>;
  @useResult
  $Res call({int retries, bool authBlocked});
}

/// @nodoc
class __$$FidoInvalidPinImplCopyWithImpl<$Res>
    extends _$FidoPinFailureReasonCopyWithImpl<$Res, _$FidoInvalidPinImpl>
    implements _$$FidoInvalidPinImplCopyWith<$Res> {
  __$$FidoInvalidPinImplCopyWithImpl(
      _$FidoInvalidPinImpl _value, $Res Function(_$FidoInvalidPinImpl) _then)
      : super(_value, _then);

  /// Create a copy of FidoPinFailureReason
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? retries = null,
    Object? authBlocked = null,
  }) {
    return _then(_$FidoInvalidPinImpl(
      null == retries
          ? _value.retries
          : retries // ignore: cast_nullable_to_non_nullable
              as int,
      null == authBlocked
          ? _value.authBlocked
          : authBlocked // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$FidoInvalidPinImpl implements FidoInvalidPin {
  _$FidoInvalidPinImpl(this.retries, this.authBlocked);

  @override
  final int retries;
  @override
  final bool authBlocked;

  @override
  String toString() {
    return 'FidoPinFailureReason.invalidPin(retries: $retries, authBlocked: $authBlocked)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FidoInvalidPinImpl &&
            (identical(other.retries, retries) || other.retries == retries) &&
            (identical(other.authBlocked, authBlocked) ||
                other.authBlocked == authBlocked));
  }

  @override
  int get hashCode => Object.hash(runtimeType, retries, authBlocked);

  /// Create a copy of FidoPinFailureReason
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FidoInvalidPinImplCopyWith<_$FidoInvalidPinImpl> get copyWith =>
      __$$FidoInvalidPinImplCopyWithImpl<_$FidoInvalidPinImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int retries, bool authBlocked) invalidPin,
    required TResult Function() weakPin,
  }) {
    return invalidPin(retries, authBlocked);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(int retries, bool authBlocked)? invalidPin,
    TResult? Function()? weakPin,
  }) {
    return invalidPin?.call(retries, authBlocked);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int retries, bool authBlocked)? invalidPin,
    TResult Function()? weakPin,
    required TResult orElse(),
  }) {
    if (invalidPin != null) {
      return invalidPin(retries, authBlocked);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(FidoInvalidPin value) invalidPin,
    required TResult Function(FidoWeakPin value) weakPin,
  }) {
    return invalidPin(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(FidoInvalidPin value)? invalidPin,
    TResult? Function(FidoWeakPin value)? weakPin,
  }) {
    return invalidPin?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(FidoInvalidPin value)? invalidPin,
    TResult Function(FidoWeakPin value)? weakPin,
    required TResult orElse(),
  }) {
    if (invalidPin != null) {
      return invalidPin(this);
    }
    return orElse();
  }
}

abstract class FidoInvalidPin implements FidoPinFailureReason {
  factory FidoInvalidPin(final int retries, final bool authBlocked) =
      _$FidoInvalidPinImpl;

  int get retries;
  bool get authBlocked;

  /// Create a copy of FidoPinFailureReason
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FidoInvalidPinImplCopyWith<_$FidoInvalidPinImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$FidoWeakPinImplCopyWith<$Res> {
  factory _$$FidoWeakPinImplCopyWith(
          _$FidoWeakPinImpl value, $Res Function(_$FidoWeakPinImpl) then) =
      __$$FidoWeakPinImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$FidoWeakPinImplCopyWithImpl<$Res>
    extends _$FidoPinFailureReasonCopyWithImpl<$Res, _$FidoWeakPinImpl>
    implements _$$FidoWeakPinImplCopyWith<$Res> {
  __$$FidoWeakPinImplCopyWithImpl(
      _$FidoWeakPinImpl _value, $Res Function(_$FidoWeakPinImpl) _then)
      : super(_value, _then);

  /// Create a copy of FidoPinFailureReason
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$FidoWeakPinImpl implements FidoWeakPin {
  const _$FidoWeakPinImpl();

  @override
  String toString() {
    return 'FidoPinFailureReason.weakPin()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$FidoWeakPinImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int retries, bool authBlocked) invalidPin,
    required TResult Function() weakPin,
  }) {
    return weakPin();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(int retries, bool authBlocked)? invalidPin,
    TResult? Function()? weakPin,
  }) {
    return weakPin?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int retries, bool authBlocked)? invalidPin,
    TResult Function()? weakPin,
    required TResult orElse(),
  }) {
    if (weakPin != null) {
      return weakPin();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(FidoInvalidPin value) invalidPin,
    required TResult Function(FidoWeakPin value) weakPin,
  }) {
    return weakPin(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(FidoInvalidPin value)? invalidPin,
    TResult? Function(FidoWeakPin value)? weakPin,
  }) {
    return weakPin?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(FidoInvalidPin value)? invalidPin,
    TResult Function(FidoWeakPin value)? weakPin,
    required TResult orElse(),
  }) {
    if (weakPin != null) {
      return weakPin(this);
    }
    return orElse();
  }
}

abstract class FidoWeakPin implements FidoPinFailureReason {
  const factory FidoWeakPin() = _$FidoWeakPinImpl;
}

Fingerprint _$FingerprintFromJson(Map<String, dynamic> json) {
  return _Fingerprint.fromJson(json);
}

/// @nodoc
mixin _$Fingerprint {
  String get templateId => throw _privateConstructorUsedError;
  String? get name => throw _privateConstructorUsedError;

  /// Serializes this Fingerprint to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Fingerprint
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FingerprintCopyWith<Fingerprint> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FingerprintCopyWith<$Res> {
  factory $FingerprintCopyWith(
          Fingerprint value, $Res Function(Fingerprint) then) =
      _$FingerprintCopyWithImpl<$Res, Fingerprint>;
  @useResult
  $Res call({String templateId, String? name});
}

/// @nodoc
class _$FingerprintCopyWithImpl<$Res, $Val extends Fingerprint>
    implements $FingerprintCopyWith<$Res> {
  _$FingerprintCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Fingerprint
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? templateId = null,
    Object? name = freezed,
  }) {
    return _then(_value.copyWith(
      templateId: null == templateId
          ? _value.templateId
          : templateId // ignore: cast_nullable_to_non_nullable
              as String,
      name: freezed == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FingerprintImplCopyWith<$Res>
    implements $FingerprintCopyWith<$Res> {
  factory _$$FingerprintImplCopyWith(
          _$FingerprintImpl value, $Res Function(_$FingerprintImpl) then) =
      __$$FingerprintImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String templateId, String? name});
}

/// @nodoc
class __$$FingerprintImplCopyWithImpl<$Res>
    extends _$FingerprintCopyWithImpl<$Res, _$FingerprintImpl>
    implements _$$FingerprintImplCopyWith<$Res> {
  __$$FingerprintImplCopyWithImpl(
      _$FingerprintImpl _value, $Res Function(_$FingerprintImpl) _then)
      : super(_value, _then);

  /// Create a copy of Fingerprint
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? templateId = null,
    Object? name = freezed,
  }) {
    return _then(_$FingerprintImpl(
      null == templateId
          ? _value.templateId
          : templateId // ignore: cast_nullable_to_non_nullable
              as String,
      freezed == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FingerprintImpl extends _Fingerprint {
  _$FingerprintImpl(this.templateId, this.name) : super._();

  factory _$FingerprintImpl.fromJson(Map<String, dynamic> json) =>
      _$$FingerprintImplFromJson(json);

  @override
  final String templateId;
  @override
  final String? name;

  @override
  String toString() {
    return 'Fingerprint(templateId: $templateId, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FingerprintImpl &&
            (identical(other.templateId, templateId) ||
                other.templateId == templateId) &&
            (identical(other.name, name) || other.name == name));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, templateId, name);

  /// Create a copy of Fingerprint
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FingerprintImplCopyWith<_$FingerprintImpl> get copyWith =>
      __$$FingerprintImplCopyWithImpl<_$FingerprintImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FingerprintImplToJson(
      this,
    );
  }
}

abstract class _Fingerprint extends Fingerprint {
  factory _Fingerprint(final String templateId, final String? name) =
      _$FingerprintImpl;
  _Fingerprint._() : super._();

  factory _Fingerprint.fromJson(Map<String, dynamic> json) =
      _$FingerprintImpl.fromJson;

  @override
  String get templateId;
  @override
  String? get name;

  /// Create a copy of Fingerprint
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FingerprintImplCopyWith<_$FingerprintImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$FingerprintEvent {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int remaining) capture,
    required TResult Function(Fingerprint fingerprint) complete,
    required TResult Function(int code) error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(int remaining)? capture,
    TResult? Function(Fingerprint fingerprint)? complete,
    TResult? Function(int code)? error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int remaining)? capture,
    TResult Function(Fingerprint fingerprint)? complete,
    TResult Function(int code)? error,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_EventCapture value) capture,
    required TResult Function(_EventComplete value) complete,
    required TResult Function(_EventError value) error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_EventCapture value)? capture,
    TResult? Function(_EventComplete value)? complete,
    TResult? Function(_EventError value)? error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_EventCapture value)? capture,
    TResult Function(_EventComplete value)? complete,
    TResult Function(_EventError value)? error,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FingerprintEventCopyWith<$Res> {
  factory $FingerprintEventCopyWith(
          FingerprintEvent value, $Res Function(FingerprintEvent) then) =
      _$FingerprintEventCopyWithImpl<$Res, FingerprintEvent>;
}

/// @nodoc
class _$FingerprintEventCopyWithImpl<$Res, $Val extends FingerprintEvent>
    implements $FingerprintEventCopyWith<$Res> {
  _$FingerprintEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FingerprintEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$EventCaptureImplCopyWith<$Res> {
  factory _$$EventCaptureImplCopyWith(
          _$EventCaptureImpl value, $Res Function(_$EventCaptureImpl) then) =
      __$$EventCaptureImplCopyWithImpl<$Res>;
  @useResult
  $Res call({int remaining});
}

/// @nodoc
class __$$EventCaptureImplCopyWithImpl<$Res>
    extends _$FingerprintEventCopyWithImpl<$Res, _$EventCaptureImpl>
    implements _$$EventCaptureImplCopyWith<$Res> {
  __$$EventCaptureImplCopyWithImpl(
      _$EventCaptureImpl _value, $Res Function(_$EventCaptureImpl) _then)
      : super(_value, _then);

  /// Create a copy of FingerprintEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? remaining = null,
  }) {
    return _then(_$EventCaptureImpl(
      null == remaining
          ? _value.remaining
          : remaining // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class _$EventCaptureImpl implements _EventCapture {
  _$EventCaptureImpl(this.remaining);

  @override
  final int remaining;

  @override
  String toString() {
    return 'FingerprintEvent.capture(remaining: $remaining)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EventCaptureImpl &&
            (identical(other.remaining, remaining) ||
                other.remaining == remaining));
  }

  @override
  int get hashCode => Object.hash(runtimeType, remaining);

  /// Create a copy of FingerprintEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EventCaptureImplCopyWith<_$EventCaptureImpl> get copyWith =>
      __$$EventCaptureImplCopyWithImpl<_$EventCaptureImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int remaining) capture,
    required TResult Function(Fingerprint fingerprint) complete,
    required TResult Function(int code) error,
  }) {
    return capture(remaining);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(int remaining)? capture,
    TResult? Function(Fingerprint fingerprint)? complete,
    TResult? Function(int code)? error,
  }) {
    return capture?.call(remaining);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int remaining)? capture,
    TResult Function(Fingerprint fingerprint)? complete,
    TResult Function(int code)? error,
    required TResult orElse(),
  }) {
    if (capture != null) {
      return capture(remaining);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_EventCapture value) capture,
    required TResult Function(_EventComplete value) complete,
    required TResult Function(_EventError value) error,
  }) {
    return capture(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_EventCapture value)? capture,
    TResult? Function(_EventComplete value)? complete,
    TResult? Function(_EventError value)? error,
  }) {
    return capture?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_EventCapture value)? capture,
    TResult Function(_EventComplete value)? complete,
    TResult Function(_EventError value)? error,
    required TResult orElse(),
  }) {
    if (capture != null) {
      return capture(this);
    }
    return orElse();
  }
}

abstract class _EventCapture implements FingerprintEvent {
  factory _EventCapture(final int remaining) = _$EventCaptureImpl;

  int get remaining;

  /// Create a copy of FingerprintEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EventCaptureImplCopyWith<_$EventCaptureImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$EventCompleteImplCopyWith<$Res> {
  factory _$$EventCompleteImplCopyWith(
          _$EventCompleteImpl value, $Res Function(_$EventCompleteImpl) then) =
      __$$EventCompleteImplCopyWithImpl<$Res>;
  @useResult
  $Res call({Fingerprint fingerprint});

  $FingerprintCopyWith<$Res> get fingerprint;
}

/// @nodoc
class __$$EventCompleteImplCopyWithImpl<$Res>
    extends _$FingerprintEventCopyWithImpl<$Res, _$EventCompleteImpl>
    implements _$$EventCompleteImplCopyWith<$Res> {
  __$$EventCompleteImplCopyWithImpl(
      _$EventCompleteImpl _value, $Res Function(_$EventCompleteImpl) _then)
      : super(_value, _then);

  /// Create a copy of FingerprintEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? fingerprint = null,
  }) {
    return _then(_$EventCompleteImpl(
      null == fingerprint
          ? _value.fingerprint
          : fingerprint // ignore: cast_nullable_to_non_nullable
              as Fingerprint,
    ));
  }

  /// Create a copy of FingerprintEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $FingerprintCopyWith<$Res> get fingerprint {
    return $FingerprintCopyWith<$Res>(_value.fingerprint, (value) {
      return _then(_value.copyWith(fingerprint: value));
    });
  }
}

/// @nodoc

class _$EventCompleteImpl implements _EventComplete {
  _$EventCompleteImpl(this.fingerprint);

  @override
  final Fingerprint fingerprint;

  @override
  String toString() {
    return 'FingerprintEvent.complete(fingerprint: $fingerprint)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EventCompleteImpl &&
            (identical(other.fingerprint, fingerprint) ||
                other.fingerprint == fingerprint));
  }

  @override
  int get hashCode => Object.hash(runtimeType, fingerprint);

  /// Create a copy of FingerprintEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EventCompleteImplCopyWith<_$EventCompleteImpl> get copyWith =>
      __$$EventCompleteImplCopyWithImpl<_$EventCompleteImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int remaining) capture,
    required TResult Function(Fingerprint fingerprint) complete,
    required TResult Function(int code) error,
  }) {
    return complete(fingerprint);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(int remaining)? capture,
    TResult? Function(Fingerprint fingerprint)? complete,
    TResult? Function(int code)? error,
  }) {
    return complete?.call(fingerprint);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int remaining)? capture,
    TResult Function(Fingerprint fingerprint)? complete,
    TResult Function(int code)? error,
    required TResult orElse(),
  }) {
    if (complete != null) {
      return complete(fingerprint);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_EventCapture value) capture,
    required TResult Function(_EventComplete value) complete,
    required TResult Function(_EventError value) error,
  }) {
    return complete(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_EventCapture value)? capture,
    TResult? Function(_EventComplete value)? complete,
    TResult? Function(_EventError value)? error,
  }) {
    return complete?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_EventCapture value)? capture,
    TResult Function(_EventComplete value)? complete,
    TResult Function(_EventError value)? error,
    required TResult orElse(),
  }) {
    if (complete != null) {
      return complete(this);
    }
    return orElse();
  }
}

abstract class _EventComplete implements FingerprintEvent {
  factory _EventComplete(final Fingerprint fingerprint) = _$EventCompleteImpl;

  Fingerprint get fingerprint;

  /// Create a copy of FingerprintEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EventCompleteImplCopyWith<_$EventCompleteImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$EventErrorImplCopyWith<$Res> {
  factory _$$EventErrorImplCopyWith(
          _$EventErrorImpl value, $Res Function(_$EventErrorImpl) then) =
      __$$EventErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({int code});
}

/// @nodoc
class __$$EventErrorImplCopyWithImpl<$Res>
    extends _$FingerprintEventCopyWithImpl<$Res, _$EventErrorImpl>
    implements _$$EventErrorImplCopyWith<$Res> {
  __$$EventErrorImplCopyWithImpl(
      _$EventErrorImpl _value, $Res Function(_$EventErrorImpl) _then)
      : super(_value, _then);

  /// Create a copy of FingerprintEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? code = null,
  }) {
    return _then(_$EventErrorImpl(
      null == code
          ? _value.code
          : code // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class _$EventErrorImpl implements _EventError {
  _$EventErrorImpl(this.code);

  @override
  final int code;

  @override
  String toString() {
    return 'FingerprintEvent.error(code: $code)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EventErrorImpl &&
            (identical(other.code, code) || other.code == code));
  }

  @override
  int get hashCode => Object.hash(runtimeType, code);

  /// Create a copy of FingerprintEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EventErrorImplCopyWith<_$EventErrorImpl> get copyWith =>
      __$$EventErrorImplCopyWithImpl<_$EventErrorImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int remaining) capture,
    required TResult Function(Fingerprint fingerprint) complete,
    required TResult Function(int code) error,
  }) {
    return error(code);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(int remaining)? capture,
    TResult? Function(Fingerprint fingerprint)? complete,
    TResult? Function(int code)? error,
  }) {
    return error?.call(code);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int remaining)? capture,
    TResult Function(Fingerprint fingerprint)? complete,
    TResult Function(int code)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(code);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_EventCapture value) capture,
    required TResult Function(_EventComplete value) complete,
    required TResult Function(_EventError value) error,
  }) {
    return error(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_EventCapture value)? capture,
    TResult? Function(_EventComplete value)? complete,
    TResult? Function(_EventError value)? error,
  }) {
    return error?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_EventCapture value)? capture,
    TResult Function(_EventComplete value)? complete,
    TResult Function(_EventError value)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(this);
    }
    return orElse();
  }
}

abstract class _EventError implements FingerprintEvent {
  factory _EventError(final int code) = _$EventErrorImpl;

  int get code;

  /// Create a copy of FingerprintEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EventErrorImplCopyWith<_$EventErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

FidoCredential _$FidoCredentialFromJson(Map<String, dynamic> json) {
  return _FidoCredential.fromJson(json);
}

/// @nodoc
mixin _$FidoCredential {
  String get rpId => throw _privateConstructorUsedError;
  String get credentialId => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get userName => throw _privateConstructorUsedError;
  String? get displayName => throw _privateConstructorUsedError;

  /// Serializes this FidoCredential to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FidoCredential
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FidoCredentialCopyWith<FidoCredential> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FidoCredentialCopyWith<$Res> {
  factory $FidoCredentialCopyWith(
          FidoCredential value, $Res Function(FidoCredential) then) =
      _$FidoCredentialCopyWithImpl<$Res, FidoCredential>;
  @useResult
  $Res call(
      {String rpId,
      String credentialId,
      String userId,
      String userName,
      String? displayName});
}

/// @nodoc
class _$FidoCredentialCopyWithImpl<$Res, $Val extends FidoCredential>
    implements $FidoCredentialCopyWith<$Res> {
  _$FidoCredentialCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FidoCredential
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? rpId = null,
    Object? credentialId = null,
    Object? userId = null,
    Object? userName = null,
    Object? displayName = freezed,
  }) {
    return _then(_value.copyWith(
      rpId: null == rpId
          ? _value.rpId
          : rpId // ignore: cast_nullable_to_non_nullable
              as String,
      credentialId: null == credentialId
          ? _value.credentialId
          : credentialId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      userName: null == userName
          ? _value.userName
          : userName // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: freezed == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FidoCredentialImplCopyWith<$Res>
    implements $FidoCredentialCopyWith<$Res> {
  factory _$$FidoCredentialImplCopyWith(_$FidoCredentialImpl value,
          $Res Function(_$FidoCredentialImpl) then) =
      __$$FidoCredentialImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String rpId,
      String credentialId,
      String userId,
      String userName,
      String? displayName});
}

/// @nodoc
class __$$FidoCredentialImplCopyWithImpl<$Res>
    extends _$FidoCredentialCopyWithImpl<$Res, _$FidoCredentialImpl>
    implements _$$FidoCredentialImplCopyWith<$Res> {
  __$$FidoCredentialImplCopyWithImpl(
      _$FidoCredentialImpl _value, $Res Function(_$FidoCredentialImpl) _then)
      : super(_value, _then);

  /// Create a copy of FidoCredential
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? rpId = null,
    Object? credentialId = null,
    Object? userId = null,
    Object? userName = null,
    Object? displayName = freezed,
  }) {
    return _then(_$FidoCredentialImpl(
      rpId: null == rpId
          ? _value.rpId
          : rpId // ignore: cast_nullable_to_non_nullable
              as String,
      credentialId: null == credentialId
          ? _value.credentialId
          : credentialId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      userName: null == userName
          ? _value.userName
          : userName // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: freezed == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FidoCredentialImpl implements _FidoCredential {
  _$FidoCredentialImpl(
      {required this.rpId,
      required this.credentialId,
      required this.userId,
      required this.userName,
      this.displayName});

  factory _$FidoCredentialImpl.fromJson(Map<String, dynamic> json) =>
      _$$FidoCredentialImplFromJson(json);

  @override
  final String rpId;
  @override
  final String credentialId;
  @override
  final String userId;
  @override
  final String userName;
  @override
  final String? displayName;

  @override
  String toString() {
    return 'FidoCredential(rpId: $rpId, credentialId: $credentialId, userId: $userId, userName: $userName, displayName: $displayName)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FidoCredentialImpl &&
            (identical(other.rpId, rpId) || other.rpId == rpId) &&
            (identical(other.credentialId, credentialId) ||
                other.credentialId == credentialId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.userName, userName) ||
                other.userName == userName) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, rpId, credentialId, userId, userName, displayName);

  /// Create a copy of FidoCredential
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FidoCredentialImplCopyWith<_$FidoCredentialImpl> get copyWith =>
      __$$FidoCredentialImplCopyWithImpl<_$FidoCredentialImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FidoCredentialImplToJson(
      this,
    );
  }
}

abstract class _FidoCredential implements FidoCredential {
  factory _FidoCredential(
      {required final String rpId,
      required final String credentialId,
      required final String userId,
      required final String userName,
      final String? displayName}) = _$FidoCredentialImpl;

  factory _FidoCredential.fromJson(Map<String, dynamic> json) =
      _$FidoCredentialImpl.fromJson;

  @override
  String get rpId;
  @override
  String get credentialId;
  @override
  String get userId;
  @override
  String get userName;
  @override
  String? get displayName;

  /// Create a copy of FidoCredential
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FidoCredentialImplCopyWith<_$FidoCredentialImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
