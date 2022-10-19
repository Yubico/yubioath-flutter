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
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

/// @nodoc
mixin _$YubiKeyData {
  DeviceNode get node => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  DeviceInfo get info => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $YubiKeyDataCopyWith<YubiKeyData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $YubiKeyDataCopyWith<$Res> {
  factory $YubiKeyDataCopyWith(
          YubiKeyData value, $Res Function(YubiKeyData) then) =
      _$YubiKeyDataCopyWithImpl<$Res, YubiKeyData>;
  @useResult
  $Res call({DeviceNode node, String name, DeviceInfo info});

  $DeviceNodeCopyWith<$Res> get node;
  $DeviceInfoCopyWith<$Res> get info;
}

/// @nodoc
class _$YubiKeyDataCopyWithImpl<$Res, $Val extends YubiKeyData>
    implements $YubiKeyDataCopyWith<$Res> {
  _$YubiKeyDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? node = null,
    Object? name = null,
    Object? info = null,
  }) {
    return _then(_value.copyWith(
      node: null == node
          ? _value.node
          : node // ignore: cast_nullable_to_non_nullable
              as DeviceNode,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      info: null == info
          ? _value.info
          : info // ignore: cast_nullable_to_non_nullable
              as DeviceInfo,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $DeviceNodeCopyWith<$Res> get node {
    return $DeviceNodeCopyWith<$Res>(_value.node, (value) {
      return _then(_value.copyWith(node: value) as $Val);
    });
  }

  @override
  @pragma('vm:prefer-inline')
  $DeviceInfoCopyWith<$Res> get info {
    return $DeviceInfoCopyWith<$Res>(_value.info, (value) {
      return _then(_value.copyWith(info: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$_YubiKeyDataCopyWith<$Res>
    implements $YubiKeyDataCopyWith<$Res> {
  factory _$$_YubiKeyDataCopyWith(
          _$_YubiKeyData value, $Res Function(_$_YubiKeyData) then) =
      __$$_YubiKeyDataCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({DeviceNode node, String name, DeviceInfo info});

  @override
  $DeviceNodeCopyWith<$Res> get node;
  @override
  $DeviceInfoCopyWith<$Res> get info;
}

/// @nodoc
class __$$_YubiKeyDataCopyWithImpl<$Res>
    extends _$YubiKeyDataCopyWithImpl<$Res, _$_YubiKeyData>
    implements _$$_YubiKeyDataCopyWith<$Res> {
  __$$_YubiKeyDataCopyWithImpl(
      _$_YubiKeyData _value, $Res Function(_$_YubiKeyData) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? node = null,
    Object? name = null,
    Object? info = null,
  }) {
    return _then(_$_YubiKeyData(
      null == node
          ? _value.node
          : node // ignore: cast_nullable_to_non_nullable
              as DeviceNode,
      null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      null == info
          ? _value.info
          : info // ignore: cast_nullable_to_non_nullable
              as DeviceInfo,
    ));
  }
}

/// @nodoc

class _$_YubiKeyData implements _YubiKeyData {
  _$_YubiKeyData(this.node, this.name, this.info);

  @override
  final DeviceNode node;
  @override
  final String name;
  @override
  final DeviceInfo info;

  @override
  String toString() {
    return 'YubiKeyData(node: $node, name: $name, info: $info)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_YubiKeyData &&
            (identical(other.node, node) || other.node == node) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.info, info) || other.info == info));
  }

  @override
  int get hashCode => Object.hash(runtimeType, node, name, info);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_YubiKeyDataCopyWith<_$_YubiKeyData> get copyWith =>
      __$$_YubiKeyDataCopyWithImpl<_$_YubiKeyData>(this, _$identity);
}

abstract class _YubiKeyData implements YubiKeyData {
  factory _YubiKeyData(
          final DeviceNode node, final String name, final DeviceInfo info) =
      _$_YubiKeyData;

  @override
  DeviceNode get node;
  @override
  String get name;
  @override
  DeviceInfo get info;
  @override
  @JsonKey(ignore: true)
  _$$_YubiKeyDataCopyWith<_$_YubiKeyData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$DeviceNode {
  DevicePath get path => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            DevicePath path, String name, UsbPid pid, DeviceInfo? info)
        usbYubiKey,
    required TResult Function(DevicePath path, String name) nfcReader,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            DevicePath path, String name, UsbPid pid, DeviceInfo? info)?
        usbYubiKey,
    TResult? Function(DevicePath path, String name)? nfcReader,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            DevicePath path, String name, UsbPid pid, DeviceInfo? info)?
        usbYubiKey,
    TResult Function(DevicePath path, String name)? nfcReader,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(UsbYubiKeyNode value) usbYubiKey,
    required TResult Function(NfcReaderNode value) nfcReader,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(UsbYubiKeyNode value)? usbYubiKey,
    TResult? Function(NfcReaderNode value)? nfcReader,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(UsbYubiKeyNode value)? usbYubiKey,
    TResult Function(NfcReaderNode value)? nfcReader,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $DeviceNodeCopyWith<DeviceNode> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DeviceNodeCopyWith<$Res> {
  factory $DeviceNodeCopyWith(
          DeviceNode value, $Res Function(DeviceNode) then) =
      _$DeviceNodeCopyWithImpl<$Res, DeviceNode>;
  @useResult
  $Res call({DevicePath path, String name});
}

/// @nodoc
class _$DeviceNodeCopyWithImpl<$Res, $Val extends DeviceNode>
    implements $DeviceNodeCopyWith<$Res> {
  _$DeviceNodeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? path = null,
    Object? name = null,
  }) {
    return _then(_value.copyWith(
      path: null == path
          ? _value.path
          : path // ignore: cast_nullable_to_non_nullable
              as DevicePath,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UsbYubiKeyNodeCopyWith<$Res>
    implements $DeviceNodeCopyWith<$Res> {
  factory _$$UsbYubiKeyNodeCopyWith(
          _$UsbYubiKeyNode value, $Res Function(_$UsbYubiKeyNode) then) =
      __$$UsbYubiKeyNodeCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({DevicePath path, String name, UsbPid pid, DeviceInfo? info});

  $DeviceInfoCopyWith<$Res>? get info;
}

/// @nodoc
class __$$UsbYubiKeyNodeCopyWithImpl<$Res>
    extends _$DeviceNodeCopyWithImpl<$Res, _$UsbYubiKeyNode>
    implements _$$UsbYubiKeyNodeCopyWith<$Res> {
  __$$UsbYubiKeyNodeCopyWithImpl(
      _$UsbYubiKeyNode _value, $Res Function(_$UsbYubiKeyNode) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? path = null,
    Object? name = null,
    Object? pid = null,
    Object? info = freezed,
  }) {
    return _then(_$UsbYubiKeyNode(
      null == path
          ? _value.path
          : path // ignore: cast_nullable_to_non_nullable
              as DevicePath,
      null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      null == pid
          ? _value.pid
          : pid // ignore: cast_nullable_to_non_nullable
              as UsbPid,
      freezed == info
          ? _value.info
          : info // ignore: cast_nullable_to_non_nullable
              as DeviceInfo?,
    ));
  }

  @override
  @pragma('vm:prefer-inline')
  $DeviceInfoCopyWith<$Res>? get info {
    if (_value.info == null) {
      return null;
    }

    return $DeviceInfoCopyWith<$Res>(_value.info!, (value) {
      return _then(_value.copyWith(info: value));
    });
  }
}

/// @nodoc

class _$UsbYubiKeyNode extends UsbYubiKeyNode {
  _$UsbYubiKeyNode(this.path, this.name, this.pid, this.info) : super._();

  @override
  final DevicePath path;
  @override
  final String name;
  @override
  final UsbPid pid;
  @override
  final DeviceInfo? info;

  @override
  String toString() {
    return 'DeviceNode.usbYubiKey(path: $path, name: $name, pid: $pid, info: $info)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UsbYubiKeyNode &&
            (identical(other.path, path) || other.path == path) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.pid, pid) || other.pid == pid) &&
            (identical(other.info, info) || other.info == info));
  }

  @override
  int get hashCode => Object.hash(runtimeType, path, name, pid, info);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$UsbYubiKeyNodeCopyWith<_$UsbYubiKeyNode> get copyWith =>
      __$$UsbYubiKeyNodeCopyWithImpl<_$UsbYubiKeyNode>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            DevicePath path, String name, UsbPid pid, DeviceInfo? info)
        usbYubiKey,
    required TResult Function(DevicePath path, String name) nfcReader,
  }) {
    return usbYubiKey(path, name, pid, info);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            DevicePath path, String name, UsbPid pid, DeviceInfo? info)?
        usbYubiKey,
    TResult? Function(DevicePath path, String name)? nfcReader,
  }) {
    return usbYubiKey?.call(path, name, pid, info);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            DevicePath path, String name, UsbPid pid, DeviceInfo? info)?
        usbYubiKey,
    TResult Function(DevicePath path, String name)? nfcReader,
    required TResult orElse(),
  }) {
    if (usbYubiKey != null) {
      return usbYubiKey(path, name, pid, info);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(UsbYubiKeyNode value) usbYubiKey,
    required TResult Function(NfcReaderNode value) nfcReader,
  }) {
    return usbYubiKey(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(UsbYubiKeyNode value)? usbYubiKey,
    TResult? Function(NfcReaderNode value)? nfcReader,
  }) {
    return usbYubiKey?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(UsbYubiKeyNode value)? usbYubiKey,
    TResult Function(NfcReaderNode value)? nfcReader,
    required TResult orElse(),
  }) {
    if (usbYubiKey != null) {
      return usbYubiKey(this);
    }
    return orElse();
  }
}

