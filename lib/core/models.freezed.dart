// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target

part of 'models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more informations: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

/// @nodoc
class _$VersionTearOff {
  const _$VersionTearOff();

  _Version call(int major, int minor, int patch) {
    return _Version(
      major,
      minor,
      patch,
    );
  }
}

/// @nodoc
const $Version = _$VersionTearOff();

/// @nodoc
mixin _$Version {
  int get major => throw _privateConstructorUsedError;
  int get minor => throw _privateConstructorUsedError;
  int get patch => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $VersionCopyWith<Version> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VersionCopyWith<$Res> {
  factory $VersionCopyWith(Version value, $Res Function(Version) then) =
      _$VersionCopyWithImpl<$Res>;
  $Res call({int major, int minor, int patch});
}

/// @nodoc
class _$VersionCopyWithImpl<$Res> implements $VersionCopyWith<$Res> {
  _$VersionCopyWithImpl(this._value, this._then);

  final Version _value;
  // ignore: unused_field
  final $Res Function(Version) _then;

  @override
  $Res call({
    Object? major = freezed,
    Object? minor = freezed,
    Object? patch = freezed,
  }) {
    return _then(_value.copyWith(
      major: major == freezed
          ? _value.major
          : major // ignore: cast_nullable_to_non_nullable
              as int,
      minor: minor == freezed
          ? _value.minor
          : minor // ignore: cast_nullable_to_non_nullable
              as int,
      patch: patch == freezed
          ? _value.patch
          : patch // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
abstract class _$VersionCopyWith<$Res> implements $VersionCopyWith<$Res> {
  factory _$VersionCopyWith(_Version value, $Res Function(_Version) then) =
      __$VersionCopyWithImpl<$Res>;
  @override
  $Res call({int major, int minor, int patch});
}

/// @nodoc
class __$VersionCopyWithImpl<$Res> extends _$VersionCopyWithImpl<$Res>
    implements _$VersionCopyWith<$Res> {
  __$VersionCopyWithImpl(_Version _value, $Res Function(_Version) _then)
      : super(_value, (v) => _then(v as _Version));

  @override
  _Version get _value => super._value as _Version;

  @override
  $Res call({
    Object? major = freezed,
    Object? minor = freezed,
    Object? patch = freezed,
  }) {
    return _then(_Version(
      major == freezed
          ? _value.major
          : major // ignore: cast_nullable_to_non_nullable
              as int,
      minor == freezed
          ? _value.minor
          : minor // ignore: cast_nullable_to_non_nullable
              as int,
      patch == freezed
          ? _value.patch
          : patch // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class _$_Version extends _Version {
  const _$_Version(this.major, this.minor, this.patch) : super._();

  @override
  final int major;
  @override
  final int minor;
  @override
  final int patch;

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Version &&
            const DeepCollectionEquality().equals(other.major, major) &&
            const DeepCollectionEquality().equals(other.minor, minor) &&
            const DeepCollectionEquality().equals(other.patch, patch));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(major),
      const DeepCollectionEquality().hash(minor),
      const DeepCollectionEquality().hash(patch));

  @JsonKey(ignore: true)
  @override
  _$VersionCopyWith<_Version> get copyWith =>
      __$VersionCopyWithImpl<_Version>(this, _$identity);
}

abstract class _Version extends Version {
  const factory _Version(int major, int minor, int patch) = _$_Version;
  const _Version._() : super._();

  @override
  int get major;
  @override
  int get minor;
  @override
  int get patch;
  @override
  @JsonKey(ignore: true)
  _$VersionCopyWith<_Version> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
class _$PairTearOff {
  const _$PairTearOff();

  _Pair<T1, T2> call<T1, T2>(T1 first, T2 second) {
    return _Pair<T1, T2>(
      first,
      second,
    );
  }
}

/// @nodoc
const $Pair = _$PairTearOff();

/// @nodoc
mixin _$Pair<T1, T2> {
  T1 get first => throw _privateConstructorUsedError;
  T2 get second => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $PairCopyWith<T1, T2, Pair<T1, T2>> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PairCopyWith<T1, T2, $Res> {
  factory $PairCopyWith(Pair<T1, T2> value, $Res Function(Pair<T1, T2>) then) =
      _$PairCopyWithImpl<T1, T2, $Res>;
  $Res call({T1 first, T2 second});
}

/// @nodoc
class _$PairCopyWithImpl<T1, T2, $Res> implements $PairCopyWith<T1, T2, $Res> {
  _$PairCopyWithImpl(this._value, this._then);

  final Pair<T1, T2> _value;
  // ignore: unused_field
  final $Res Function(Pair<T1, T2>) _then;

  @override
  $Res call({
    Object? first = freezed,
    Object? second = freezed,
  }) {
    return _then(_value.copyWith(
      first: first == freezed
          ? _value.first
          : first // ignore: cast_nullable_to_non_nullable
              as T1,
      second: second == freezed
          ? _value.second
          : second // ignore: cast_nullable_to_non_nullable
              as T2,
    ));
  }
}

/// @nodoc
abstract class _$PairCopyWith<T1, T2, $Res>
    implements $PairCopyWith<T1, T2, $Res> {
  factory _$PairCopyWith(
          _Pair<T1, T2> value, $Res Function(_Pair<T1, T2>) then) =
      __$PairCopyWithImpl<T1, T2, $Res>;
  @override
  $Res call({T1 first, T2 second});
}

/// @nodoc
class __$PairCopyWithImpl<T1, T2, $Res> extends _$PairCopyWithImpl<T1, T2, $Res>
    implements _$PairCopyWith<T1, T2, $Res> {
  __$PairCopyWithImpl(_Pair<T1, T2> _value, $Res Function(_Pair<T1, T2>) _then)
      : super(_value, (v) => _then(v as _Pair<T1, T2>));

  @override
  _Pair<T1, T2> get _value => super._value as _Pair<T1, T2>;

  @override
  $Res call({
    Object? first = freezed,
    Object? second = freezed,
  }) {
    return _then(_Pair<T1, T2>(
      first == freezed
          ? _value.first
          : first // ignore: cast_nullable_to_non_nullable
              as T1,
      second == freezed
          ? _value.second
          : second // ignore: cast_nullable_to_non_nullable
              as T2,
    ));
  }
}

/// @nodoc

class _$_Pair<T1, T2> implements _Pair<T1, T2> {
  _$_Pair(this.first, this.second);

  @override
  final T1 first;
  @override
  final T2 second;

  @override
  String toString() {
    return 'Pair<$T1, $T2>(first: $first, second: $second)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Pair<T1, T2> &&
            const DeepCollectionEquality().equals(other.first, first) &&
            const DeepCollectionEquality().equals(other.second, second));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(first),
      const DeepCollectionEquality().hash(second));

  @JsonKey(ignore: true)
  @override
  _$PairCopyWith<T1, T2, _Pair<T1, T2>> get copyWith =>
      __$PairCopyWithImpl<T1, T2, _Pair<T1, T2>>(this, _$identity);
}

abstract class _Pair<T1, T2> implements Pair<T1, T2> {
  factory _Pair(T1 first, T2 second) = _$_Pair<T1, T2>;

  @override
  T1 get first;
  @override
  T2 get second;
  @override
  @JsonKey(ignore: true)
  _$PairCopyWith<T1, T2, _Pair<T1, T2>> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
class _$ApplicationStateResultTearOff {
  const _$ApplicationStateResultTearOff();

  _None<T> none<T>() {
    return _None<T>();
  }

  _Failure<T> failure<T>(String reason) {
    return _Failure<T>(
      reason,
    );
  }

  _Success<T> success<T>(T state) {
    return _Success<T>(
      state,
    );
  }
}

/// @nodoc
const $ApplicationStateResult = _$ApplicationStateResultTearOff();

/// @nodoc
mixin _$ApplicationStateResult<T> {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() none,
    required TResult Function(String reason) failure,
    required TResult Function(T state) success,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult Function()? none,
    TResult Function(String reason)? failure,
    TResult Function(T state)? success,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? none,
    TResult Function(String reason)? failure,
    TResult Function(T state)? success,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_None<T> value) none,
    required TResult Function(_Failure<T> value) failure,
    required TResult Function(_Success<T> value) success,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult Function(_None<T> value)? none,
    TResult Function(_Failure<T> value)? failure,
    TResult Function(_Success<T> value)? success,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_None<T> value)? none,
    TResult Function(_Failure<T> value)? failure,
    TResult Function(_Success<T> value)? success,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ApplicationStateResultCopyWith<T, $Res> {
  factory $ApplicationStateResultCopyWith(ApplicationStateResult<T> value,
          $Res Function(ApplicationStateResult<T>) then) =
      _$ApplicationStateResultCopyWithImpl<T, $Res>;
}

/// @nodoc
class _$ApplicationStateResultCopyWithImpl<T, $Res>
    implements $ApplicationStateResultCopyWith<T, $Res> {
  _$ApplicationStateResultCopyWithImpl(this._value, this._then);

  final ApplicationStateResult<T> _value;
  // ignore: unused_field
  final $Res Function(ApplicationStateResult<T>) _then;
}

/// @nodoc
abstract class _$NoneCopyWith<T, $Res> {
  factory _$NoneCopyWith(_None<T> value, $Res Function(_None<T>) then) =
      __$NoneCopyWithImpl<T, $Res>;
}

/// @nodoc
class __$NoneCopyWithImpl<T, $Res>
    extends _$ApplicationStateResultCopyWithImpl<T, $Res>
    implements _$NoneCopyWith<T, $Res> {
  __$NoneCopyWithImpl(_None<T> _value, $Res Function(_None<T>) _then)
      : super(_value, (v) => _then(v as _None<T>));

  @override
  _None<T> get _value => super._value as _None<T>;
}

/// @nodoc

class _$_None<T> implements _None<T> {
  _$_None();

  @override
  String toString() {
    return 'ApplicationStateResult<$T>.none()';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _None<T>);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() none,
    required TResult Function(String reason) failure,
    required TResult Function(T state) success,
  }) {
    return none();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult Function()? none,
    TResult Function(String reason)? failure,
    TResult Function(T state)? success,
  }) {
    return none?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? none,
    TResult Function(String reason)? failure,
    TResult Function(T state)? success,
    required TResult orElse(),
  }) {
    if (none != null) {
      return none();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_None<T> value) none,
    required TResult Function(_Failure<T> value) failure,
    required TResult Function(_Success<T> value) success,
  }) {
    return none(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult Function(_None<T> value)? none,
    TResult Function(_Failure<T> value)? failure,
    TResult Function(_Success<T> value)? success,
  }) {
    return none?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_None<T> value)? none,
    TResult Function(_Failure<T> value)? failure,
    TResult Function(_Success<T> value)? success,
    required TResult orElse(),
  }) {
    if (none != null) {
      return none(this);
    }
    return orElse();
  }
}

