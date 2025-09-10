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
mixin _$FidoState {

 Map<String, dynamic> get info; bool get unlocked; bool get unlockedRead;// TODO: Need to implement support on Android
 int? get pinRetries;
/// Create a copy of FidoState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FidoStateCopyWith<FidoState> get copyWith => _$FidoStateCopyWithImpl<FidoState>(this as FidoState, _$identity);

  /// Serializes this FidoState to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FidoState&&const DeepCollectionEquality().equals(other.info, info)&&(identical(other.unlocked, unlocked) || other.unlocked == unlocked)&&(identical(other.unlockedRead, unlockedRead) || other.unlockedRead == unlockedRead)&&(identical(other.pinRetries, pinRetries) || other.pinRetries == pinRetries));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(info),unlocked,unlockedRead,pinRetries);

@override
String toString() {
  return 'FidoState(info: $info, unlocked: $unlocked, unlockedRead: $unlockedRead, pinRetries: $pinRetries)';
}


}

/// @nodoc
abstract mixin class $FidoStateCopyWith<$Res>  {
  factory $FidoStateCopyWith(FidoState value, $Res Function(FidoState) _then) = _$FidoStateCopyWithImpl;
@useResult
$Res call({
 Map<String, dynamic> info, bool unlocked, bool unlockedRead, int? pinRetries
});




}
/// @nodoc
class _$FidoStateCopyWithImpl<$Res>
    implements $FidoStateCopyWith<$Res> {
  _$FidoStateCopyWithImpl(this._self, this._then);

  final FidoState _self;
  final $Res Function(FidoState) _then;

/// Create a copy of FidoState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? info = null,Object? unlocked = null,Object? unlockedRead = null,Object? pinRetries = freezed,}) {
  return _then(_self.copyWith(
info: null == info ? _self.info : info // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,unlocked: null == unlocked ? _self.unlocked : unlocked // ignore: cast_nullable_to_non_nullable
as bool,unlockedRead: null == unlockedRead ? _self.unlockedRead : unlockedRead // ignore: cast_nullable_to_non_nullable
as bool,pinRetries: freezed == pinRetries ? _self.pinRetries : pinRetries // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [FidoState].
extension FidoStatePatterns on FidoState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FidoState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FidoState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FidoState value)  $default,){
final _that = this;
switch (_that) {
case _FidoState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FidoState value)?  $default,){
final _that = this;
switch (_that) {
case _FidoState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Map<String, dynamic> info,  bool unlocked,  bool unlockedRead,  int? pinRetries)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FidoState() when $default != null:
return $default(_that.info,_that.unlocked,_that.unlockedRead,_that.pinRetries);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Map<String, dynamic> info,  bool unlocked,  bool unlockedRead,  int? pinRetries)  $default,) {final _that = this;
switch (_that) {
case _FidoState():
return $default(_that.info,_that.unlocked,_that.unlockedRead,_that.pinRetries);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Map<String, dynamic> info,  bool unlocked,  bool unlockedRead,  int? pinRetries)?  $default,) {final _that = this;
switch (_that) {
case _FidoState() when $default != null:
return $default(_that.info,_that.unlocked,_that.unlockedRead,_that.pinRetries);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FidoState extends FidoState {
   _FidoState({required final  Map<String, dynamic> info, required this.unlocked, this.unlockedRead = false, this.pinRetries}): _info = info,super._();
  factory _FidoState.fromJson(Map<String, dynamic> json) => _$FidoStateFromJson(json);

 final  Map<String, dynamic> _info;
@override Map<String, dynamic> get info {
  if (_info is EqualUnmodifiableMapView) return _info;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_info);
}

@override final  bool unlocked;
@override@JsonKey() final  bool unlockedRead;
// TODO: Need to implement support on Android
@override final  int? pinRetries;

/// Create a copy of FidoState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FidoStateCopyWith<_FidoState> get copyWith => __$FidoStateCopyWithImpl<_FidoState>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FidoStateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FidoState&&const DeepCollectionEquality().equals(other._info, _info)&&(identical(other.unlocked, unlocked) || other.unlocked == unlocked)&&(identical(other.unlockedRead, unlockedRead) || other.unlockedRead == unlockedRead)&&(identical(other.pinRetries, pinRetries) || other.pinRetries == pinRetries));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_info),unlocked,unlockedRead,pinRetries);

@override
String toString() {
  return 'FidoState(info: $info, unlocked: $unlocked, unlockedRead: $unlockedRead, pinRetries: $pinRetries)';
}


}

/// @nodoc
abstract mixin class _$FidoStateCopyWith<$Res> implements $FidoStateCopyWith<$Res> {
  factory _$FidoStateCopyWith(_FidoState value, $Res Function(_FidoState) _then) = __$FidoStateCopyWithImpl;
@override @useResult
$Res call({
 Map<String, dynamic> info, bool unlocked, bool unlockedRead, int? pinRetries
});




}
/// @nodoc
class __$FidoStateCopyWithImpl<$Res>
    implements _$FidoStateCopyWith<$Res> {
  __$FidoStateCopyWithImpl(this._self, this._then);

  final _FidoState _self;
  final $Res Function(_FidoState) _then;

/// Create a copy of FidoState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? info = null,Object? unlocked = null,Object? unlockedRead = null,Object? pinRetries = freezed,}) {
  return _then(_FidoState(
info: null == info ? _self._info : info // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,unlocked: null == unlocked ? _self.unlocked : unlocked // ignore: cast_nullable_to_non_nullable
as bool,unlockedRead: null == unlockedRead ? _self.unlockedRead : unlockedRead // ignore: cast_nullable_to_non_nullable
as bool,pinRetries: freezed == pinRetries ? _self.pinRetries : pinRetries // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

/// @nodoc
mixin _$PinResult {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PinResult);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PinResult()';
}


}

/// @nodoc
class $PinResultCopyWith<$Res>  {
$PinResultCopyWith(PinResult _, $Res Function(PinResult) __);
}


/// Adds pattern-matching-related methods to [PinResult].
extension PinResultPatterns on PinResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( PinResultSuccess value)?  success,TResult Function( PinResultFailure value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case PinResultSuccess() when success != null:
return success(_that);case PinResultFailure() when failed != null:
return failed(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( PinResultSuccess value)  success,required TResult Function( PinResultFailure value)  failed,}){
final _that = this;
switch (_that) {
case PinResultSuccess():
return success(_that);case PinResultFailure():
return failed(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( PinResultSuccess value)?  success,TResult? Function( PinResultFailure value)?  failed,}){
final _that = this;
switch (_that) {
case PinResultSuccess() when success != null:
return success(_that);case PinResultFailure() when failed != null:
return failed(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  success,TResult Function( FidoPinFailureReason reason)?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case PinResultSuccess() when success != null:
return success();case PinResultFailure() when failed != null:
return failed(_that.reason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  success,required TResult Function( FidoPinFailureReason reason)  failed,}) {final _that = this;
switch (_that) {
case PinResultSuccess():
return success();case PinResultFailure():
return failed(_that.reason);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  success,TResult? Function( FidoPinFailureReason reason)?  failed,}) {final _that = this;
switch (_that) {
case PinResultSuccess() when success != null:
return success();case PinResultFailure() when failed != null:
return failed(_that.reason);case _:
  return null;

}
}

}

/// @nodoc


class PinResultSuccess implements PinResult {
   PinResultSuccess();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PinResultSuccess);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PinResult.success()';
}


}




/// @nodoc


class PinResultFailure implements PinResult {
   PinResultFailure(this.reason);
  

 final  FidoPinFailureReason reason;

/// Create a copy of PinResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PinResultFailureCopyWith<PinResultFailure> get copyWith => _$PinResultFailureCopyWithImpl<PinResultFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PinResultFailure&&(identical(other.reason, reason) || other.reason == reason));
}


@override
int get hashCode => Object.hash(runtimeType,reason);

@override
String toString() {
  return 'PinResult.failed(reason: $reason)';
}


}

/// @nodoc
abstract mixin class $PinResultFailureCopyWith<$Res> implements $PinResultCopyWith<$Res> {
  factory $PinResultFailureCopyWith(PinResultFailure value, $Res Function(PinResultFailure) _then) = _$PinResultFailureCopyWithImpl;
@useResult
$Res call({
 FidoPinFailureReason reason
});


$FidoPinFailureReasonCopyWith<$Res> get reason;

}
/// @nodoc
class _$PinResultFailureCopyWithImpl<$Res>
    implements $PinResultFailureCopyWith<$Res> {
  _$PinResultFailureCopyWithImpl(this._self, this._then);

  final PinResultFailure _self;
  final $Res Function(PinResultFailure) _then;

/// Create a copy of PinResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? reason = null,}) {
  return _then(PinResultFailure(
null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as FidoPinFailureReason,
  ));
}

/// Create a copy of PinResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FidoPinFailureReasonCopyWith<$Res> get reason {
  
  return $FidoPinFailureReasonCopyWith<$Res>(_self.reason, (value) {
    return _then(_self.copyWith(reason: value));
  });
}
}

