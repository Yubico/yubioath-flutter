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

PinMetadata _$PinMetadataFromJson(Map<String, dynamic> json) {
  return _PinMetadata.fromJson(json);
}

/// @nodoc
mixin _$PinMetadata {
  bool get defaultValue => throw _privateConstructorUsedError;
  int get totalAttempts => throw _privateConstructorUsedError;
  int get attemptsRemaining => throw _privateConstructorUsedError;

  /// Serializes this PinMetadata to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PinMetadata
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PinMetadataCopyWith<PinMetadata> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PinMetadataCopyWith<$Res> {
  factory $PinMetadataCopyWith(
          PinMetadata value, $Res Function(PinMetadata) then) =
      _$PinMetadataCopyWithImpl<$Res, PinMetadata>;
  @useResult
  $Res call({bool defaultValue, int totalAttempts, int attemptsRemaining});
}

/// @nodoc
class _$PinMetadataCopyWithImpl<$Res, $Val extends PinMetadata>
    implements $PinMetadataCopyWith<$Res> {
  _$PinMetadataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PinMetadata
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? defaultValue = null,
    Object? totalAttempts = null,
    Object? attemptsRemaining = null,
  }) {
    return _then(_value.copyWith(
      defaultValue: null == defaultValue
          ? _value.defaultValue
          : defaultValue // ignore: cast_nullable_to_non_nullable
              as bool,
      totalAttempts: null == totalAttempts
          ? _value.totalAttempts
          : totalAttempts // ignore: cast_nullable_to_non_nullable
              as int,
      attemptsRemaining: null == attemptsRemaining
          ? _value.attemptsRemaining
          : attemptsRemaining // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PinMetadataImplCopyWith<$Res>
    implements $PinMetadataCopyWith<$Res> {
  factory _$$PinMetadataImplCopyWith(
          _$PinMetadataImpl value, $Res Function(_$PinMetadataImpl) then) =
      __$$PinMetadataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({bool defaultValue, int totalAttempts, int attemptsRemaining});
}

/// @nodoc
class __$$PinMetadataImplCopyWithImpl<$Res>
    extends _$PinMetadataCopyWithImpl<$Res, _$PinMetadataImpl>
    implements _$$PinMetadataImplCopyWith<$Res> {
  __$$PinMetadataImplCopyWithImpl(
      _$PinMetadataImpl _value, $Res Function(_$PinMetadataImpl) _then)
      : super(_value, _then);

  /// Create a copy of PinMetadata
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? defaultValue = null,
    Object? totalAttempts = null,
    Object? attemptsRemaining = null,
  }) {
    return _then(_$PinMetadataImpl(
      null == defaultValue
          ? _value.defaultValue
          : defaultValue // ignore: cast_nullable_to_non_nullable
              as bool,
      null == totalAttempts
          ? _value.totalAttempts
          : totalAttempts // ignore: cast_nullable_to_non_nullable
              as int,
      null == attemptsRemaining
          ? _value.attemptsRemaining
          : attemptsRemaining // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PinMetadataImpl implements _PinMetadata {
  _$PinMetadataImpl(
      this.defaultValue, this.totalAttempts, this.attemptsRemaining);

  factory _$PinMetadataImpl.fromJson(Map<String, dynamic> json) =>
      _$$PinMetadataImplFromJson(json);

  @override
  final bool defaultValue;
  @override
  final int totalAttempts;
  @override
  final int attemptsRemaining;

  @override
  String toString() {
    return 'PinMetadata(defaultValue: $defaultValue, totalAttempts: $totalAttempts, attemptsRemaining: $attemptsRemaining)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PinMetadataImpl &&
            (identical(other.defaultValue, defaultValue) ||
                other.defaultValue == defaultValue) &&
            (identical(other.totalAttempts, totalAttempts) ||
                other.totalAttempts == totalAttempts) &&
            (identical(other.attemptsRemaining, attemptsRemaining) ||
                other.attemptsRemaining == attemptsRemaining));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, defaultValue, totalAttempts, attemptsRemaining);

  /// Create a copy of PinMetadata
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PinMetadataImplCopyWith<_$PinMetadataImpl> get copyWith =>
      __$$PinMetadataImplCopyWithImpl<_$PinMetadataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PinMetadataImplToJson(
      this,
    );
  }
}

abstract class _PinMetadata implements PinMetadata {
  factory _PinMetadata(final bool defaultValue, final int totalAttempts,
      final int attemptsRemaining) = _$PinMetadataImpl;

  factory _PinMetadata.fromJson(Map<String, dynamic> json) =
      _$PinMetadataImpl.fromJson;

  @override
  bool get defaultValue;
  @override
  int get totalAttempts;
  @override
  int get attemptsRemaining;

  /// Create a copy of PinMetadata
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PinMetadataImplCopyWith<_$PinMetadataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$PinVerificationStatus {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() success,
    required TResult Function(PivPinFailureReason reason) failure,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? success,
    TResult? Function(PivPinFailureReason reason)? failure,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? success,
    TResult Function(PivPinFailureReason reason)? failure,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(PinSuccess value) success,
    required TResult Function(PinFailure value) failure,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PinSuccess value)? success,
    TResult? Function(PinFailure value)? failure,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PinSuccess value)? success,
    TResult Function(PinFailure value)? failure,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PinVerificationStatusCopyWith<$Res> {
  factory $PinVerificationStatusCopyWith(PinVerificationStatus value,
          $Res Function(PinVerificationStatus) then) =
      _$PinVerificationStatusCopyWithImpl<$Res, PinVerificationStatus>;
}

/// @nodoc
class _$PinVerificationStatusCopyWithImpl<$Res,
        $Val extends PinVerificationStatus>
    implements $PinVerificationStatusCopyWith<$Res> {
  _$PinVerificationStatusCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PinVerificationStatus
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
    extends _$PinVerificationStatusCopyWithImpl<$Res, _$PinSuccessImpl>
    implements _$$PinSuccessImplCopyWith<$Res> {
  __$$PinSuccessImplCopyWithImpl(
      _$PinSuccessImpl _value, $Res Function(_$PinSuccessImpl) _then)
      : super(_value, _then);

  /// Create a copy of PinVerificationStatus
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$PinSuccessImpl implements PinSuccess {
  const _$PinSuccessImpl();

  @override
  String toString() {
    return 'PinVerificationStatus.success()';
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
    required TResult Function(PivPinFailureReason reason) failure,
  }) {
    return success();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? success,
    TResult? Function(PivPinFailureReason reason)? failure,
  }) {
    return success?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? success,
    TResult Function(PivPinFailureReason reason)? failure,
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
    required TResult Function(PinSuccess value) success,
    required TResult Function(PinFailure value) failure,
  }) {
    return success(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PinSuccess value)? success,
    TResult? Function(PinFailure value)? failure,
  }) {
    return success?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PinSuccess value)? success,
    TResult Function(PinFailure value)? failure,
    required TResult orElse(),
  }) {
    if (success != null) {
      return success(this);
    }
    return orElse();
  }
}

abstract class PinSuccess implements PinVerificationStatus {
  const factory PinSuccess() = _$PinSuccessImpl;
}

/// @nodoc
abstract class _$$PinFailureImplCopyWith<$Res> {
  factory _$$PinFailureImplCopyWith(
          _$PinFailureImpl value, $Res Function(_$PinFailureImpl) then) =
      __$$PinFailureImplCopyWithImpl<$Res>;
  @useResult
  $Res call({PivPinFailureReason reason});

  $PivPinFailureReasonCopyWith<$Res> get reason;
}

/// @nodoc
class __$$PinFailureImplCopyWithImpl<$Res>
    extends _$PinVerificationStatusCopyWithImpl<$Res, _$PinFailureImpl>
    implements _$$PinFailureImplCopyWith<$Res> {
  __$$PinFailureImplCopyWithImpl(
      _$PinFailureImpl _value, $Res Function(_$PinFailureImpl) _then)
      : super(_value, _then);

  /// Create a copy of PinVerificationStatus
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
              as PivPinFailureReason,
    ));
  }

  /// Create a copy of PinVerificationStatus
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PivPinFailureReasonCopyWith<$Res> get reason {
    return $PivPinFailureReasonCopyWith<$Res>(_value.reason, (value) {
      return _then(_value.copyWith(reason: value));
    });
  }
}

/// @nodoc

class _$PinFailureImpl implements PinFailure {
  _$PinFailureImpl(this.reason);

  @override
  final PivPinFailureReason reason;

  @override
  String toString() {
    return 'PinVerificationStatus.failure(reason: $reason)';
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

  /// Create a copy of PinVerificationStatus
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
    required TResult Function(PivPinFailureReason reason) failure,
  }) {
    return failure(reason);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? success,
    TResult? Function(PivPinFailureReason reason)? failure,
  }) {
    return failure?.call(reason);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? success,
    TResult Function(PivPinFailureReason reason)? failure,
    required TResult orElse(),
  }) {
    if (failure != null) {
      return failure(reason);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(PinSuccess value) success,
    required TResult Function(PinFailure value) failure,
  }) {
    return failure(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PinSuccess value)? success,
    TResult? Function(PinFailure value)? failure,
  }) {
    return failure?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PinSuccess value)? success,
    TResult Function(PinFailure value)? failure,
    required TResult orElse(),
  }) {
    if (failure != null) {
      return failure(this);
    }
    return orElse();
  }
}

abstract class PinFailure implements PinVerificationStatus {
  factory PinFailure(final PivPinFailureReason reason) = _$PinFailureImpl;

  PivPinFailureReason get reason;

  /// Create a copy of PinVerificationStatus
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PinFailureImplCopyWith<_$PinFailureImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$PivPinFailureReason {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int attemptsRemaining) invalidPin,
    required TResult Function() weakPin,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(int attemptsRemaining)? invalidPin,
    TResult? Function()? weakPin,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int attemptsRemaining)? invalidPin,
    TResult Function()? weakPin,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(PivInvalidPin value) invalidPin,
    required TResult Function(PivWeakPin value) weakPin,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PivInvalidPin value)? invalidPin,
    TResult? Function(PivWeakPin value)? weakPin,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PivInvalidPin value)? invalidPin,
    TResult Function(PivWeakPin value)? weakPin,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PivPinFailureReasonCopyWith<$Res> {
  factory $PivPinFailureReasonCopyWith(
          PivPinFailureReason value, $Res Function(PivPinFailureReason) then) =
      _$PivPinFailureReasonCopyWithImpl<$Res, PivPinFailureReason>;
}

