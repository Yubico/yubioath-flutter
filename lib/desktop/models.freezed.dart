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
RpcResponse _$RpcResponseFromJson(
  Map<String, dynamic> json
) {
        switch (json['kind']) {
                  case 'success':
          return Success.fromJson(
            json
          );
                case 'signal':
          return Signal.fromJson(
            json
          );
                case 'error':
          return RpcError.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'kind',
  'RpcResponse',
  'Invalid union type "${json['kind']}"!'
);
        }
      
}

/// @nodoc
mixin _$RpcResponse {

 Map<String, dynamic> get body;
/// Create a copy of RpcResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RpcResponseCopyWith<RpcResponse> get copyWith => _$RpcResponseCopyWithImpl<RpcResponse>(this as RpcResponse, _$identity);

  /// Serializes this RpcResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RpcResponse&&const DeepCollectionEquality().equals(other.body, body));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(body));

@override
String toString() {
  return 'RpcResponse(body: $body)';
}


}

/// @nodoc
abstract mixin class $RpcResponseCopyWith<$Res>  {
  factory $RpcResponseCopyWith(RpcResponse value, $Res Function(RpcResponse) _then) = _$RpcResponseCopyWithImpl;
@useResult
$Res call({
 Map<String, dynamic> body
});




}
/// @nodoc
class _$RpcResponseCopyWithImpl<$Res>
    implements $RpcResponseCopyWith<$Res> {
  _$RpcResponseCopyWithImpl(this._self, this._then);

  final RpcResponse _self;
  final $Res Function(RpcResponse) _then;

/// Create a copy of RpcResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? body = null,}) {
  return _then(_self.copyWith(
body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// Adds pattern-matching-related methods to [RpcResponse].
extension RpcResponsePatterns on RpcResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( Success value)?  success,TResult Function( Signal value)?  signal,TResult Function( RpcError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case Success() when success != null:
return success(_that);case Signal() when signal != null:
return signal(_that);case RpcError() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( Success value)  success,required TResult Function( Signal value)  signal,required TResult Function( RpcError value)  error,}){
final _that = this;
switch (_that) {
case Success():
return success(_that);case Signal():
return signal(_that);case RpcError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( Success value)?  success,TResult? Function( Signal value)?  signal,TResult? Function( RpcError value)?  error,}){
final _that = this;
switch (_that) {
case Success() when success != null:
return success(_that);case Signal() when signal != null:
return signal(_that);case RpcError() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( Map<String, dynamic> body,  List<String> flags)?  success,TResult Function( String status,  Map<String, dynamic> body)?  signal,TResult Function( String status,  String message,  Map<String, dynamic> body)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case Success() when success != null:
return success(_that.body,_that.flags);case Signal() when signal != null:
return signal(_that.status,_that.body);case RpcError() when error != null:
return error(_that.status,_that.message,_that.body);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( Map<String, dynamic> body,  List<String> flags)  success,required TResult Function( String status,  Map<String, dynamic> body)  signal,required TResult Function( String status,  String message,  Map<String, dynamic> body)  error,}) {final _that = this;
switch (_that) {
case Success():
return success(_that.body,_that.flags);case Signal():
return signal(_that.status,_that.body);case RpcError():
return error(_that.status,_that.message,_that.body);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( Map<String, dynamic> body,  List<String> flags)?  success,TResult? Function( String status,  Map<String, dynamic> body)?  signal,TResult? Function( String status,  String message,  Map<String, dynamic> body)?  error,}) {final _that = this;
switch (_that) {
case Success() when success != null:
return success(_that.body,_that.flags);case Signal() when signal != null:
return signal(_that.status,_that.body);case RpcError() when error != null:
return error(_that.status,_that.message,_that.body);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class Success implements RpcResponse {
   Success(final  Map<String, dynamic> body, final  List<String> flags, {final  String? $type}): _body = body,_flags = flags,$type = $type ?? 'success';
  factory Success.fromJson(Map<String, dynamic> json) => _$SuccessFromJson(json);

 final  Map<String, dynamic> _body;
@override Map<String, dynamic> get body {
  if (_body is EqualUnmodifiableMapView) return _body;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_body);
}

 final  List<String> _flags;
 List<String> get flags {
  if (_flags is EqualUnmodifiableListView) return _flags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_flags);
}


@JsonKey(name: 'kind')
final String $type;


/// Create a copy of RpcResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SuccessCopyWith<Success> get copyWith => _$SuccessCopyWithImpl<Success>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SuccessToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Success&&const DeepCollectionEquality().equals(other._body, _body)&&const DeepCollectionEquality().equals(other._flags, _flags));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_body),const DeepCollectionEquality().hash(_flags));

@override
String toString() {
  return 'RpcResponse.success(body: $body, flags: $flags)';
}


}

/// @nodoc
abstract mixin class $SuccessCopyWith<$Res> implements $RpcResponseCopyWith<$Res> {
  factory $SuccessCopyWith(Success value, $Res Function(Success) _then) = _$SuccessCopyWithImpl;
@override @useResult
$Res call({
 Map<String, dynamic> body, List<String> flags
});




}
/// @nodoc
class _$SuccessCopyWithImpl<$Res>
    implements $SuccessCopyWith<$Res> {
  _$SuccessCopyWithImpl(this._self, this._then);

  final Success _self;
  final $Res Function(Success) _then;

/// Create a copy of RpcResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? body = null,Object? flags = null,}) {
  return _then(Success(
null == body ? _self._body : body // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,null == flags ? _self._flags : flags // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

/// @nodoc
@JsonSerializable()

class Signal implements RpcResponse {
   Signal(this.status, final  Map<String, dynamic> body, {final  String? $type}): _body = body,$type = $type ?? 'signal';
  factory Signal.fromJson(Map<String, dynamic> json) => _$SignalFromJson(json);

 final  String status;
 final  Map<String, dynamic> _body;
@override Map<String, dynamic> get body {
  if (_body is EqualUnmodifiableMapView) return _body;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_body);
}


@JsonKey(name: 'kind')
final String $type;


/// Create a copy of RpcResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SignalCopyWith<Signal> get copyWith => _$SignalCopyWithImpl<Signal>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SignalToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Signal&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._body, _body));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,const DeepCollectionEquality().hash(_body));

@override
String toString() {
  return 'RpcResponse.signal(status: $status, body: $body)';
}


}

/// @nodoc
abstract mixin class $SignalCopyWith<$Res> implements $RpcResponseCopyWith<$Res> {
  factory $SignalCopyWith(Signal value, $Res Function(Signal) _then) = _$SignalCopyWithImpl;
@override @useResult
$Res call({
 String status, Map<String, dynamic> body
});




}
/// @nodoc
class _$SignalCopyWithImpl<$Res>
    implements $SignalCopyWith<$Res> {
  _$SignalCopyWithImpl(this._self, this._then);

  final Signal _self;
  final $Res Function(Signal) _then;

/// Create a copy of RpcResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? body = null,}) {
  return _then(Signal(
null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,null == body ? _self._body : body // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}

/// @nodoc
@JsonSerializable()

class RpcError implements RpcResponse {
   RpcError(this.status, this.message, final  Map<String, dynamic> body, {final  String? $type}): _body = body,$type = $type ?? 'error';
  factory RpcError.fromJson(Map<String, dynamic> json) => _$RpcErrorFromJson(json);

 final  String status;
 final  String message;
 final  Map<String, dynamic> _body;
@override Map<String, dynamic> get body {
  if (_body is EqualUnmodifiableMapView) return _body;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_body);
}


@JsonKey(name: 'kind')
final String $type;


/// Create a copy of RpcResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RpcErrorCopyWith<RpcError> get copyWith => _$RpcErrorCopyWithImpl<RpcError>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RpcErrorToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RpcError&&(identical(other.status, status) || other.status == status)&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other._body, _body));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,message,const DeepCollectionEquality().hash(_body));

@override
String toString() {
  return 'RpcResponse.error(status: $status, message: $message, body: $body)';
}


}

/// @nodoc
abstract mixin class $RpcErrorCopyWith<$Res> implements $RpcResponseCopyWith<$Res> {
  factory $RpcErrorCopyWith(RpcError value, $Res Function(RpcError) _then) = _$RpcErrorCopyWithImpl;
@override @useResult
$Res call({
 String status, String message, Map<String, dynamic> body
});




}
/// @nodoc
class _$RpcErrorCopyWithImpl<$Res>
    implements $RpcErrorCopyWith<$Res> {
  _$RpcErrorCopyWithImpl(this._self, this._then);

  final RpcError _self;
  final $Res Function(RpcError) _then;

/// Create a copy of RpcResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? message = null,Object? body = null,}) {
  return _then(RpcError(
null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,null == body ? _self._body : body // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}


/// @nodoc
mixin _$RpcState {

 String get version; bool get isAdmin;
/// Create a copy of RpcState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RpcStateCopyWith<RpcState> get copyWith => _$RpcStateCopyWithImpl<RpcState>(this as RpcState, _$identity);

  /// Serializes this RpcState to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RpcState&&(identical(other.version, version) || other.version == version)&&(identical(other.isAdmin, isAdmin) || other.isAdmin == isAdmin));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,version,isAdmin);

@override
String toString() {
  return 'RpcState(version: $version, isAdmin: $isAdmin)';
}


}

/// @nodoc
abstract mixin class $RpcStateCopyWith<$Res>  {
  factory $RpcStateCopyWith(RpcState value, $Res Function(RpcState) _then) = _$RpcStateCopyWithImpl;
@useResult
$Res call({
 String version, bool isAdmin
});




}
/// @nodoc
class _$RpcStateCopyWithImpl<$Res>
    implements $RpcStateCopyWith<$Res> {
  _$RpcStateCopyWithImpl(this._self, this._then);

  final RpcState _self;
  final $Res Function(RpcState) _then;

/// Create a copy of RpcState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? version = null,Object? isAdmin = null,}) {
  return _then(_self.copyWith(
version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,isAdmin: null == isAdmin ? _self.isAdmin : isAdmin // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [RpcState].
extension RpcStatePatterns on RpcState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RpcState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RpcState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RpcState value)  $default,){
final _that = this;
switch (_that) {
case _RpcState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RpcState value)?  $default,){
final _that = this;
switch (_that) {
case _RpcState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String version,  bool isAdmin)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RpcState() when $default != null:
return $default(_that.version,_that.isAdmin);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String version,  bool isAdmin)  $default,) {final _that = this;
switch (_that) {
case _RpcState():
return $default(_that.version,_that.isAdmin);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String version,  bool isAdmin)?  $default,) {final _that = this;
switch (_that) {
case _RpcState() when $default != null:
return $default(_that.version,_that.isAdmin);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RpcState implements RpcState {
  const _RpcState(this.version, this.isAdmin);
  factory _RpcState.fromJson(Map<String, dynamic> json) => _$RpcStateFromJson(json);

@override final  String version;
@override final  bool isAdmin;

/// Create a copy of RpcState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RpcStateCopyWith<_RpcState> get copyWith => __$RpcStateCopyWithImpl<_RpcState>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RpcStateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RpcState&&(identical(other.version, version) || other.version == version)&&(identical(other.isAdmin, isAdmin) || other.isAdmin == isAdmin));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,version,isAdmin);

@override
String toString() {
  return 'RpcState(version: $version, isAdmin: $isAdmin)';
}


}

/// @nodoc
abstract mixin class _$RpcStateCopyWith<$Res> implements $RpcStateCopyWith<$Res> {
  factory _$RpcStateCopyWith(_RpcState value, $Res Function(_RpcState) _then) = __$RpcStateCopyWithImpl;
@override @useResult
$Res call({
 String version, bool isAdmin
});




}
/// @nodoc
class __$RpcStateCopyWithImpl<$Res>
    implements _$RpcStateCopyWith<$Res> {
  __$RpcStateCopyWithImpl(this._self, this._then);

  final _RpcState _self;
  final $Res Function(_RpcState) _then;

/// Create a copy of RpcState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? version = null,Object? isAdmin = null,}) {
  return _then(_RpcState(
null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,null == isAdmin ? _self.isAdmin : isAdmin // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