/// @nodoc
mixin _$FidoPinFailureReason {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FidoPinFailureReason);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'FidoPinFailureReason()';
}


}

/// @nodoc
class $FidoPinFailureReasonCopyWith<$Res>  {
$FidoPinFailureReasonCopyWith(FidoPinFailureReason _, $Res Function(FidoPinFailureReason) __);
}


/// Adds pattern-matching-related methods to [FidoPinFailureReason].
extension FidoPinFailureReasonPatterns on FidoPinFailureReason {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( FidoInvalidPin value)?  invalidPin,TResult Function( FidoWeakPin value)?  weakPin,required TResult orElse(),}){
final _that = this;
switch (_that) {
case FidoInvalidPin() when invalidPin != null:
return invalidPin(_that);case FidoWeakPin() when weakPin != null:
return weakPin(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( FidoInvalidPin value)  invalidPin,required TResult Function( FidoWeakPin value)  weakPin,}){
final _that = this;
switch (_that) {
case FidoInvalidPin():
return invalidPin(_that);case FidoWeakPin():
return weakPin(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( FidoInvalidPin value)?  invalidPin,TResult? Function( FidoWeakPin value)?  weakPin,}){
final _that = this;
switch (_that) {
case FidoInvalidPin() when invalidPin != null:
return invalidPin(_that);case FidoWeakPin() when weakPin != null:
return weakPin(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( int retries,  bool authBlocked)?  invalidPin,TResult Function()?  weakPin,required TResult orElse(),}) {final _that = this;
switch (_that) {
case FidoInvalidPin() when invalidPin != null:
return invalidPin(_that.retries,_that.authBlocked);case FidoWeakPin() when weakPin != null:
return weakPin();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( int retries,  bool authBlocked)  invalidPin,required TResult Function()  weakPin,}) {final _that = this;
switch (_that) {
case FidoInvalidPin():
return invalidPin(_that.retries,_that.authBlocked);case FidoWeakPin():
return weakPin();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( int retries,  bool authBlocked)?  invalidPin,TResult? Function()?  weakPin,}) {final _that = this;
switch (_that) {
case FidoInvalidPin() when invalidPin != null:
return invalidPin(_that.retries,_that.authBlocked);case FidoWeakPin() when weakPin != null:
return weakPin();case _:
  return null;

}
}

}

/// @nodoc


class FidoInvalidPin implements FidoPinFailureReason {
   FidoInvalidPin(this.retries, this.authBlocked);
  

 final  int retries;
 final  bool authBlocked;

/// Create a copy of FidoPinFailureReason
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FidoInvalidPinCopyWith<FidoInvalidPin> get copyWith => _$FidoInvalidPinCopyWithImpl<FidoInvalidPin>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FidoInvalidPin&&(identical(other.retries, retries) || other.retries == retries)&&(identical(other.authBlocked, authBlocked) || other.authBlocked == authBlocked));
}


@override
int get hashCode => Object.hash(runtimeType,retries,authBlocked);

@override
String toString() {
  return 'FidoPinFailureReason.invalidPin(retries: $retries, authBlocked: $authBlocked)';
}


}