abstract class UsbYubiKeyNode extends DeviceNode {
  factory UsbYubiKeyNode(final DevicePath path, final String name,
      final UsbPid pid, final DeviceInfo? info) = _$UsbYubiKeyNode;
  UsbYubiKeyNode._() : super._();

  @override
  DevicePath get path;
  @override
  String get name;
  UsbPid get pid;
  DeviceInfo? get info;
  @override
  @JsonKey(ignore: true)
  _$$UsbYubiKeyNodeCopyWith<_$UsbYubiKeyNode> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$NfcReaderNodeCopyWith<$Res>
    implements $DeviceNodeCopyWith<$Res> {
  factory _$$NfcReaderNodeCopyWith(
          _$NfcReaderNode value, $Res Function(_$NfcReaderNode) then) =
      __$$NfcReaderNodeCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({DevicePath path, String name});
}

/// @nodoc
class __$$NfcReaderNodeCopyWithImpl<$Res>
    extends _$DeviceNodeCopyWithImpl<$Res, _$NfcReaderNode>
    implements _$$NfcReaderNodeCopyWith<$Res> {
  __$$NfcReaderNodeCopyWithImpl(
      _$NfcReaderNode _value, $Res Function(_$NfcReaderNode) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? path = null,
    Object? name = null,
  }) {
    return _then(_$NfcReaderNode(
      null == path
          ? _value.path
          : path // ignore: cast_nullable_to_non_nullable
              as DevicePath,
      null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$NfcReaderNode extends NfcReaderNode {
  _$NfcReaderNode(this.path, this.name) : super._();

  @override
  final DevicePath path;
  @override
  final String name;

  @override
  String toString() {
    return 'DeviceNode.nfcReader(path: $path, name: $name)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NfcReaderNode &&
            (identical(other.path, path) || other.path == path) &&
            (identical(other.name, name) || other.name == name));
  }

  @override
  int get hashCode => Object.hash(runtimeType, path, name);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$NfcReaderNodeCopyWith<_$NfcReaderNode> get copyWith =>
      __$$NfcReaderNodeCopyWithImpl<_$NfcReaderNode>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            DevicePath path, String name, UsbPid pid, DeviceInfo? info)
        usbYubiKey,
    required TResult Function(DevicePath path, String name) nfcReader,
  }) {
    return nfcReader(path, name);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            DevicePath path, String name, UsbPid pid, DeviceInfo? info)?
        usbYubiKey,
    TResult? Function(DevicePath path, String name)? nfcReader,
  }) {
    return nfcReader?.call(path, name);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            DevicePath path, String name, UsbPid pid, DeviceInfo? info)?
        usbYubiKey,
    TResult Function(DevicePath path, String name)? nfcReader,
    required TResult orElse(),
  }) {
    if (nfcReader != null) {
      return nfcReader(path, name);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(UsbYubiKeyNode value) usbYubiKey,
    required TResult Function(NfcReaderNode value) nfcReader,
  }) {
    return nfcReader(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(UsbYubiKeyNode value)? usbYubiKey,
    TResult? Function(NfcReaderNode value)? nfcReader,
  }) {
    return nfcReader?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(UsbYubiKeyNode value)? usbYubiKey,
    TResult Function(NfcReaderNode value)? nfcReader,
    required TResult orElse(),
  }) {
    if (nfcReader != null) {
      return nfcReader(this);
    }
    return orElse();
  }
}