/// @nodoc
class _$PivPinFailureReasonCopyWithImpl<$Res, $Val extends PivPinFailureReason>
    implements $PivPinFailureReasonCopyWith<$Res> {
  _$PivPinFailureReasonCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PivPinFailureReason
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$PivInvalidPinImplCopyWith<$Res> {
  factory _$$PivInvalidPinImplCopyWith(
          _$PivInvalidPinImpl value, $Res Function(_$PivInvalidPinImpl) then) =
      __$$PivInvalidPinImplCopyWithImpl<$Res>;
  @useResult
  $Res call({int attemptsRemaining});
}

/// @nodoc
class __$$PivInvalidPinImplCopyWithImpl<$Res>
    extends _$PivPinFailureReasonCopyWithImpl<$Res, _$PivInvalidPinImpl>
    implements _$$PivInvalidPinImplCopyWith<$Res> {
  __$$PivInvalidPinImplCopyWithImpl(
      _$PivInvalidPinImpl _value, $Res Function(_$PivInvalidPinImpl) _then)
      : super(_value, _then);

  /// Create a copy of PivPinFailureReason
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? attemptsRemaining = null,
  }) {
    return _then(_$PivInvalidPinImpl(
      null == attemptsRemaining
          ? _value.attemptsRemaining
          : attemptsRemaining // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class _$PivInvalidPinImpl implements PivInvalidPin {
  _$PivInvalidPinImpl(this.attemptsRemaining);

  @override
  final int attemptsRemaining;

  @override
  String toString() {
    return 'PivPinFailureReason.invalidPin(attemptsRemaining: $attemptsRemaining)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PivInvalidPinImpl &&
            (identical(other.attemptsRemaining, attemptsRemaining) ||
                other.attemptsRemaining == attemptsRemaining));
  }

  @override
  int get hashCode => Object.hash(runtimeType, attemptsRemaining);

  /// Create a copy of PivPinFailureReason
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PivInvalidPinImplCopyWith<_$PivInvalidPinImpl> get copyWith =>
      __$$PivInvalidPinImplCopyWithImpl<_$PivInvalidPinImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int attemptsRemaining) invalidPin,
    required TResult Function() weakPin,
  }) {
    return invalidPin(attemptsRemaining);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(int attemptsRemaining)? invalidPin,
    TResult? Function()? weakPin,
  }) {
    return invalidPin?.call(attemptsRemaining);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int attemptsRemaining)? invalidPin,
    TResult Function()? weakPin,
    required TResult orElse(),
  }) {
    if (invalidPin != null) {
      return invalidPin(attemptsRemaining);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(PivInvalidPin value) invalidPin,
    required TResult Function(PivWeakPin value) weakPin,
  }) {
    return invalidPin(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PivInvalidPin value)? invalidPin,
    TResult? Function(PivWeakPin value)? weakPin,
  }) {
    return invalidPin?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PivInvalidPin value)? invalidPin,
    TResult Function(PivWeakPin value)? weakPin,
    required TResult orElse(),
  }) {
    if (invalidPin != null) {
      return invalidPin(this);
    }
    return orElse();
  }
}

abstract class PivInvalidPin implements PivPinFailureReason {
  factory PivInvalidPin(final int attemptsRemaining) = _$PivInvalidPinImpl;

  int get attemptsRemaining;

  /// Create a copy of PivPinFailureReason
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PivInvalidPinImplCopyWith<_$PivInvalidPinImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$PivWeakPinImplCopyWith<$Res> {
  factory _$$PivWeakPinImplCopyWith(
          _$PivWeakPinImpl value, $Res Function(_$PivWeakPinImpl) then) =
      __$$PivWeakPinImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$PivWeakPinImplCopyWithImpl<$Res>
    extends _$PivPinFailureReasonCopyWithImpl<$Res, _$PivWeakPinImpl>
    implements _$$PivWeakPinImplCopyWith<$Res> {
  __$$PivWeakPinImplCopyWithImpl(
      _$PivWeakPinImpl _value, $Res Function(_$PivWeakPinImpl) _then)
      : super(_value, _then);

  /// Create a copy of PivPinFailureReason
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$PivWeakPinImpl implements PivWeakPin {
  const _$PivWeakPinImpl();

  @override
  String toString() {
    return 'PivPinFailureReason.weakPin()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$PivWeakPinImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int attemptsRemaining) invalidPin,
    required TResult Function() weakPin,
  }) {
    return weakPin();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(int attemptsRemaining)? invalidPin,
    TResult? Function()? weakPin,
  }) {
    return weakPin?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int attemptsRemaining)? invalidPin,
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
    required TResult Function(PivInvalidPin value) invalidPin,
    required TResult Function(PivWeakPin value) weakPin,
  }) {
    return weakPin(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PivInvalidPin value)? invalidPin,
    TResult? Function(PivWeakPin value)? weakPin,
  }) {
    return weakPin?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PivInvalidPin value)? invalidPin,
    TResult Function(PivWeakPin value)? weakPin,
    required TResult orElse(),
  }) {
    if (weakPin != null) {
      return weakPin(this);
    }
    return orElse();
  }
}

abstract class PivWeakPin implements PivPinFailureReason {
  const factory PivWeakPin() = _$PivWeakPinImpl;
}

ManagementKeyMetadata _$ManagementKeyMetadataFromJson(
    Map<String, dynamic> json) {
  return _ManagementKeyMetadata.fromJson(json);
}