abstract class _None<T> implements ApplicationStateResult<T> {
  factory _None() = _$_None<T>;
}

/// @nodoc
abstract class _$FailureCopyWith<T, $Res> {
  factory _$FailureCopyWith(
          _Failure<T> value, $Res Function(_Failure<T>) then) =
      __$FailureCopyWithImpl<T, $Res>;
  $Res call({String reason});
}

/// @nodoc
class __$FailureCopyWithImpl<T, $Res>
    extends _$ApplicationStateResultCopyWithImpl<T, $Res>
    implements _$FailureCopyWith<T, $Res> {
  __$FailureCopyWithImpl(_Failure<T> _value, $Res Function(_Failure<T>) _then)
      : super(_value, (v) => _then(v as _Failure<T>));

  @override
  _Failure<T> get _value => super._value as _Failure<T>;

  @override
  $Res call({
    Object? reason = freezed,
  }) {
    return _then(_Failure<T>(
      reason == freezed
          ? _value.reason
          : reason // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$_Failure<T> implements _Failure<T> {
  _$_Failure(this.reason);

  @override
  final String reason;

  @override
  String toString() {
    return 'ApplicationStateResult<$T>.failure(reason: $reason)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Failure<T> &&
            const DeepCollectionEquality().equals(other.reason, reason));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(reason));

  @JsonKey(ignore: true)
  @override
  _$FailureCopyWith<T, _Failure<T>> get copyWith =>
      __$FailureCopyWithImpl<T, _Failure<T>>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() none,
    required TResult Function(String reason) failure,
    required TResult Function(T state) success,
  }) {
    return failure(reason);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult Function()? none,
    TResult Function(String reason)? failure,
    TResult Function(T state)? success,
  }) {
    return failure?.call(reason);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? none,
    TResult Function(String reason)? failure,
    TResult Function(T state)? success,
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
    required TResult Function(_None<T> value) none,
    required TResult Function(_Failure<T> value) failure,
    required TResult Function(_Success<T> value) success,
  }) {
    return failure(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult Function(_None<T> value)? none,
    TResult Function(_Failure<T> value)? failure,
    TResult Function(_Success<T> value)? success,
  }) {
    return failure?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_None<T> value)? none,
    TResult Function(_Failure<T> value)? failure,
    TResult Function(_Success<T> value)? success,
    required TResult orElse(),
  }) {
    if (failure != null) {
      return failure(this);
    }
    return orElse();
  }
}

