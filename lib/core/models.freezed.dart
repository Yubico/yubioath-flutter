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
mixin _$Version {

 int get major; int get minor; int get patch;
/// Create a copy of Version
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VersionCopyWith<Version> get copyWith => _$VersionCopyWithImpl<Version>(this as Version, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Version&&(identical(other.major, major) || other.major == major)&&(identical(other.minor, minor) || other.minor == minor)&&(identical(other.patch, patch) || other.patch == patch));
}


@override
int get hashCode => Object.hash(runtimeType,major,minor,patch);



}

/// @nodoc
abstract mixin class $VersionCopyWith<$Res>  {
  factory $VersionCopyWith(Version value, $Res Function(Version) _then) = _$VersionCopyWithImpl;
@useResult
$Res call({
 int major, int minor, int patch
});




}
/// @nodoc
class _$VersionCopyWithImpl<$Res>
    implements $VersionCopyWith<$Res> {
  _$VersionCopyWithImpl(this._self, this._then);

  final Version _self;
  final $Res Function(Version) _then;

/// Create a copy of Version
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? major = null,Object? minor = null,Object? patch = null,}) {
  return _then(_self.copyWith(
major: null == major ? _self.major : major // ignore: cast_nullable_to_non_nullable
as int,minor: null == minor ? _self.minor : minor // ignore: cast_nullable_to_non_nullable
as int,patch: null == patch ? _self.patch : patch // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// @nodoc


class _Version extends Version {
  const _Version(this.major, this.minor, this.patch): assert(major >= 0),assert(major < 256),assert(minor >= 0),assert(minor < 256),assert(patch >= 0),assert(patch < 256),super._();
  

@override final  int major;
@override final  int minor;
@override final  int patch;

/// Create a copy of Version
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VersionCopyWith<_Version> get copyWith => __$VersionCopyWithImpl<_Version>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Version&&(identical(other.major, major) || other.major == major)&&(identical(other.minor, minor) || other.minor == minor)&&(identical(other.patch, patch) || other.patch == patch));
}


@override
int get hashCode => Object.hash(runtimeType,major,minor,patch);



}

/// @nodoc
abstract mixin class _$VersionCopyWith<$Res> implements $VersionCopyWith<$Res> {
  factory _$VersionCopyWith(_Version value, $Res Function(_Version) _then) = __$VersionCopyWithImpl;
@override @useResult
$Res call({
 int major, int minor, int patch
});




}
/// @nodoc
class __$VersionCopyWithImpl<$Res>
    implements _$VersionCopyWith<$Res> {
  __$VersionCopyWithImpl(this._self, this._then);

  final _Version _self;
  final $Res Function(_Version) _then;

/// Create a copy of Version
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? major = null,Object? minor = null,Object? patch = null,}) {
  return _then(_Version(
null == major ? _self.major : major // ignore: cast_nullable_to_non_nullable
as int,null == minor ? _self.minor : minor // ignore: cast_nullable_to_non_nullable
as int,null == patch ? _self.patch : patch // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
