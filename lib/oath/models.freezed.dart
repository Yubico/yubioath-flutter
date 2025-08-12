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
mixin _$OathCredential {

 String get deviceId; String get id;@_IssuerConverter() String? get issuer; String get name; OathType get oathType; int get period; bool get touchRequired;
/// Create a copy of OathCredential
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OathCredentialCopyWith<OathCredential> get copyWith => _$OathCredentialCopyWithImpl<OathCredential>(this as OathCredential, _$identity);

  /// Serializes this OathCredential to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OathCredential&&(identical(other.deviceId, deviceId) || other.deviceId == deviceId)&&(identical(other.id, id) || other.id == id)&&(identical(other.issuer, issuer) || other.issuer == issuer)&&(identical(other.name, name) || other.name == name)&&(identical(other.oathType, oathType) || other.oathType == oathType)&&(identical(other.period, period) || other.period == period)&&(identical(other.touchRequired, touchRequired) || other.touchRequired == touchRequired));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,deviceId,id,issuer,name,oathType,period,touchRequired);

@override
String toString() {
  return 'OathCredential(deviceId: $deviceId, id: $id, issuer: $issuer, name: $name, oathType: $oathType, period: $period, touchRequired: $touchRequired)';
}


}

/// @nodoc
abstract mixin class $OathCredentialCopyWith<$Res>  {
  factory $OathCredentialCopyWith(OathCredential value, $Res Function(OathCredential) _then) = _$OathCredentialCopyWithImpl;
@useResult
$Res call({
 String deviceId, String id,@_IssuerConverter() String? issuer, String name, OathType oathType, int period, bool touchRequired
});




}
/// @nodoc
class _$OathCredentialCopyWithImpl<$Res>
    implements $OathCredentialCopyWith<$Res> {
  _$OathCredentialCopyWithImpl(this._self, this._then);

  final OathCredential _self;
  final $Res Function(OathCredential) _then;

/// Create a copy of OathCredential
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? deviceId = null,Object? id = null,Object? issuer = freezed,Object? name = null,Object? oathType = null,Object? period = null,Object? touchRequired = null,}) {
  return _then(_self.copyWith(
deviceId: null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as String,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,issuer: freezed == issuer ? _self.issuer : issuer // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,oathType: null == oathType ? _self.oathType : oathType // ignore: cast_nullable_to_non_nullable
as OathType,period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as int,touchRequired: null == touchRequired ? _self.touchRequired : touchRequired // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [OathCredential].
extension OathCredentialPatterns on OathCredential {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OathCredential value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OathCredential() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OathCredential value)  $default,){
final _that = this;
switch (_that) {
case _OathCredential():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OathCredential value)?  $default,){
final _that = this;
switch (_that) {
case _OathCredential() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String deviceId,  String id, @_IssuerConverter()  String? issuer,  String name,  OathType oathType,  int period,  bool touchRequired)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OathCredential() when $default != null:
return $default(_that.deviceId,_that.id,_that.issuer,_that.name,_that.oathType,_that.period,_that.touchRequired);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String deviceId,  String id, @_IssuerConverter()  String? issuer,  String name,  OathType oathType,  int period,  bool touchRequired)  $default,) {final _that = this;
switch (_that) {
case _OathCredential():
return $default(_that.deviceId,_that.id,_that.issuer,_that.name,_that.oathType,_that.period,_that.touchRequired);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String deviceId,  String id, @_IssuerConverter()  String? issuer,  String name,  OathType oathType,  int period,  bool touchRequired)?  $default,) {final _that = this;
switch (_that) {
case _OathCredential() when $default != null:
return $default(_that.deviceId,_that.id,_that.issuer,_that.name,_that.oathType,_that.period,_that.touchRequired);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OathCredential implements OathCredential {
   _OathCredential(this.deviceId, this.id, @_IssuerConverter() this.issuer, this.name, this.oathType, this.period, this.touchRequired);
  factory _OathCredential.fromJson(Map<String, dynamic> json) => _$OathCredentialFromJson(json);

@override final  String deviceId;
@override final  String id;
@override@_IssuerConverter() final  String? issuer;
@override final  String name;
@override final  OathType oathType;
@override final  int period;
@override final  bool touchRequired;

/// Create a copy of OathCredential
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OathCredentialCopyWith<_OathCredential> get copyWith => __$OathCredentialCopyWithImpl<_OathCredential>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OathCredentialToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OathCredential&&(identical(other.deviceId, deviceId) || other.deviceId == deviceId)&&(identical(other.id, id) || other.id == id)&&(identical(other.issuer, issuer) || other.issuer == issuer)&&(identical(other.name, name) || other.name == name)&&(identical(other.oathType, oathType) || other.oathType == oathType)&&(identical(other.period, period) || other.period == period)&&(identical(other.touchRequired, touchRequired) || other.touchRequired == touchRequired));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,deviceId,id,issuer,name,oathType,period,touchRequired);

@override
String toString() {
  return 'OathCredential(deviceId: $deviceId, id: $id, issuer: $issuer, name: $name, oathType: $oathType, period: $period, touchRequired: $touchRequired)';
}


}

/// @nodoc
abstract mixin class _$OathCredentialCopyWith<$Res> implements $OathCredentialCopyWith<$Res> {
  factory _$OathCredentialCopyWith(_OathCredential value, $Res Function(_OathCredential) _then) = __$OathCredentialCopyWithImpl;
@override @useResult
$Res call({
 String deviceId, String id,@_IssuerConverter() String? issuer, String name, OathType oathType, int period, bool touchRequired
});




}
/// @nodoc
class __$OathCredentialCopyWithImpl<$Res>
    implements _$OathCredentialCopyWith<$Res> {
  __$OathCredentialCopyWithImpl(this._self, this._then);

  final _OathCredential _self;
  final $Res Function(_OathCredential) _then;

/// Create a copy of OathCredential
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? deviceId = null,Object? id = null,Object? issuer = freezed,Object? name = null,Object? oathType = null,Object? period = null,Object? touchRequired = null,}) {
  return _then(_OathCredential(
null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as String,null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,freezed == issuer ? _self.issuer : issuer // ignore: cast_nullable_to_non_nullable
as String?,null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,null == oathType ? _self.oathType : oathType // ignore: cast_nullable_to_non_nullable
as OathType,null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as int,null == touchRequired ? _self.touchRequired : touchRequired // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$OathCode {

 String get value; int get validFrom; int get validTo;
/// Create a copy of OathCode
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OathCodeCopyWith<OathCode> get copyWith => _$OathCodeCopyWithImpl<OathCode>(this as OathCode, _$identity);

  /// Serializes this OathCode to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OathCode&&(identical(other.value, value) || other.value == value)&&(identical(other.validFrom, validFrom) || other.validFrom == validFrom)&&(identical(other.validTo, validTo) || other.validTo == validTo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,value,validFrom,validTo);

@override
String toString() {
  return 'OathCode(value: $value, validFrom: $validFrom, validTo: $validTo)';
}


}

/// @nodoc
abstract mixin class $OathCodeCopyWith<$Res>  {
  factory $OathCodeCopyWith(OathCode value, $Res Function(OathCode) _then) = _$OathCodeCopyWithImpl;
@useResult
$Res call({
 String value, int validFrom, int validTo
});




}
/// @nodoc
class _$OathCodeCopyWithImpl<$Res>
    implements $OathCodeCopyWith<$Res> {
  _$OathCodeCopyWithImpl(this._self, this._then);

  final OathCode _self;
  final $Res Function(OathCode) _then;

/// Create a copy of OathCode
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? value = null,Object? validFrom = null,Object? validTo = null,}) {
  return _then(_self.copyWith(
value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,validFrom: null == validFrom ? _self.validFrom : validFrom // ignore: cast_nullable_to_non_nullable
as int,validTo: null == validTo ? _self.validTo : validTo // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [OathCode].
extension OathCodePatterns on OathCode {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OathCode value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OathCode() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OathCode value)  $default,){
final _that = this;
switch (_that) {
case _OathCode():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OathCode value)?  $default,){
final _that = this;
switch (_that) {
case _OathCode() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String value,  int validFrom,  int validTo)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OathCode() when $default != null:
return $default(_that.value,_that.validFrom,_that.validTo);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String value,  int validFrom,  int validTo)  $default,) {final _that = this;
switch (_that) {
case _OathCode():
return $default(_that.value,_that.validFrom,_that.validTo);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String value,  int validFrom,  int validTo)?  $default,) {final _that = this;
switch (_that) {
case _OathCode() when $default != null:
return $default(_that.value,_that.validFrom,_that.validTo);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OathCode implements OathCode {
   _OathCode(this.value, this.validFrom, this.validTo);
  factory _OathCode.fromJson(Map<String, dynamic> json) => _$OathCodeFromJson(json);

@override final  String value;
@override final  int validFrom;
@override final  int validTo;

/// Create a copy of OathCode
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OathCodeCopyWith<_OathCode> get copyWith => __$OathCodeCopyWithImpl<_OathCode>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OathCodeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OathCode&&(identical(other.value, value) || other.value == value)&&(identical(other.validFrom, validFrom) || other.validFrom == validFrom)&&(identical(other.validTo, validTo) || other.validTo == validTo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,value,validFrom,validTo);

@override
String toString() {
  return 'OathCode(value: $value, validFrom: $validFrom, validTo: $validTo)';
}


}

/// @nodoc
abstract mixin class _$OathCodeCopyWith<$Res> implements $OathCodeCopyWith<$Res> {
  factory _$OathCodeCopyWith(_OathCode value, $Res Function(_OathCode) _then) = __$OathCodeCopyWithImpl;
@override @useResult
$Res call({
 String value, int validFrom, int validTo
});




}
/// @nodoc
class __$OathCodeCopyWithImpl<$Res>
    implements _$OathCodeCopyWith<$Res> {
  __$OathCodeCopyWithImpl(this._self, this._then);

  final _OathCode _self;
  final $Res Function(_OathCode) _then;

/// Create a copy of OathCode
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? value = null,Object? validFrom = null,Object? validTo = null,}) {
  return _then(_OathCode(
null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,null == validFrom ? _self.validFrom : validFrom // ignore: cast_nullable_to_non_nullable
as int,null == validTo ? _self.validTo : validTo // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$OathPair {

 OathCredential get credential; OathCode? get code;
/// Create a copy of OathPair
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OathPairCopyWith<OathPair> get copyWith => _$OathPairCopyWithImpl<OathPair>(this as OathPair, _$identity);

  /// Serializes this OathPair to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OathPair&&(identical(other.credential, credential) || other.credential == credential)&&(identical(other.code, code) || other.code == code));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,credential,code);

@override
String toString() {
  return 'OathPair(credential: $credential, code: $code)';
}


}

/// @nodoc
abstract mixin class $OathPairCopyWith<$Res>  {
  factory $OathPairCopyWith(OathPair value, $Res Function(OathPair) _then) = _$OathPairCopyWithImpl;
@useResult
$Res call({
 OathCredential credential, OathCode? code
});


$OathCredentialCopyWith<$Res> get credential;$OathCodeCopyWith<$Res>? get code;

}
/// @nodoc
class _$OathPairCopyWithImpl<$Res>
    implements $OathPairCopyWith<$Res> {
  _$OathPairCopyWithImpl(this._self, this._then);

  final OathPair _self;
  final $Res Function(OathPair) _then;

/// Create a copy of OathPair
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? credential = null,Object? code = freezed,}) {
  return _then(_self.copyWith(
credential: null == credential ? _self.credential : credential // ignore: cast_nullable_to_non_nullable
as OathCredential,code: freezed == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as OathCode?,
  ));
}
/// Create a copy of OathPair
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OathCredentialCopyWith<$Res> get credential {
  
  return $OathCredentialCopyWith<$Res>(_self.credential, (value) {
    return _then(_self.copyWith(credential: value));
  });
}/// Create a copy of OathPair
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OathCodeCopyWith<$Res>? get code {
    if (_self.code == null) {
    return null;
  }

  return $OathCodeCopyWith<$Res>(_self.code!, (value) {
    return _then(_self.copyWith(code: value));
  });
}
}


/// Adds pattern-matching-related methods to [OathPair].
extension OathPairPatterns on OathPair {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OathPair value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OathPair() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OathPair value)  $default,){
final _that = this;
switch (_that) {
case _OathPair():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OathPair value)?  $default,){
final _that = this;
switch (_that) {
case _OathPair() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( OathCredential credential,  OathCode? code)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OathPair() when $default != null:
return $default(_that.credential,_that.code);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( OathCredential credential,  OathCode? code)  $default,) {final _that = this;
switch (_that) {
case _OathPair():
return $default(_that.credential,_that.code);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( OathCredential credential,  OathCode? code)?  $default,) {final _that = this;
switch (_that) {
case _OathPair() when $default != null:
return $default(_that.credential,_that.code);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OathPair implements OathPair {
   _OathPair(this.credential, this.code);
  factory _OathPair.fromJson(Map<String, dynamic> json) => _$OathPairFromJson(json);

@override final  OathCredential credential;
@override final  OathCode? code;

/// Create a copy of OathPair
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OathPairCopyWith<_OathPair> get copyWith => __$OathPairCopyWithImpl<_OathPair>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OathPairToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OathPair&&(identical(other.credential, credential) || other.credential == credential)&&(identical(other.code, code) || other.code == code));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,credential,code);

@override
String toString() {
  return 'OathPair(credential: $credential, code: $code)';
}


}

/// @nodoc
abstract mixin class _$OathPairCopyWith<$Res> implements $OathPairCopyWith<$Res> {
  factory _$OathPairCopyWith(_OathPair value, $Res Function(_OathPair) _then) = __$OathPairCopyWithImpl;
@override @useResult
$Res call({
 OathCredential credential, OathCode? code
});


@override $OathCredentialCopyWith<$Res> get credential;@override $OathCodeCopyWith<$Res>? get code;

}
/// @nodoc
class __$OathPairCopyWithImpl<$Res>
    implements _$OathPairCopyWith<$Res> {
  __$OathPairCopyWithImpl(this._self, this._then);

  final _OathPair _self;
  final $Res Function(_OathPair) _then;

/// Create a copy of OathPair
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? credential = null,Object? code = freezed,}) {
  return _then(_OathPair(
null == credential ? _self.credential : credential // ignore: cast_nullable_to_non_nullable
as OathCredential,freezed == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as OathCode?,
  ));
}

/// Create a copy of OathPair
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OathCredentialCopyWith<$Res> get credential {
  
  return $OathCredentialCopyWith<$Res>(_self.credential, (value) {
    return _then(_self.copyWith(credential: value));
  });
}/// Create a copy of OathPair
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OathCodeCopyWith<$Res>? get code {
    if (_self.code == null) {
    return null;
  }

  return $OathCodeCopyWith<$Res>(_self.code!, (value) {
    return _then(_self.copyWith(code: value));
  });
}
}


/// @nodoc
mixin _$OathState {

 String get deviceId; Version get version; bool get hasKey; bool get remembered; bool get locked; KeystoreState get keystore;
/// Create a copy of OathState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OathStateCopyWith<OathState> get copyWith => _$OathStateCopyWithImpl<OathState>(this as OathState, _$identity);

  /// Serializes this OathState to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OathState&&(identical(other.deviceId, deviceId) || other.deviceId == deviceId)&&(identical(other.version, version) || other.version == version)&&(identical(other.hasKey, hasKey) || other.hasKey == hasKey)&&(identical(other.remembered, remembered) || other.remembered == remembered)&&(identical(other.locked, locked) || other.locked == locked)&&(identical(other.keystore, keystore) || other.keystore == keystore));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,deviceId,version,hasKey,remembered,locked,keystore);

@override
String toString() {
  return 'OathState(deviceId: $deviceId, version: $version, hasKey: $hasKey, remembered: $remembered, locked: $locked, keystore: $keystore)';
}


}

/// @nodoc
abstract mixin class $OathStateCopyWith<$Res>  {
  factory $OathStateCopyWith(OathState value, $Res Function(OathState) _then) = _$OathStateCopyWithImpl;
@useResult
$Res call({
 String deviceId, Version version, bool hasKey, bool remembered, bool locked, KeystoreState keystore
});


$VersionCopyWith<$Res> get version;

}
/// @nodoc
class _$OathStateCopyWithImpl<$Res>
    implements $OathStateCopyWith<$Res> {
  _$OathStateCopyWithImpl(this._self, this._then);

  final OathState _self;
  final $Res Function(OathState) _then;

/// Create a copy of OathState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? deviceId = null,Object? version = null,Object? hasKey = null,Object? remembered = null,Object? locked = null,Object? keystore = null,}) {
  return _then(_self.copyWith(
deviceId: null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as Version,hasKey: null == hasKey ? _self.hasKey : hasKey // ignore: cast_nullable_to_non_nullable
as bool,remembered: null == remembered ? _self.remembered : remembered // ignore: cast_nullable_to_non_nullable
as bool,locked: null == locked ? _self.locked : locked // ignore: cast_nullable_to_non_nullable
as bool,keystore: null == keystore ? _self.keystore : keystore // ignore: cast_nullable_to_non_nullable
as KeystoreState,
  ));
}
/// Create a copy of OathState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VersionCopyWith<$Res> get version {
  
  return $VersionCopyWith<$Res>(_self.version, (value) {
    return _then(_self.copyWith(version: value));
  });
}
}


