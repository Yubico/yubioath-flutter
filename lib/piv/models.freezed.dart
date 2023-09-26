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

PinMetadata _$PinMetadataFromJson(Map<String, dynamic> json) {
  return _PinMetadata.fromJson(json);
}

/// @nodoc
mixin _$PinMetadata {
  bool get defaultValue => throw _privateConstructorUsedError;
  int get totalAttempts => throw _privateConstructorUsedError;
  int get attemptsRemaining => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
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
abstract class _$$_PinMetadataCopyWith<$Res>
    implements $PinMetadataCopyWith<$Res> {
  factory _$$_PinMetadataCopyWith(
          _$_PinMetadata value, $Res Function(_$_PinMetadata) then) =
      __$$_PinMetadataCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({bool defaultValue, int totalAttempts, int attemptsRemaining});
}

/// @nodoc
class __$$_PinMetadataCopyWithImpl<$Res>
    extends _$PinMetadataCopyWithImpl<$Res, _$_PinMetadata>
    implements _$$_PinMetadataCopyWith<$Res> {
  __$$_PinMetadataCopyWithImpl(
      _$_PinMetadata _value, $Res Function(_$_PinMetadata) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? defaultValue = null,
    Object? totalAttempts = null,
    Object? attemptsRemaining = null,
  }) {
    return _then(_$_PinMetadata(
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
class _$_PinMetadata implements _PinMetadata {
  _$_PinMetadata(this.defaultValue, this.totalAttempts, this.attemptsRemaining);

  factory _$_PinMetadata.fromJson(Map<String, dynamic> json) =>
      _$$_PinMetadataFromJson(json);

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
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_PinMetadata &&
            (identical(other.defaultValue, defaultValue) ||
                other.defaultValue == defaultValue) &&
            (identical(other.totalAttempts, totalAttempts) ||
                other.totalAttempts == totalAttempts) &&
            (identical(other.attemptsRemaining, attemptsRemaining) ||
                other.attemptsRemaining == attemptsRemaining));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, defaultValue, totalAttempts, attemptsRemaining);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_PinMetadataCopyWith<_$_PinMetadata> get copyWith =>
      __$$_PinMetadataCopyWithImpl<_$_PinMetadata>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_PinMetadataToJson(
      this,
    );
  }
}

abstract class _PinMetadata implements PinMetadata {
  factory _PinMetadata(final bool defaultValue, final int totalAttempts,
      final int attemptsRemaining) = _$_PinMetadata;

  factory _PinMetadata.fromJson(Map<String, dynamic> json) =
      _$_PinMetadata.fromJson;

  @override
  bool get defaultValue;
  @override
  int get totalAttempts;
  @override
  int get attemptsRemaining;
  @override
  @JsonKey(ignore: true)
  _$$_PinMetadataCopyWith<_$_PinMetadata> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$PinVerificationStatus {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() success,
    required TResult Function(int attemptsRemaining) failure,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? success,
    TResult? Function(int attemptsRemaining)? failure,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? success,
    TResult Function(int attemptsRemaining)? failure,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_PinSuccess value) success,
    required TResult Function(_PinFailure value) failure,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_PinSuccess value)? success,
    TResult? Function(_PinFailure value)? failure,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_PinSuccess value)? success,
    TResult Function(_PinFailure value)? failure,
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
}

/// @nodoc
abstract class _$$_PinSuccessCopyWith<$Res> {
  factory _$$_PinSuccessCopyWith(
          _$_PinSuccess value, $Res Function(_$_PinSuccess) then) =
      __$$_PinSuccessCopyWithImpl<$Res>;
}

/// @nodoc
class __$$_PinSuccessCopyWithImpl<$Res>
    extends _$PinVerificationStatusCopyWithImpl<$Res, _$_PinSuccess>
    implements _$$_PinSuccessCopyWith<$Res> {
  __$$_PinSuccessCopyWithImpl(
      _$_PinSuccess _value, $Res Function(_$_PinSuccess) _then)
      : super(_value, _then);
}

/// @nodoc

class _$_PinSuccess implements _PinSuccess {
  const _$_PinSuccess();

  @override
  String toString() {
    return 'PinVerificationStatus.success()';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$_PinSuccess);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() success,
    required TResult Function(int attemptsRemaining) failure,
  }) {
    return success();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? success,
    TResult? Function(int attemptsRemaining)? failure,
  }) {
    return success?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? success,
    TResult Function(int attemptsRemaining)? failure,
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
    required TResult Function(_PinFailure value) failure,
  }) {
    return success(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_PinSuccess value)? success,
    TResult? Function(_PinFailure value)? failure,
  }) {
    return success?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_PinSuccess value)? success,
    TResult Function(_PinFailure value)? failure,
    required TResult orElse(),
  }) {
    if (success != null) {
      return success(this);
    }
    return orElse();
  }
}

abstract class _PinSuccess implements PinVerificationStatus {
  const factory _PinSuccess() = _$_PinSuccess;
}

/// @nodoc
abstract class _$$_PinFailureCopyWith<$Res> {
  factory _$$_PinFailureCopyWith(
          _$_PinFailure value, $Res Function(_$_PinFailure) then) =
      __$$_PinFailureCopyWithImpl<$Res>;
  @useResult
  $Res call({int attemptsRemaining});
}

