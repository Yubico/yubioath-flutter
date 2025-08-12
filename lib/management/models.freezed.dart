// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DeviceConfig {

 Map<Transport, int> get enabledCapabilities; int? get autoEjectTimeout; int? get challengeResponseTimeout; int? get deviceFlags;
/// Create a copy of DeviceConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeviceConfigCopyWith<DeviceConfig> get copyWith => _$DeviceConfigCopyWithImpl<DeviceConfig>(this as DeviceConfig, _$identity);

  /// Serializes this DeviceConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeviceConfig&&const DeepCollectionEquality().equals(other.enabledCapabilities, enabledCapabilities)&&(identical(other.autoEjectTimeout, autoEjectTimeout) || other.autoEjectTimeout == autoEjectTimeout)&&(identical(other.challengeResponseTimeout, challengeResponseTimeout) || other.challengeResponseTimeout == challengeResponseTimeout)&&(identical(other.deviceFlags, deviceFlags) || other.deviceFlags == deviceFlags));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(enabledCapabilities),autoEjectTimeout,challengeResponseTimeout,deviceFlags);

@override
String toString() {
  return 'DeviceConfig(enabledCapabilities: $enabledCapabilities, autoEjectTimeout: $autoEjectTimeout, challengeResponseTimeout: $challengeResponseTimeout, deviceFlags: $deviceFlags)';
}


}