abstract class _Failure<T> implements ApplicationStateResult<T> {
  factory _Failure(String reason) = _$_Failure<T>;

  String get reason;
  @JsonKey(ignore: true)
  _$FailureCopyWith<T, _Failure<T>> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$SuccessCopyWith<T, $Res> {
  factory _$SuccessCopyWith(
          _Success<T> value, $Res Function(_Success<T>) then) =
      __$SuccessCopyWithImpl<T, $Res>;
  $Res call({T state});
}

/// @nodoc
class __$SuccessCopyWithImpl<T, $Res>
    extends _$ApplicationStateResultCopyWithImpl<T, $Res>
    implements _$SuccessCopyWith<T, $Res> {
  __$SuccessCopyWithImpl(_Success<T> _value, $Res Function(_Success<T>) _then)
      : super(_value, (v) => _then(v as _Success<T>));

  @override
  _Success<T> get _value => super._value as _Success<T>;

  @override
  $Res call({
    Object? state = freezed,
  }) {
    return _then(_Success<T>(
      state == freezed
          ? _value.state
          : state // ignore: cast_nullable_to_non_nullable
              as T,
    ));
  }
}

/// @nodoc

class _$_Success<T> implements _Success<T> {
  _$_Success(this.state);

  @override
  final T state;

  @override
  String toString() {
    return 'ApplicationStateResult<$T>.success(state: $state)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Success<T> &&
            const DeepCollectionEquality().equals(other.state, state));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(state));