/// @nodoc
mixin _$ManagementKeyMetadata {
  ManagementKeyType get keyType => throw _privateConstructorUsedError;
  bool get defaultValue => throw _privateConstructorUsedError;
  TouchPolicy get touchPolicy => throw _privateConstructorUsedError;

  /// Serializes this ManagementKeyMetadata to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ManagementKeyMetadata
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ManagementKeyMetadataCopyWith<ManagementKeyMetadata> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ManagementKeyMetadataCopyWith<$Res> {
  factory $ManagementKeyMetadataCopyWith(ManagementKeyMetadata value,
          $Res Function(ManagementKeyMetadata) then) =
      _$ManagementKeyMetadataCopyWithImpl<$Res, ManagementKeyMetadata>;
  @useResult
  $Res call(
      {ManagementKeyType keyType, bool defaultValue, TouchPolicy touchPolicy});
}

/// @nodoc
class _$ManagementKeyMetadataCopyWithImpl<$Res,
        $Val extends ManagementKeyMetadata>
    implements $ManagementKeyMetadataCopyWith<$Res> {
  _$ManagementKeyMetadataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ManagementKeyMetadata
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? keyType = null,
    Object? defaultValue = null,
    Object? touchPolicy = null,
  }) {
    return _then(_value.copyWith(
      keyType: null == keyType
          ? _value.keyType
          : keyType // ignore: cast_nullable_to_non_nullable
              as ManagementKeyType,
      defaultValue: null == defaultValue
          ? _value.defaultValue
          : defaultValue // ignore: cast_nullable_to_non_nullable
              as bool,
      touchPolicy: null == touchPolicy
          ? _value.touchPolicy
          : touchPolicy // ignore: cast_nullable_to_non_nullable
              as TouchPolicy,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ManagementKeyMetadataImplCopyWith<$Res>
    implements $ManagementKeyMetadataCopyWith<$Res> {
  factory _$$ManagementKeyMetadataImplCopyWith(
          _$ManagementKeyMetadataImpl value,
          $Res Function(_$ManagementKeyMetadataImpl) then) =
      __$$ManagementKeyMetadataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {ManagementKeyType keyType, bool defaultValue, TouchPolicy touchPolicy});
}

/// @nodoc
class __$$ManagementKeyMetadataImplCopyWithImpl<$Res>
    extends _$ManagementKeyMetadataCopyWithImpl<$Res,
        _$ManagementKeyMetadataImpl>
    implements _$$ManagementKeyMetadataImplCopyWith<$Res> {
  __$$ManagementKeyMetadataImplCopyWithImpl(_$ManagementKeyMetadataImpl _value,
      $Res Function(_$ManagementKeyMetadataImpl) _then)
      : super(_value, _then);

  /// Create a copy of ManagementKeyMetadata
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? keyType = null,
    Object? defaultValue = null,
    Object? touchPolicy = null,
  }) {
    return _then(_$ManagementKeyMetadataImpl(
      null == keyType
          ? _value.keyType
          : keyType // ignore: cast_nullable_to_non_nullable
              as ManagementKeyType,
      null == defaultValue
          ? _value.defaultValue
          : defaultValue // ignore: cast_nullable_to_non_nullable
              as bool,
      null == touchPolicy
          ? _value.touchPolicy
          : touchPolicy // ignore: cast_nullable_to_non_nullable
              as TouchPolicy,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ManagementKeyMetadataImpl implements _ManagementKeyMetadata {
  _$ManagementKeyMetadataImpl(
      this.keyType, this.defaultValue, this.touchPolicy);

  factory _$ManagementKeyMetadataImpl.fromJson(Map<String, dynamic> json) =>
      _$$ManagementKeyMetadataImplFromJson(json);

  @override
  final ManagementKeyType keyType;
  @override
  final bool defaultValue;
  @override
  final TouchPolicy touchPolicy;

  @override
  String toString() {
    return 'ManagementKeyMetadata(keyType: $keyType, defaultValue: $defaultValue, touchPolicy: $touchPolicy)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ManagementKeyMetadataImpl &&
            (identical(other.keyType, keyType) || other.keyType == keyType) &&
            (identical(other.defaultValue, defaultValue) ||
                other.defaultValue == defaultValue) &&
            (identical(other.touchPolicy, touchPolicy) ||
                other.touchPolicy == touchPolicy));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, keyType, defaultValue, touchPolicy);

  /// Create a copy of ManagementKeyMetadata
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ManagementKeyMetadataImplCopyWith<_$ManagementKeyMetadataImpl>
      get copyWith => __$$ManagementKeyMetadataImplCopyWithImpl<
          _$ManagementKeyMetadataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ManagementKeyMetadataImplToJson(
      this,
    );
  }
}

abstract class _ManagementKeyMetadata implements ManagementKeyMetadata {
  factory _ManagementKeyMetadata(
      final ManagementKeyType keyType,
      final bool defaultValue,
      final TouchPolicy touchPolicy) = _$ManagementKeyMetadataImpl;

  factory _ManagementKeyMetadata.fromJson(Map<String, dynamic> json) =
      _$ManagementKeyMetadataImpl.fromJson;

  @override
  ManagementKeyType get keyType;
  @override
  bool get defaultValue;
  @override
  TouchPolicy get touchPolicy;

  /// Create a copy of ManagementKeyMetadata
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ManagementKeyMetadataImplCopyWith<_$ManagementKeyMetadataImpl>
      get copyWith => throw _privateConstructorUsedError;
}

SlotMetadata _$SlotMetadataFromJson(Map<String, dynamic> json) {
  return _SlotMetadata.fromJson(json);
}

/// @nodoc
mixin _$SlotMetadata {
  KeyType get keyType => throw _privateConstructorUsedError;
  PinPolicy get pinPolicy => throw _privateConstructorUsedError;
  TouchPolicy get touchPolicy => throw _privateConstructorUsedError;
  bool get generated => throw _privateConstructorUsedError;
  String get publicKey => throw _privateConstructorUsedError;

  /// Serializes this SlotMetadata to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SlotMetadata
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SlotMetadataCopyWith<SlotMetadata> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SlotMetadataCopyWith<$Res> {
  factory $SlotMetadataCopyWith(
          SlotMetadata value, $Res Function(SlotMetadata) then) =
      _$SlotMetadataCopyWithImpl<$Res, SlotMetadata>;
  @useResult
  $Res call(
      {KeyType keyType,
      PinPolicy pinPolicy,
      TouchPolicy touchPolicy,
      bool generated,
      String publicKey});
}

/// @nodoc
class _$SlotMetadataCopyWithImpl<$Res, $Val extends SlotMetadata>
    implements $SlotMetadataCopyWith<$Res> {
  _$SlotMetadataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SlotMetadata
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? keyType = null,
    Object? pinPolicy = null,
    Object? touchPolicy = null,
    Object? generated = null,
    Object? publicKey = null,
  }) {
    return _then(_value.copyWith(
      keyType: null == keyType
          ? _value.keyType
          : keyType // ignore: cast_nullable_to_non_nullable
              as KeyType,
      pinPolicy: null == pinPolicy
          ? _value.pinPolicy
          : pinPolicy // ignore: cast_nullable_to_non_nullable
              as PinPolicy,
      touchPolicy: null == touchPolicy
          ? _value.touchPolicy
          : touchPolicy // ignore: cast_nullable_to_non_nullable
              as TouchPolicy,
      generated: null == generated
          ? _value.generated
          : generated // ignore: cast_nullable_to_non_nullable
              as bool,
      publicKey: null == publicKey
          ? _value.publicKey
          : publicKey // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SlotMetadataImplCopyWith<$Res>
    implements $SlotMetadataCopyWith<$Res> {
  factory _$$SlotMetadataImplCopyWith(
          _$SlotMetadataImpl value, $Res Function(_$SlotMetadataImpl) then) =
      __$$SlotMetadataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {KeyType keyType,
      PinPolicy pinPolicy,
      TouchPolicy touchPolicy,
      bool generated,
      String publicKey});
}

/// @nodoc
class __$$SlotMetadataImplCopyWithImpl<$Res>
    extends _$SlotMetadataCopyWithImpl<$Res, _$SlotMetadataImpl>
    implements _$$SlotMetadataImplCopyWith<$Res> {
  __$$SlotMetadataImplCopyWithImpl(
      _$SlotMetadataImpl _value, $Res Function(_$SlotMetadataImpl) _then)
      : super(_value, _then);

  /// Create a copy of SlotMetadata
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? keyType = null,
    Object? pinPolicy = null,
    Object? touchPolicy = null,
    Object? generated = null,
    Object? publicKey = null,
  }) {
    return _then(_$SlotMetadataImpl(
      null == keyType
          ? _value.keyType
          : keyType // ignore: cast_nullable_to_non_nullable
              as KeyType,
      null == pinPolicy
          ? _value.pinPolicy
          : pinPolicy // ignore: cast_nullable_to_non_nullable
              as PinPolicy,
      null == touchPolicy
          ? _value.touchPolicy
          : touchPolicy // ignore: cast_nullable_to_non_nullable
              as TouchPolicy,
      null == generated
          ? _value.generated
          : generated // ignore: cast_nullable_to_non_nullable
              as bool,
      null == publicKey
          ? _value.publicKey
          : publicKey // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SlotMetadataImpl implements _SlotMetadata {
  _$SlotMetadataImpl(this.keyType, this.pinPolicy, this.touchPolicy,
      this.generated, this.publicKey);

  factory _$SlotMetadataImpl.fromJson(Map<String, dynamic> json) =>
      _$$SlotMetadataImplFromJson(json);

  @override
  final KeyType keyType;
  @override
  final PinPolicy pinPolicy;
  @override
  final TouchPolicy touchPolicy;
  @override
  final bool generated;
  @override
  final String publicKey;

  @override
  String toString() {
    return 'SlotMetadata(keyType: $keyType, pinPolicy: $pinPolicy, touchPolicy: $touchPolicy, generated: $generated, publicKey: $publicKey)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SlotMetadataImpl &&
            (identical(other.keyType, keyType) || other.keyType == keyType) &&
            (identical(other.pinPolicy, pinPolicy) ||
                other.pinPolicy == pinPolicy) &&
            (identical(other.touchPolicy, touchPolicy) ||
                other.touchPolicy == touchPolicy) &&
            (identical(other.generated, generated) ||
                other.generated == generated) &&
            (identical(other.publicKey, publicKey) ||
                other.publicKey == publicKey));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, keyType, pinPolicy, touchPolicy, generated, publicKey);

  /// Create a copy of SlotMetadata
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SlotMetadataImplCopyWith<_$SlotMetadataImpl> get copyWith =>
      __$$SlotMetadataImplCopyWithImpl<_$SlotMetadataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SlotMetadataImplToJson(
      this,
    );
  }
}

abstract class _SlotMetadata implements SlotMetadata {
  factory _SlotMetadata(
      final KeyType keyType,
      final PinPolicy pinPolicy,
      final TouchPolicy touchPolicy,
      final bool generated,
      final String publicKey) = _$SlotMetadataImpl;

  factory _SlotMetadata.fromJson(Map<String, dynamic> json) =
      _$SlotMetadataImpl.fromJson;

  @override
  KeyType get keyType;
  @override
  PinPolicy get pinPolicy;
  @override
  TouchPolicy get touchPolicy;
  @override
  bool get generated;
  @override
  String get publicKey;

  /// Create a copy of SlotMetadata
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SlotMetadataImplCopyWith<_$SlotMetadataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PivStateMetadata _$PivStateMetadataFromJson(Map<String, dynamic> json) {
  return _PivStateMetadata.fromJson(json);
}

/// @nodoc
mixin _$PivStateMetadata {
  ManagementKeyMetadata get managementKeyMetadata =>
      throw _privateConstructorUsedError;
  PinMetadata get pinMetadata => throw _privateConstructorUsedError;
  PinMetadata get pukMetadata => throw _privateConstructorUsedError;

  /// Serializes this PivStateMetadata to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PivStateMetadata
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PivStateMetadataCopyWith<PivStateMetadata> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PivStateMetadataCopyWith<$Res> {
  factory $PivStateMetadataCopyWith(
          PivStateMetadata value, $Res Function(PivStateMetadata) then) =
      _$PivStateMetadataCopyWithImpl<$Res, PivStateMetadata>;
  @useResult
  $Res call(
      {ManagementKeyMetadata managementKeyMetadata,
      PinMetadata pinMetadata,
      PinMetadata pukMetadata});

  $ManagementKeyMetadataCopyWith<$Res> get managementKeyMetadata;
  $PinMetadataCopyWith<$Res> get pinMetadata;
  $PinMetadataCopyWith<$Res> get pukMetadata;
}

/// @nodoc
class _$PivStateMetadataCopyWithImpl<$Res, $Val extends PivStateMetadata>
    implements $PivStateMetadataCopyWith<$Res> {
  _$PivStateMetadataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PivStateMetadata
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? managementKeyMetadata = null,
    Object? pinMetadata = null,
    Object? pukMetadata = null,
  }) {
    return _then(_value.copyWith(
      managementKeyMetadata: null == managementKeyMetadata
          ? _value.managementKeyMetadata
          : managementKeyMetadata // ignore: cast_nullable_to_non_nullable
              as ManagementKeyMetadata,
      pinMetadata: null == pinMetadata
          ? _value.pinMetadata
          : pinMetadata // ignore: cast_nullable_to_non_nullable
              as PinMetadata,
      pukMetadata: null == pukMetadata
          ? _value.pukMetadata
          : pukMetadata // ignore: cast_nullable_to_non_nullable
              as PinMetadata,
    ) as $Val);
  }

  /// Create a copy of PivStateMetadata
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ManagementKeyMetadataCopyWith<$Res> get managementKeyMetadata {
    return $ManagementKeyMetadataCopyWith<$Res>(_value.managementKeyMetadata,
        (value) {
      return _then(_value.copyWith(managementKeyMetadata: value) as $Val);
    });
  }

  /// Create a copy of PivStateMetadata
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PinMetadataCopyWith<$Res> get pinMetadata {
    return $PinMetadataCopyWith<$Res>(_value.pinMetadata, (value) {
      return _then(_value.copyWith(pinMetadata: value) as $Val);
    });
  }

  /// Create a copy of PivStateMetadata
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PinMetadataCopyWith<$Res> get pukMetadata {
    return $PinMetadataCopyWith<$Res>(_value.pukMetadata, (value) {
      return _then(_value.copyWith(pukMetadata: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$PivStateMetadataImplCopyWith<$Res>
    implements $PivStateMetadataCopyWith<$Res> {
  factory _$$PivStateMetadataImplCopyWith(_$PivStateMetadataImpl value,
          $Res Function(_$PivStateMetadataImpl) then) =
      __$$PivStateMetadataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {ManagementKeyMetadata managementKeyMetadata,
      PinMetadata pinMetadata,
      PinMetadata pukMetadata});

  @override
  $ManagementKeyMetadataCopyWith<$Res> get managementKeyMetadata;
  @override
  $PinMetadataCopyWith<$Res> get pinMetadata;
  @override
  $PinMetadataCopyWith<$Res> get pukMetadata;
}

/// @nodoc
class __$$PivStateMetadataImplCopyWithImpl<$Res>
    extends _$PivStateMetadataCopyWithImpl<$Res, _$PivStateMetadataImpl>
    implements _$$PivStateMetadataImplCopyWith<$Res> {
  __$$PivStateMetadataImplCopyWithImpl(_$PivStateMetadataImpl _value,
      $Res Function(_$PivStateMetadataImpl) _then)
      : super(_value, _then);

  /// Create a copy of PivStateMetadata
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? managementKeyMetadata = null,
    Object? pinMetadata = null,
    Object? pukMetadata = null,
  }) {
    return _then(_$PivStateMetadataImpl(
      managementKeyMetadata: null == managementKeyMetadata
          ? _value.managementKeyMetadata
          : managementKeyMetadata // ignore: cast_nullable_to_non_nullable
              as ManagementKeyMetadata,
      pinMetadata: null == pinMetadata
          ? _value.pinMetadata
          : pinMetadata // ignore: cast_nullable_to_non_nullable
              as PinMetadata,
      pukMetadata: null == pukMetadata
          ? _value.pukMetadata
          : pukMetadata // ignore: cast_nullable_to_non_nullable
              as PinMetadata,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PivStateMetadataImpl implements _PivStateMetadata {
  _$PivStateMetadataImpl(
      {required this.managementKeyMetadata,
      required this.pinMetadata,
      required this.pukMetadata});

  factory _$PivStateMetadataImpl.fromJson(Map<String, dynamic> json) =>
      _$$PivStateMetadataImplFromJson(json);

  @override
  final ManagementKeyMetadata managementKeyMetadata;
  @override
  final PinMetadata pinMetadata;
  @override
  final PinMetadata pukMetadata;

  @override
  String toString() {
    return 'PivStateMetadata(managementKeyMetadata: $managementKeyMetadata, pinMetadata: $pinMetadata, pukMetadata: $pukMetadata)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PivStateMetadataImpl &&
            (identical(other.managementKeyMetadata, managementKeyMetadata) ||
                other.managementKeyMetadata == managementKeyMetadata) &&
            (identical(other.pinMetadata, pinMetadata) ||
                other.pinMetadata == pinMetadata) &&
            (identical(other.pukMetadata, pukMetadata) ||
                other.pukMetadata == pukMetadata));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, managementKeyMetadata, pinMetadata, pukMetadata);

  /// Create a copy of PivStateMetadata
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PivStateMetadataImplCopyWith<_$PivStateMetadataImpl> get copyWith =>
      __$$PivStateMetadataImplCopyWithImpl<_$PivStateMetadataImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PivStateMetadataImplToJson(
      this,
    );
  }
}

abstract class _PivStateMetadata implements PivStateMetadata {
  factory _PivStateMetadata(
      {required final ManagementKeyMetadata managementKeyMetadata,
      required final PinMetadata pinMetadata,
      required final PinMetadata pukMetadata}) = _$PivStateMetadataImpl;

  factory _PivStateMetadata.fromJson(Map<String, dynamic> json) =
      _$PivStateMetadataImpl.fromJson;

  @override
  ManagementKeyMetadata get managementKeyMetadata;
  @override
  PinMetadata get pinMetadata;
  @override
  PinMetadata get pukMetadata;

  /// Create a copy of PivStateMetadata
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PivStateMetadataImplCopyWith<_$PivStateMetadataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PivState _$PivStateFromJson(Map<String, dynamic> json) {
  return _PivState.fromJson(json);
}

/// @nodoc
mixin _$PivState {
  Version get version => throw _privateConstructorUsedError;
  bool get authenticated => throw _privateConstructorUsedError;
  bool get derivedKey => throw _privateConstructorUsedError;
  bool get storedKey => throw _privateConstructorUsedError;
  int get pinAttempts => throw _privateConstructorUsedError;
  bool get supportsBio => throw _privateConstructorUsedError;
  String? get chuid => throw _privateConstructorUsedError;
  String? get ccc => throw _privateConstructorUsedError;
  PivStateMetadata? get metadata => throw _privateConstructorUsedError;

  /// Serializes this PivState to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PivState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PivStateCopyWith<PivState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PivStateCopyWith<$Res> {
  factory $PivStateCopyWith(PivState value, $Res Function(PivState) then) =
      _$PivStateCopyWithImpl<$Res, PivState>;
  @useResult
  $Res call(
      {Version version,
      bool authenticated,
      bool derivedKey,
      bool storedKey,
      int pinAttempts,
      bool supportsBio,
      String? chuid,
      String? ccc,
      PivStateMetadata? metadata});

  $VersionCopyWith<$Res> get version;
  $PivStateMetadataCopyWith<$Res>? get metadata;
}

/// @nodoc
class _$PivStateCopyWithImpl<$Res, $Val extends PivState>
    implements $PivStateCopyWith<$Res> {
  _$PivStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PivState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? version = null,
    Object? authenticated = null,
    Object? derivedKey = null,
    Object? storedKey = null,
    Object? pinAttempts = null,
    Object? supportsBio = null,
    Object? chuid = freezed,
    Object? ccc = freezed,
    Object? metadata = freezed,
  }) {
    return _then(_value.copyWith(
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as Version,
      authenticated: null == authenticated
          ? _value.authenticated
          : authenticated // ignore: cast_nullable_to_non_nullable
              as bool,
      derivedKey: null == derivedKey
          ? _value.derivedKey
          : derivedKey // ignore: cast_nullable_to_non_nullable
              as bool,
      storedKey: null == storedKey
          ? _value.storedKey
          : storedKey // ignore: cast_nullable_to_non_nullable
              as bool,
      pinAttempts: null == pinAttempts
          ? _value.pinAttempts
          : pinAttempts // ignore: cast_nullable_to_non_nullable
              as int,
      supportsBio: null == supportsBio
          ? _value.supportsBio
          : supportsBio // ignore: cast_nullable_to_non_nullable
              as bool,
      chuid: freezed == chuid
          ? _value.chuid
          : chuid // ignore: cast_nullable_to_non_nullable
              as String?,
      ccc: freezed == ccc
          ? _value.ccc
          : ccc // ignore: cast_nullable_to_non_nullable
              as String?,
      metadata: freezed == metadata
          ? _value.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as PivStateMetadata?,
    ) as $Val);
  }

  /// Create a copy of PivState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $VersionCopyWith<$Res> get version {
    return $VersionCopyWith<$Res>(_value.version, (value) {
      return _then(_value.copyWith(version: value) as $Val);
    });
  }

  /// Create a copy of PivState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PivStateMetadataCopyWith<$Res>? get metadata {
    if (_value.metadata == null) {
      return null;
    }

    return $PivStateMetadataCopyWith<$Res>(_value.metadata!, (value) {
      return _then(_value.copyWith(metadata: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$PivStateImplCopyWith<$Res>
    implements $PivStateCopyWith<$Res> {
  factory _$$PivStateImplCopyWith(
          _$PivStateImpl value, $Res Function(_$PivStateImpl) then) =
      __$$PivStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {Version version,
      bool authenticated,
      bool derivedKey,
      bool storedKey,
      int pinAttempts,
      bool supportsBio,
      String? chuid,
      String? ccc,
      PivStateMetadata? metadata});

  @override
  $VersionCopyWith<$Res> get version;
  @override
  $PivStateMetadataCopyWith<$Res>? get metadata;
}

/// @nodoc
class __$$PivStateImplCopyWithImpl<$Res>
    extends _$PivStateCopyWithImpl<$Res, _$PivStateImpl>
    implements _$$PivStateImplCopyWith<$Res> {
  __$$PivStateImplCopyWithImpl(
      _$PivStateImpl _value, $Res Function(_$PivStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of PivState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? version = null,
    Object? authenticated = null,
    Object? derivedKey = null,
    Object? storedKey = null,
    Object? pinAttempts = null,
    Object? supportsBio = null,
    Object? chuid = freezed,
    Object? ccc = freezed,
    Object? metadata = freezed,
  }) {
    return _then(_$PivStateImpl(
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as Version,
      authenticated: null == authenticated
          ? _value.authenticated
          : authenticated // ignore: cast_nullable_to_non_nullable
              as bool,
      derivedKey: null == derivedKey
          ? _value.derivedKey
          : derivedKey // ignore: cast_nullable_to_non_nullable
              as bool,
      storedKey: null == storedKey
          ? _value.storedKey
          : storedKey // ignore: cast_nullable_to_non_nullable
              as bool,
      pinAttempts: null == pinAttempts
          ? _value.pinAttempts
          : pinAttempts // ignore: cast_nullable_to_non_nullable
              as int,
      supportsBio: null == supportsBio
          ? _value.supportsBio
          : supportsBio // ignore: cast_nullable_to_non_nullable
              as bool,
      chuid: freezed == chuid
          ? _value.chuid
          : chuid // ignore: cast_nullable_to_non_nullable
              as String?,
      ccc: freezed == ccc
          ? _value.ccc
          : ccc // ignore: cast_nullable_to_non_nullable
              as String?,
      metadata: freezed == metadata
          ? _value.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as PivStateMetadata?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PivStateImpl extends _PivState {
  _$PivStateImpl(
      {required this.version,
      required this.authenticated,
      required this.derivedKey,
      required this.storedKey,
      required this.pinAttempts,
      required this.supportsBio,
      this.chuid,
      this.ccc,
      this.metadata})
      : super._();

  factory _$PivStateImpl.fromJson(Map<String, dynamic> json) =>
      _$$PivStateImplFromJson(json);

  @override
  final Version version;
  @override
  final bool authenticated;
  @override
  final bool derivedKey;
  @override
  final bool storedKey;
  @override
  final int pinAttempts;
  @override
  final bool supportsBio;
  @override
  final String? chuid;
  @override
  final String? ccc;
  @override
  final PivStateMetadata? metadata;

  @override
  String toString() {
    return 'PivState(version: $version, authenticated: $authenticated, derivedKey: $derivedKey, storedKey: $storedKey, pinAttempts: $pinAttempts, supportsBio: $supportsBio, chuid: $chuid, ccc: $ccc, metadata: $metadata)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PivStateImpl &&
            (identical(other.version, version) || other.version == version) &&
            (identical(other.authenticated, authenticated) ||
                other.authenticated == authenticated) &&
            (identical(other.derivedKey, derivedKey) ||
                other.derivedKey == derivedKey) &&
            (identical(other.storedKey, storedKey) ||
                other.storedKey == storedKey) &&
            (identical(other.pinAttempts, pinAttempts) ||
                other.pinAttempts == pinAttempts) &&
            (identical(other.supportsBio, supportsBio) ||
                other.supportsBio == supportsBio) &&
            (identical(other.chuid, chuid) || other.chuid == chuid) &&
            (identical(other.ccc, ccc) || other.ccc == ccc) &&
            (identical(other.metadata, metadata) ||
                other.metadata == metadata));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, version, authenticated,
      derivedKey, storedKey, pinAttempts, supportsBio, chuid, ccc, metadata);

  /// Create a copy of PivState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PivStateImplCopyWith<_$PivStateImpl> get copyWith =>
      __$$PivStateImplCopyWithImpl<_$PivStateImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PivStateImplToJson(
      this,
    );
  }
}

abstract class _PivState extends PivState {
  factory _PivState(
      {required final Version version,
      required final bool authenticated,
      required final bool derivedKey,
      required final bool storedKey,
      required final int pinAttempts,
      required final bool supportsBio,
      final String? chuid,
      final String? ccc,
      final PivStateMetadata? metadata}) = _$PivStateImpl;
  _PivState._() : super._();

  factory _PivState.fromJson(Map<String, dynamic> json) =
      _$PivStateImpl.fromJson;

  @override
  Version get version;
  @override
  bool get authenticated;
  @override
  bool get derivedKey;
  @override
  bool get storedKey;
  @override
  int get pinAttempts;
  @override
  bool get supportsBio;
  @override
  String? get chuid;
  @override
  String? get ccc;
  @override
  PivStateMetadata? get metadata;

  /// Create a copy of PivState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PivStateImplCopyWith<_$PivStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CertInfo _$CertInfoFromJson(Map<String, dynamic> json) {
  return _CertInfo.fromJson(json);
}

/// @nodoc
mixin _$CertInfo {
  KeyType? get keyType => throw _privateConstructorUsedError;
  String get subject => throw _privateConstructorUsedError;
  String get issuer => throw _privateConstructorUsedError;
  String get serial => throw _privateConstructorUsedError;
  String get notValidBefore => throw _privateConstructorUsedError;
  String get notValidAfter => throw _privateConstructorUsedError;
  String get fingerprint => throw _privateConstructorUsedError;

  /// Serializes this CertInfo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CertInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CertInfoCopyWith<CertInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CertInfoCopyWith<$Res> {
  factory $CertInfoCopyWith(CertInfo value, $Res Function(CertInfo) then) =
      _$CertInfoCopyWithImpl<$Res, CertInfo>;
  @useResult
  $Res call(
      {KeyType? keyType,
      String subject,
      String issuer,
      String serial,
      String notValidBefore,
      String notValidAfter,
      String fingerprint});
}

/// @nodoc
class _$CertInfoCopyWithImpl<$Res, $Val extends CertInfo>
    implements $CertInfoCopyWith<$Res> {
  _$CertInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CertInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? keyType = freezed,
    Object? subject = null,
    Object? issuer = null,
    Object? serial = null,
    Object? notValidBefore = null,
    Object? notValidAfter = null,
    Object? fingerprint = null,
  }) {
    return _then(_value.copyWith(
      keyType: freezed == keyType
          ? _value.keyType
          : keyType // ignore: cast_nullable_to_non_nullable
              as KeyType?,
      subject: null == subject
          ? _value.subject
          : subject // ignore: cast_nullable_to_non_nullable
              as String,
      issuer: null == issuer
          ? _value.issuer
          : issuer // ignore: cast_nullable_to_non_nullable
              as String,
      serial: null == serial
          ? _value.serial
          : serial // ignore: cast_nullable_to_non_nullable
              as String,
      notValidBefore: null == notValidBefore
          ? _value.notValidBefore
          : notValidBefore // ignore: cast_nullable_to_non_nullable
              as String,
      notValidAfter: null == notValidAfter
          ? _value.notValidAfter
          : notValidAfter // ignore: cast_nullable_to_non_nullable
              as String,
      fingerprint: null == fingerprint
          ? _value.fingerprint
          : fingerprint // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CertInfoImplCopyWith<$Res>
    implements $CertInfoCopyWith<$Res> {
  factory _$$CertInfoImplCopyWith(
          _$CertInfoImpl value, $Res Function(_$CertInfoImpl) then) =
      __$$CertInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {KeyType? keyType,
      String subject,
      String issuer,
      String serial,
      String notValidBefore,
      String notValidAfter,
      String fingerprint});
}

/// @nodoc
class __$$CertInfoImplCopyWithImpl<$Res>
    extends _$CertInfoCopyWithImpl<$Res, _$CertInfoImpl>
    implements _$$CertInfoImplCopyWith<$Res> {
  __$$CertInfoImplCopyWithImpl(
      _$CertInfoImpl _value, $Res Function(_$CertInfoImpl) _then)
      : super(_value, _then);

  /// Create a copy of CertInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? keyType = freezed,
    Object? subject = null,
    Object? issuer = null,
    Object? serial = null,
    Object? notValidBefore = null,
    Object? notValidAfter = null,
    Object? fingerprint = null,
  }) {
    return _then(_$CertInfoImpl(
      keyType: freezed == keyType
          ? _value.keyType
          : keyType // ignore: cast_nullable_to_non_nullable
              as KeyType?,
      subject: null == subject
          ? _value.subject
          : subject // ignore: cast_nullable_to_non_nullable
              as String,
      issuer: null == issuer
          ? _value.issuer
          : issuer // ignore: cast_nullable_to_non_nullable
              as String,
      serial: null == serial
          ? _value.serial
          : serial // ignore: cast_nullable_to_non_nullable
              as String,
      notValidBefore: null == notValidBefore
          ? _value.notValidBefore
          : notValidBefore // ignore: cast_nullable_to_non_nullable
              as String,
      notValidAfter: null == notValidAfter
          ? _value.notValidAfter
          : notValidAfter // ignore: cast_nullable_to_non_nullable
              as String,
      fingerprint: null == fingerprint
          ? _value.fingerprint
          : fingerprint // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CertInfoImpl implements _CertInfo {
  _$CertInfoImpl(
      {required this.keyType,
      required this.subject,
      required this.issuer,
      required this.serial,
      required this.notValidBefore,
      required this.notValidAfter,
      required this.fingerprint});

  factory _$CertInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$CertInfoImplFromJson(json);

  @override
  final KeyType? keyType;
  @override
  final String subject;
  @override
  final String issuer;
  @override
  final String serial;
  @override
  final String notValidBefore;
  @override
  final String notValidAfter;
  @override
  final String fingerprint;

  @override
  String toString() {
    return 'CertInfo(keyType: $keyType, subject: $subject, issuer: $issuer, serial: $serial, notValidBefore: $notValidBefore, notValidAfter: $notValidAfter, fingerprint: $fingerprint)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CertInfoImpl &&
            (identical(other.keyType, keyType) || other.keyType == keyType) &&
            (identical(other.subject, subject) || other.subject == subject) &&
            (identical(other.issuer, issuer) || other.issuer == issuer) &&
            (identical(other.serial, serial) || other.serial == serial) &&
            (identical(other.notValidBefore, notValidBefore) ||
                other.notValidBefore == notValidBefore) &&
            (identical(other.notValidAfter, notValidAfter) ||
                other.notValidAfter == notValidAfter) &&
            (identical(other.fingerprint, fingerprint) ||
                other.fingerprint == fingerprint));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, keyType, subject, issuer, serial,
      notValidBefore, notValidAfter, fingerprint);

  /// Create a copy of CertInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CertInfoImplCopyWith<_$CertInfoImpl> get copyWith =>
      __$$CertInfoImplCopyWithImpl<_$CertInfoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CertInfoImplToJson(
      this,
    );
  }
}

abstract class _CertInfo implements CertInfo {
  factory _CertInfo(
      {required final KeyType? keyType,
      required final String subject,
      required final String issuer,
      required final String serial,
      required final String notValidBefore,
      required final String notValidAfter,
      required final String fingerprint}) = _$CertInfoImpl;

  factory _CertInfo.fromJson(Map<String, dynamic> json) =
      _$CertInfoImpl.fromJson;

  @override
  KeyType? get keyType;
  @override
  String get subject;
  @override
  String get issuer;
  @override
  String get serial;
  @override
  String get notValidBefore;
  @override
  String get notValidAfter;
  @override
  String get fingerprint;

  /// Create a copy of CertInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CertInfoImplCopyWith<_$CertInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PivSlot _$PivSlotFromJson(Map<String, dynamic> json) {
  return _PivSlot.fromJson(json);
}

/// @nodoc
mixin _$PivSlot {
  SlotId get slot => throw _privateConstructorUsedError;
  SlotMetadata? get metadata => throw _privateConstructorUsedError;
  CertInfo? get certInfo => throw _privateConstructorUsedError;

  /// Serializes this PivSlot to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PivSlot
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PivSlotCopyWith<PivSlot> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PivSlotCopyWith<$Res> {
  factory $PivSlotCopyWith(PivSlot value, $Res Function(PivSlot) then) =
      _$PivSlotCopyWithImpl<$Res, PivSlot>;
  @useResult
  $Res call({SlotId slot, SlotMetadata? metadata, CertInfo? certInfo});

  $SlotMetadataCopyWith<$Res>? get metadata;
  $CertInfoCopyWith<$Res>? get certInfo;
}

/// @nodoc
class _$PivSlotCopyWithImpl<$Res, $Val extends PivSlot>
    implements $PivSlotCopyWith<$Res> {
  _$PivSlotCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PivSlot
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? slot = null,
    Object? metadata = freezed,
    Object? certInfo = freezed,
  }) {
    return _then(_value.copyWith(
      slot: null == slot
          ? _value.slot
          : slot // ignore: cast_nullable_to_non_nullable
              as SlotId,
      metadata: freezed == metadata
          ? _value.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as SlotMetadata?,
      certInfo: freezed == certInfo
          ? _value.certInfo
          : certInfo // ignore: cast_nullable_to_non_nullable
              as CertInfo?,
    ) as $Val);
  }

  /// Create a copy of PivSlot
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SlotMetadataCopyWith<$Res>? get metadata {
    if (_value.metadata == null) {
      return null;
    }

    return $SlotMetadataCopyWith<$Res>(_value.metadata!, (value) {
      return _then(_value.copyWith(metadata: value) as $Val);
    });
  }

  /// Create a copy of PivSlot
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CertInfoCopyWith<$Res>? get certInfo {
    if (_value.certInfo == null) {
      return null;
    }

    return $CertInfoCopyWith<$Res>(_value.certInfo!, (value) {
      return _then(_value.copyWith(certInfo: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$PivSlotImplCopyWith<$Res> implements $PivSlotCopyWith<$Res> {
  factory _$$PivSlotImplCopyWith(
          _$PivSlotImpl value, $Res Function(_$PivSlotImpl) then) =
      __$$PivSlotImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({SlotId slot, SlotMetadata? metadata, CertInfo? certInfo});

  @override
  $SlotMetadataCopyWith<$Res>? get metadata;
  @override
  $CertInfoCopyWith<$Res>? get certInfo;
}

/// @nodoc
class __$$PivSlotImplCopyWithImpl<$Res>
    extends _$PivSlotCopyWithImpl<$Res, _$PivSlotImpl>
    implements _$$PivSlotImplCopyWith<$Res> {
  __$$PivSlotImplCopyWithImpl(
      _$PivSlotImpl _value, $Res Function(_$PivSlotImpl) _then)
      : super(_value, _then);

  /// Create a copy of PivSlot
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? slot = null,
    Object? metadata = freezed,
    Object? certInfo = freezed,
  }) {
    return _then(_$PivSlotImpl(
      slot: null == slot
          ? _value.slot
          : slot // ignore: cast_nullable_to_non_nullable
              as SlotId,
      metadata: freezed == metadata
          ? _value.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as SlotMetadata?,
      certInfo: freezed == certInfo
          ? _value.certInfo
          : certInfo // ignore: cast_nullable_to_non_nullable
              as CertInfo?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PivSlotImpl implements _PivSlot {
  _$PivSlotImpl({required this.slot, this.metadata, this.certInfo});

  factory _$PivSlotImpl.fromJson(Map<String, dynamic> json) =>
      _$$PivSlotImplFromJson(json);

  @override
  final SlotId slot;
  @override
  final SlotMetadata? metadata;
  @override
  final CertInfo? certInfo;

  @override
  String toString() {
    return 'PivSlot(slot: $slot, metadata: $metadata, certInfo: $certInfo)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PivSlotImpl &&
            (identical(other.slot, slot) || other.slot == slot) &&
            (identical(other.metadata, metadata) ||
                other.metadata == metadata) &&
            (identical(other.certInfo, certInfo) ||
                other.certInfo == certInfo));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, slot, metadata, certInfo);

  /// Create a copy of PivSlot
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PivSlotImplCopyWith<_$PivSlotImpl> get copyWith =>
      __$$PivSlotImplCopyWithImpl<_$PivSlotImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PivSlotImplToJson(
      this,
    );
  }
}

abstract class _PivSlot implements PivSlot {
  factory _PivSlot(
      {required final SlotId slot,
      final SlotMetadata? metadata,
      final CertInfo? certInfo}) = _$PivSlotImpl;

  factory _PivSlot.fromJson(Map<String, dynamic> json) = _$PivSlotImpl.fromJson;

  @override
  SlotId get slot;
  @override
  SlotMetadata? get metadata;
  @override
  CertInfo? get certInfo;

  /// Create a copy of PivSlot
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PivSlotImplCopyWith<_$PivSlotImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PivExamineResult _$PivExamineResultFromJson(Map<String, dynamic> json) {
  switch (json['runtimeType']) {
    case 'result':
      return _ExamineResult.fromJson(json);
    case 'invalidPassword':
      return _InvalidPassword.fromJson(json);

    default:
      throw CheckedFromJsonException(json, 'runtimeType', 'PivExamineResult',
          'Invalid union type "${json['runtimeType']}"!');
  }
}

/// @nodoc
mixin _$PivExamineResult {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            bool password, KeyType? keyType, CertInfo? certInfo)
        result,
    required TResult Function() invalidPassword,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(bool password, KeyType? keyType, CertInfo? certInfo)?
        result,
    TResult? Function()? invalidPassword,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(bool password, KeyType? keyType, CertInfo? certInfo)?
        result,
    TResult Function()? invalidPassword,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_ExamineResult value) result,
    required TResult Function(_InvalidPassword value) invalidPassword,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_ExamineResult value)? result,
    TResult? Function(_InvalidPassword value)? invalidPassword,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_ExamineResult value)? result,
    TResult Function(_InvalidPassword value)? invalidPassword,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  /// Serializes this PivExamineResult to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PivExamineResultCopyWith<$Res> {
  factory $PivExamineResultCopyWith(
          PivExamineResult value, $Res Function(PivExamineResult) then) =
      _$PivExamineResultCopyWithImpl<$Res, PivExamineResult>;
}

/// @nodoc
class _$PivExamineResultCopyWithImpl<$Res, $Val extends PivExamineResult>
    implements $PivExamineResultCopyWith<$Res> {
  _$PivExamineResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PivExamineResult
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$ExamineResultImplCopyWith<$Res> {
  factory _$$ExamineResultImplCopyWith(
          _$ExamineResultImpl value, $Res Function(_$ExamineResultImpl) then) =
      __$$ExamineResultImplCopyWithImpl<$Res>;
  @useResult
  $Res call({bool password, KeyType? keyType, CertInfo? certInfo});

  $CertInfoCopyWith<$Res>? get certInfo;
}

/// @nodoc
class __$$ExamineResultImplCopyWithImpl<$Res>
    extends _$PivExamineResultCopyWithImpl<$Res, _$ExamineResultImpl>
    implements _$$ExamineResultImplCopyWith<$Res> {
  __$$ExamineResultImplCopyWithImpl(
      _$ExamineResultImpl _value, $Res Function(_$ExamineResultImpl) _then)
      : super(_value, _then);

  /// Create a copy of PivExamineResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? password = null,
    Object? keyType = freezed,
    Object? certInfo = freezed,
  }) {
    return _then(_$ExamineResultImpl(
      password: null == password
          ? _value.password
          : password // ignore: cast_nullable_to_non_nullable
              as bool,
      keyType: freezed == keyType
          ? _value.keyType
          : keyType // ignore: cast_nullable_to_non_nullable
              as KeyType?,
      certInfo: freezed == certInfo
          ? _value.certInfo
          : certInfo // ignore: cast_nullable_to_non_nullable
              as CertInfo?,
    ));
  }

  /// Create a copy of PivExamineResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CertInfoCopyWith<$Res>? get certInfo {
    if (_value.certInfo == null) {
      return null;
    }

    return $CertInfoCopyWith<$Res>(_value.certInfo!, (value) {
      return _then(_value.copyWith(certInfo: value));
    });
  }
}

/// @nodoc
@JsonSerializable()
class _$ExamineResultImpl implements _ExamineResult {
  _$ExamineResultImpl(
      {required this.password,
      required this.keyType,
      required this.certInfo,
      final String? $type})
      : $type = $type ?? 'result';

  factory _$ExamineResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$ExamineResultImplFromJson(json);

  @override
  final bool password;
  @override
  final KeyType? keyType;
  @override
  final CertInfo? certInfo;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'PivExamineResult.result(password: $password, keyType: $keyType, certInfo: $certInfo)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ExamineResultImpl &&
            (identical(other.password, password) ||
                other.password == password) &&
            (identical(other.keyType, keyType) || other.keyType == keyType) &&
            (identical(other.certInfo, certInfo) ||
                other.certInfo == certInfo));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, password, keyType, certInfo);

  /// Create a copy of PivExamineResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ExamineResultImplCopyWith<_$ExamineResultImpl> get copyWith =>
      __$$ExamineResultImplCopyWithImpl<_$ExamineResultImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            bool password, KeyType? keyType, CertInfo? certInfo)
        result,
    required TResult Function() invalidPassword,
  }) {
    return result(password, keyType, certInfo);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(bool password, KeyType? keyType, CertInfo? certInfo)?
        result,
    TResult? Function()? invalidPassword,
  }) {
    return result?.call(password, keyType, certInfo);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(bool password, KeyType? keyType, CertInfo? certInfo)?
        result,
    TResult Function()? invalidPassword,
    required TResult orElse(),
  }) {
    if (result != null) {
      return result(password, keyType, certInfo);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_ExamineResult value) result,
    required TResult Function(_InvalidPassword value) invalidPassword,
  }) {
    return result(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_ExamineResult value)? result,
    TResult? Function(_InvalidPassword value)? invalidPassword,
  }) {
    return result?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_ExamineResult value)? result,
    TResult Function(_InvalidPassword value)? invalidPassword,
    required TResult orElse(),
  }) {
    if (result != null) {
      return result(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$ExamineResultImplToJson(
      this,
    );
  }
}

abstract class _ExamineResult implements PivExamineResult {
  factory _ExamineResult(
      {required final bool password,
      required final KeyType? keyType,
      required final CertInfo? certInfo}) = _$ExamineResultImpl;

  factory _ExamineResult.fromJson(Map<String, dynamic> json) =
      _$ExamineResultImpl.fromJson;

  bool get password;
  KeyType? get keyType;
  CertInfo? get certInfo;

  /// Create a copy of PivExamineResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ExamineResultImplCopyWith<_$ExamineResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$InvalidPasswordImplCopyWith<$Res> {
  factory _$$InvalidPasswordImplCopyWith(_$InvalidPasswordImpl value,
          $Res Function(_$InvalidPasswordImpl) then) =
      __$$InvalidPasswordImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$InvalidPasswordImplCopyWithImpl<$Res>
    extends _$PivExamineResultCopyWithImpl<$Res, _$InvalidPasswordImpl>
    implements _$$InvalidPasswordImplCopyWith<$Res> {
  __$$InvalidPasswordImplCopyWithImpl(
      _$InvalidPasswordImpl _value, $Res Function(_$InvalidPasswordImpl) _then)
      : super(_value, _then);

  /// Create a copy of PivExamineResult
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
@JsonSerializable()
class _$InvalidPasswordImpl implements _InvalidPassword {
  _$InvalidPasswordImpl({final String? $type})
      : $type = $type ?? 'invalidPassword';

  factory _$InvalidPasswordImpl.fromJson(Map<String, dynamic> json) =>
      _$$InvalidPasswordImplFromJson(json);

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'PivExamineResult.invalidPassword()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$InvalidPasswordImpl);
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            bool password, KeyType? keyType, CertInfo? certInfo)
        result,
    required TResult Function() invalidPassword,
  }) {
    return invalidPassword();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(bool password, KeyType? keyType, CertInfo? certInfo)?
        result,
    TResult? Function()? invalidPassword,
  }) {
    return invalidPassword?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(bool password, KeyType? keyType, CertInfo? certInfo)?
        result,
    TResult Function()? invalidPassword,
    required TResult orElse(),
  }) {
    if (invalidPassword != null) {
      return invalidPassword();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_ExamineResult value) result,
    required TResult Function(_InvalidPassword value) invalidPassword,
  }) {
    return invalidPassword(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_ExamineResult value)? result,
    TResult? Function(_InvalidPassword value)? invalidPassword,
  }) {
    return invalidPassword?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_ExamineResult value)? result,
    TResult Function(_InvalidPassword value)? invalidPassword,
    required TResult orElse(),
  }) {
    if (invalidPassword != null) {
      return invalidPassword(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$InvalidPasswordImplToJson(
      this,
    );
  }
}

abstract class _InvalidPassword implements PivExamineResult {
  factory _InvalidPassword() = _$InvalidPasswordImpl;

  factory _InvalidPassword.fromJson(Map<String, dynamic> json) =
      _$InvalidPasswordImpl.fromJson;
}

/// @nodoc
mixin _$PivGenerateParameters {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() publicKey,
    required TResult Function(
            String subject, DateTime validFrom, DateTime validTo)
        certificate,
    required TResult Function(String subject) csr,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? publicKey,
    TResult? Function(String subject, DateTime validFrom, DateTime validTo)?
        certificate,
    TResult? Function(String subject)? csr,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? publicKey,
    TResult Function(String subject, DateTime validFrom, DateTime validTo)?
        certificate,
    TResult Function(String subject)? csr,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_GeneratePublicKey value) publicKey,
    required TResult Function(_GenerateCertificate value) certificate,
    required TResult Function(_GenerateCsr value) csr,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_GeneratePublicKey value)? publicKey,
    TResult? Function(_GenerateCertificate value)? certificate,
    TResult? Function(_GenerateCsr value)? csr,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_GeneratePublicKey value)? publicKey,
    TResult Function(_GenerateCertificate value)? certificate,
    TResult Function(_GenerateCsr value)? csr,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PivGenerateParametersCopyWith<$Res> {
  factory $PivGenerateParametersCopyWith(PivGenerateParameters value,
          $Res Function(PivGenerateParameters) then) =
      _$PivGenerateParametersCopyWithImpl<$Res, PivGenerateParameters>;
}