/// @nodoc
abstract mixin class $DeviceConfigCopyWith<$Res>  {
  factory $DeviceConfigCopyWith(DeviceConfig value, $Res Function(DeviceConfig) _then) = _$DeviceConfigCopyWithImpl;
@useResult
$Res call({
 Map<Transport, int> enabledCapabilities, int? autoEjectTimeout, int? challengeResponseTimeout, int? deviceFlags
});




}
/// @nodoc
class _$DeviceConfigCopyWithImpl<$Res>
    implements $DeviceConfigCopyWith<$Res> {
  _$DeviceConfigCopyWithImpl(this._self, this._then);

  final DeviceConfig _self;
  final $Res Function(DeviceConfig) _then;

/// Create a copy of DeviceConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? enabledCapabilities = null,Object? autoEjectTimeout = freezed,Object? challengeResponseTimeout = freezed,Object? deviceFlags = freezed,}) {
  return _then(_self.copyWith(
enabledCapabilities: null == enabledCapabilities ? _self.enabledCapabilities : enabledCapabilities // ignore: cast_nullable_to_non_nullable
as Map<Transport, int>,autoEjectTimeout: freezed == autoEjectTimeout ? _self.autoEjectTimeout : autoEjectTimeout // ignore: cast_nullable_to_non_nullable
as int?,challengeResponseTimeout: freezed == challengeResponseTimeout ? _self.challengeResponseTimeout : challengeResponseTimeout // ignore: cast_nullable_to_non_nullable
as int?,deviceFlags: freezed == deviceFlags ? _self.deviceFlags : deviceFlags // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [DeviceConfig].
extension DeviceConfigPatterns on DeviceConfig {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DeviceConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DeviceConfig() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DeviceConfig value)  $default,){
final _that = this;
switch (_that) {
case _DeviceConfig():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DeviceConfig value)?  $default,){
final _that = this;
switch (_that) {
case _DeviceConfig() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Map<Transport, int> enabledCapabilities,  int? autoEjectTimeout,  int? challengeResponseTimeout,  int? deviceFlags)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DeviceConfig() when $default != null:
return $default(_that.enabledCapabilities,_that.autoEjectTimeout,_that.challengeResponseTimeout,_that.deviceFlags);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Map<Transport, int> enabledCapabilities,  int? autoEjectTimeout,  int? challengeResponseTimeout,  int? deviceFlags)  $default,) {final _that = this;
switch (_that) {
case _DeviceConfig():
return $default(_that.enabledCapabilities,_that.autoEjectTimeout,_that.challengeResponseTimeout,_that.deviceFlags);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Map<Transport, int> enabledCapabilities,  int? autoEjectTimeout,  int? challengeResponseTimeout,  int? deviceFlags)?  $default,) {final _that = this;
switch (_that) {
case _DeviceConfig() when $default != null:
return $default(_that.enabledCapabilities,_that.autoEjectTimeout,_that.challengeResponseTimeout,_that.deviceFlags);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DeviceConfig implements DeviceConfig {
   _DeviceConfig(final  Map<Transport, int> enabledCapabilities, this.autoEjectTimeout, this.challengeResponseTimeout, this.deviceFlags): _enabledCapabilities = enabledCapabilities;
  factory _DeviceConfig.fromJson(Map<String, dynamic> json) => _$DeviceConfigFromJson(json);

 final  Map<Transport, int> _enabledCapabilities;
@override Map<Transport, int> get enabledCapabilities {
  if (_enabledCapabilities is EqualUnmodifiableMapView) return _enabledCapabilities;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_enabledCapabilities);
}

@override final  int? autoEjectTimeout;
@override final  int? challengeResponseTimeout;
@override final  int? deviceFlags;

/// Create a copy of DeviceConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeviceConfigCopyWith<_DeviceConfig> get copyWith => __$DeviceConfigCopyWithImpl<_DeviceConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DeviceConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeviceConfig&&const DeepCollectionEquality().equals(other._enabledCapabilities, _enabledCapabilities)&&(identical(other.autoEjectTimeout, autoEjectTimeout) || other.autoEjectTimeout == autoEjectTimeout)&&(identical(other.challengeResponseTimeout, challengeResponseTimeout) || other.challengeResponseTimeout == challengeResponseTimeout)&&(identical(other.deviceFlags, deviceFlags) || other.deviceFlags == deviceFlags));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_enabledCapabilities),autoEjectTimeout,challengeResponseTimeout,deviceFlags);

@override
String toString() {
  return 'DeviceConfig(enabledCapabilities: $enabledCapabilities, autoEjectTimeout: $autoEjectTimeout, challengeResponseTimeout: $challengeResponseTimeout, deviceFlags: $deviceFlags)';
}


}

/// @nodoc
abstract mixin class _$DeviceConfigCopyWith<$Res> implements $DeviceConfigCopyWith<$Res> {
  factory _$DeviceConfigCopyWith(_DeviceConfig value, $Res Function(_DeviceConfig) _then) = __$DeviceConfigCopyWithImpl;
@override @useResult
$Res call({
 Map<Transport, int> enabledCapabilities, int? autoEjectTimeout, int? challengeResponseTimeout, int? deviceFlags
});




}
/// @nodoc
class __$DeviceConfigCopyWithImpl<$Res>
    implements _$DeviceConfigCopyWith<$Res> {
  __$DeviceConfigCopyWithImpl(this._self, this._then);

  final _DeviceConfig _self;
  final $Res Function(_DeviceConfig) _then;

/// Create a copy of DeviceConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? enabledCapabilities = null,Object? autoEjectTimeout = freezed,Object? challengeResponseTimeout = freezed,Object? deviceFlags = freezed,}) {
  return _then(_DeviceConfig(
null == enabledCapabilities ? _self._enabledCapabilities : enabledCapabilities // ignore: cast_nullable_to_non_nullable
as Map<Transport, int>,freezed == autoEjectTimeout ? _self.autoEjectTimeout : autoEjectTimeout // ignore: cast_nullable_to_non_nullable
as int?,freezed == challengeResponseTimeout ? _self.challengeResponseTimeout : challengeResponseTimeout // ignore: cast_nullable_to_non_nullable
as int?,freezed == deviceFlags ? _self.deviceFlags : deviceFlags // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$VersionQualifier {

 Version get version; ReleaseType get type; int get iteration;
/// Create a copy of VersionQualifier
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VersionQualifierCopyWith<VersionQualifier> get copyWith => _$VersionQualifierCopyWithImpl<VersionQualifier>(this as VersionQualifier, _$identity);

  /// Serializes this VersionQualifier to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VersionQualifier&&(identical(other.version, version) || other.version == version)&&(identical(other.type, type) || other.type == type)&&(identical(other.iteration, iteration) || other.iteration == iteration));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,version,type,iteration);



}

/// @nodoc
abstract mixin class $VersionQualifierCopyWith<$Res>  {
  factory $VersionQualifierCopyWith(VersionQualifier value, $Res Function(VersionQualifier) _then) = _$VersionQualifierCopyWithImpl;
@useResult
$Res call({
 Version version, ReleaseType type, int iteration
});


$VersionCopyWith<$Res> get version;

}
/// @nodoc
class _$VersionQualifierCopyWithImpl<$Res>
    implements $VersionQualifierCopyWith<$Res> {
  _$VersionQualifierCopyWithImpl(this._self, this._then);

  final VersionQualifier _self;
  final $Res Function(VersionQualifier) _then;

/// Create a copy of VersionQualifier
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? version = null,Object? type = null,Object? iteration = null,}) {
  return _then(_self.copyWith(
version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as Version,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ReleaseType,iteration: null == iteration ? _self.iteration : iteration // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of VersionQualifier
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VersionCopyWith<$Res> get version {
  
  return $VersionCopyWith<$Res>(_self.version, (value) {
    return _then(_self.copyWith(version: value));
  });
}
}


/// Adds pattern-matching-related methods to [VersionQualifier].
extension VersionQualifierPatterns on VersionQualifier {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VersionQualifier value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VersionQualifier() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VersionQualifier value)  $default,){
final _that = this;
switch (_that) {
case _VersionQualifier():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VersionQualifier value)?  $default,){
final _that = this;
switch (_that) {
case _VersionQualifier() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Version version,  ReleaseType type,  int iteration)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VersionQualifier() when $default != null:
return $default(_that.version,_that.type,_that.iteration);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Version version,  ReleaseType type,  int iteration)  $default,) {final _that = this;
switch (_that) {
case _VersionQualifier():
return $default(_that.version,_that.type,_that.iteration);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Version version,  ReleaseType type,  int iteration)?  $default,) {final _that = this;
switch (_that) {
case _VersionQualifier() when $default != null:
return $default(_that.version,_that.type,_that.iteration);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VersionQualifier extends VersionQualifier {
   _VersionQualifier(this.version, this.type, this.iteration): super._();
  factory _VersionQualifier.fromJson(Map<String, dynamic> json) => _$VersionQualifierFromJson(json);

@override final  Version version;
@override final  ReleaseType type;
@override final  int iteration;

/// Create a copy of VersionQualifier
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VersionQualifierCopyWith<_VersionQualifier> get copyWith => __$VersionQualifierCopyWithImpl<_VersionQualifier>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VersionQualifierToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VersionQualifier&&(identical(other.version, version) || other.version == version)&&(identical(other.type, type) || other.type == type)&&(identical(other.iteration, iteration) || other.iteration == iteration));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,version,type,iteration);



}

/// @nodoc
abstract mixin class _$VersionQualifierCopyWith<$Res> implements $VersionQualifierCopyWith<$Res> {
  factory _$VersionQualifierCopyWith(_VersionQualifier value, $Res Function(_VersionQualifier) _then) = __$VersionQualifierCopyWithImpl;
@override @useResult
$Res call({
 Version version, ReleaseType type, int iteration
});


@override $VersionCopyWith<$Res> get version;

}
/// @nodoc
class __$VersionQualifierCopyWithImpl<$Res>
    implements _$VersionQualifierCopyWith<$Res> {
  __$VersionQualifierCopyWithImpl(this._self, this._then);

  final _VersionQualifier _self;
  final $Res Function(_VersionQualifier) _then;

/// Create a copy of VersionQualifier
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? version = null,Object? type = null,Object? iteration = null,}) {
  return _then(_VersionQualifier(
null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as Version,null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ReleaseType,null == iteration ? _self.iteration : iteration // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of VersionQualifier
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VersionCopyWith<$Res> get version {
  
  return $VersionCopyWith<$Res>(_self.version, (value) {
    return _then(_self.copyWith(version: value));
  });
}
}


/// @nodoc
mixin _$DeviceInfo {

 DeviceConfig get config; int? get serial; Version get version; FormFactor get formFactor; Map<Transport, int> get supportedCapabilities; bool get isLocked; bool get isFips; bool get isSky; bool get pinComplexity; int get fipsCapable; int get fipsApproved; int get resetBlocked; VersionQualifier get versionQualifier;
/// Create a copy of DeviceInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeviceInfoCopyWith<DeviceInfo> get copyWith => _$DeviceInfoCopyWithImpl<DeviceInfo>(this as DeviceInfo, _$identity);

  /// Serializes this DeviceInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeviceInfo&&(identical(other.config, config) || other.config == config)&&(identical(other.serial, serial) || other.serial == serial)&&(identical(other.version, version) || other.version == version)&&(identical(other.formFactor, formFactor) || other.formFactor == formFactor)&&const DeepCollectionEquality().equals(other.supportedCapabilities, supportedCapabilities)&&(identical(other.isLocked, isLocked) || other.isLocked == isLocked)&&(identical(other.isFips, isFips) || other.isFips == isFips)&&(identical(other.isSky, isSky) || other.isSky == isSky)&&(identical(other.pinComplexity, pinComplexity) || other.pinComplexity == pinComplexity)&&(identical(other.fipsCapable, fipsCapable) || other.fipsCapable == fipsCapable)&&(identical(other.fipsApproved, fipsApproved) || other.fipsApproved == fipsApproved)&&(identical(other.resetBlocked, resetBlocked) || other.resetBlocked == resetBlocked)&&(identical(other.versionQualifier, versionQualifier) || other.versionQualifier == versionQualifier));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,config,serial,version,formFactor,const DeepCollectionEquality().hash(supportedCapabilities),isLocked,isFips,isSky,pinComplexity,fipsCapable,fipsApproved,resetBlocked,versionQualifier);

@override
String toString() {
  return 'DeviceInfo(config: $config, serial: $serial, version: $version, formFactor: $formFactor, supportedCapabilities: $supportedCapabilities, isLocked: $isLocked, isFips: $isFips, isSky: $isSky, pinComplexity: $pinComplexity, fipsCapable: $fipsCapable, fipsApproved: $fipsApproved, resetBlocked: $resetBlocked, versionQualifier: $versionQualifier)';
}


}

/// @nodoc
abstract mixin class $DeviceInfoCopyWith<$Res>  {
  factory $DeviceInfoCopyWith(DeviceInfo value, $Res Function(DeviceInfo) _then) = _$DeviceInfoCopyWithImpl;
@useResult
$Res call({
 DeviceConfig config, int? serial, Version version, FormFactor formFactor, Map<Transport, int> supportedCapabilities, bool isLocked, bool isFips, bool isSky, bool pinComplexity, int fipsCapable, int fipsApproved, int resetBlocked, VersionQualifier versionQualifier
});


$DeviceConfigCopyWith<$Res> get config;$VersionCopyWith<$Res> get version;$VersionQualifierCopyWith<$Res> get versionQualifier;

}
/// @nodoc
class _$DeviceInfoCopyWithImpl<$Res>
    implements $DeviceInfoCopyWith<$Res> {
  _$DeviceInfoCopyWithImpl(this._self, this._then);

  final DeviceInfo _self;
  final $Res Function(DeviceInfo) _then;

/// Create a copy of DeviceInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? config = null,Object? serial = freezed,Object? version = null,Object? formFactor = null,Object? supportedCapabilities = null,Object? isLocked = null,Object? isFips = null,Object? isSky = null,Object? pinComplexity = null,Object? fipsCapable = null,Object? fipsApproved = null,Object? resetBlocked = null,Object? versionQualifier = null,}) {
  return _then(_self.copyWith(
config: null == config ? _self.config : config // ignore: cast_nullable_to_non_nullable
as DeviceConfig,serial: freezed == serial ? _self.serial : serial // ignore: cast_nullable_to_non_nullable
as int?,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as Version,formFactor: null == formFactor ? _self.formFactor : formFactor // ignore: cast_nullable_to_non_nullable
as FormFactor,supportedCapabilities: null == supportedCapabilities ? _self.supportedCapabilities : supportedCapabilities // ignore: cast_nullable_to_non_nullable
as Map<Transport, int>,isLocked: null == isLocked ? _self.isLocked : isLocked // ignore: cast_nullable_to_non_nullable
as bool,isFips: null == isFips ? _self.isFips : isFips // ignore: cast_nullable_to_non_nullable
as bool,isSky: null == isSky ? _self.isSky : isSky // ignore: cast_nullable_to_non_nullable
as bool,pinComplexity: null == pinComplexity ? _self.pinComplexity : pinComplexity // ignore: cast_nullable_to_non_nullable
as bool,fipsCapable: null == fipsCapable ? _self.fipsCapable : fipsCapable // ignore: cast_nullable_to_non_nullable
as int,fipsApproved: null == fipsApproved ? _self.fipsApproved : fipsApproved // ignore: cast_nullable_to_non_nullable
as int,resetBlocked: null == resetBlocked ? _self.resetBlocked : resetBlocked // ignore: cast_nullable_to_non_nullable
as int,versionQualifier: null == versionQualifier ? _self.versionQualifier : versionQualifier // ignore: cast_nullable_to_non_nullable
as VersionQualifier,
  ));
}
/// Create a copy of DeviceInfo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DeviceConfigCopyWith<$Res> get config {
  
  return $DeviceConfigCopyWith<$Res>(_self.config, (value) {
    return _then(_self.copyWith(config: value));
  });
}/// Create a copy of DeviceInfo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VersionCopyWith<$Res> get version {
  
  return $VersionCopyWith<$Res>(_self.version, (value) {
    return _then(_self.copyWith(version: value));
  });
}/// Create a copy of DeviceInfo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VersionQualifierCopyWith<$Res> get versionQualifier {
  
  return $VersionQualifierCopyWith<$Res>(_self.versionQualifier, (value) {
    return _then(_self.copyWith(versionQualifier: value));
  });
}
}


