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
mixin _$YubiKeyData {

 DeviceNode get node; String get name; DeviceInfo get info;
/// Create a copy of YubiKeyData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$YubiKeyDataCopyWith<YubiKeyData> get copyWith => _$YubiKeyDataCopyWithImpl<YubiKeyData>(this as YubiKeyData, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is YubiKeyData&&(identical(other.node, node) || other.node == node)&&(identical(other.name, name) || other.name == name)&&(identical(other.info, info) || other.info == info));
}


@override
int get hashCode => Object.hash(runtimeType,node,name,info);

@override
String toString() {
  return 'YubiKeyData(node: $node, name: $name, info: $info)';
}


}

/// @nodoc
abstract mixin class $YubiKeyDataCopyWith<$Res>  {
  factory $YubiKeyDataCopyWith(YubiKeyData value, $Res Function(YubiKeyData) _then) = _$YubiKeyDataCopyWithImpl;
@useResult
$Res call({
 DeviceNode node, String name, DeviceInfo info
});


$DeviceNodeCopyWith<$Res> get node;$DeviceInfoCopyWith<$Res> get info;

}
/// @nodoc
class _$YubiKeyDataCopyWithImpl<$Res>
    implements $YubiKeyDataCopyWith<$Res> {
  _$YubiKeyDataCopyWithImpl(this._self, this._then);

  final YubiKeyData _self;
  final $Res Function(YubiKeyData) _then;

/// Create a copy of YubiKeyData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? node = null,Object? name = null,Object? info = null,}) {
  return _then(_self.copyWith(
node: null == node ? _self.node : node // ignore: cast_nullable_to_non_nullable
as DeviceNode,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,info: null == info ? _self.info : info // ignore: cast_nullable_to_non_nullable
as DeviceInfo,
  ));
}
/// Create a copy of YubiKeyData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DeviceNodeCopyWith<$Res> get node {
  
  return $DeviceNodeCopyWith<$Res>(_self.node, (value) {
    return _then(_self.copyWith(node: value));
  });
}/// Create a copy of YubiKeyData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DeviceInfoCopyWith<$Res> get info {
  
  return $DeviceInfoCopyWith<$Res>(_self.info, (value) {
    return _then(_self.copyWith(info: value));
  });
}
}


/// Adds pattern-matching-related methods to [YubiKeyData].
extension YubiKeyDataPatterns on YubiKeyData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _YubiKeyData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _YubiKeyData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _YubiKeyData value)  $default,){
final _that = this;
switch (_that) {
case _YubiKeyData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _YubiKeyData value)?  $default,){
final _that = this;
switch (_that) {
case _YubiKeyData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DeviceNode node,  String name,  DeviceInfo info)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _YubiKeyData() when $default != null:
return $default(_that.node,_that.name,_that.info);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DeviceNode node,  String name,  DeviceInfo info)  $default,) {final _that = this;
switch (_that) {
case _YubiKeyData():
return $default(_that.node,_that.name,_that.info);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DeviceNode node,  String name,  DeviceInfo info)?  $default,) {final _that = this;
switch (_that) {
case _YubiKeyData() when $default != null:
return $default(_that.node,_that.name,_that.info);case _:
  return null;

}
}

}

/// @nodoc


class _YubiKeyData implements YubiKeyData {
   _YubiKeyData(this.node, this.name, this.info);
  

@override final  DeviceNode node;
@override final  String name;
@override final  DeviceInfo info;

/// Create a copy of YubiKeyData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$YubiKeyDataCopyWith<_YubiKeyData> get copyWith => __$YubiKeyDataCopyWithImpl<_YubiKeyData>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _YubiKeyData&&(identical(other.node, node) || other.node == node)&&(identical(other.name, name) || other.name == name)&&(identical(other.info, info) || other.info == info));
}


@override
int get hashCode => Object.hash(runtimeType,node,name,info);

@override
String toString() {
  return 'YubiKeyData(node: $node, name: $name, info: $info)';
}


}