/// @nodoc
class __$$_PinFailureCopyWithImpl<$Res>
    extends _$PinVerificationStatusCopyWithImpl<$Res, _$_PinFailure>
    implements _$$_PinFailureCopyWith<$Res> {
  __$$_PinFailureCopyWithImpl(
      _$_PinFailure _value, $Res Function(_$_PinFailure) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? attemptsRemaining = null,
  }) {
    return _then(_$_PinFailure(
      null == attemptsRemaining
          ? _value.attemptsRemaining
          : attemptsRemaining // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class _$_PinFailure implements _PinFailure {
  _$_PinFailure(this.attemptsRemaining);

  @override
  final int attemptsRemaining;

  @override
  String toString() {
    return 'PinVerificationStatus.failure(attemptsRemaining: $attemptsRemaining)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_PinFailure &&
            (identical(other.attemptsRemaining, attemptsRemaining) ||
                other.attemptsRemaining == attemptsRemaining));
  }

  @override
  int get hashCode => Object.hash(runtimeType, attemptsRemaining);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_PinFailureCopyWith<_$_PinFailure> get copyWith =>
      __$$_PinFailureCopyWithImpl<_$_PinFailure>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() success,
    required TResult Function(int attemptsRemaining) failure,
  }) {
    return failure(attemptsRemaining);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? success,
    TResult? Function(int attemptsRemaining)? failure,
  }) {
    return failure?.call(attemptsRemaining);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? success,
    TResult Function(int attemptsRemaining)? failure,
    required TResult orElse(),
  }) {
    if (failure != null) {
      return failure(attemptsRemaining);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_PinSuccess value) success,
    required TResult Function(_PinFailure value) failure,
  }) {
    return failure(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_PinSuccess value)? success,
    TResult? Function(_PinFailure value)? failure,
  }) {
    return failure?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_PinSuccess value)? success,
    TResult Function(_PinFailure value)? failure,
    required TResult orElse(),
  }) {
    if (failure != null) {
      return failure(this);
    }
    return orElse();
  }
}

abstract class _PinFailure implements PinVerificationStatus {
  factory _PinFailure(final int attemptsRemaining) = _$_PinFailure;

  int get attemptsRemaining;
  @JsonKey(ignore: true)
  _$$_PinFailureCopyWith<_$_PinFailure> get copyWith =>
      throw _privateConstructorUsedError;
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

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
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
abstract class _$$_ManagementKeyMetadataCopyWith<$Res>
    implements $ManagementKeyMetadataCopyWith<$Res> {
  factory _$$_ManagementKeyMetadataCopyWith(_$_ManagementKeyMetadata value,
          $Res Function(_$_ManagementKeyMetadata) then) =
      __$$_ManagementKeyMetadataCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {ManagementKeyType keyType, bool defaultValue, TouchPolicy touchPolicy});
}

/// @nodoc
class __$$_ManagementKeyMetadataCopyWithImpl<$Res>
    extends _$ManagementKeyMetadataCopyWithImpl<$Res, _$_ManagementKeyMetadata>
    implements _$$_ManagementKeyMetadataCopyWith<$Res> {
  __$$_ManagementKeyMetadataCopyWithImpl(_$_ManagementKeyMetadata _value,
      $Res Function(_$_ManagementKeyMetadata) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? keyType = null,
    Object? defaultValue = null,
    Object? touchPolicy = null,
  }) {
    return _then(_$_ManagementKeyMetadata(
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
class _$_ManagementKeyMetadata implements _ManagementKeyMetadata {
  _$_ManagementKeyMetadata(this.keyType, this.defaultValue, this.touchPolicy);

  factory _$_ManagementKeyMetadata.fromJson(Map<String, dynamic> json) =>
      _$$_ManagementKeyMetadataFromJson(json);

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
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_ManagementKeyMetadata &&
            (identical(other.keyType, keyType) || other.keyType == keyType) &&
            (identical(other.defaultValue, defaultValue) ||
                other.defaultValue == defaultValue) &&
            (identical(other.touchPolicy, touchPolicy) ||
                other.touchPolicy == touchPolicy));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, keyType, defaultValue, touchPolicy);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_ManagementKeyMetadataCopyWith<_$_ManagementKeyMetadata> get copyWith =>
      __$$_ManagementKeyMetadataCopyWithImpl<_$_ManagementKeyMetadata>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_ManagementKeyMetadataToJson(
      this,
    );
  }
}

abstract class _ManagementKeyMetadata implements ManagementKeyMetadata {
  factory _ManagementKeyMetadata(
      final ManagementKeyType keyType,
      final bool defaultValue,
      final TouchPolicy touchPolicy) = _$_ManagementKeyMetadata;

  factory _ManagementKeyMetadata.fromJson(Map<String, dynamic> json) =
      _$_ManagementKeyMetadata.fromJson;

  @override
  ManagementKeyType get keyType;
  @override
  bool get defaultValue;
  @override
  TouchPolicy get touchPolicy;
  @override
  @JsonKey(ignore: true)
  _$$_ManagementKeyMetadataCopyWith<_$_ManagementKeyMetadata> get copyWith =>
      throw _privateConstructorUsedError;
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
  String get publicKeyEncoded => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
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
      String publicKeyEncoded});
}

/// @nodoc
class _$SlotMetadataCopyWithImpl<$Res, $Val extends SlotMetadata>
    implements $SlotMetadataCopyWith<$Res> {
  _$SlotMetadataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? keyType = null,
    Object? pinPolicy = null,
    Object? touchPolicy = null,
    Object? generated = null,
    Object? publicKeyEncoded = null,
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
      publicKeyEncoded: null == publicKeyEncoded
          ? _value.publicKeyEncoded
          : publicKeyEncoded // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$_SlotMetadataCopyWith<$Res>
    implements $SlotMetadataCopyWith<$Res> {
  factory _$$_SlotMetadataCopyWith(
          _$_SlotMetadata value, $Res Function(_$_SlotMetadata) then) =
      __$$_SlotMetadataCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {KeyType keyType,
      PinPolicy pinPolicy,
      TouchPolicy touchPolicy,
      bool generated,
      String publicKeyEncoded});
}