abstract class NfcReaderNode extends DeviceNode {
  factory NfcReaderNode(final DevicePath path, final String name) =
      _$NfcReaderNode;
  NfcReaderNode._() : super._();

  @override
  DevicePath get path;
  @override
  String get name;
  @override
  @JsonKey(ignore: true)
  _$$NfcReaderNodeCopyWith<_$NfcReaderNode> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$MenuAction {
  String get text => throw _privateConstructorUsedError;
  Widget get icon => throw _privateConstructorUsedError;
  String? get trailing => throw _privateConstructorUsedError;
  void Function(BuildContext)? get action => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $MenuActionCopyWith<MenuAction> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MenuActionCopyWith<$Res> {
  factory $MenuActionCopyWith(
          MenuAction value, $Res Function(MenuAction) then) =
      _$MenuActionCopyWithImpl<$Res, MenuAction>;
  @useResult
  $Res call(
      {String text,
      Widget icon,
      String? trailing,
      void Function(BuildContext)? action});
}

/// @nodoc
class _$MenuActionCopyWithImpl<$Res, $Val extends MenuAction>
    implements $MenuActionCopyWith<$Res> {
  _$MenuActionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? text = null,
    Object? icon = null,
    Object? trailing = freezed,
    Object? action = freezed,
  }) {
    return _then(_value.copyWith(
      text: null == text
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      icon: null == icon
          ? _value.icon
          : icon // ignore: cast_nullable_to_non_nullable
              as Widget,
      trailing: freezed == trailing
          ? _value.trailing
          : trailing // ignore: cast_nullable_to_non_nullable
              as String?,
      action: freezed == action
          ? _value.action
          : action // ignore: cast_nullable_to_non_nullable
              as void Function(BuildContext)?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$_MenuActionCopyWith<$Res>
    implements $MenuActionCopyWith<$Res> {
  factory _$$_MenuActionCopyWith(
          _$_MenuAction value, $Res Function(_$_MenuAction) then) =
      __$$_MenuActionCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String text,
      Widget icon,
      String? trailing,
      void Function(BuildContext)? action});
}

/// @nodoc
class __$$_MenuActionCopyWithImpl<$Res>
    extends _$MenuActionCopyWithImpl<$Res, _$_MenuAction>
    implements _$$_MenuActionCopyWith<$Res> {
  __$$_MenuActionCopyWithImpl(
      _$_MenuAction _value, $Res Function(_$_MenuAction) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? text = null,
    Object? icon = null,
    Object? trailing = freezed,
    Object? action = freezed,
  }) {
    return _then(_$_MenuAction(
      text: null == text
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      icon: null == icon
          ? _value.icon
          : icon // ignore: cast_nullable_to_non_nullable
              as Widget,
      trailing: freezed == trailing
          ? _value.trailing
          : trailing // ignore: cast_nullable_to_non_nullable
              as String?,
      action: freezed == action
          ? _value.action
          : action // ignore: cast_nullable_to_non_nullable
              as void Function(BuildContext)?,
    ));
  }
}

/// @nodoc

class _$_MenuAction implements _MenuAction {
  _$_MenuAction(
      {required this.text, required this.icon, this.trailing, this.action});