/// @nodoc
abstract mixin class _$YubiKeyDataCopyWith<$Res> implements $YubiKeyDataCopyWith<$Res> {
  factory _$YubiKeyDataCopyWith(_YubiKeyData value, $Res Function(_YubiKeyData) _then) = __$YubiKeyDataCopyWithImpl;
@override @useResult
$Res call({
 DeviceNode node, String name, DeviceInfo info
});


@override $DeviceNodeCopyWith<$Res> get node;@override $DeviceInfoCopyWith<$Res> get info;

}
/// @nodoc
class __$YubiKeyDataCopyWithImpl<$Res>
    implements _$YubiKeyDataCopyWith<$Res> {
  __$YubiKeyDataCopyWithImpl(this._self, this._then);

  final _YubiKeyData _self;
  final $Res Function(_YubiKeyData) _then;

/// Create a copy of YubiKeyData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? node = null,Object? name = null,Object? info = null,}) {
  return _then(_YubiKeyData(
null == node ? _self.node : node // ignore: cast_nullable_to_non_nullable
as DeviceNode,null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,null == info ? _self.info : info // ignore: cast_nullable_to_non_nullable
as DeviceInfo,
  ));
}

/// Create a copy of YubiKeyData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DeviceNodeCopyWith<$Res> get node {
  
  return $DeviceNodeCopyWith<$Res>(_self.node, (value) {
    return _then(_self.copyWith(node: value));
  });
}/// Create a copy of YubiKeyData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DeviceInfoCopyWith<$Res> get info {
  
  return $DeviceInfoCopyWith<$Res>(_self.info, (value) {
    return _then(_self.copyWith(info: value));
  });
}
}

/// @nodoc
mixin _$DeviceNode {

 DevicePath get path; String get name;
/// Create a copy of DeviceNode
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeviceNodeCopyWith<DeviceNode> get copyWith => _$DeviceNodeCopyWithImpl<DeviceNode>(this as DeviceNode, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeviceNode&&(identical(other.path, path) || other.path == path)&&(identical(other.name, name) || other.name == name));
}


@override
int get hashCode => Object.hash(runtimeType,path,name);

@override
String toString() {
  return 'DeviceNode(path: $path, name: $name)';
}


}