/// Adds pattern-matching-related methods to [OathState].
extension OathStatePatterns on OathState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OathState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OathState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OathState value)  $default,){
final _that = this;
switch (_that) {
case _OathState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OathState value)?  $default,){
final _that = this;
switch (_that) {
case _OathState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String deviceId,  Version version,  bool hasKey,  bool remembered,  bool locked,  KeystoreState keystore)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OathState() when $default != null:
return $default(_that.deviceId,_that.version,_that.hasKey,_that.remembered,_that.locked,_that.keystore);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String deviceId,  Version version,  bool hasKey,  bool remembered,  bool locked,  KeystoreState keystore)  $default,) {final _that = this;
switch (_that) {
case _OathState():
return $default(_that.deviceId,_that.version,_that.hasKey,_that.remembered,_that.locked,_that.keystore);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String deviceId,  Version version,  bool hasKey,  bool remembered,  bool locked,  KeystoreState keystore)?  $default,) {final _that = this;
switch (_that) {
case _OathState() when $default != null:
return $default(_that.deviceId,_that.version,_that.hasKey,_that.remembered,_that.locked,_that.keystore);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OathState extends OathState {
   _OathState(this.deviceId, this.version, {required this.hasKey, required this.remembered, required this.locked, required this.keystore}): super._();
  factory _OathState.fromJson(Map<String, dynamic> json) => _$OathStateFromJson(json);

@override final  String deviceId;
@override final  Version version;
@override final  bool hasKey;
@override final  bool remembered;
@override final  bool locked;
@override final  KeystoreState keystore;

/// Create a copy of OathState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OathStateCopyWith<_OathState> get copyWith => __$OathStateCopyWithImpl<_OathState>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OathStateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OathState&&(identical(other.deviceId, deviceId) || other.deviceId == deviceId)&&(identical(other.version, version) || other.version == version)&&(identical(other.hasKey, hasKey) || other.hasKey == hasKey)&&(identical(other.remembered, remembered) || other.remembered == remembered)&&(identical(other.locked, locked) || other.locked == locked)&&(identical(other.keystore, keystore) || other.keystore == keystore));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,deviceId,version,hasKey,remembered,locked,keystore);

@override
String toString() {
  return 'OathState(deviceId: $deviceId, version: $version, hasKey: $hasKey, remembered: $remembered, locked: $locked, keystore: $keystore)';
}


}

/// @nodoc
abstract mixin class _$OathStateCopyWith<$Res> implements $OathStateCopyWith<$Res> {
  factory _$OathStateCopyWith(_OathState value, $Res Function(_OathState) _then) = __$OathStateCopyWithImpl;
@override @useResult
$Res call({
 String deviceId, Version version, bool hasKey, bool remembered, bool locked, KeystoreState keystore
});


@override $VersionCopyWith<$Res> get version;

}
/// @nodoc
class __$OathStateCopyWithImpl<$Res>
    implements _$OathStateCopyWith<$Res> {
  __$OathStateCopyWithImpl(this._self, this._then);

  final _OathState _self;
  final $Res Function(_OathState) _then;

/// Create a copy of OathState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? deviceId = null,Object? version = null,Object? hasKey = null,Object? remembered = null,Object? locked = null,Object? keystore = null,}) {
  return _then(_OathState(
null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as String,null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as Version,hasKey: null == hasKey ? _self.hasKey : hasKey // ignore: cast_nullable_to_non_nullable
as bool,remembered: null == remembered ? _self.remembered : remembered // ignore: cast_nullable_to_non_nullable
as bool,locked: null == locked ? _self.locked : locked // ignore: cast_nullable_to_non_nullable
as bool,keystore: null == keystore ? _self.keystore : keystore // ignore: cast_nullable_to_non_nullable
as KeystoreState,
  ));
}

/// Create a copy of OathState
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
mixin _$CredentialData {

 String? get issuer; String get name; String get secret; OathType get oathType; HashAlgorithm get hashAlgorithm; int get digits; int get period; int get counter;
/// Create a copy of CredentialData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CredentialDataCopyWith<CredentialData> get copyWith => _$CredentialDataCopyWithImpl<CredentialData>(this as CredentialData, _$identity);

  /// Serializes this CredentialData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CredentialData&&(identical(other.issuer, issuer) || other.issuer == issuer)&&(identical(other.name, name) || other.name == name)&&(identical(other.secret, secret) || other.secret == secret)&&(identical(other.oathType, oathType) || other.oathType == oathType)&&(identical(other.hashAlgorithm, hashAlgorithm) || other.hashAlgorithm == hashAlgorithm)&&(identical(other.digits, digits) || other.digits == digits)&&(identical(other.period, period) || other.period == period)&&(identical(other.counter, counter) || other.counter == counter));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,issuer,name,secret,oathType,hashAlgorithm,digits,period,counter);

@override
String toString() {
  return 'CredentialData(issuer: $issuer, name: $name, secret: $secret, oathType: $oathType, hashAlgorithm: $hashAlgorithm, digits: $digits, period: $period, counter: $counter)';
}


}

/// @nodoc
abstract mixin class $CredentialDataCopyWith<$Res>  {
  factory $CredentialDataCopyWith(CredentialData value, $Res Function(CredentialData) _then) = _$CredentialDataCopyWithImpl;
@useResult
$Res call({
 String? issuer, String name, String secret, OathType oathType, HashAlgorithm hashAlgorithm, int digits, int period, int counter
});




}
/// @nodoc
class _$CredentialDataCopyWithImpl<$Res>
    implements $CredentialDataCopyWith<$Res> {
  _$CredentialDataCopyWithImpl(this._self, this._then);

  final CredentialData _self;
  final $Res Function(CredentialData) _then;

/// Create a copy of CredentialData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? issuer = freezed,Object? name = null,Object? secret = null,Object? oathType = null,Object? hashAlgorithm = null,Object? digits = null,Object? period = null,Object? counter = null,}) {
  return _then(_self.copyWith(
issuer: freezed == issuer ? _self.issuer : issuer // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,secret: null == secret ? _self.secret : secret // ignore: cast_nullable_to_non_nullable
as String,oathType: null == oathType ? _self.oathType : oathType // ignore: cast_nullable_to_non_nullable
as OathType,hashAlgorithm: null == hashAlgorithm ? _self.hashAlgorithm : hashAlgorithm // ignore: cast_nullable_to_non_nullable
as HashAlgorithm,digits: null == digits ? _self.digits : digits // ignore: cast_nullable_to_non_nullable
as int,period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as int,counter: null == counter ? _self.counter : counter // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [CredentialData].
extension CredentialDataPatterns on CredentialData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CredentialData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CredentialData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CredentialData value)  $default,){
final _that = this;
switch (_that) {
case _CredentialData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CredentialData value)?  $default,){
final _that = this;
switch (_that) {
case _CredentialData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? issuer,  String name,  String secret,  OathType oathType,  HashAlgorithm hashAlgorithm,  int digits,  int period,  int counter)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CredentialData() when $default != null:
return $default(_that.issuer,_that.name,_that.secret,_that.oathType,_that.hashAlgorithm,_that.digits,_that.period,_that.counter);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? issuer,  String name,  String secret,  OathType oathType,  HashAlgorithm hashAlgorithm,  int digits,  int period,  int counter)  $default,) {final _that = this;
switch (_that) {
case _CredentialData():
return $default(_that.issuer,_that.name,_that.secret,_that.oathType,_that.hashAlgorithm,_that.digits,_that.period,_that.counter);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? issuer,  String name,  String secret,  OathType oathType,  HashAlgorithm hashAlgorithm,  int digits,  int period,  int counter)?  $default,) {final _that = this;
switch (_that) {
case _CredentialData() when $default != null:
return $default(_that.issuer,_that.name,_that.secret,_that.oathType,_that.hashAlgorithm,_that.digits,_that.period,_that.counter);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CredentialData extends CredentialData {
   _CredentialData({this.issuer, required this.name, required this.secret, this.oathType = defaultOathType, this.hashAlgorithm = defaultHashAlgorithm, this.digits = defaultDigits, this.period = defaultPeriod, this.counter = defaultCounter}): super._();
  factory _CredentialData.fromJson(Map<String, dynamic> json) => _$CredentialDataFromJson(json);

@override final  String? issuer;
@override final  String name;
@override final  String secret;
@override@JsonKey() final  OathType oathType;
@override@JsonKey() final  HashAlgorithm hashAlgorithm;
@override@JsonKey() final  int digits;
@override@JsonKey() final  int period;
@override@JsonKey() final  int counter;

/// Create a copy of CredentialData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CredentialDataCopyWith<_CredentialData> get copyWith => __$CredentialDataCopyWithImpl<_CredentialData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CredentialDataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CredentialData&&(identical(other.issuer, issuer) || other.issuer == issuer)&&(identical(other.name, name) || other.name == name)&&(identical(other.secret, secret) || other.secret == secret)&&(identical(other.oathType, oathType) || other.oathType == oathType)&&(identical(other.hashAlgorithm, hashAlgorithm) || other.hashAlgorithm == hashAlgorithm)&&(identical(other.digits, digits) || other.digits == digits)&&(identical(other.period, period) || other.period == period)&&(identical(other.counter, counter) || other.counter == counter));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,issuer,name,secret,oathType,hashAlgorithm,digits,period,counter);

@override
String toString() {
  return 'CredentialData(issuer: $issuer, name: $name, secret: $secret, oathType: $oathType, hashAlgorithm: $hashAlgorithm, digits: $digits, period: $period, counter: $counter)';
}


}

/// @nodoc
abstract mixin class _$CredentialDataCopyWith<$Res> implements $CredentialDataCopyWith<$Res> {
  factory _$CredentialDataCopyWith(_CredentialData value, $Res Function(_CredentialData) _then) = __$CredentialDataCopyWithImpl;
@override @useResult
$Res call({
 String? issuer, String name, String secret, OathType oathType, HashAlgorithm hashAlgorithm, int digits, int period, int counter
});




}
/// @nodoc
class __$CredentialDataCopyWithImpl<$Res>
    implements _$CredentialDataCopyWith<$Res> {
  __$CredentialDataCopyWithImpl(this._self, this._then);

  final _CredentialData _self;
  final $Res Function(_CredentialData) _then;

/// Create a copy of CredentialData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? issuer = freezed,Object? name = null,Object? secret = null,Object? oathType = null,Object? hashAlgorithm = null,Object? digits = null,Object? period = null,Object? counter = null,}) {
  return _then(_CredentialData(
issuer: freezed == issuer ? _self.issuer : issuer // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,secret: null == secret ? _self.secret : secret // ignore: cast_nullable_to_non_nullable
as String,oathType: null == oathType ? _self.oathType : oathType // ignore: cast_nullable_to_non_nullable
as OathType,hashAlgorithm: null == hashAlgorithm ? _self.hashAlgorithm : hashAlgorithm // ignore: cast_nullable_to_non_nullable
as HashAlgorithm,digits: null == digits ? _self.digits : digits // ignore: cast_nullable_to_non_nullable
as int,period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as int,counter: null == counter ? _self.counter : counter // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