/// @nodoc
abstract mixin class $FidoInvalidPinCopyWith<$Res> implements $FidoPinFailureReasonCopyWith<$Res> {
  factory $FidoInvalidPinCopyWith(FidoInvalidPin value, $Res Function(FidoInvalidPin) _then) = _$FidoInvalidPinCopyWithImpl;
@useResult
$Res call({
 int retries, bool authBlocked
});




}
/// @nodoc
class _$FidoInvalidPinCopyWithImpl<$Res>
    implements $FidoInvalidPinCopyWith<$Res> {
  _$FidoInvalidPinCopyWithImpl(this._self, this._then);

  final FidoInvalidPin _self;
  final $Res Function(FidoInvalidPin) _then;

/// Create a copy of FidoPinFailureReason
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? retries = null,Object? authBlocked = null,}) {
  return _then(FidoInvalidPin(
null == retries ? _self.retries : retries // ignore: cast_nullable_to_non_nullable
as int,null == authBlocked ? _self.authBlocked : authBlocked // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class FidoWeakPin implements FidoPinFailureReason {
  const FidoWeakPin();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FidoWeakPin);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'FidoPinFailureReason.weakPin()';
}


}





/// @nodoc
mixin _$Fingerprint {

 String get templateId; String? get name;
/// Create a copy of Fingerprint
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FingerprintCopyWith<Fingerprint> get copyWith => _$FingerprintCopyWithImpl<Fingerprint>(this as Fingerprint, _$identity);

  /// Serializes this Fingerprint to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Fingerprint&&(identical(other.templateId, templateId) || other.templateId == templateId)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,templateId,name);

@override
String toString() {
  return 'Fingerprint(templateId: $templateId, name: $name)';
}


}