/// @nodoc
abstract mixin class $DeviceNodeCopyWith<$Res>  {
  factory $DeviceNodeCopyWith(DeviceNode value, $Res Function(DeviceNode) _then) = _$DeviceNodeCopyWithImpl;
@useResult
$Res call({
 DevicePath path, String name
});




}
/// @nodoc
class _$DeviceNodeCopyWithImpl<$Res>
    implements $DeviceNodeCopyWith<$Res> {
  _$DeviceNodeCopyWithImpl(this._self, this._then);

  final DeviceNode _self;
  final $Res Function(DeviceNode) _then;

/// Create a copy of DeviceNode
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? path = null,Object? name = null,}) {
  return _then(_self.copyWith(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as DevicePath,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [DeviceNode].
extension DeviceNodePatterns on DeviceNode {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( UsbYubiKeyNode value)?  usbYubiKey,TResult Function( NfcReaderNode value)?  nfcReader,required TResult orElse(),}){
final _that = this;
switch (_that) {
case UsbYubiKeyNode() when usbYubiKey != null:
return usbYubiKey(_that);case NfcReaderNode() when nfcReader != null:
return nfcReader(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( UsbYubiKeyNode value)  usbYubiKey,required TResult Function( NfcReaderNode value)  nfcReader,}){
final _that = this;
switch (_that) {
case UsbYubiKeyNode():
return usbYubiKey(_that);case NfcReaderNode():
return nfcReader(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( UsbYubiKeyNode value)?  usbYubiKey,TResult? Function( NfcReaderNode value)?  nfcReader,}){
final _that = this;
switch (_that) {
case UsbYubiKeyNode() when usbYubiKey != null:
return usbYubiKey(_that);case NfcReaderNode() when nfcReader != null:
return nfcReader(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( DevicePath path,  String name,  UsbPid pid,  DeviceInfo? info)?  usbYubiKey,TResult Function( DevicePath path,  String name)?  nfcReader,required TResult orElse(),}) {final _that = this;
switch (_that) {
case UsbYubiKeyNode() when usbYubiKey != null:
return usbYubiKey(_that.path,_that.name,_that.pid,_that.info);case NfcReaderNode() when nfcReader != null:
return nfcReader(_that.path,_that.name);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( DevicePath path,  String name,  UsbPid pid,  DeviceInfo? info)  usbYubiKey,required TResult Function( DevicePath path,  String name)  nfcReader,}) {final _that = this;
switch (_that) {
case UsbYubiKeyNode():
return usbYubiKey(_that.path,_that.name,_that.pid,_that.info);case NfcReaderNode():
return nfcReader(_that.path,_that.name);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( DevicePath path,  String name,  UsbPid pid,  DeviceInfo? info)?  usbYubiKey,TResult? Function( DevicePath path,  String name)?  nfcReader,}) {final _that = this;
switch (_that) {
case UsbYubiKeyNode() when usbYubiKey != null:
return usbYubiKey(_that.path,_that.name,_that.pid,_that.info);case NfcReaderNode() when nfcReader != null:
return nfcReader(_that.path,_that.name);case _:
  return null;

}
}

}

/// @nodoc


class UsbYubiKeyNode extends DeviceNode {
   UsbYubiKeyNode(this.path, this.name, this.pid, this.info): super._();
  

@override final  DevicePath path;
@override final  String name;
 final  UsbPid pid;
 final  DeviceInfo? info;

/// Create a copy of DeviceNode
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UsbYubiKeyNodeCopyWith<UsbYubiKeyNode> get copyWith => _$UsbYubiKeyNodeCopyWithImpl<UsbYubiKeyNode>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UsbYubiKeyNode&&(identical(other.path, path) || other.path == path)&&(identical(other.name, name) || other.name == name)&&(identical(other.pid, pid) || other.pid == pid)&&(identical(other.info, info) || other.info == info));
}


@override
int get hashCode => Object.hash(runtimeType,path,name,pid,info);

@override
String toString() {
  return 'DeviceNode.usbYubiKey(path: $path, name: $name, pid: $pid, info: $info)';
}


}

/// @nodoc
abstract mixin class $UsbYubiKeyNodeCopyWith<$Res> implements $DeviceNodeCopyWith<$Res> {
  factory $UsbYubiKeyNodeCopyWith(UsbYubiKeyNode value, $Res Function(UsbYubiKeyNode) _then) = _$UsbYubiKeyNodeCopyWithImpl;
@override @useResult
$Res call({
 DevicePath path, String name, UsbPid pid, DeviceInfo? info
});


$DeviceInfoCopyWith<$Res>? get info;

}
/// @nodoc
class _$UsbYubiKeyNodeCopyWithImpl<$Res>
    implements $UsbYubiKeyNodeCopyWith<$Res> {
  _$UsbYubiKeyNodeCopyWithImpl(this._self, this._then);

  final UsbYubiKeyNode _self;
  final $Res Function(UsbYubiKeyNode) _then;

/// Create a copy of DeviceNode
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? path = null,Object? name = null,Object? pid = null,Object? info = freezed,}) {
  return _then(UsbYubiKeyNode(
null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as DevicePath,null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,null == pid ? _self.pid : pid // ignore: cast_nullable_to_non_nullable
as UsbPid,freezed == info ? _self.info : info // ignore: cast_nullable_to_non_nullable
as DeviceInfo?,
  ));
}

/// Create a copy of DeviceNode
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DeviceInfoCopyWith<$Res>? get info {
    if (_self.info == null) {
    return null;
  }

  return $DeviceInfoCopyWith<$Res>(_self.info!, (value) {
    return _then(_self.copyWith(info: value));
  });
}
}

/// @nodoc


class NfcReaderNode extends DeviceNode {
   NfcReaderNode(this.path, this.name): super._();
  

@override final  DevicePath path;
@override final  String name;

/// Create a copy of DeviceNode
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NfcReaderNodeCopyWith<NfcReaderNode> get copyWith => _$NfcReaderNodeCopyWithImpl<NfcReaderNode>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NfcReaderNode&&(identical(other.path, path) || other.path == path)&&(identical(other.name, name) || other.name == name));
}


@override
int get hashCode => Object.hash(runtimeType,path,name);

@override
String toString() {
  return 'DeviceNode.nfcReader(path: $path, name: $name)';
}


}

