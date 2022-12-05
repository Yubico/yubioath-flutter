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
      _$VersionCopyWithImpl<$Res, Version>;
  @useResult
  $Res call({int major, int minor, int patch});
}

/// @nodoc
class _$VersionCopyWithImpl<$Res, $Val extends Version>
    implements $VersionCopyWith<$Res> {
  _$VersionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? major = null,
    Object? minor = null,
    Object? patch = null,
  }) {
    return _then(_value.copyWith(
      major: null == major
          ? _value.major
          : major // ignore: cast_nullable_to_non_nullable
              as int,
      minor: null == minor
          ? _value.minor
          : minor // ignore: cast_nullable_to_non_nullable
              as int,
      patch: null == patch
          ? _value.patch
          : patch // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$_VersionCopyWith<$Res> implements $VersionCopyWith<$Res> {
  factory _$$_VersionCopyWith(
          _$_Version value, $Res Function(_$_Version) then) =
      __$$_VersionCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int major, int minor, int patch});
}

/// @nodoc
class __$$_VersionCopyWithImpl<$Res>
    extends _$VersionCopyWithImpl<$Res, _$_Version>
    implements _$$_VersionCopyWith<$Res> {
  __$$_VersionCopyWithImpl(_$_Version _value, $Res Function(_$_Version) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? major = null,
    Object? minor = null,
    Object? patch = null,
  }) {
    return _then(_$_Version(
      null == major
          ? _value.major
          : major // ignore: cast_nullable_to_non_nullable
              as int,
      null == minor
          ? _value.minor
          : minor // ignore: cast_nullable_to_non_nullable
              as int,
      null == patch
          ? _value.patch
          : patch // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class _$_Version extends _Version {
  const _$_Version(this.major, this.minor, this.patch)
      : assert(major >= 0),
        assert(major < 256),
        assert(minor >= 0),
        assert(minor < 256),
        assert(patch >= 0),
        assert(patch < 256),
        super._();

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
            other is _$_Version &&
            (identical(other.major, major) || other.major == major) &&
            (identical(other.minor, minor) || other.minor == minor) &&
            (identical(other.patch, patch) || other.patch == patch));
  }

  @override
  int get hashCode => Object.hash(runtimeType, major, minor, patch);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_VersionCopyWith<_$_Version> get copyWith =>
      __$$_VersionCopyWithImpl<_$_Version>(this, _$identity);
}

abstract class _Version extends Version {
  const factory _Version(final int major, final int minor, final int patch) =
      _$_Version;
  const _Version._() : super._();

  @override
  int get major;
  @override
  int get minor;
  @override
  int get patch;
  @override
  @JsonKey(ignore: true)
  _$$_VersionCopyWith<_$_Version> get copyWith =>
      throw _privateConstructorUsedError;
}

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
      _$PairCopyWithImpl<T1, T2, $Res, Pair<T1, T2>>;
  @useResult
  $Res call({T1 first, T2 second});
}

/// @nodoc
class _$PairCopyWithImpl<T1, T2, $Res, $Val extends Pair<T1, T2>>
    implements $PairCopyWith<T1, T2, $Res> {
  _$PairCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? first = freezed,
    Object? second = freezed,
  }) {
    return _then(_value.copyWith(
      first: freezed == first
          ? _value.first
          : first // ignore: cast_nullable_to_non_nullable
              as T1,
      second: freezed == second
          ? _value.second
          : second // ignore: cast_nullable_to_non_nullable
              as T2,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$_PairCopyWith<T1, T2, $Res>
    implements $PairCopyWith<T1, T2, $Res> {
  factory _$$_PairCopyWith(
          _$_Pair<T1, T2> value, $Res Function(_$_Pair<T1, T2>) then) =
      __$$_PairCopyWithImpl<T1, T2, $Res>;
  @override
  @useResult
  $Res call({T1 first, T2 second});
}

/// @nodoc
class __$$_PairCopyWithImpl<T1, T2, $Res>
    extends _$PairCopyWithImpl<T1, T2, $Res, _$_Pair<T1, T2>>
    implements _$$_PairCopyWith<T1, T2, $Res> {
  __$$_PairCopyWithImpl(
      _$_Pair<T1, T2> _value, $Res Function(_$_Pair<T1, T2>) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? first = freezed,
    Object? second = freezed,
  }) {
    return _then(_$_Pair<T1, T2>(
      freezed == first
          ? _value.first
          : first // ignore: cast_nullable_to_non_nullable
              as T1,
      freezed == second
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
            other is _$_Pair<T1, T2> &&
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
  @pragma('vm:prefer-inline')
  _$$_PairCopyWith<T1, T2, _$_Pair<T1, T2>> get copyWith =>
      __$$_PairCopyWithImpl<T1, T2, _$_Pair<T1, T2>>(this, _$identity);
}

abstract class _Pair<T1, T2> implements Pair<T1, T2> {
  factory _Pair(final T1 first, final T2 second) = _$_Pair<T1, T2>;

  @override
  T1 get first;
  @override
  T2 get second;
  @override
  @JsonKey(ignore: true)
  _$$_PairCopyWith<T1, T2, _$_Pair<T1, T2>> get copyWith =>
      throw _privateConstructorUsedError;
}