/// @nodoc
class _$PivGenerateParametersCopyWithImpl<$Res,
        $Val extends PivGenerateParameters>
    implements $PivGenerateParametersCopyWith<$Res> {
  _$PivGenerateParametersCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PivGenerateParameters
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$GeneratePublicKeyImplCopyWith<$Res> {
  factory _$$GeneratePublicKeyImplCopyWith(_$GeneratePublicKeyImpl value,
          $Res Function(_$GeneratePublicKeyImpl) then) =
      __$$GeneratePublicKeyImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$GeneratePublicKeyImplCopyWithImpl<$Res>
    extends _$PivGenerateParametersCopyWithImpl<$Res, _$GeneratePublicKeyImpl>
    implements _$$GeneratePublicKeyImplCopyWith<$Res> {
  __$$GeneratePublicKeyImplCopyWithImpl(_$GeneratePublicKeyImpl _value,
      $Res Function(_$GeneratePublicKeyImpl) _then)
      : super(_value, _then);

  /// Create a copy of PivGenerateParameters
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$GeneratePublicKeyImpl implements _GeneratePublicKey {
  _$GeneratePublicKeyImpl();

  @override
  String toString() {
    return 'PivGenerateParameters.publicKey()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$GeneratePublicKeyImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() publicKey,
    required TResult Function(
            String subject, DateTime validFrom, DateTime validTo)
        certificate,
    required TResult Function(String subject) csr,
  }) {
    return publicKey();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? publicKey,
    TResult? Function(String subject, DateTime validFrom, DateTime validTo)?
        certificate,
    TResult? Function(String subject)? csr,
  }) {
    return publicKey?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? publicKey,
    TResult Function(String subject, DateTime validFrom, DateTime validTo)?
        certificate,
    TResult Function(String subject)? csr,
    required TResult orElse(),
  }) {
    if (publicKey != null) {
      return publicKey();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_GeneratePublicKey value) publicKey,
    required TResult Function(_GenerateCertificate value) certificate,
    required TResult Function(_GenerateCsr value) csr,
  }) {
    return publicKey(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_GeneratePublicKey value)? publicKey,
    TResult? Function(_GenerateCertificate value)? certificate,
    TResult? Function(_GenerateCsr value)? csr,
  }) {
    return publicKey?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_GeneratePublicKey value)? publicKey,
    TResult Function(_GenerateCertificate value)? certificate,
    TResult Function(_GenerateCsr value)? csr,
    required TResult orElse(),
  }) {
    if (publicKey != null) {
      return publicKey(this);
    }
    return orElse();
  }
}