/// @nodoc
abstract mixin class $FingerprintCopyWith<$Res>  {
  factory $FingerprintCopyWith(Fingerprint value, $Res Function(Fingerprint) _then) = _$FingerprintCopyWithImpl;
@useResult
$Res call({
 String templateId, String? name
});




}
/// @nodoc
class _$FingerprintCopyWithImpl<$Res>
    implements $FingerprintCopyWith<$Res> {
  _$FingerprintCopyWithImpl(this._self, this._then);

  final Fingerprint _self;
  final $Res Function(Fingerprint) _then;

/// Create a copy of Fingerprint
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? templateId = null,Object? name = freezed,}) {
  return _then(_self.copyWith(
templateId: null == templateId ? _self.templateId : templateId // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Fingerprint].
extension FingerprintPatterns on Fingerprint {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Fingerprint value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Fingerprint() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Fingerprint value)  $default,){
final _that = this;
switch (_that) {
case _Fingerprint():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Fingerprint value)?  $default,){
final _that = this;
switch (_that) {
case _Fingerprint() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String templateId,  String? name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Fingerprint() when $default != null:
return $default(_that.templateId,_that.name);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String templateId,  String? name)  $default,) {final _that = this;
switch (_that) {
case _Fingerprint():
return $default(_that.templateId,_that.name);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String templateId,  String? name)?  $default,) {final _that = this;
switch (_that) {
case _Fingerprint() when $default != null:
return $default(_that.templateId,_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Fingerprint extends Fingerprint {
   _Fingerprint(this.templateId, this.name): super._();
  factory _Fingerprint.fromJson(Map<String, dynamic> json) => _$FingerprintFromJson(json);

@override final  String templateId;
@override final  String? name;

/// Create a copy of Fingerprint
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FingerprintCopyWith<_Fingerprint> get copyWith => __$FingerprintCopyWithImpl<_Fingerprint>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FingerprintToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Fingerprint&&(identical(other.templateId, templateId) || other.templateId == templateId)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,templateId,name);

@override
String toString() {
  return 'Fingerprint(templateId: $templateId, name: $name)';
}


}

/// @nodoc
abstract mixin class _$FingerprintCopyWith<$Res> implements $FingerprintCopyWith<$Res> {
  factory _$FingerprintCopyWith(_Fingerprint value, $Res Function(_Fingerprint) _then) = __$FingerprintCopyWithImpl;
@override @useResult
$Res call({
 String templateId, String? name
});




}
/// @nodoc
class __$FingerprintCopyWithImpl<$Res>
    implements _$FingerprintCopyWith<$Res> {
  __$FingerprintCopyWithImpl(this._self, this._then);

  final _Fingerprint _self;
  final $Res Function(_Fingerprint) _then;

/// Create a copy of Fingerprint
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? templateId = null,Object? name = freezed,}) {
  return _then(_Fingerprint(
null == templateId ? _self.templateId : templateId // ignore: cast_nullable_to_non_nullable
as String,freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$FingerprintEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FingerprintEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'FingerprintEvent()';
}


}

/// @nodoc
class $FingerprintEventCopyWith<$Res>  {
$FingerprintEventCopyWith(FingerprintEvent _, $Res Function(FingerprintEvent) __);
}


/// Adds pattern-matching-related methods to [FingerprintEvent].
extension FingerprintEventPatterns on FingerprintEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( FingerprintEventCapture value)?  capture,TResult Function( FingerprintEventComplete value)?  complete,TResult Function( FingerprintEventError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case FingerprintEventCapture() when capture != null:
return capture(_that);case FingerprintEventComplete() when complete != null:
return complete(_that);case FingerprintEventError() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( FingerprintEventCapture value)  capture,required TResult Function( FingerprintEventComplete value)  complete,required TResult Function( FingerprintEventError value)  error,}){
final _that = this;
switch (_that) {
case FingerprintEventCapture():
return capture(_that);case FingerprintEventComplete():
return complete(_that);case FingerprintEventError():
return error(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( FingerprintEventCapture value)?  capture,TResult? Function( FingerprintEventComplete value)?  complete,TResult? Function( FingerprintEventError value)?  error,}){
final _that = this;
switch (_that) {
case FingerprintEventCapture() when capture != null:
return capture(_that);case FingerprintEventComplete() when complete != null:
return complete(_that);case FingerprintEventError() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( int remaining)?  capture,TResult Function( Fingerprint fingerprint)?  complete,TResult Function( int code)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case FingerprintEventCapture() when capture != null:
return capture(_that.remaining);case FingerprintEventComplete() when complete != null:
return complete(_that.fingerprint);case FingerprintEventError() when error != null:
return error(_that.code);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( int remaining)  capture,required TResult Function( Fingerprint fingerprint)  complete,required TResult Function( int code)  error,}) {final _that = this;
switch (_that) {
case FingerprintEventCapture():
return capture(_that.remaining);case FingerprintEventComplete():
return complete(_that.fingerprint);case FingerprintEventError():
return error(_that.code);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( int remaining)?  capture,TResult? Function( Fingerprint fingerprint)?  complete,TResult? Function( int code)?  error,}) {final _that = this;
switch (_that) {
case FingerprintEventCapture() when capture != null:
return capture(_that.remaining);case FingerprintEventComplete() when complete != null:
return complete(_that.fingerprint);case FingerprintEventError() when error != null:
return error(_that.code);case _:
  return null;

}
}

}

/// @nodoc


class FingerprintEventCapture implements FingerprintEvent {
   FingerprintEventCapture(this.remaining);
  

 final  int remaining;

/// Create a copy of FingerprintEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FingerprintEventCaptureCopyWith<FingerprintEventCapture> get copyWith => _$FingerprintEventCaptureCopyWithImpl<FingerprintEventCapture>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FingerprintEventCapture&&(identical(other.remaining, remaining) || other.remaining == remaining));
}


@override
int get hashCode => Object.hash(runtimeType,remaining);

@override
String toString() {
  return 'FingerprintEvent.capture(remaining: $remaining)';
}


}

/// @nodoc
abstract mixin class $FingerprintEventCaptureCopyWith<$Res> implements $FingerprintEventCopyWith<$Res> {
  factory $FingerprintEventCaptureCopyWith(FingerprintEventCapture value, $Res Function(FingerprintEventCapture) _then) = _$FingerprintEventCaptureCopyWithImpl;
@useResult
$Res call({
 int remaining
});




}
/// @nodoc
class _$FingerprintEventCaptureCopyWithImpl<$Res>
    implements $FingerprintEventCaptureCopyWith<$Res> {
  _$FingerprintEventCaptureCopyWithImpl(this._self, this._then);

  final FingerprintEventCapture _self;
  final $Res Function(FingerprintEventCapture) _then;

/// Create a copy of FingerprintEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? remaining = null,}) {
  return _then(FingerprintEventCapture(
null == remaining ? _self.remaining : remaining // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class FingerprintEventComplete implements FingerprintEvent {
   FingerprintEventComplete(this.fingerprint);
  

 final  Fingerprint fingerprint;

/// Create a copy of FingerprintEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FingerprintEventCompleteCopyWith<FingerprintEventComplete> get copyWith => _$FingerprintEventCompleteCopyWithImpl<FingerprintEventComplete>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FingerprintEventComplete&&(identical(other.fingerprint, fingerprint) || other.fingerprint == fingerprint));
}


@override
int get hashCode => Object.hash(runtimeType,fingerprint);

@override
String toString() {
  return 'FingerprintEvent.complete(fingerprint: $fingerprint)';
}


}

/// @nodoc
abstract mixin class $FingerprintEventCompleteCopyWith<$Res> implements $FingerprintEventCopyWith<$Res> {
  factory $FingerprintEventCompleteCopyWith(FingerprintEventComplete value, $Res Function(FingerprintEventComplete) _then) = _$FingerprintEventCompleteCopyWithImpl;
@useResult
$Res call({
 Fingerprint fingerprint
});


$FingerprintCopyWith<$Res> get fingerprint;

}
/// @nodoc
class _$FingerprintEventCompleteCopyWithImpl<$Res>
    implements $FingerprintEventCompleteCopyWith<$Res> {
  _$FingerprintEventCompleteCopyWithImpl(this._self, this._then);

  final FingerprintEventComplete _self;
  final $Res Function(FingerprintEventComplete) _then;

/// Create a copy of FingerprintEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? fingerprint = null,}) {
  return _then(FingerprintEventComplete(
null == fingerprint ? _self.fingerprint : fingerprint // ignore: cast_nullable_to_non_nullable
as Fingerprint,
  ));
}

/// Create a copy of FingerprintEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FingerprintCopyWith<$Res> get fingerprint {
  
  return $FingerprintCopyWith<$Res>(_self.fingerprint, (value) {
    return _then(_self.copyWith(fingerprint: value));
  });
}
}

/// @nodoc


class FingerprintEventError implements FingerprintEvent {
   FingerprintEventError(this.code);
  

 final  int code;

/// Create a copy of FingerprintEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FingerprintEventErrorCopyWith<FingerprintEventError> get copyWith => _$FingerprintEventErrorCopyWithImpl<FingerprintEventError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FingerprintEventError&&(identical(other.code, code) || other.code == code));
}


@override
int get hashCode => Object.hash(runtimeType,code);

@override
String toString() {
  return 'FingerprintEvent.error(code: $code)';
}


}

