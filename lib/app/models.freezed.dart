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

DeviceNode _$DeviceNodeFromJson(Map<String, dynamic> json) {
  return _DeviceNode.fromJson(json);
}

/// @nodoc
class _$DeviceNodeTearOff {
  const _$DeviceNodeTearOff();

  _DeviceNode call(List<String> path, int pid, Transport transport, String name,
      DeviceInfo info) {
    return _DeviceNode(
      path,
      pid,
      transport,
      name,
      info,
    );
  }

  DeviceNode fromJson(Map<String, Object?> json) {
    return DeviceNode.fromJson(json);
  }
}

/// @nodoc
const $DeviceNode = _$DeviceNodeTearOff();

/// @nodoc
mixin _$DeviceNode {
  List<String> get path => throw _privateConstructorUsedError;
  int get pid => throw _privateConstructorUsedError;
  Transport get transport => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  DeviceInfo get info => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $DeviceNodeCopyWith<DeviceNode> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DeviceNodeCopyWith<$Res> {
  factory $DeviceNodeCopyWith(
          DeviceNode value, $Res Function(DeviceNode) then) =
      _$DeviceNodeCopyWithImpl<$Res>;
  $Res call(
      {List<String> path,
      int pid,
      Transport transport,
      String name,
      DeviceInfo info});

  $DeviceInfoCopyWith<$Res> get info;
}

/// @nodoc
class _$DeviceNodeCopyWithImpl<$Res> implements $DeviceNodeCopyWith<$Res> {
  _$DeviceNodeCopyWithImpl(this._value, this._then);

  final DeviceNode _value;
  // ignore: unused_field
  final $Res Function(DeviceNode) _then;

  @override
  $Res call({
    Object? path = freezed,
    Object? pid = freezed,
    Object? transport = freezed,
    Object? name = freezed,
    Object? info = freezed,
  }) {
    return _then(_value.copyWith(
      path: path == freezed
          ? _value.path
          : path // ignore: cast_nullable_to_non_nullable
              as List<String>,
      pid: pid == freezed
          ? _value.pid
          : pid // ignore: cast_nullable_to_non_nullable
              as int,
      transport: transport == freezed
          ? _value.transport
          : transport // ignore: cast_nullable_to_non_nullable
              as Transport,
      name: name == freezed
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      info: info == freezed
          ? _value.info
          : info // ignore: cast_nullable_to_non_nullable
              as DeviceInfo,
    ));
  }

  @override
  $DeviceInfoCopyWith<$Res> get info {
    return $DeviceInfoCopyWith<$Res>(_value.info, (value) {
      return _then(_value.copyWith(info: value));
    });
  }
}

/// @nodoc
abstract class _$DeviceNodeCopyWith<$Res> implements $DeviceNodeCopyWith<$Res> {
  factory _$DeviceNodeCopyWith(
          _DeviceNode value, $Res Function(_DeviceNode) then) =
      __$DeviceNodeCopyWithImpl<$Res>;
  @override
  $Res call(
      {List<String> path,
      int pid,
      Transport transport,
      String name,
      DeviceInfo info});

  @override
  $DeviceInfoCopyWith<$Res> get info;
}

/// @nodoc
class __$DeviceNodeCopyWithImpl<$Res> extends _$DeviceNodeCopyWithImpl<$Res>
    implements _$DeviceNodeCopyWith<$Res> {
  __$DeviceNodeCopyWithImpl(
      _DeviceNode _value, $Res Function(_DeviceNode) _then)
      : super(_value, (v) => _then(v as _DeviceNode));

  @override
  _DeviceNode get _value => super._value as _DeviceNode;

  @override
  $Res call({
    Object? path = freezed,
    Object? pid = freezed,
    Object? transport = freezed,
    Object? name = freezed,
    Object? info = freezed,
  }) {
    return _then(_DeviceNode(
      path == freezed
          ? _value.path
          : path // ignore: cast_nullable_to_non_nullable
              as List<String>,
      pid == freezed
          ? _value.pid
          : pid // ignore: cast_nullable_to_non_nullable
              as int,
      transport == freezed
          ? _value.transport
          : transport // ignore: cast_nullable_to_non_nullable
              as Transport,
      name == freezed
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      info == freezed
          ? _value.info
          : info // ignore: cast_nullable_to_non_nullable
              as DeviceInfo,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$_DeviceNode implements _DeviceNode {
  _$_DeviceNode(this.path, this.pid, this.transport, this.name, this.info);

  factory _$_DeviceNode.fromJson(Map<String, dynamic> json) =>
      _$$_DeviceNodeFromJson(json);

  @override
  final List<String> path;
  @override
  final int pid;
  @override
  final Transport transport;
  @override
  final String name;
  @override
  final DeviceInfo info;

  @override
  String toString() {
    return 'DeviceNode(path: $path, pid: $pid, transport: $transport, name: $name, info: $info)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _DeviceNode &&
            const DeepCollectionEquality().equals(other.path, path) &&
            (identical(other.pid, pid) || other.pid == pid) &&
            (identical(other.transport, transport) ||
                other.transport == transport) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.info, info) || other.info == info));
  }

  @override
  int get hashCode => Object.hash(runtimeType,
      const DeepCollectionEquality().hash(path), pid, transport, name, info);

  @JsonKey(ignore: true)
  @override
  _$DeviceNodeCopyWith<_DeviceNode> get copyWith =>
      __$DeviceNodeCopyWithImpl<_DeviceNode>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_DeviceNodeToJson(this);
  }
}

abstract class _DeviceNode implements DeviceNode {
  factory _DeviceNode(List<String> path, int pid, Transport transport,
      String name, DeviceInfo info) = _$_DeviceNode;

  factory _DeviceNode.fromJson(Map<String, dynamic> json) =
      _$_DeviceNode.fromJson;

  @override
  List<String> get path;
  @override
  int get pid;
  @override
  Transport get transport;
  @override
  String get name;
  @override
  DeviceInfo get info;
  @override
  @JsonKey(ignore: true)
  _$DeviceNodeCopyWith<_DeviceNode> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
class _$MenuActionTearOff {
  const _$MenuActionTearOff();

  _MenuAction call(
      {required String text, required Icon icon, void Function()? action}) {
    return _MenuAction(
      text: text,
      icon: icon,
      action: action,
    );
  }
}

/// @nodoc
const $MenuAction = _$MenuActionTearOff();

/// @nodoc
mixin _$MenuAction {
  String get text => throw _privateConstructorUsedError;
  Icon get icon => throw _privateConstructorUsedError;
  void Function()? get action => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $MenuActionCopyWith<MenuAction> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MenuActionCopyWith<$Res> {
  factory $MenuActionCopyWith(
          MenuAction value, $Res Function(MenuAction) then) =
      _$MenuActionCopyWithImpl<$Res>;
  $Res call({String text, Icon icon, void Function()? action});
}

/// @nodoc
class _$MenuActionCopyWithImpl<$Res> implements $MenuActionCopyWith<$Res> {
  _$MenuActionCopyWithImpl(this._value, this._then);

  final MenuAction _value;
  // ignore: unused_field
  final $Res Function(MenuAction) _then;

  @override
  $Res call({
    Object? text = freezed,
    Object? icon = freezed,
    Object? action = freezed,
  }) {
    return _then(_value.copyWith(
      text: text == freezed
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      icon: icon == freezed
          ? _value.icon
          : icon // ignore: cast_nullable_to_non_nullable
              as Icon,
      action: action == freezed
          ? _value.action
          : action // ignore: cast_nullable_to_non_nullable
              as void Function()?,
    ));
  }
}

/// @nodoc
abstract class _$MenuActionCopyWith<$Res> implements $MenuActionCopyWith<$Res> {
  factory _$MenuActionCopyWith(
          _MenuAction value, $Res Function(_MenuAction) then) =
      __$MenuActionCopyWithImpl<$Res>;
  @override
  $Res call({String text, Icon icon, void Function()? action});
}

/// @nodoc
class __$MenuActionCopyWithImpl<$Res> extends _$MenuActionCopyWithImpl<$Res>
    implements _$MenuActionCopyWith<$Res> {
  __$MenuActionCopyWithImpl(
      _MenuAction _value, $Res Function(_MenuAction) _then)
      : super(_value, (v) => _then(v as _MenuAction));

  @override
  _MenuAction get _value => super._value as _MenuAction;

  @override
  $Res call({
    Object? text = freezed,
    Object? icon = freezed,
    Object? action = freezed,
  }) {
    return _then(_MenuAction(
      text: text == freezed
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      icon: icon == freezed
          ? _value.icon
          : icon // ignore: cast_nullable_to_non_nullable
              as Icon,
      action: action == freezed
          ? _value.action
          : action // ignore: cast_nullable_to_non_nullable
              as void Function()?,
    ));
  }
}

/// @nodoc

class _$_MenuAction implements _MenuAction {
  _$_MenuAction({required this.text, required this.icon, this.action});

  @override
  final String text;
  @override
  final Icon icon;
  @override
  final void Function()? action;

  @override
  String toString() {
    return 'MenuAction(text: $text, icon: $icon, action: $action)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _MenuAction &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.icon, icon) || other.icon == icon) &&
            (identical(other.action, action) || other.action == action));
  }

  @override
  int get hashCode => Object.hash(runtimeType, text, icon, action);

  @JsonKey(ignore: true)
  @override
  _$MenuActionCopyWith<_MenuAction> get copyWith =>
      __$MenuActionCopyWithImpl<_MenuAction>(this, _$identity);
}

abstract class _MenuAction implements MenuAction {
  factory _MenuAction(
      {required String text,
      required Icon icon,
      void Function()? action}) = _$_MenuAction;

  @override
  String get text;
  @override
  Icon get icon;
  @override
  void Function()? get action;
  @override
  @JsonKey(ignore: true)
  _$MenuActionCopyWith<_MenuAction> get copyWith =>
      throw _privateConstructorUsedError;
}