abstract class _GeneratePublicKey implements PivGenerateParameters {
  factory _GeneratePublicKey() = _$GeneratePublicKeyImpl;
}

/// @nodoc
abstract class _$$GenerateCertificateImplCopyWith<$Res> {
  factory _$$GenerateCertificateImplCopyWith(_$GenerateCertificateImpl value,
          $Res Function(_$GenerateCertificateImpl) then) =
      __$$GenerateCertificateImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String subject, DateTime validFrom, DateTime validTo});
}

/// @nodoc
class __$$GenerateCertificateImplCopyWithImpl<$Res>
    extends _$PivGenerateParametersCopyWithImpl<$Res, _$GenerateCertificateImpl>
    implements _$$GenerateCertificateImplCopyWith<$Res> {
  __$$GenerateCertificateImplCopyWithImpl(_$GenerateCertificateImpl _value,
      $Res Function(_$GenerateCertificateImpl) _then)
      : super(_value, _then);

  /// Create a copy of PivGenerateParameters
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? subject = null,
    Object? validFrom = null,
    Object? validTo = null,
  }) {
    return _then(_$GenerateCertificateImpl(
      subject: null == subject
          ? _value.subject
          : subject // ignore: cast_nullable_to_non_nullable
              as String,
      validFrom: null == validFrom
          ? _value.validFrom
          : validFrom // ignore: cast_nullable_to_non_nullable
              as DateTime,
      validTo: null == validTo
          ? _value.validTo
          : validTo // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc

class _$GenerateCertificateImpl implements _GenerateCertificate {
  _$GenerateCertificateImpl(
      {required this.subject, required this.validFrom, required this.validTo});

  @override
  final String subject;
  @override
  final DateTime validFrom;
  @override
  final DateTime validTo;

  @override
  String toString() {
    return 'PivGenerateParameters.certificate(subject: $subject, validFrom: $validFrom, validTo: $validTo)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GenerateCertificateImpl &&
            (identical(other.subject, subject) || other.subject == subject) &&
            (identical(other.validFrom, validFrom) ||
                other.validFrom == validFrom) &&
            (identical(other.validTo, validTo) || other.validTo == validTo));
  }

  @override
  int get hashCode => Object.hash(runtimeType, subject, validFrom, validTo);

  /// Create a copy of PivGenerateParameters
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GenerateCertificateImplCopyWith<_$GenerateCertificateImpl> get copyWith =>
      __$$GenerateCertificateImplCopyWithImpl<_$GenerateCertificateImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() publicKey,
    required TResult Function(
            String subject, DateTime validFrom, DateTime validTo)
        certificate,
    required TResult Function(String subject) csr,
  }) {
    return certificate(subject, validFrom, validTo);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? publicKey,
    TResult? Function(String subject, DateTime validFrom, DateTime validTo)?
        certificate,
    TResult? Function(String subject)? csr,
  }) {
    return certificate?.call(subject, validFrom, validTo);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? publicKey,
    TResult Function(String subject, DateTime validFrom, DateTime validTo)?
        certificate,
    TResult Function(String subject)? csr,
    required TResult orElse(),
  }) {
    if (certificate != null) {
      return certificate(subject, validFrom, validTo);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_GeneratePublicKey value) publicKey,
    required TResult Function(_GenerateCertificate value) certificate,
    required TResult Function(_GenerateCsr value) csr,
  }) {
    return certificate(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_GeneratePublicKey value)? publicKey,
    TResult? Function(_GenerateCertificate value)? certificate,
    TResult? Function(_GenerateCsr value)? csr,
  }) {
    return certificate?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_GeneratePublicKey value)? publicKey,
    TResult Function(_GenerateCertificate value)? certificate,
    TResult Function(_GenerateCsr value)? csr,
    required TResult orElse(),
  }) {
    if (certificate != null) {
      return certificate(this);
    }
    return orElse();
  }
}