  @override
  final String text;
  @override
  final Widget icon;
  @override
  final String? trailing;
  @override
  final void Function(BuildContext)? action;

  @override
  String toString() {
    return 'MenuAction(text: $text, icon: $icon, trailing: $trailing, action: $action)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_MenuAction &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.icon, icon) || other.icon == icon) &&
            (identical(other.trailing, trailing) ||
                other.trailing == trailing) &&
            (identical(other.action, action) || other.action == action));
  }

  @override
  int get hashCode => Object.hash(runtimeType, text, icon, trailing, action);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_MenuActionCopyWith<_$_MenuAction> get copyWith =>
      __$$_MenuActionCopyWithImpl<_$_MenuAction>(this, _$identity);
}

abstract class _MenuAction implements MenuAction {
  factory _MenuAction(
      {required final String text,
      required final Widget icon,
      final String? trailing,
      final void Function(BuildContext)? action}) = _$_MenuAction;

  @override
  String get text;
  @override
  Widget get icon;
  @override
  String? get trailing;
  @override
  void Function(BuildContext)? get action;
  @override
  @JsonKey(ignore: true)
  _$$_MenuActionCopyWith<_$_MenuAction> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$WindowState {
  bool get focused => throw _privateConstructorUsedError;
  bool get visible => throw _privateConstructorUsedError;
  bool get active => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $WindowStateCopyWith<WindowState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WindowStateCopyWith<$Res> {
  factory $WindowStateCopyWith(
          WindowState value, $Res Function(WindowState) then) =
      _$WindowStateCopyWithImpl<$Res, WindowState>;
  @useResult
  $Res call({bool focused, bool visible, bool active});
}

/// @nodoc
class _$WindowStateCopyWithImpl<$Res, $Val extends WindowState>
    implements $WindowStateCopyWith<$Res> {
  _$WindowStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? focused = null,
    Object? visible = null,
    Object? active = null,
  }) {
    return _then(_value.copyWith(
      focused: null == focused
          ? _value.focused
          : focused // ignore: cast_nullable_to_non_nullable
              as bool,
      visible: null == visible
          ? _value.visible
          : visible // ignore: cast_nullable_to_non_nullable
              as bool,
      active: null == active
          ? _value.active
          : active // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$_WindowStateCopyWith<$Res>
    implements $WindowStateCopyWith<$Res> {
  factory _$$_WindowStateCopyWith(
          _$_WindowState value, $Res Function(_$_WindowState) then) =
      __$$_WindowStateCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({bool focused, bool visible, bool active});
}

/// @nodoc
class __$$_WindowStateCopyWithImpl<$Res>
    extends _$WindowStateCopyWithImpl<$Res, _$_WindowState>
    implements _$$_WindowStateCopyWith<$Res> {
  __$$_WindowStateCopyWithImpl(
      _$_WindowState _value, $Res Function(_$_WindowState) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? focused = null,
    Object? visible = null,
    Object? active = null,
  }) {
    return _then(_$_WindowState(
      focused: null == focused
          ? _value.focused
          : focused // ignore: cast_nullable_to_non_nullable
              as bool,
      visible: null == visible
          ? _value.visible
          : visible // ignore: cast_nullable_to_non_nullable
              as bool,
      active: null == active
          ? _value.active
          : active // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$_WindowState implements _WindowState {
  _$_WindowState(
      {required this.focused, required this.visible, required this.active});

  @override
  final bool focused;
  @override
  final bool visible;
  @override
  final bool active;

  @override
  String toString() {
    return 'WindowState(focused: $focused, visible: $visible, active: $active)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_WindowState &&
            (identical(other.focused, focused) || other.focused == focused) &&
            (identical(other.visible, visible) || other.visible == visible) &&
            (identical(other.active, active) || other.active == active));
  }

  @override
  int get hashCode => Object.hash(runtimeType, focused, visible, active);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_WindowStateCopyWith<_$_WindowState> get copyWith =>
      __$$_WindowStateCopyWithImpl<_$_WindowState>(this, _$identity);
}

abstract class _WindowState implements WindowState {
  factory _WindowState(
      {required final bool focused,
      required final bool visible,
      required final bool active}) = _$_WindowState;

  @override
  bool get focused;
  @override
  bool get visible;
  @override
  bool get active;
  @override
  @JsonKey(ignore: true)
  _$$_WindowStateCopyWith<_$_WindowState> get copyWith =>
      throw _privateConstructorUsedError;
}