/// @nodoc
abstract mixin class $NfcReaderNodeCopyWith<$Res> implements $DeviceNodeCopyWith<$Res> {
  factory $NfcReaderNodeCopyWith(NfcReaderNode value, $Res Function(NfcReaderNode) _then) = _$NfcReaderNodeCopyWithImpl;
@override @useResult
$Res call({
 DevicePath path, String name
});




}
/// @nodoc
class _$NfcReaderNodeCopyWithImpl<$Res>
    implements $NfcReaderNodeCopyWith<$Res> {
  _$NfcReaderNodeCopyWithImpl(this._self, this._then);

  final NfcReaderNode _self;
  final $Res Function(NfcReaderNode) _then;

/// Create a copy of DeviceNode
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? path = null,Object? name = null,}) {
  return _then(NfcReaderNode(
null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as DevicePath,null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$ActionItem {

 Widget get icon; String get title; String? get subtitle; String? get shortcut; Widget? get trailing; Intent? get intent; ActionStyle? get actionStyle; Key? get key; Feature? get feature;
/// Create a copy of ActionItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ActionItemCopyWith<ActionItem> get copyWith => _$ActionItemCopyWithImpl<ActionItem>(this as ActionItem, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ActionItem&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.title, title) || other.title == title)&&(identical(other.subtitle, subtitle) || other.subtitle == subtitle)&&(identical(other.shortcut, shortcut) || other.shortcut == shortcut)&&(identical(other.trailing, trailing) || other.trailing == trailing)&&(identical(other.intent, intent) || other.intent == intent)&&(identical(other.actionStyle, actionStyle) || other.actionStyle == actionStyle)&&(identical(other.key, key) || other.key == key)&&(identical(other.feature, feature) || other.feature == feature));
}


@override
int get hashCode => Object.hash(runtimeType,icon,title,subtitle,shortcut,trailing,intent,actionStyle,key,feature);

@override
String toString() {
  return 'ActionItem(icon: $icon, title: $title, subtitle: $subtitle, shortcut: $shortcut, trailing: $trailing, intent: $intent, actionStyle: $actionStyle, key: $key, feature: $feature)';
}


}

/// @nodoc
abstract mixin class $ActionItemCopyWith<$Res>  {
  factory $ActionItemCopyWith(ActionItem value, $Res Function(ActionItem) _then) = _$ActionItemCopyWithImpl;
@useResult
$Res call({
 Widget icon, String title, String? subtitle, String? shortcut, Widget? trailing, Intent? intent, ActionStyle? actionStyle, Key? key, Feature? feature
});




}
/// @nodoc
class _$ActionItemCopyWithImpl<$Res>
    implements $ActionItemCopyWith<$Res> {
  _$ActionItemCopyWithImpl(this._self, this._then);

  final ActionItem _self;
  final $Res Function(ActionItem) _then;

/// Create a copy of ActionItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? icon = null,Object? title = null,Object? subtitle = freezed,Object? shortcut = freezed,Object? trailing = freezed,Object? intent = freezed,Object? actionStyle = freezed,Object? key = freezed,Object? feature = freezed,}) {
  return _then(_self.copyWith(
icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as Widget,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,subtitle: freezed == subtitle ? _self.subtitle : subtitle // ignore: cast_nullable_to_non_nullable
as String?,shortcut: freezed == shortcut ? _self.shortcut : shortcut // ignore: cast_nullable_to_non_nullable
as String?,trailing: freezed == trailing ? _self.trailing : trailing // ignore: cast_nullable_to_non_nullable
as Widget?,intent: freezed == intent ? _self.intent : intent // ignore: cast_nullable_to_non_nullable
as Intent?,actionStyle: freezed == actionStyle ? _self.actionStyle : actionStyle // ignore: cast_nullable_to_non_nullable
as ActionStyle?,key: freezed == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as Key?,feature: freezed == feature ? _self.feature : feature // ignore: cast_nullable_to_non_nullable
as Feature?,
  ));
}

}


/// Adds pattern-matching-related methods to [ActionItem].
extension ActionItemPatterns on ActionItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ActionItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ActionItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ActionItem value)  $default,){
final _that = this;
switch (_that) {
case _ActionItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ActionItem value)?  $default,){
final _that = this;
switch (_that) {
case _ActionItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Widget icon,  String title,  String? subtitle,  String? shortcut,  Widget? trailing,  Intent? intent,  ActionStyle? actionStyle,  Key? key,  Feature? feature)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ActionItem() when $default != null:
return $default(_that.icon,_that.title,_that.subtitle,_that.shortcut,_that.trailing,_that.intent,_that.actionStyle,_that.key,_that.feature);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Widget icon,  String title,  String? subtitle,  String? shortcut,  Widget? trailing,  Intent? intent,  ActionStyle? actionStyle,  Key? key,  Feature? feature)  $default,) {final _that = this;
switch (_that) {
case _ActionItem():
return $default(_that.icon,_that.title,_that.subtitle,_that.shortcut,_that.trailing,_that.intent,_that.actionStyle,_that.key,_that.feature);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Widget icon,  String title,  String? subtitle,  String? shortcut,  Widget? trailing,  Intent? intent,  ActionStyle? actionStyle,  Key? key,  Feature? feature)?  $default,) {final _that = this;
switch (_that) {
case _ActionItem() when $default != null:
return $default(_that.icon,_that.title,_that.subtitle,_that.shortcut,_that.trailing,_that.intent,_that.actionStyle,_that.key,_that.feature);case _:
  return null;

}
}

}