/// Adds pattern-matching-related methods to [DeviceInfo].
extension DeviceInfoPatterns on DeviceInfo {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DeviceInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DeviceInfo() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DeviceInfo value)  $default,){
final _that = this;
switch (_that) {
case _DeviceInfo():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DeviceInfo value)?  $default,){
final _that = this;
switch (_that) {
case _DeviceInfo() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DeviceConfig config,  int? serial,  Version version,  FormFactor formFactor,  Map<Transport, int> supportedCapabilities,  bool isLocked,  bool isFips,  bool isSky,  bool pinComplexity,  int fipsCapable,  int fipsApproved,  int resetBlocked,  VersionQualifier versionQualifier)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DeviceInfo() when $default != null:
return $default(_that.config,_that.serial,_that.version,_that.formFactor,_that.supportedCapabilities,_that.isLocked,_that.isFips,_that.isSky,_that.pinComplexity,_that.fipsCapable,_that.fipsApproved,_that.resetBlocked,_that.versionQualifier);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DeviceConfig config,  int? serial,  Version version,  FormFactor formFactor,  Map<Transport, int> supportedCapabilities,  bool isLocked,  bool isFips,  bool isSky,  bool pinComplexity,  int fipsCapable,  int fipsApproved,  int resetBlocked,  VersionQualifier versionQualifier)  $default,) {final _that = this;
switch (_that) {
case _DeviceInfo():
return $default(_that.config,_that.serial,_that.version,_that.formFactor,_that.supportedCapabilities,_that.isLocked,_that.isFips,_that.isSky,_that.pinComplexity,_that.fipsCapable,_that.fipsApproved,_that.resetBlocked,_that.versionQualifier);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DeviceConfig config,  int? serial,  Version version,  FormFactor formFactor,  Map<Transport, int> supportedCapabilities,  bool isLocked,  bool isFips,  bool isSky,  bool pinComplexity,  int fipsCapable,  int fipsApproved,  int resetBlocked,  VersionQualifier versionQualifier)?  $default,) {final _that = this;
switch (_that) {
case _DeviceInfo() when $default != null:
return $default(_that.config,_that.serial,_that.version,_that.formFactor,_that.supportedCapabilities,_that.isLocked,_that.isFips,_that.isSky,_that.pinComplexity,_that.fipsCapable,_that.fipsApproved,_that.resetBlocked,_that.versionQualifier);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DeviceInfo extends DeviceInfo {
   _DeviceInfo(this.config, this.serial, this.version, this.formFactor, final  Map<Transport, int> supportedCapabilities, this.isLocked, this.isFips, this.isSky, this.pinComplexity, this.fipsCapable, this.fipsApproved, this.resetBlocked, this.versionQualifier): _supportedCapabilities = supportedCapabilities,super._();
  factory _DeviceInfo.fromJson(Map<String, dynamic> json) => _$DeviceInfoFromJson(json);

@override final  DeviceConfig config;
@override final  int? serial;
@override final  Version version;
@override final  FormFactor formFactor;
 final  Map<Transport, int> _supportedCapabilities;
@override Map<Transport, int> get supportedCapabilities {
  if (_supportedCapabilities is EqualUnmodifiableMapView) return _supportedCapabilities;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_supportedCapabilities);
}

@override final  bool isLocked;
@override final  bool isFips;
@override final  bool isSky;
@override final  bool pinComplexity;
@override final  int fipsCapable;
@override final  int fipsApproved;
@override final  int resetBlocked;
@override final  VersionQualifier versionQualifier;

/// Create a copy of DeviceInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeviceInfoCopyWith<_DeviceInfo> get copyWith => __$DeviceInfoCopyWithImpl<_DeviceInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DeviceInfoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeviceInfo&&(identical(other.config, config) || other.config == config)&&(identical(other.serial, serial) || other.serial == serial)&&(identical(other.version, version) || other.version == version)&&(identical(other.formFactor, formFactor) || other.formFactor == formFactor)&&const DeepCollectionEquality().equals(other._supportedCapabilities, _supportedCapabilities)&&(identical(other.isLocked, isLocked) || other.isLocked == isLocked)&&(identical(other.isFips, isFips) || other.isFips == isFips)&&(identical(other.isSky, isSky) || other.isSky == isSky)&&(identical(other.pinComplexity, pinComplexity) || other.pinComplexity == pinComplexity)&&(identical(other.fipsCapable, fipsCapable) || other.fipsCapable == fipsCapable)&&(identical(other.fipsApproved, fipsApproved) || other.fipsApproved == fipsApproved)&&(identical(other.resetBlocked, resetBlocked) || other.resetBlocked == resetBlocked)&&(identical(other.versionQualifier, versionQualifier) || other.versionQualifier == versionQualifier));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,config,serial,version,formFactor,const DeepCollectionEquality().hash(_supportedCapabilities),isLocked,isFips,isSky,pinComplexity,fipsCapable,fipsApproved,resetBlocked,versionQualifier);

@override
String toString() {
  return 'DeviceInfo(config: $config, serial: $serial, version: $version, formFactor: $formFactor, supportedCapabilities: $supportedCapabilities, isLocked: $isLocked, isFips: $isFips, isSky: $isSky, pinComplexity: $pinComplexity, fipsCapable: $fipsCapable, fipsApproved: $fipsApproved, resetBlocked: $resetBlocked, versionQualifier: $versionQualifier)';
}


}

/// @nodoc
abstract mixin class _$DeviceInfoCopyWith<$Res> implements $DeviceInfoCopyWith<$Res> {
  factory _$DeviceInfoCopyWith(_DeviceInfo value, $Res Function(_DeviceInfo) _then) = __$DeviceInfoCopyWithImpl;
@override @useResult
$Res call({
 DeviceConfig config, int? serial, Version version, FormFactor formFactor, Map<Transport, int> supportedCapabilities, bool isLocked, bool isFips, bool isSky, bool pinComplexity, int fipsCapable, int fipsApproved, int resetBlocked, VersionQualifier versionQualifier
});


@override $DeviceConfigCopyWith<$Res> get config;@override $VersionCopyWith<$Res> get version;@override $VersionQualifierCopyWith<$Res> get versionQualifier;

}
/// @nodoc
class __$DeviceInfoCopyWithImpl<$Res>
    implements _$DeviceInfoCopyWith<$Res> {
  __$DeviceInfoCopyWithImpl(this._self, this._then);

  final _DeviceInfo _self;
  final $Res Function(_DeviceInfo) _then;

/// Create a copy of DeviceInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? config = null,Object? serial = freezed,Object? version = null,Object? formFactor = null,Object? supportedCapabilities = null,Object? isLocked = null,Object? isFips = null,Object? isSky = null,Object? pinComplexity = null,Object? fipsCapable = null,Object? fipsApproved = null,Object? resetBlocked = null,Object? versionQualifier = null,}) {
  return _then(_DeviceInfo(
null == config ? _self.config : config // ignore: cast_nullable_to_non_nullable
as DeviceConfig,freezed == serial ? _self.serial : serial // ignore: cast_nullable_to_non_nullable
as int?,null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as Version,null == formFactor ? _self.formFactor : formFactor // ignore: cast_nullable_to_non_nullable
as FormFactor,null == supportedCapabilities ? _self._supportedCapabilities : supportedCapabilities // ignore: cast_nullable_to_non_nullable
as Map<Transport, int>,null == isLocked ? _self.isLocked : isLocked // ignore: cast_nullable_to_non_nullable
as bool,null == isFips ? _self.isFips : isFips // ignore: cast_nullable_to_non_nullable
as bool,null == isSky ? _self.isSky : isSky // ignore: cast_nullable_to_non_nullable
as bool,null == pinComplexity ? _self.pinComplexity : pinComplexity // ignore: cast_nullable_to_non_nullable
as bool,null == fipsCapable ? _self.fipsCapable : fipsCapable // ignore: cast_nullable_to_non_nullable
as int,null == fipsApproved ? _self.fipsApproved : fipsApproved // ignore: cast_nullable_to_non_nullable
as int,null == resetBlocked ? _self.resetBlocked : resetBlocked // ignore: cast_nullable_to_non_nullable
as int,null == versionQualifier ? _self.versionQualifier : versionQualifier // ignore: cast_nullable_to_non_nullable
as VersionQualifier,
  ));
}

/// Create a copy of DeviceInfo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DeviceConfigCopyWith<$Res> get config {
  
  return $DeviceConfigCopyWith<$Res>(_self.config, (value) {
    return _then(_self.copyWith(config: value));
  });
}/// Create a copy of DeviceInfo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VersionCopyWith<$Res> get version {
  
  return $VersionCopyWith<$Res>(_self.version, (value) {
    return _then(_self.copyWith(version: value));
  });
}/// Create a copy of DeviceInfo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VersionQualifierCopyWith<$Res> get versionQualifier {
  
  return $VersionQualifierCopyWith<$Res>(_self.versionQualifier, (value) {
    return _then(_self.copyWith(versionQualifier: value));
  });
}
}

// dart format on