abstract class _GenerateCertificate implements PivGenerateParameters {
  factory _GenerateCertificate(
      {required final String subject,
      required final DateTime validFrom,
      required final DateTime validTo}) = _$GenerateCertificateImpl;

  String get subject;
  DateTime get validFrom;
  DateTime get validTo;

  /// Create a copy of PivGenerateParameters
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GenerateCertificateImplCopyWith<_$GenerateCertificateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$GenerateCsrImplCopyWith<$Res> {
  factory _$$GenerateCsrImplCopyWith(
          _$GenerateCsrImpl value, $Res Function(_$GenerateCsrImpl) then) =
      __$$GenerateCsrImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String subject});
}

/// @nodoc
class __$$GenerateCsrImplCopyWithImpl<$Res>
    extends _$PivGenerateParametersCopyWithImpl<$Res, _$GenerateCsrImpl>
    implements _$$GenerateCsrImplCopyWith<$Res> {
  __$$GenerateCsrImplCopyWithImpl(
      _$GenerateCsrImpl _value, $Res Function(_$GenerateCsrImpl) _then)
      : super(_value, _then);

  /// Create a copy of PivGenerateParameters
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? subject = null,
  }) {
    return _then(_$GenerateCsrImpl(
      subject: null == subject
          ? _value.subject
          : subject // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$GenerateCsrImpl implements _GenerateCsr {
  _$GenerateCsrImpl({required this.subject});

  @override
  final String subject;

  @override
  String toString() {
    return 'PivGenerateParameters.csr(subject: $subject)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GenerateCsrImpl &&
            (identical(other.subject, subject) || other.subject == subject));
  }

  @override
  int get hashCode => Object.hash(runtimeType, subject);

  /// Create a copy of PivGenerateParameters
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GenerateCsrImplCopyWith<_$GenerateCsrImpl> get copyWith =>
      __$$GenerateCsrImplCopyWithImpl<_$GenerateCsrImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() publicKey,
    required TResult Function(
            String subject, DateTime validFrom, DateTime validTo)
        certificate,
    required TResult Function(String subject) csr,
  }) {
    return csr(subject);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? publicKey,
    TResult? Function(String subject, DateTime validFrom, DateTime validTo)?
        certificate,
    TResult? Function(String subject)? csr,
  }) {
    return csr?.call(subject);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? publicKey,
    TResult Function(String subject, DateTime validFrom, DateTime validTo)?
        certificate,
    TResult Function(String subject)? csr,
    required TResult orElse(),
  }) {
    if (csr != null) {
      return csr(subject);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_GeneratePublicKey value) publicKey,
    required TResult Function(_GenerateCertificate value) certificate,
    required TResult Function(_GenerateCsr value) csr,
  }) {
    return csr(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_GeneratePublicKey value)? publicKey,
    TResult? Function(_GenerateCertificate value)? certificate,
    TResult? Function(_GenerateCsr value)? csr,
  }) {
    return csr?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_GeneratePublicKey value)? publicKey,
    TResult Function(_GenerateCertificate value)? certificate,
    TResult Function(_GenerateCsr value)? csr,
    required TResult orElse(),
  }) {
    if (csr != null) {
      return csr(this);
    }
    return orElse();
  }
}