/// @nodoc


class _ActionItem implements ActionItem {
   _ActionItem({required this.icon, required this.title, this.subtitle, this.shortcut, this.trailing, this.intent, this.actionStyle, this.key, this.feature});
  

@override final  Widget icon;
@override final  String title;
@override final  String? subtitle;
@override final  String? shortcut;
@override final  Widget? trailing;
@override final  Intent? intent;
@override final  ActionStyle? actionStyle;
@override final  Key? key;
@override final  Feature? feature;

/// Create a copy of ActionItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ActionItemCopyWith<_ActionItem> get copyWith => __$ActionItemCopyWithImpl<_ActionItem>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ActionItem&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.title, title) || other.title == title)&&(identical(other.subtitle, subtitle) || other.subtitle == subtitle)&&(identical(other.shortcut, shortcut) || other.shortcut == shortcut)&&(identical(other.trailing, trailing) || other.trailing == trailing)&&(identical(other.intent, intent) || other.intent == intent)&&(identical(other.actionStyle, actionStyle) || other.actionStyle == actionStyle)&&(identical(other.key, key) || other.key == key)&&(identical(other.feature, feature) || other.feature == feature));
}


@override
int get hashCode => Object.hash(runtimeType,icon,title,subtitle,shortcut,trailing,intent,actionStyle,key,feature);

@override
String toString() {
  return 'ActionItem(icon: $icon, title: $title, subtitle: $subtitle, shortcut: $shortcut, trailing: $trailing, intent: $intent, actionStyle: $actionStyle, key: $key, feature: $feature)';
}


}

/// @nodoc
abstract mixin class _$ActionItemCopyWith<$Res> implements $ActionItemCopyWith<$Res> {
  factory _$ActionItemCopyWith(_ActionItem value, $Res Function(_ActionItem) _then) = __$ActionItemCopyWithImpl;
@override @useResult
$Res call({
 Widget icon, String title, String? subtitle, String? shortcut, Widget? trailing, Intent? intent, ActionStyle? actionStyle, Key? key, Feature? feature
});




}
/// @nodoc
class __$ActionItemCopyWithImpl<$Res>
    implements _$ActionItemCopyWith<$Res> {
  __$ActionItemCopyWithImpl(this._self, this._then);

  final _ActionItem _self;
  final $Res Function(_ActionItem) _then;

/// Create a copy of ActionItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? icon = null,Object? title = null,Object? subtitle = freezed,Object? shortcut = freezed,Object? trailing = freezed,Object? intent = freezed,Object? actionStyle = freezed,Object? key = freezed,Object? feature = freezed,}) {
  return _then(_ActionItem(
icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as Widget,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,subtitle: freezed == subtitle ? _self.subtitle : subtitle // ignore: cast_nullable_to_non_nullable
as String?,shortcut: freezed == shortcut ? _self.shortcut : shortcut // ignore: cast_nullable_to_non_nullable
as String?,trailing: freezed == trailing ? _self.trailing : trailing // ignore: cast_nullable_to_non_nullable
as Widget?,intent: freezed == intent ? _self.intent : intent // ignore: cast_nullable_to_non_nullable
as Intent?,actionStyle: freezed == actionStyle ? _self.actionStyle : actionStyle // ignore: cast_nullable_to_non_nullable
as ActionStyle?,key: freezed == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as Key?,feature: freezed == feature ? _self.feature : feature // ignore: cast_nullable_to_non_nullable
as Feature?,
  ));
}


}

/// @nodoc
mixin _$WindowState {

 bool get focused; bool get visible; bool get active; bool get hidden;
/// Create a copy of WindowState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WindowStateCopyWith<WindowState> get copyWith => _$WindowStateCopyWithImpl<WindowState>(this as WindowState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WindowState&&(identical(other.focused, focused) || other.focused == focused)&&(identical(other.visible, visible) || other.visible == visible)&&(identical(other.active, active) || other.active == active)&&(identical(other.hidden, hidden) || other.hidden == hidden));
}