/// @nodoc
class __$$_SlotMetadataCopyWithImpl<$Res>
    extends _$SlotMetadataCopyWithImpl<$Res, _$_SlotMetadata>
    implements _$$_SlotMetadataCopyWith<$Res> {
  __$$_SlotMetadataCopyWithImpl(
      _$_SlotMetadata _value, $Res Function(_$_SlotMetadata) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? keyType = null,
    Object? pinPolicy = null,
    Object? touchPolicy = null,
    Object? generated = null,
    Object? publicKeyEncoded = null,
  }) {
    return _then(_$_SlotMetadata(
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
      null == publicKeyEncoded
          ? _value.publicKeyEncoded
          : publicKeyEncoded // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$_SlotMetadata implements _SlotMetadata {
  _$_SlotMetadata(this.keyType, this.pinPolicy, this.touchPolicy,
      this.generated, this.publicKeyEncoded);

  factory _$_SlotMetadata.fromJson(Map<String, dynamic> json) =>
      _$$_SlotMetadataFromJson(json);

  @override
  final KeyType keyType;
  @override
  final PinPolicy pinPolicy;
  @override
  final TouchPolicy touchPolicy;
  @override
  final bool generated;
  @override
  final String publicKeyEncoded;

  @override
  String toString() {
    return 'SlotMetadata(keyType: $keyType, pinPolicy: $pinPolicy, touchPolicy: $touchPolicy, generated: $generated, publicKeyEncoded: $publicKeyEncoded)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_SlotMetadata &&
            (identical(other.keyType, keyType) || other.keyType == keyType) &&
            (identical(other.pinPolicy, pinPolicy) ||
                other.pinPolicy == pinPolicy) &&
            (identical(other.touchPolicy, touchPolicy) ||
                other.touchPolicy == touchPolicy) &&
            (identical(other.generated, generated) ||
                other.generated == generated) &&
            (identical(other.publicKeyEncoded, publicKeyEncoded) ||
                other.publicKeyEncoded == publicKeyEncoded));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, keyType, pinPolicy, touchPolicy,
      generated, publicKeyEncoded);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_SlotMetadataCopyWith<_$_SlotMetadata> get copyWith =>
      __$$_SlotMetadataCopyWithImpl<_$_SlotMetadata>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_SlotMetadataToJson(
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
      final String publicKeyEncoded) = _$_SlotMetadata;

  factory _SlotMetadata.fromJson(Map<String, dynamic> json) =
      _$_SlotMetadata.fromJson;

  @override
  KeyType get keyType;
  @override
  PinPolicy get pinPolicy;
  @override
  TouchPolicy get touchPolicy;
  @override
  bool get generated;
  @override
  String get publicKeyEncoded;
  @override
  @JsonKey(ignore: true)
  _$$_SlotMetadataCopyWith<_$_SlotMetadata> get copyWith =>
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

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
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

  @override
  @pragma('vm:prefer-inline')
  $ManagementKeyMetadataCopyWith<$Res> get managementKeyMetadata {
    return $ManagementKeyMetadataCopyWith<$Res>(_value.managementKeyMetadata,
        (value) {
      return _then(_value.copyWith(managementKeyMetadata: value) as $Val);
    });
  }

  @override
  @pragma('vm:prefer-inline')
  $PinMetadataCopyWith<$Res> get pinMetadata {
    return $PinMetadataCopyWith<$Res>(_value.pinMetadata, (value) {
      return _then(_value.copyWith(pinMetadata: value) as $Val);
    });
  }

  @override
  @pragma('vm:prefer-inline')
  $PinMetadataCopyWith<$Res> get pukMetadata {
    return $PinMetadataCopyWith<$Res>(_value.pukMetadata, (value) {
      return _then(_value.copyWith(pukMetadata: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$_PivStateMetadataCopyWith<$Res>
    implements $PivStateMetadataCopyWith<$Res> {
  factory _$$_PivStateMetadataCopyWith(
          _$_PivStateMetadata value, $Res Function(_$_PivStateMetadata) then) =
      __$$_PivStateMetadataCopyWithImpl<$Res>;
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
class __$$_PivStateMetadataCopyWithImpl<$Res>
    extends _$PivStateMetadataCopyWithImpl<$Res, _$_PivStateMetadata>
    implements _$$_PivStateMetadataCopyWith<$Res> {
  __$$_PivStateMetadataCopyWithImpl(
      _$_PivStateMetadata _value, $Res Function(_$_PivStateMetadata) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? managementKeyMetadata = null,
    Object? pinMetadata = null,
    Object? pukMetadata = null,
  }) {
    return _then(_$_PivStateMetadata(
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
class _$_PivStateMetadata implements _PivStateMetadata {
  _$_PivStateMetadata(
      {required this.managementKeyMetadata,
      required this.pinMetadata,
      required this.pukMetadata});

  factory _$_PivStateMetadata.fromJson(Map<String, dynamic> json) =>
      _$$_PivStateMetadataFromJson(json);

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
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_PivStateMetadata &&
            (identical(other.managementKeyMetadata, managementKeyMetadata) ||
                other.managementKeyMetadata == managementKeyMetadata) &&
            (identical(other.pinMetadata, pinMetadata) ||
                other.pinMetadata == pinMetadata) &&
            (identical(other.pukMetadata, pukMetadata) ||
                other.pukMetadata == pukMetadata));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, managementKeyMetadata, pinMetadata, pukMetadata);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_PivStateMetadataCopyWith<_$_PivStateMetadata> get copyWith =>
      __$$_PivStateMetadataCopyWithImpl<_$_PivStateMetadata>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_PivStateMetadataToJson(
      this,
    );
  }
}

abstract class _PivStateMetadata implements PivStateMetadata {
  factory _PivStateMetadata(
      {required final ManagementKeyMetadata managementKeyMetadata,
      required final PinMetadata pinMetadata,
      required final PinMetadata pukMetadata}) = _$_PivStateMetadata;

  factory _PivStateMetadata.fromJson(Map<String, dynamic> json) =
      _$_PivStateMetadata.fromJson;

  @override
  ManagementKeyMetadata get managementKeyMetadata;
  @override
  PinMetadata get pinMetadata;
  @override
  PinMetadata get pukMetadata;
  @override
  @JsonKey(ignore: true)
  _$$_PivStateMetadataCopyWith<_$_PivStateMetadata> get copyWith =>
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
  String? get chuid => throw _privateConstructorUsedError;
  String? get ccc => throw _privateConstructorUsedError;
  PivStateMetadata? get metadata => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
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

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? version = null,
    Object? authenticated = null,
    Object? derivedKey = null,
    Object? storedKey = null,
    Object? pinAttempts = null,
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

  @override
  @pragma('vm:prefer-inline')
  $VersionCopyWith<$Res> get version {
    return $VersionCopyWith<$Res>(_value.version, (value) {
      return _then(_value.copyWith(version: value) as $Val);
    });
  }

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
abstract class _$$_PivStateCopyWith<$Res> implements $PivStateCopyWith<$Res> {
  factory _$$_PivStateCopyWith(
          _$_PivState value, $Res Function(_$_PivState) then) =
      __$$_PivStateCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {Version version,
      bool authenticated,
      bool derivedKey,
      bool storedKey,
      int pinAttempts,
      String? chuid,
      String? ccc,
      PivStateMetadata? metadata});

  @override
  $VersionCopyWith<$Res> get version;
  @override
  $PivStateMetadataCopyWith<$Res>? get metadata;
}

/// @nodoc
class __$$_PivStateCopyWithImpl<$Res>
    extends _$PivStateCopyWithImpl<$Res, _$_PivState>
    implements _$$_PivStateCopyWith<$Res> {
  __$$_PivStateCopyWithImpl(
      _$_PivState _value, $Res Function(_$_PivState) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? version = null,
    Object? authenticated = null,
    Object? derivedKey = null,
    Object? storedKey = null,
    Object? pinAttempts = null,
    Object? chuid = freezed,
    Object? ccc = freezed,
    Object? metadata = freezed,
  }) {
    return _then(_$_PivState(
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
class _$_PivState extends _PivState {
  _$_PivState(
      {required this.version,
      required this.authenticated,
      required this.derivedKey,
      required this.storedKey,
      required this.pinAttempts,
      this.chuid,
      this.ccc,
      this.metadata})
      : super._();

  factory _$_PivState.fromJson(Map<String, dynamic> json) =>
      _$$_PivStateFromJson(json);

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
  final String? chuid;
  @override
  final String? ccc;
  @override
  final PivStateMetadata? metadata;

  @override
  String toString() {
    return 'PivState(version: $version, authenticated: $authenticated, derivedKey: $derivedKey, storedKey: $storedKey, pinAttempts: $pinAttempts, chuid: $chuid, ccc: $ccc, metadata: $metadata)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_PivState &&
            (identical(other.version, version) || other.version == version) &&
            (identical(other.authenticated, authenticated) ||
                other.authenticated == authenticated) &&
            (identical(other.derivedKey, derivedKey) ||
                other.derivedKey == derivedKey) &&
            (identical(other.storedKey, storedKey) ||
                other.storedKey == storedKey) &&
            (identical(other.pinAttempts, pinAttempts) ||
                other.pinAttempts == pinAttempts) &&
            (identical(other.chuid, chuid) || other.chuid == chuid) &&
            (identical(other.ccc, ccc) || other.ccc == ccc) &&
            (identical(other.metadata, metadata) ||
                other.metadata == metadata));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, version, authenticated,
      derivedKey, storedKey, pinAttempts, chuid, ccc, metadata);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_PivStateCopyWith<_$_PivState> get copyWith =>
      __$$_PivStateCopyWithImpl<_$_PivState>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_PivStateToJson(
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
      final String? chuid,
      final String? ccc,
      final PivStateMetadata? metadata}) = _$_PivState;
  _PivState._() : super._();

  factory _PivState.fromJson(Map<String, dynamic> json) = _$_PivState.fromJson;

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
  String? get chuid;
  @override
  String? get ccc;
  @override
  PivStateMetadata? get metadata;
  @override
  @JsonKey(ignore: true)
  _$$_PivStateCopyWith<_$_PivState> get copyWith =>
      throw _privateConstructorUsedError;
}

CertInfo _$CertInfoFromJson(Map<String, dynamic> json) {
  return _CertInfo.fromJson(json);
}

/// @nodoc
mixin _$CertInfo {
  String get subject => throw _privateConstructorUsedError;
  String get issuer => throw _privateConstructorUsedError;
  String get serial => throw _privateConstructorUsedError;
  String get notValidBefore => throw _privateConstructorUsedError;
  String get notValidAfter => throw _privateConstructorUsedError;
  String get fingerprint => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $CertInfoCopyWith<CertInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CertInfoCopyWith<$Res> {
  factory $CertInfoCopyWith(CertInfo value, $Res Function(CertInfo) then) =
      _$CertInfoCopyWithImpl<$Res, CertInfo>;
  @useResult
  $Res call(
      {String subject,
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

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? subject = null,
    Object? issuer = null,
    Object? serial = null,
    Object? notValidBefore = null,
    Object? notValidAfter = null,
    Object? fingerprint = null,
  }) {
    return _then(_value.copyWith(
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
abstract class _$$_CertInfoCopyWith<$Res> implements $CertInfoCopyWith<$Res> {
  factory _$$_CertInfoCopyWith(
          _$_CertInfo value, $Res Function(_$_CertInfo) then) =
      __$$_CertInfoCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String subject,
      String issuer,
      String serial,
      String notValidBefore,
      String notValidAfter,
      String fingerprint});
}

/// @nodoc
class __$$_CertInfoCopyWithImpl<$Res>
    extends _$CertInfoCopyWithImpl<$Res, _$_CertInfo>
    implements _$$_CertInfoCopyWith<$Res> {
  __$$_CertInfoCopyWithImpl(
      _$_CertInfo _value, $Res Function(_$_CertInfo) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? subject = null,
    Object? issuer = null,
    Object? serial = null,
    Object? notValidBefore = null,
    Object? notValidAfter = null,
    Object? fingerprint = null,
  }) {
    return _then(_$_CertInfo(
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
class _$_CertInfo implements _CertInfo {
  _$_CertInfo(
      {required this.subject,
      required this.issuer,
      required this.serial,
      required this.notValidBefore,
      required this.notValidAfter,
      required this.fingerprint});

  factory _$_CertInfo.fromJson(Map<String, dynamic> json) =>
      _$$_CertInfoFromJson(json);

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
    return 'CertInfo(subject: $subject, issuer: $issuer, serial: $serial, notValidBefore: $notValidBefore, notValidAfter: $notValidAfter, fingerprint: $fingerprint)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_CertInfo &&
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

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, subject, issuer, serial,
      notValidBefore, notValidAfter, fingerprint);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_CertInfoCopyWith<_$_CertInfo> get copyWith =>
      __$$_CertInfoCopyWithImpl<_$_CertInfo>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_CertInfoToJson(
      this,
    );
  }
}

abstract class _CertInfo implements CertInfo {
  factory _CertInfo(
      {required final String subject,
      required final String issuer,
      required final String serial,
      required final String notValidBefore,
      required final String notValidAfter,
      required final String fingerprint}) = _$_CertInfo;

  factory _CertInfo.fromJson(Map<String, dynamic> json) = _$_CertInfo.fromJson;

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
  @override
  @JsonKey(ignore: true)
  _$$_CertInfoCopyWith<_$_CertInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

PivSlot _$PivSlotFromJson(Map<String, dynamic> json) {
  return _PivSlot.fromJson(json);
}

/// @nodoc
mixin _$PivSlot {
  SlotId get slot => throw _privateConstructorUsedError;
  bool? get hasKey => throw _privateConstructorUsedError;
  CertInfo? get certInfo => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PivSlotCopyWith<PivSlot> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PivSlotCopyWith<$Res> {
  factory $PivSlotCopyWith(PivSlot value, $Res Function(PivSlot) then) =
      _$PivSlotCopyWithImpl<$Res, PivSlot>;
  @useResult
  $Res call({SlotId slot, bool? hasKey, CertInfo? certInfo});

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

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? slot = null,
    Object? hasKey = freezed,
    Object? certInfo = freezed,
  }) {
    return _then(_value.copyWith(
      slot: null == slot
          ? _value.slot
          : slot // ignore: cast_nullable_to_non_nullable
              as SlotId,
      hasKey: freezed == hasKey
          ? _value.hasKey
          : hasKey // ignore: cast_nullable_to_non_nullable
              as bool?,
      certInfo: freezed == certInfo
          ? _value.certInfo
          : certInfo // ignore: cast_nullable_to_non_nullable
              as CertInfo?,
    ) as $Val);
  }

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
abstract class _$$_PivSlotCopyWith<$Res> implements $PivSlotCopyWith<$Res> {
  factory _$$_PivSlotCopyWith(
          _$_PivSlot value, $Res Function(_$_PivSlot) then) =
      __$$_PivSlotCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({SlotId slot, bool? hasKey, CertInfo? certInfo});

  @override
  $CertInfoCopyWith<$Res>? get certInfo;
}

/// @nodoc
class __$$_PivSlotCopyWithImpl<$Res>
    extends _$PivSlotCopyWithImpl<$Res, _$_PivSlot>
    implements _$$_PivSlotCopyWith<$Res> {
  __$$_PivSlotCopyWithImpl(_$_PivSlot _value, $Res Function(_$_PivSlot) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? slot = null,
    Object? hasKey = freezed,
    Object? certInfo = freezed,
  }) {
    return _then(_$_PivSlot(
      slot: null == slot
          ? _value.slot
          : slot // ignore: cast_nullable_to_non_nullable
              as SlotId,
      hasKey: freezed == hasKey
          ? _value.hasKey
          : hasKey // ignore: cast_nullable_to_non_nullable
              as bool?,
      certInfo: freezed == certInfo
          ? _value.certInfo
          : certInfo // ignore: cast_nullable_to_non_nullable
              as CertInfo?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$_PivSlot implements _PivSlot {
  _$_PivSlot({required this.slot, this.hasKey, this.certInfo});

  factory _$_PivSlot.fromJson(Map<String, dynamic> json) =>
      _$$_PivSlotFromJson(json);

  @override
  final SlotId slot;
  @override
  final bool? hasKey;
  @override
  final CertInfo? certInfo;

  @override
  String toString() {
    return 'PivSlot(slot: $slot, hasKey: $hasKey, certInfo: $certInfo)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_PivSlot &&
            (identical(other.slot, slot) || other.slot == slot) &&
            (identical(other.hasKey, hasKey) || other.hasKey == hasKey) &&
            (identical(other.certInfo, certInfo) ||
                other.certInfo == certInfo));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, slot, hasKey, certInfo);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_PivSlotCopyWith<_$_PivSlot> get copyWith =>
      __$$_PivSlotCopyWithImpl<_$_PivSlot>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_PivSlotToJson(
      this,
    );
  }
}

abstract class _PivSlot implements PivSlot {
  factory _PivSlot(
      {required final SlotId slot,
      final bool? hasKey,
      final CertInfo? certInfo}) = _$_PivSlot;

  factory _PivSlot.fromJson(Map<String, dynamic> json) = _$_PivSlot.fromJson;

  @override
  SlotId get slot;
  @override
  bool? get hasKey;
  @override
  CertInfo? get certInfo;
  @override
  @JsonKey(ignore: true)
  _$$_PivSlotCopyWith<_$_PivSlot> get copyWith =>
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
}

/// @nodoc
abstract class _$$_ExamineResultCopyWith<$Res> {
  factory _$$_ExamineResultCopyWith(
          _$_ExamineResult value, $Res Function(_$_ExamineResult) then) =
      __$$_ExamineResultCopyWithImpl<$Res>;
  @useResult
  $Res call({bool password, KeyType? keyType, CertInfo? certInfo});

  $CertInfoCopyWith<$Res>? get certInfo;
}

/// @nodoc
class __$$_ExamineResultCopyWithImpl<$Res>
    extends _$PivExamineResultCopyWithImpl<$Res, _$_ExamineResult>
    implements _$$_ExamineResultCopyWith<$Res> {
  __$$_ExamineResultCopyWithImpl(
      _$_ExamineResult _value, $Res Function(_$_ExamineResult) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? password = null,
    Object? keyType = freezed,
    Object? certInfo = freezed,
  }) {
    return _then(_$_ExamineResult(
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
class _$_ExamineResult implements _ExamineResult {
  _$_ExamineResult(
      {required this.password,
      required this.keyType,
      required this.certInfo,
      final String? $type})
      : $type = $type ?? 'result';

  factory _$_ExamineResult.fromJson(Map<String, dynamic> json) =>
      _$$_ExamineResultFromJson(json);

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
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_ExamineResult &&
            (identical(other.password, password) ||
                other.password == password) &&
            (identical(other.keyType, keyType) || other.keyType == keyType) &&
            (identical(other.certInfo, certInfo) ||
                other.certInfo == certInfo));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, password, keyType, certInfo);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_ExamineResultCopyWith<_$_ExamineResult> get copyWith =>
      __$$_ExamineResultCopyWithImpl<_$_ExamineResult>(this, _$identity);

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
    return _$$_ExamineResultToJson(
      this,
    );
  }
}

abstract class _ExamineResult implements PivExamineResult {
  factory _ExamineResult(
      {required final bool password,
      required final KeyType? keyType,
      required final CertInfo? certInfo}) = _$_ExamineResult;

  factory _ExamineResult.fromJson(Map<String, dynamic> json) =
      _$_ExamineResult.fromJson;

  bool get password;
  KeyType? get keyType;
  CertInfo? get certInfo;
  @JsonKey(ignore: true)
  _$$_ExamineResultCopyWith<_$_ExamineResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$_InvalidPasswordCopyWith<$Res> {
  factory _$$_InvalidPasswordCopyWith(
          _$_InvalidPassword value, $Res Function(_$_InvalidPassword) then) =
      __$$_InvalidPasswordCopyWithImpl<$Res>;
}

/// @nodoc
class __$$_InvalidPasswordCopyWithImpl<$Res>
    extends _$PivExamineResultCopyWithImpl<$Res, _$_InvalidPassword>
    implements _$$_InvalidPasswordCopyWith<$Res> {
  __$$_InvalidPasswordCopyWithImpl(
      _$_InvalidPassword _value, $Res Function(_$_InvalidPassword) _then)
      : super(_value, _then);
}

/// @nodoc
@JsonSerializable()
class _$_InvalidPassword implements _InvalidPassword {
  _$_InvalidPassword({final String? $type})
      : $type = $type ?? 'invalidPassword';

  factory _$_InvalidPassword.fromJson(Map<String, dynamic> json) =>
      _$$_InvalidPasswordFromJson(json);

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'PivExamineResult.invalidPassword()';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$_InvalidPassword);
  }

  @JsonKey(ignore: true)
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
    return _$$_InvalidPasswordToJson(
      this,
    );
  }
}

abstract class _InvalidPassword implements PivExamineResult {
  factory _InvalidPassword() = _$_InvalidPassword;

  factory _InvalidPassword.fromJson(Map<String, dynamic> json) =
      _$_InvalidPassword.fromJson;
}

/// @nodoc
mixin _$PivGenerateParameters {
  String get subject => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String subject, DateTime validFrom, DateTime validTo)
        certificate,
    required TResult Function(String subject) csr,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String subject, DateTime validFrom, DateTime validTo)?
        certificate,
    TResult? Function(String subject)? csr,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String subject, DateTime validFrom, DateTime validTo)?
        certificate,
    TResult Function(String subject)? csr,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_GenerateCertificate value) certificate,
    required TResult Function(_GenerateCsr value) csr,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_GenerateCertificate value)? certificate,
    TResult? Function(_GenerateCsr value)? csr,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_GenerateCertificate value)? certificate,
    TResult Function(_GenerateCsr value)? csr,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $PivGenerateParametersCopyWith<PivGenerateParameters> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PivGenerateParametersCopyWith<$Res> {
  factory $PivGenerateParametersCopyWith(PivGenerateParameters value,
          $Res Function(PivGenerateParameters) then) =
      _$PivGenerateParametersCopyWithImpl<$Res, PivGenerateParameters>;
  @useResult
  $Res call({String subject});
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

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? subject = null,
  }) {
    return _then(_value.copyWith(
      subject: null == subject
          ? _value.subject
          : subject // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$_GenerateCertificateCopyWith<$Res>
    implements $PivGenerateParametersCopyWith<$Res> {
  factory _$$_GenerateCertificateCopyWith(_$_GenerateCertificate value,
          $Res Function(_$_GenerateCertificate) then) =
      __$$_GenerateCertificateCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String subject, DateTime validFrom, DateTime validTo});
}

/// @nodoc
class __$$_GenerateCertificateCopyWithImpl<$Res>
    extends _$PivGenerateParametersCopyWithImpl<$Res, _$_GenerateCertificate>
    implements _$$_GenerateCertificateCopyWith<$Res> {
  __$$_GenerateCertificateCopyWithImpl(_$_GenerateCertificate _value,
      $Res Function(_$_GenerateCertificate) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? subject = null,
    Object? validFrom = null,
    Object? validTo = null,
  }) {
    return _then(_$_GenerateCertificate(
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

class _$_GenerateCertificate implements _GenerateCertificate {
  _$_GenerateCertificate(
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
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_GenerateCertificate &&
            (identical(other.subject, subject) || other.subject == subject) &&
            (identical(other.validFrom, validFrom) ||
                other.validFrom == validFrom) &&
            (identical(other.validTo, validTo) || other.validTo == validTo));
  }

  @override
  int get hashCode => Object.hash(runtimeType, subject, validFrom, validTo);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_GenerateCertificateCopyWith<_$_GenerateCertificate> get copyWith =>
      __$$_GenerateCertificateCopyWithImpl<_$_GenerateCertificate>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
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
    TResult? Function(String subject, DateTime validFrom, DateTime validTo)?
        certificate,
    TResult? Function(String subject)? csr,
  }) {
    return certificate?.call(subject, validFrom, validTo);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
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
    required TResult Function(_GenerateCertificate value) certificate,
    required TResult Function(_GenerateCsr value) csr,
  }) {
    return certificate(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_GenerateCertificate value)? certificate,
    TResult? Function(_GenerateCsr value)? csr,
  }) {
    return certificate?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
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
      required final DateTime validTo}) = _$_GenerateCertificate;

  @override
  String get subject;
  DateTime get validFrom;
  DateTime get validTo;
  @override
  @JsonKey(ignore: true)
  _$$_GenerateCertificateCopyWith<_$_GenerateCertificate> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$_GenerateCsrCopyWith<$Res>
    implements $PivGenerateParametersCopyWith<$Res> {
  factory _$$_GenerateCsrCopyWith(
          _$_GenerateCsr value, $Res Function(_$_GenerateCsr) then) =
      __$$_GenerateCsrCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String subject});
}

/// @nodoc
class __$$_GenerateCsrCopyWithImpl<$Res>
    extends _$PivGenerateParametersCopyWithImpl<$Res, _$_GenerateCsr>
    implements _$$_GenerateCsrCopyWith<$Res> {
  __$$_GenerateCsrCopyWithImpl(
      _$_GenerateCsr _value, $Res Function(_$_GenerateCsr) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? subject = null,
  }) {
    return _then(_$_GenerateCsr(
      subject: null == subject
          ? _value.subject
          : subject // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$_GenerateCsr implements _GenerateCsr {
  _$_GenerateCsr({required this.subject});

  @override
  final String subject;

  @override
  String toString() {
    return 'PivGenerateParameters.csr(subject: $subject)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_GenerateCsr &&
            (identical(other.subject, subject) || other.subject == subject));
  }

  @override
  int get hashCode => Object.hash(runtimeType, subject);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_GenerateCsrCopyWith<_$_GenerateCsr> get copyWith =>
      __$$_GenerateCsrCopyWithImpl<_$_GenerateCsr>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
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
    TResult? Function(String subject, DateTime validFrom, DateTime validTo)?
        certificate,
    TResult? Function(String subject)? csr,
  }) {
    return csr?.call(subject);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
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
    required TResult Function(_GenerateCertificate value) certificate,
    required TResult Function(_GenerateCsr value) csr,
  }) {
    return csr(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_GenerateCertificate value)? certificate,
    TResult? Function(_GenerateCsr value)? csr,
  }) {
    return csr?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
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
  factory _GenerateCsr({required final String subject}) = _$_GenerateCsr;

  @override
  String get subject;
  @override
  @JsonKey(ignore: true)
  _$$_GenerateCsrCopyWith<_$_GenerateCsr> get copyWith =>
      throw _privateConstructorUsedError;
}

PivGenerateResult _$PivGenerateResultFromJson(Map<String, dynamic> json) {
  return _PivGenerateResult.fromJson(json);
}

/// @nodoc
mixin _$PivGenerateResult {
  GenerateType get generateType => throw _privateConstructorUsedError;
  String get publicKey => throw _privateConstructorUsedError;
  String get result => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PivGenerateResultCopyWith<PivGenerateResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PivGenerateResultCopyWith<$Res> {
  factory $PivGenerateResultCopyWith(
          PivGenerateResult value, $Res Function(PivGenerateResult) then) =
      _$PivGenerateResultCopyWithImpl<$Res, PivGenerateResult>;
  @useResult
  $Res call({GenerateType generateType, String publicKey, String result});
}

/// @nodoc
class _$PivGenerateResultCopyWithImpl<$Res, $Val extends PivGenerateResult>
    implements $PivGenerateResultCopyWith<$Res> {
  _$PivGenerateResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? generateType = null,
    Object? publicKey = null,
    Object? result = null,
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
      result: null == result
          ? _value.result
          : result // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$_PivGenerateResultCopyWith<$Res>
    implements $PivGenerateResultCopyWith<$Res> {
  factory _$$_PivGenerateResultCopyWith(_$_PivGenerateResult value,
          $Res Function(_$_PivGenerateResult) then) =
      __$$_PivGenerateResultCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({GenerateType generateType, String publicKey, String result});
}

/// @nodoc
class __$$_PivGenerateResultCopyWithImpl<$Res>
    extends _$PivGenerateResultCopyWithImpl<$Res, _$_PivGenerateResult>
    implements _$$_PivGenerateResultCopyWith<$Res> {
  __$$_PivGenerateResultCopyWithImpl(
      _$_PivGenerateResult _value, $Res Function(_$_PivGenerateResult) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? generateType = null,
    Object? publicKey = null,
    Object? result = null,
  }) {
    return _then(_$_PivGenerateResult(
      generateType: null == generateType
          ? _value.generateType
          : generateType // ignore: cast_nullable_to_non_nullable
              as GenerateType,
      publicKey: null == publicKey
          ? _value.publicKey
          : publicKey // ignore: cast_nullable_to_non_nullable
              as String,
      result: null == result
          ? _value.result
          : result // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$_PivGenerateResult implements _PivGenerateResult {
  _$_PivGenerateResult(
      {required this.generateType,
      required this.publicKey,
      required this.result});

  factory _$_PivGenerateResult.fromJson(Map<String, dynamic> json) =>
      _$$_PivGenerateResultFromJson(json);

  @override
  final GenerateType generateType;
  @override
  final String publicKey;
  @override
  final String result;

  @override
  String toString() {
    return 'PivGenerateResult(generateType: $generateType, publicKey: $publicKey, result: $result)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_PivGenerateResult &&
            (identical(other.generateType, generateType) ||
                other.generateType == generateType) &&
            (identical(other.publicKey, publicKey) ||
                other.publicKey == publicKey) &&
            (identical(other.result, result) || other.result == result));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, generateType, publicKey, result);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_PivGenerateResultCopyWith<_$_PivGenerateResult> get copyWith =>
      __$$_PivGenerateResultCopyWithImpl<_$_PivGenerateResult>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_PivGenerateResultToJson(
      this,
    );
  }
}

abstract class _PivGenerateResult implements PivGenerateResult {
  factory _PivGenerateResult(
      {required final GenerateType generateType,
      required final String publicKey,
      required final String result}) = _$_PivGenerateResult;

  factory _PivGenerateResult.fromJson(Map<String, dynamic> json) =
      _$_PivGenerateResult.fromJson;

  @override
  GenerateType get generateType;
  @override
  String get publicKey;
  @override
  String get result;
  @override
  @JsonKey(ignore: true)
  _$$_PivGenerateResultCopyWith<_$_PivGenerateResult> get copyWith =>
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

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
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
abstract class _$$_PivImportResultCopyWith<$Res>
    implements $PivImportResultCopyWith<$Res> {
  factory _$$_PivImportResultCopyWith(
          _$_PivImportResult value, $Res Function(_$_PivImportResult) then) =
      __$$_PivImportResultCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({SlotMetadata? metadata, String? publicKey, String? certificate});

  @override
  $SlotMetadataCopyWith<$Res>? get metadata;
}

/// @nodoc
class __$$_PivImportResultCopyWithImpl<$Res>
    extends _$PivImportResultCopyWithImpl<$Res, _$_PivImportResult>
    implements _$$_PivImportResultCopyWith<$Res> {
  __$$_PivImportResultCopyWithImpl(
      _$_PivImportResult _value, $Res Function(_$_PivImportResult) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? metadata = freezed,
    Object? publicKey = freezed,
    Object? certificate = freezed,
  }) {
    return _then(_$_PivImportResult(
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
class _$_PivImportResult implements _PivImportResult {
  _$_PivImportResult(
      {required this.metadata,
      required this.publicKey,
      required this.certificate});

  factory _$_PivImportResult.fromJson(Map<String, dynamic> json) =>
      _$$_PivImportResultFromJson(json);

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
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_PivImportResult &&
            (identical(other.metadata, metadata) ||
                other.metadata == metadata) &&
            (identical(other.publicKey, publicKey) ||
                other.publicKey == publicKey) &&
            (identical(other.certificate, certificate) ||
                other.certificate == certificate));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, metadata, publicKey, certificate);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_PivImportResultCopyWith<_$_PivImportResult> get copyWith =>
      __$$_PivImportResultCopyWithImpl<_$_PivImportResult>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_PivImportResultToJson(
      this,
    );
  }
}

abstract class _PivImportResult implements PivImportResult {
  factory _PivImportResult(
      {required final SlotMetadata? metadata,
      required final String? publicKey,
      required final String? certificate}) = _$_PivImportResult;

  factory _PivImportResult.fromJson(Map<String, dynamic> json) =
      _$_PivImportResult.fromJson;

  @override
  SlotMetadata? get metadata;
  @override
  String? get publicKey;
  @override
  String? get certificate;
  @override
  @JsonKey(ignore: true)
  _$$_PivImportResultCopyWith<_$_PivImportResult> get copyWith =>
      throw _privateConstructorUsedError;
}