abstract class _GenerateCsr implements PivGenerateParameters {
  factory _GenerateCsr({required final String subject}) = _$GenerateCsrImpl;

  String get subject;

  /// Create a copy of PivGenerateParameters
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GenerateCsrImplCopyWith<_$GenerateCsrImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PivGenerateResult _$PivGenerateResultFromJson(Map<String, dynamic> json) {
  return _PivGenerateResult.fromJson(json);
}

/// @nodoc
mixin _$PivGenerateResult {
  GenerateType get generateType => throw _privateConstructorUsedError;
  String get publicKey => throw _privateConstructorUsedError;
  String? get result => throw _privateConstructorUsedError;

  /// Serializes this PivGenerateResult to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PivGenerateResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PivGenerateResultCopyWith<PivGenerateResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PivGenerateResultCopyWith<$Res> {
  factory $PivGenerateResultCopyWith(
          PivGenerateResult value, $Res Function(PivGenerateResult) then) =
      _$PivGenerateResultCopyWithImpl<$Res, PivGenerateResult>;
  @useResult
  $Res call({GenerateType generateType, String publicKey, String? result});
}

/// @nodoc
class _$PivGenerateResultCopyWithImpl<$Res, $Val extends PivGenerateResult>
    implements $PivGenerateResultCopyWith<$Res> {
  _$PivGenerateResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PivGenerateResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? generateType = null,
    Object? publicKey = null,
    Object? result = freezed,
  }) {
    return _then(_value.copyWith(
      generateType: null == generateType
          ? _value.generateType
          : generateType // ignore: cast_nullable_to_non_nullable
              as GenerateType,
      publicKey: null == publicKey
          ? _value.publicKey
          : publicKey // ignore: cast_nullable_to_non_nullable
              as String,
      result: freezed == result
          ? _value.result
          : result // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PivGenerateResultImplCopyWith<$Res>
    implements $PivGenerateResultCopyWith<$Res> {
  factory _$$PivGenerateResultImplCopyWith(_$PivGenerateResultImpl value,
          $Res Function(_$PivGenerateResultImpl) then) =
      __$$PivGenerateResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({GenerateType generateType, String publicKey, String? result});
}

/// @nodoc
class __$$PivGenerateResultImplCopyWithImpl<$Res>
    extends _$PivGenerateResultCopyWithImpl<$Res, _$PivGenerateResultImpl>
    implements _$$PivGenerateResultImplCopyWith<$Res> {
  __$$PivGenerateResultImplCopyWithImpl(_$PivGenerateResultImpl _value,
      $Res Function(_$PivGenerateResultImpl) _then)
      : super(_value, _then);

  /// Create a copy of PivGenerateResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? generateType = null,
    Object? publicKey = null,
    Object? result = freezed,
  }) {
    return _then(_$PivGenerateResultImpl(
      generateType: null == generateType
          ? _value.generateType
          : generateType // ignore: cast_nullable_to_non_nullable
              as GenerateType,
      publicKey: null == publicKey
          ? _value.publicKey
          : publicKey // ignore: cast_nullable_to_non_nullable
              as String,
      result: freezed == result
          ? _value.result
          : result // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PivGenerateResultImpl implements _PivGenerateResult {
  _$PivGenerateResultImpl(
      {required this.generateType, required this.publicKey, this.result});

  factory _$PivGenerateResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$PivGenerateResultImplFromJson(json);

  @override
  final GenerateType generateType;
  @override
  final String publicKey;
  @override
  final String? result;

  @override
  String toString() {
    return 'PivGenerateResult(generateType: $generateType, publicKey: $publicKey, result: $result)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PivGenerateResultImpl &&
            (identical(other.generateType, generateType) ||
                other.generateType == generateType) &&
            (identical(other.publicKey, publicKey) ||
                other.publicKey == publicKey) &&
            (identical(other.result, result) || other.result == result));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, generateType, publicKey, result);

  /// Create a copy of PivGenerateResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PivGenerateResultImplCopyWith<_$PivGenerateResultImpl> get copyWith =>
      __$$PivGenerateResultImplCopyWithImpl<_$PivGenerateResultImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PivGenerateResultImplToJson(
      this,
    );
  }
}

abstract class _PivGenerateResult implements PivGenerateResult {
  factory _PivGenerateResult(
      {required final GenerateType generateType,
      required final String publicKey,
      final String? result}) = _$PivGenerateResultImpl;

  factory _PivGenerateResult.fromJson(Map<String, dynamic> json) =
      _$PivGenerateResultImpl.fromJson;

  @override
  GenerateType get generateType;
  @override
  String get publicKey;
  @override
  String? get result;

  /// Create a copy of PivGenerateResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PivGenerateResultImplCopyWith<_$PivGenerateResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PivImportResult _$PivImportResultFromJson(Map<String, dynamic> json) {
  return _PivImportResult.fromJson(json);
}

/// @nodoc
mixin _$PivImportResult {
  SlotMetadata? get metadata => throw _privateConstructorUsedError;
  String? get publicKey => throw _privateConstructorUsedError;
  String? get certificate => throw _privateConstructorUsedError;

  /// Serializes this PivImportResult to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PivImportResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PivImportResultCopyWith<PivImportResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PivImportResultCopyWith<$Res> {
  factory $PivImportResultCopyWith(
          PivImportResult value, $Res Function(PivImportResult) then) =
      _$PivImportResultCopyWithImpl<$Res, PivImportResult>;
  @useResult
  $Res call({SlotMetadata? metadata, String? publicKey, String? certificate});

  $SlotMetadataCopyWith<$Res>? get metadata;
}

/// @nodoc
class _$PivImportResultCopyWithImpl<$Res, $Val extends PivImportResult>
    implements $PivImportResultCopyWith<$Res> {
  _$PivImportResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PivImportResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? metadata = freezed,
    Object? publicKey = freezed,
    Object? certificate = freezed,
  }) {
    return _then(_value.copyWith(
      metadata: freezed == metadata
          ? _value.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as SlotMetadata?,
      publicKey: freezed == publicKey
          ? _value.publicKey
          : publicKey // ignore: cast_nullable_to_non_nullable
              as String?,
      certificate: freezed == certificate
          ? _value.certificate
          : certificate // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }

  /// Create a copy of PivImportResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SlotMetadataCopyWith<$Res>? get metadata {
    if (_value.metadata == null) {
      return null;
    }

    return $SlotMetadataCopyWith<$Res>(_value.metadata!, (value) {
      return _then(_value.copyWith(metadata: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$PivImportResultImplCopyWith<$Res>
    implements $PivImportResultCopyWith<$Res> {
  factory _$$PivImportResultImplCopyWith(_$PivImportResultImpl value,
          $Res Function(_$PivImportResultImpl) then) =
      __$$PivImportResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({SlotMetadata? metadata, String? publicKey, String? certificate});

  @override
  $SlotMetadataCopyWith<$Res>? get metadata;
}

/// @nodoc
class __$$PivImportResultImplCopyWithImpl<$Res>
    extends _$PivImportResultCopyWithImpl<$Res, _$PivImportResultImpl>
    implements _$$PivImportResultImplCopyWith<$Res> {
  __$$PivImportResultImplCopyWithImpl(
      _$PivImportResultImpl _value, $Res Function(_$PivImportResultImpl) _then)
      : super(_value, _then);

  /// Create a copy of PivImportResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? metadata = freezed,
    Object? publicKey = freezed,
    Object? certificate = freezed,
  }) {
    return _then(_$PivImportResultImpl(
      metadata: freezed == metadata
          ? _value.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as SlotMetadata?,
      publicKey: freezed == publicKey
          ? _value.publicKey
          : publicKey // ignore: cast_nullable_to_non_nullable
              as String?,
      certificate: freezed == certificate
          ? _value.certificate
          : certificate // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PivImportResultImpl implements _PivImportResult {
  _$PivImportResultImpl(
      {required this.metadata,
      required this.publicKey,
      required this.certificate});

  factory _$PivImportResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$PivImportResultImplFromJson(json);

  @override
  final SlotMetadata? metadata;
  @override
  final String? publicKey;
  @override
  final String? certificate;

  @override
  String toString() {
    return 'PivImportResult(metadata: $metadata, publicKey: $publicKey, certificate: $certificate)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PivImportResultImpl &&
            (identical(other.metadata, metadata) ||
                other.metadata == metadata) &&
            (identical(other.publicKey, publicKey) ||
                other.publicKey == publicKey) &&
            (identical(other.certificate, certificate) ||
                other.certificate == certificate));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, metadata, publicKey, certificate);

  /// Create a copy of PivImportResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PivImportResultImplCopyWith<_$PivImportResultImpl> get copyWith =>
      __$$PivImportResultImplCopyWithImpl<_$PivImportResultImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PivImportResultImplToJson(
      this,
    );
  }
}

abstract class _PivImportResult implements PivImportResult {
  factory _PivImportResult(
      {required final SlotMetadata? metadata,
      required final String? publicKey,
      required final String? certificate}) = _$PivImportResultImpl;

  factory _PivImportResult.fromJson(Map<String, dynamic> json) =
      _$PivImportResultImpl.fromJson;

  @override
  SlotMetadata? get metadata;
  @override
  String? get publicKey;
  @override
  String? get certificate;

  /// Create a copy of PivImportResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PivImportResultImplCopyWith<_$PivImportResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