@override
int get hashCode => Object.hash(runtimeType,focused,visible,active,hidden);

@override
String toString() {
  return 'WindowState(focused: $focused, visible: $visible, active: $active, hidden: $hidden)';
}


}

/// @nodoc
abstract mixin class $WindowStateCopyWith<$Res>  {
  factory $WindowStateCopyWith(WindowState value, $Res Function(WindowState) _then) = _$WindowStateCopyWithImpl;
@useResult
$Res call({
 bool focused, bool visible, bool active, bool hidden
});




}
/// @nodoc
class _$WindowStateCopyWithImpl<$Res>
    implements $WindowStateCopyWith<$Res> {
  _$WindowStateCopyWithImpl(this._self, this._then);

  final WindowState _self;
  final $Res Function(WindowState) _then;

/// Create a copy of WindowState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? focused = null,Object? visible = null,Object? active = null,Object? hidden = null,}) {
  return _then(_self.copyWith(
focused: null == focused ? _self.focused : focused // ignore: cast_nullable_to_non_nullable
as bool,visible: null == visible ? _self.visible : visible // ignore: cast_nullable_to_non_nullable
as bool,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as bool,hidden: null == hidden ? _self.hidden : hidden // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [WindowState].
extension WindowStatePatterns on WindowState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WindowState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WindowState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WindowState value)  $default,){
final _that = this;
switch (_that) {
case _WindowState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WindowState value)?  $default,){
final _that = this;
switch (_that) {
case _WindowState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool focused,  bool visible,  bool active,  bool hidden)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WindowState() when $default != null:
return $default(_that.focused,_that.visible,_that.active,_that.hidden);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool focused,  bool visible,  bool active,  bool hidden)  $default,) {final _that = this;
switch (_that) {
case _WindowState():
return $default(_that.focused,_that.visible,_that.active,_that.hidden);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool focused,  bool visible,  bool active,  bool hidden)?  $default,) {final _that = this;
switch (_that) {
case _WindowState() when $default != null:
return $default(_that.focused,_that.visible,_that.active,_that.hidden);case _:
  return null;

}
}

}

/// @nodoc


class _WindowState implements WindowState {
   _WindowState({required this.focused, required this.visible, required this.active, this.hidden = false});
  

@override final  bool focused;
@override final  bool visible;
@override final  bool active;
@override@JsonKey() final  bool hidden;

/// Create a copy of WindowState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WindowStateCopyWith<_WindowState> get copyWith => __$WindowStateCopyWithImpl<_WindowState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WindowState&&(identical(other.focused, focused) || other.focused == focused)&&(identical(other.visible, visible) || other.visible == visible)&&(identical(other.active, active) || other.active == active)&&(identical(other.hidden, hidden) || other.hidden == hidden));
}


@override
int get hashCode => Object.hash(runtimeType,focused,visible,active,hidden);

@override
String toString() {
  return 'WindowState(focused: $focused, visible: $visible, active: $active, hidden: $hidden)';
}


}