  @JsonKey(ignore: true)
  @override
  _$SuccessCopyWith<T, _Success<T>> get copyWith =>
      __$SuccessCopyWithImpl<T, _Success<T>>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() none,
    required TResult Function(String reason) failure,
    required TResult Function(T state) success,
  }) {
    return success(state);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult Function()? none,
    TResult Function(String reason)? failure,
    TResult Function(T state)? success,
  }) {
    return success?.call(state);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? none,
    TResult Function(String reason)? failure,
    TResult Function(T state)? success,
    required TResult orElse(),
  }) {
    if (success != null) {
      return success(state);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_None<T> value) none,
    required TResult Function(_Failure<T> value) failure,
    required TResult Function(_Success<T> value) success,
  }) {
    return success(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult Function(_None<T> value)? none,
    TResult Function(_Failure<T> value)? failure,
    TResult Function(_Success<T> value)? success,
  }) {
    return success?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_None<T> value)? none,
    TResult Function(_Failure<T> value)? failure,
    TResult Function(_Success<T> value)? success,
    required TResult orElse(),
  }) {
    if (success != null) {
      return success(this);
    }
    return orElse();
  }
}

abstract class _Success<T> implements ApplicationStateResult<T> {
  factory _Success(T state) = _$_Success<T>;

  T get state;
  @JsonKey(ignore: true)
  _$SuccessCopyWith<T, _Success<T>> get copyWith =>
      throw _privateConstructorUsedError;
}
