// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
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