/// @nodoc
abstract mixin class $FingerprintEventErrorCopyWith<$Res> implements $FingerprintEventCopyWith<$Res> {
  factory $FingerprintEventErrorCopyWith(FingerprintEventError value, $Res Function(FingerprintEventError) _then) = _$FingerprintEventErrorCopyWithImpl;
@useResult
$Res call({
 int code
});




}
/// @nodoc
class _$FingerprintEventErrorCopyWithImpl<$Res>
    implements $FingerprintEventErrorCopyWith<$Res> {
  _$FingerprintEventErrorCopyWithImpl(this._self, this._then);

  final FingerprintEventError _self;
  final $Res Function(FingerprintEventError) _then;

/// Create a copy of FingerprintEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? code = null,}) {
  return _then(FingerprintEventError(
null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$FidoCredential {

 String get rpId; String get credentialId; String get userId; String get userName; String? get displayName;
/// Create a copy of FidoCredential
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FidoCredentialCopyWith<FidoCredential> get copyWith => _$FidoCredentialCopyWithImpl<FidoCredential>(this as FidoCredential, _$identity);

  /// Serializes this FidoCredential to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FidoCredential&&(identical(other.rpId, rpId) || other.rpId == rpId)&&(identical(other.credentialId, credentialId) || other.credentialId == credentialId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.userName, userName) || other.userName == userName)&&(identical(other.displayName, displayName) || other.displayName == displayName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,rpId,credentialId,userId,userName,displayName);

@override
String toString() {
  return 'FidoCredential(rpId: $rpId, credentialId: $credentialId, userId: $userId, userName: $userName, displayName: $displayName)';
}


}

/// @nodoc
abstract mixin class $FidoCredentialCopyWith<$Res>  {
  factory $FidoCredentialCopyWith(FidoCredential value, $Res Function(FidoCredential) _then) = _$FidoCredentialCopyWithImpl;
@useResult
$Res call({
 String rpId, String credentialId, String userId, String userName, String? displayName
});




}
/// @nodoc
class _$FidoCredentialCopyWithImpl<$Res>
    implements $FidoCredentialCopyWith<$Res> {
  _$FidoCredentialCopyWithImpl(this._self, this._then);

  final FidoCredential _self;
  final $Res Function(FidoCredential) _then;

/// Create a copy of FidoCredential
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rpId = null,Object? credentialId = null,Object? userId = null,Object? userName = null,Object? displayName = freezed,}) {
  return _then(_self.copyWith(
rpId: null == rpId ? _self.rpId : rpId // ignore: cast_nullable_to_non_nullable
as String,credentialId: null == credentialId ? _self.credentialId : credentialId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,userName: null == userName ? _self.userName : userName // ignore: cast_nullable_to_non_nullable
as String,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [FidoCredential].
extension FidoCredentialPatterns on FidoCredential {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FidoCredential value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FidoCredential() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FidoCredential value)  $default,){
final _that = this;
switch (_that) {
case _FidoCredential():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FidoCredential value)?  $default,){
final _that = this;
switch (_that) {
case _FidoCredential() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String rpId,  String credentialId,  String userId,  String userName,  String? displayName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FidoCredential() when $default != null:
return $default(_that.rpId,_that.credentialId,_that.userId,_that.userName,_that.displayName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String rpId,  String credentialId,  String userId,  String userName,  String? displayName)  $default,) {final _that = this;
switch (_that) {
case _FidoCredential():
return $default(_that.rpId,_that.credentialId,_that.userId,_that.userName,_that.displayName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String rpId,  String credentialId,  String userId,  String userName,  String? displayName)?  $default,) {final _that = this;
switch (_that) {
case _FidoCredential() when $default != null:
return $default(_that.rpId,_that.credentialId,_that.userId,_that.userName,_that.displayName);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FidoCredential implements FidoCredential {
   _FidoCredential({required this.rpId, required this.credentialId, required this.userId, required this.userName, this.displayName});
  factory _FidoCredential.fromJson(Map<String, dynamic> json) => _$FidoCredentialFromJson(json);

@override final  String rpId;
@override final  String credentialId;
@override final  String userId;
@override final  String userName;
@override final  String? displayName;

/// Create a copy of FidoCredential
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FidoCredentialCopyWith<_FidoCredential> get copyWith => __$FidoCredentialCopyWithImpl<_FidoCredential>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FidoCredentialToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FidoCredential&&(identical(other.rpId, rpId) || other.rpId == rpId)&&(identical(other.credentialId, credentialId) || other.credentialId == credentialId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.userName, userName) || other.userName == userName)&&(identical(other.displayName, displayName) || other.displayName == displayName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,rpId,credentialId,userId,userName,displayName);

@override
String toString() {
  return 'FidoCredential(rpId: $rpId, credentialId: $credentialId, userId: $userId, userName: $userName, displayName: $displayName)';
}


}

/// @nodoc
abstract mixin class _$FidoCredentialCopyWith<$Res> implements $FidoCredentialCopyWith<$Res> {
  factory _$FidoCredentialCopyWith(_FidoCredential value, $Res Function(_FidoCredential) _then) = __$FidoCredentialCopyWithImpl;
@override @useResult
$Res call({
 String rpId, String credentialId, String userId, String userName, String? displayName
});




}
/// @nodoc
class __$FidoCredentialCopyWithImpl<$Res>
    implements _$FidoCredentialCopyWith<$Res> {
  __$FidoCredentialCopyWithImpl(this._self, this._then);

  final _FidoCredential _self;
  final $Res Function(_FidoCredential) _then;

/// Create a copy of FidoCredential
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? rpId = null,Object? credentialId = null,Object? userId = null,Object? userName = null,Object? displayName = freezed,}) {
  return _then(_FidoCredential(
rpId: null == rpId ? _self.rpId : rpId // ignore: cast_nullable_to_non_nullable
as String,credentialId: null == credentialId ? _self.credentialId : credentialId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,userName: null == userName ? _self.userName : userName // ignore: cast_nullable_to_non_nullable
as String,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