/// @nodoc
abstract mixin class _$WindowStateCopyWith<$Res> implements $WindowStateCopyWith<$Res> {
  factory _$WindowStateCopyWith(_WindowState value, $Res Function(_WindowState) _then) = __$WindowStateCopyWithImpl;
@override @useResult
$Res call({
 bool focused, bool visible, bool active, bool hidden
});




}
/// @nodoc
class __$WindowStateCopyWithImpl<$Res>
    implements _$WindowStateCopyWith<$Res> {
  __$WindowStateCopyWithImpl(this._self, this._then);

  final _WindowState _self;
  final $Res Function(_WindowState) _then;

/// Create a copy of WindowState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? focused = null,Object? visible = null,Object? active = null,Object? hidden = null,}) {
  return _then(_WindowState(
focused: null == focused ? _self.focused : focused // ignore: cast_nullable_to_non_nullable
as bool,visible: null == visible ? _self.visible : visible // ignore: cast_nullable_to_non_nullable
as bool,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as bool,hidden: null == hidden ? _self.hidden : hidden // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$KeyCustomization {

 int get serial;@JsonKey(includeIfNull: false) String? get name;@JsonKey(includeIfNull: false)@_ColorConverter() Color? get color;
/// Create a copy of KeyCustomization
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$KeyCustomizationCopyWith<KeyCustomization> get copyWith => _$KeyCustomizationCopyWithImpl<KeyCustomization>(this as KeyCustomization, _$identity);

  /// Serializes this KeyCustomization to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is KeyCustomization&&(identical(other.serial, serial) || other.serial == serial)&&(identical(other.name, name) || other.name == name)&&(identical(other.color, color) || other.color == color));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,serial,name,color);

@override
String toString() {
  return 'KeyCustomization(serial: $serial, name: $name, color: $color)';
}


}

/// @nodoc
abstract mixin class $KeyCustomizationCopyWith<$Res>  {
  factory $KeyCustomizationCopyWith(KeyCustomization value, $Res Function(KeyCustomization) _then) = _$KeyCustomizationCopyWithImpl;
@useResult
$Res call({
 int serial,@JsonKey(includeIfNull: false) String? name,@JsonKey(includeIfNull: false)@_ColorConverter() Color? color
});




}
/// @nodoc
class _$KeyCustomizationCopyWithImpl<$Res>
    implements $KeyCustomizationCopyWith<$Res> {
  _$KeyCustomizationCopyWithImpl(this._self, this._then);

  final KeyCustomization _self;
  final $Res Function(KeyCustomization) _then;

/// Create a copy of KeyCustomization
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? serial = null,Object? name = freezed,Object? color = freezed,}) {
  return _then(_self.copyWith(
serial: null == serial ? _self.serial : serial // ignore: cast_nullable_to_non_nullable
as int,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as Color?,
  ));
}

}


/// Adds pattern-matching-related methods to [KeyCustomization].
extension KeyCustomizationPatterns on KeyCustomization {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _KeyCustomization value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _KeyCustomization() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _KeyCustomization value)  $default,){
final _that = this;
switch (_that) {
case _KeyCustomization():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _KeyCustomization value)?  $default,){
final _that = this;
switch (_that) {
case _KeyCustomization() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int serial, @JsonKey(includeIfNull: false)  String? name, @JsonKey(includeIfNull: false)@_ColorConverter()  Color? color)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _KeyCustomization() when $default != null:
return $default(_that.serial,_that.name,_that.color);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int serial, @JsonKey(includeIfNull: false)  String? name, @JsonKey(includeIfNull: false)@_ColorConverter()  Color? color)  $default,) {final _that = this;
switch (_that) {
case _KeyCustomization():
return $default(_that.serial,_that.name,_that.color);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int serial, @JsonKey(includeIfNull: false)  String? name, @JsonKey(includeIfNull: false)@_ColorConverter()  Color? color)?  $default,) {final _that = this;
switch (_that) {
case _KeyCustomization() when $default != null:
return $default(_that.serial,_that.name,_that.color);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _KeyCustomization implements KeyCustomization {
   _KeyCustomization({required this.serial, @JsonKey(includeIfNull: false) this.name, @JsonKey(includeIfNull: false)@_ColorConverter() this.color});
  factory _KeyCustomization.fromJson(Map<String, dynamic> json) => _$KeyCustomizationFromJson(json);

@override final  int serial;
@override@JsonKey(includeIfNull: false) final  String? name;
@override@JsonKey(includeIfNull: false)@_ColorConverter() final  Color? color;

/// Create a copy of KeyCustomization
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$KeyCustomizationCopyWith<_KeyCustomization> get copyWith => __$KeyCustomizationCopyWithImpl<_KeyCustomization>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$KeyCustomizationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _KeyCustomization&&(identical(other.serial, serial) || other.serial == serial)&&(identical(other.name, name) || other.name == name)&&(identical(other.color, color) || other.color == color));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,serial,name,color);

@override
String toString() {
  return 'KeyCustomization(serial: $serial, name: $name, color: $color)';
}


}

/// @nodoc
abstract mixin class _$KeyCustomizationCopyWith<$Res> implements $KeyCustomizationCopyWith<$Res> {
  factory _$KeyCustomizationCopyWith(_KeyCustomization value, $Res Function(_KeyCustomization) _then) = __$KeyCustomizationCopyWithImpl;
@override @useResult
$Res call({
 int serial,@JsonKey(includeIfNull: false) String? name,@JsonKey(includeIfNull: false)@_ColorConverter() Color? color
});




}
/// @nodoc
class __$KeyCustomizationCopyWithImpl<$Res>
    implements _$KeyCustomizationCopyWith<$Res> {
  __$KeyCustomizationCopyWithImpl(this._self, this._then);

  final _KeyCustomization _self;
  final $Res Function(_KeyCustomization) _then;

/// Create a copy of KeyCustomization
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? serial = null,Object? name = freezed,Object? color = freezed,}) {
  return _then(_KeyCustomization(
serial: null == serial ? _self.serial : serial // ignore: cast_nullable_to_non_nullable
as int,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as Color?,
  ));
}


}


