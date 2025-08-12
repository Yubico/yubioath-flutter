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
mixin _$NfcOverlayWidgetProperties {

 Widget get child; bool get visible; bool get hasCloseButton;
/// Create a copy of NfcOverlayWidgetProperties
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NfcOverlayWidgetPropertiesCopyWith<NfcOverlayWidgetProperties> get copyWith => _$NfcOverlayWidgetPropertiesCopyWithImpl<NfcOverlayWidgetProperties>(this as NfcOverlayWidgetProperties, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NfcOverlayWidgetProperties&&(identical(other.child, child) || other.child == child)&&(identical(other.visible, visible) || other.visible == visible)&&(identical(other.hasCloseButton, hasCloseButton) || other.hasCloseButton == hasCloseButton));
}


@override
int get hashCode => Object.hash(runtimeType,child,visible,hasCloseButton);

@override
String toString() {
  return 'NfcOverlayWidgetProperties(child: $child, visible: $visible, hasCloseButton: $hasCloseButton)';
}


}

/// @nodoc
abstract mixin class $NfcOverlayWidgetPropertiesCopyWith<$Res>  {
  factory $NfcOverlayWidgetPropertiesCopyWith(NfcOverlayWidgetProperties value, $Res Function(NfcOverlayWidgetProperties) _then) = _$NfcOverlayWidgetPropertiesCopyWithImpl;
@useResult
$Res call({
 Widget child, bool visible, bool hasCloseButton
});




}
/// @nodoc
class _$NfcOverlayWidgetPropertiesCopyWithImpl<$Res>
    implements $NfcOverlayWidgetPropertiesCopyWith<$Res> {
  _$NfcOverlayWidgetPropertiesCopyWithImpl(this._self, this._then);

  final NfcOverlayWidgetProperties _self;
  final $Res Function(NfcOverlayWidgetProperties) _then;

/// Create a copy of NfcOverlayWidgetProperties
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? child = null,Object? visible = null,Object? hasCloseButton = null,}) {
  return _then(_self.copyWith(
child: null == child ? _self.child : child // ignore: cast_nullable_to_non_nullable
as Widget,visible: null == visible ? _self.visible : visible // ignore: cast_nullable_to_non_nullable
as bool,hasCloseButton: null == hasCloseButton ? _self.hasCloseButton : hasCloseButton // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [NfcOverlayWidgetProperties].
extension NfcOverlayWidgetPropertiesPatterns on NfcOverlayWidgetProperties {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NfcOverlayWidgetProperties value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NfcOverlayWidgetProperties() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NfcOverlayWidgetProperties value)  $default,){
final _that = this;
switch (_that) {
case _NfcOverlayWidgetProperties():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NfcOverlayWidgetProperties value)?  $default,){
final _that = this;
switch (_that) {
case _NfcOverlayWidgetProperties() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Widget child,  bool visible,  bool hasCloseButton)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NfcOverlayWidgetProperties() when $default != null:
return $default(_that.child,_that.visible,_that.hasCloseButton);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Widget child,  bool visible,  bool hasCloseButton)  $default,) {final _that = this;
switch (_that) {
case _NfcOverlayWidgetProperties():
return $default(_that.child,_that.visible,_that.hasCloseButton);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Widget child,  bool visible,  bool hasCloseButton)?  $default,) {final _that = this;
switch (_that) {
case _NfcOverlayWidgetProperties() when $default != null:
return $default(_that.child,_that.visible,_that.hasCloseButton);case _:
  return null;

}
}

}

/// @nodoc


class _NfcOverlayWidgetProperties implements NfcOverlayWidgetProperties {
   _NfcOverlayWidgetProperties({required this.child, this.visible = false, this.hasCloseButton = false});
  

@override final  Widget child;
@override@JsonKey() final  bool visible;
@override@JsonKey() final  bool hasCloseButton;

/// Create a copy of NfcOverlayWidgetProperties
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NfcOverlayWidgetPropertiesCopyWith<_NfcOverlayWidgetProperties> get copyWith => __$NfcOverlayWidgetPropertiesCopyWithImpl<_NfcOverlayWidgetProperties>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NfcOverlayWidgetProperties&&(identical(other.child, child) || other.child == child)&&(identical(other.visible, visible) || other.visible == visible)&&(identical(other.hasCloseButton, hasCloseButton) || other.hasCloseButton == hasCloseButton));
}


@override
int get hashCode => Object.hash(runtimeType,child,visible,hasCloseButton);

@override
String toString() {
  return 'NfcOverlayWidgetProperties(child: $child, visible: $visible, hasCloseButton: $hasCloseButton)';
}


}

/// @nodoc
abstract mixin class _$NfcOverlayWidgetPropertiesCopyWith<$Res> implements $NfcOverlayWidgetPropertiesCopyWith<$Res> {
  factory _$NfcOverlayWidgetPropertiesCopyWith(_NfcOverlayWidgetProperties value, $Res Function(_NfcOverlayWidgetProperties) _then) = __$NfcOverlayWidgetPropertiesCopyWithImpl;
@override @useResult
$Res call({
 Widget child, bool visible, bool hasCloseButton
});




}
/// @nodoc
class __$NfcOverlayWidgetPropertiesCopyWithImpl<$Res>
    implements _$NfcOverlayWidgetPropertiesCopyWith<$Res> {
  __$NfcOverlayWidgetPropertiesCopyWithImpl(this._self, this._then);

  final _NfcOverlayWidgetProperties _self;
  final $Res Function(_NfcOverlayWidgetProperties) _then;

/// Create a copy of NfcOverlayWidgetProperties
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? child = null,Object? visible = null,Object? hasCloseButton = null,}) {
  return _then(_NfcOverlayWidgetProperties(
child: null == child ? _self.child : child // ignore: cast_nullable_to_non_nullable
as Widget,visible: null == visible ? _self.visible : visible // ignore: cast_nullable_to_non_nullable
as bool,hasCloseButton: null == hasCloseButton ? _self.hasCloseButton : hasCloseButton // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