/// @nodoc
mixin _$LocaleStatus {

 int get translated; int get proofread;
/// Create a copy of LocaleStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LocaleStatusCopyWith<LocaleStatus> get copyWith => _$LocaleStatusCopyWithImpl<LocaleStatus>(this as LocaleStatus, _$identity);

  /// Serializes this LocaleStatus to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LocaleStatus&&(identical(other.translated, translated) || other.translated == translated)&&(identical(other.proofread, proofread) || other.proofread == proofread));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,translated,proofread);

@override
String toString() {
  return 'LocaleStatus(translated: $translated, proofread: $proofread)';
}


}

/// @nodoc
abstract mixin class $LocaleStatusCopyWith<$Res>  {
  factory $LocaleStatusCopyWith(LocaleStatus value, $Res Function(LocaleStatus) _then) = _$LocaleStatusCopyWithImpl;
@useResult
$Res call({
 int translated, int proofread
});




}
/// @nodoc
class _$LocaleStatusCopyWithImpl<$Res>
    implements $LocaleStatusCopyWith<$Res> {
  _$LocaleStatusCopyWithImpl(this._self, this._then);

  final LocaleStatus _self;
  final $Res Function(LocaleStatus) _then;

/// Create a copy of LocaleStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? translated = null,Object? proofread = null,}) {
  return _then(_self.copyWith(
translated: null == translated ? _self.translated : translated // ignore: cast_nullable_to_non_nullable
as int,proofread: null == proofread ? _self.proofread : proofread // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [LocaleStatus].
extension LocaleStatusPatterns on LocaleStatus {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LocaleStatus value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LocaleStatus() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LocaleStatus value)  $default,){
final _that = this;
switch (_that) {
case _LocaleStatus():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LocaleStatus value)?  $default,){
final _that = this;
switch (_that) {
case _LocaleStatus() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int translated,  int proofread)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LocaleStatus() when $default != null:
return $default(_that.translated,_that.proofread);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int translated,  int proofread)  $default,) {final _that = this;
switch (_that) {
case _LocaleStatus():
return $default(_that.translated,_that.proofread);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int translated,  int proofread)?  $default,) {final _that = this;
switch (_that) {
case _LocaleStatus() when $default != null:
return $default(_that.translated,_that.proofread);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LocaleStatus implements LocaleStatus {
   _LocaleStatus({required this.translated, required this.proofread});
  factory _LocaleStatus.fromJson(Map<String, dynamic> json) => _$LocaleStatusFromJson(json);

@override final  int translated;
@override final  int proofread;

/// Create a copy of LocaleStatus
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LocaleStatusCopyWith<_LocaleStatus> get copyWith => __$LocaleStatusCopyWithImpl<_LocaleStatus>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LocaleStatusToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LocaleStatus&&(identical(other.translated, translated) || other.translated == translated)&&(identical(other.proofread, proofread) || other.proofread == proofread));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,translated,proofread);

@override
String toString() {
  return 'LocaleStatus(translated: $translated, proofread: $proofread)';
}


}

/// @nodoc
abstract mixin class _$LocaleStatusCopyWith<$Res> implements $LocaleStatusCopyWith<$Res> {
  factory _$LocaleStatusCopyWith(_LocaleStatus value, $Res Function(_LocaleStatus) _then) = __$LocaleStatusCopyWithImpl;
@override @useResult
$Res call({
 int translated, int proofread
});




}
/// @nodoc
class __$LocaleStatusCopyWithImpl<$Res>
    implements _$LocaleStatusCopyWith<$Res> {
  __$LocaleStatusCopyWithImpl(this._self, this._then);

  final _LocaleStatus _self;
  final $Res Function(_LocaleStatus) _then;

/// Create a copy of LocaleStatus
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? translated = null,Object? proofread = null,}) {
  return _then(_LocaleStatus(
translated: null == translated ? _self.translated : translated // ignore: cast_nullable_to_non_nullable
as int,proofread: null == proofread ? _self.proofread : proofread // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
