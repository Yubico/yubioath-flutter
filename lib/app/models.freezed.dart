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
abstract class _$$YubiKeyDataImplCopyWith<$Res>
    implements $YubiKeyDataCopyWith<$Res> {
  factory _$$YubiKeyDataImplCopyWith(
          _$YubiKeyDataImpl value, $Res Function(_$YubiKeyDataImpl) then) =
      __$$YubiKeyDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({DeviceNode node, String name, DeviceInfo info});

  @override
  $DeviceNodeCopyWith<$Res> get node;
  @override
  $DeviceInfoCopyWith<$Res> get info;
}

/// @nodoc
class __$$YubiKeyDataImplCopyWithImpl<$Res>
    extends _$YubiKeyDataCopyWithImpl<$Res, _$YubiKeyDataImpl>
    implements _$$YubiKeyDataImplCopyWith<$Res> {
  __$$YubiKeyDataImplCopyWithImpl(
      _$YubiKeyDataImpl _value, $Res Function(_$YubiKeyDataImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? node = null,
    Object? name = null,
    Object? info = null,
  }) {
    return _then(_$YubiKeyDataImpl(
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

class _$YubiKeyDataImpl implements _YubiKeyData {
  _$YubiKeyDataImpl(this.node, this.name, this.info);

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
            other is _$YubiKeyDataImpl &&
            (identical(other.node, node) || other.node == node) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.info, info) || other.info == info));
  }

  @override
  int get hashCode => Object.hash(runtimeType, node, name, info);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$YubiKeyDataImplCopyWith<_$YubiKeyDataImpl> get copyWith =>
      __$$YubiKeyDataImplCopyWithImpl<_$YubiKeyDataImpl>(this, _$identity);
}

abstract class _YubiKeyData implements YubiKeyData {
  factory _YubiKeyData(
          final DeviceNode node, final String name, final DeviceInfo info) =
      _$YubiKeyDataImpl;

  @override
  DeviceNode get node;
  @override
  String get name;
  @override
  DeviceInfo get info;
  @override
  @JsonKey(ignore: true)
  _$$YubiKeyDataImplCopyWith<_$YubiKeyDataImpl> get copyWith =>
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
abstract class _$$UsbYubiKeyNodeImplCopyWith<$Res>
    implements $DeviceNodeCopyWith<$Res> {
  factory _$$UsbYubiKeyNodeImplCopyWith(_$UsbYubiKeyNodeImpl value,
          $Res Function(_$UsbYubiKeyNodeImpl) then) =
      __$$UsbYubiKeyNodeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({DevicePath path, String name, UsbPid pid, DeviceInfo? info});

  $DeviceInfoCopyWith<$Res>? get info;
}

/// @nodoc
class __$$UsbYubiKeyNodeImplCopyWithImpl<$Res>
    extends _$DeviceNodeCopyWithImpl<$Res, _$UsbYubiKeyNodeImpl>
    implements _$$UsbYubiKeyNodeImplCopyWith<$Res> {
  __$$UsbYubiKeyNodeImplCopyWithImpl(
      _$UsbYubiKeyNodeImpl _value, $Res Function(_$UsbYubiKeyNodeImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? path = null,
    Object? name = null,
    Object? pid = null,
    Object? info = freezed,
  }) {
    return _then(_$UsbYubiKeyNodeImpl(
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

class _$UsbYubiKeyNodeImpl extends UsbYubiKeyNode {
  _$UsbYubiKeyNodeImpl(this.path, this.name, this.pid, this.info) : super._();

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
            other is _$UsbYubiKeyNodeImpl &&
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
  _$$UsbYubiKeyNodeImplCopyWith<_$UsbYubiKeyNodeImpl> get copyWith =>
      __$$UsbYubiKeyNodeImplCopyWithImpl<_$UsbYubiKeyNodeImpl>(
          this, _$identity);

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
      final UsbPid pid, final DeviceInfo? info) = _$UsbYubiKeyNodeImpl;
  UsbYubiKeyNode._() : super._();

  @override
  DevicePath get path;
  @override
  String get name;
  UsbPid get pid;
  DeviceInfo? get info;
  @override
  @JsonKey(ignore: true)
  _$$UsbYubiKeyNodeImplCopyWith<_$UsbYubiKeyNodeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$NfcReaderNodeImplCopyWith<$Res>
    implements $DeviceNodeCopyWith<$Res> {
  factory _$$NfcReaderNodeImplCopyWith(
          _$NfcReaderNodeImpl value, $Res Function(_$NfcReaderNodeImpl) then) =
      __$$NfcReaderNodeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({DevicePath path, String name});
}

/// @nodoc
class __$$NfcReaderNodeImplCopyWithImpl<$Res>
    extends _$DeviceNodeCopyWithImpl<$Res, _$NfcReaderNodeImpl>
    implements _$$NfcReaderNodeImplCopyWith<$Res> {
  __$$NfcReaderNodeImplCopyWithImpl(
      _$NfcReaderNodeImpl _value, $Res Function(_$NfcReaderNodeImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? path = null,
    Object? name = null,
  }) {
    return _then(_$NfcReaderNodeImpl(
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

class _$NfcReaderNodeImpl extends NfcReaderNode {
  _$NfcReaderNodeImpl(this.path, this.name) : super._();

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
            other is _$NfcReaderNodeImpl &&
            (identical(other.path, path) || other.path == path) &&
            (identical(other.name, name) || other.name == name));
  }

  @override
  int get hashCode => Object.hash(runtimeType, path, name);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$NfcReaderNodeImplCopyWith<_$NfcReaderNodeImpl> get copyWith =>
      __$$NfcReaderNodeImplCopyWithImpl<_$NfcReaderNodeImpl>(this, _$identity);

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
      _$NfcReaderNodeImpl;
  NfcReaderNode._() : super._();

  @override
  DevicePath get path;
  @override
  String get name;
  @override
  @JsonKey(ignore: true)
  _$$NfcReaderNodeImplCopyWith<_$NfcReaderNodeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$ActionItem {
  Widget get icon => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get subtitle => throw _privateConstructorUsedError;
  String? get shortcut => throw _privateConstructorUsedError;
  Widget? get trailing => throw _privateConstructorUsedError;
  Intent? get intent => throw _privateConstructorUsedError;
  ActionStyle? get actionStyle => throw _privateConstructorUsedError;
  Key? get key => throw _privateConstructorUsedError;
  Feature? get feature => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $ActionItemCopyWith<ActionItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ActionItemCopyWith<$Res> {
  factory $ActionItemCopyWith(
          ActionItem value, $Res Function(ActionItem) then) =
      _$ActionItemCopyWithImpl<$Res, ActionItem>;
  @useResult
  $Res call(
      {Widget icon,
      String title,
      String? subtitle,
      String? shortcut,
      Widget? trailing,
      Intent? intent,
      ActionStyle? actionStyle,
      Key? key,
      Feature? feature});
}

/// @nodoc
class _$ActionItemCopyWithImpl<$Res, $Val extends ActionItem>
    implements $ActionItemCopyWith<$Res> {
  _$ActionItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? icon = null,
    Object? title = null,
    Object? subtitle = freezed,
    Object? shortcut = freezed,
    Object? trailing = freezed,
    Object? intent = freezed,
    Object? actionStyle = freezed,
    Object? key = freezed,
    Object? feature = freezed,
  }) {
    return _then(_value.copyWith(
      icon: null == icon
          ? _value.icon
          : icon // ignore: cast_nullable_to_non_nullable
              as Widget,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      subtitle: freezed == subtitle
          ? _value.subtitle
          : subtitle // ignore: cast_nullable_to_non_nullable
              as String?,
      shortcut: freezed == shortcut
          ? _value.shortcut
          : shortcut // ignore: cast_nullable_to_non_nullable
              as String?,
      trailing: freezed == trailing
          ? _value.trailing
          : trailing // ignore: cast_nullable_to_non_nullable
              as Widget?,
      intent: freezed == intent
          ? _value.intent
          : intent // ignore: cast_nullable_to_non_nullable
              as Intent?,
      actionStyle: freezed == actionStyle
          ? _value.actionStyle
          : actionStyle // ignore: cast_nullable_to_non_nullable
              as ActionStyle?,
      key: freezed == key
          ? _value.key
          : key // ignore: cast_nullable_to_non_nullable
              as Key?,
      feature: freezed == feature
          ? _value.feature
          : feature // ignore: cast_nullable_to_non_nullable
              as Feature?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ActionItemImplCopyWith<$Res>
    implements $ActionItemCopyWith<$Res> {
  factory _$$ActionItemImplCopyWith(
          _$ActionItemImpl value, $Res Function(_$ActionItemImpl) then) =
      __$$ActionItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {Widget icon,
      String title,
      String? subtitle,
      String? shortcut,
      Widget? trailing,
      Intent? intent,
      ActionStyle? actionStyle,
      Key? key,
      Feature? feature});
}

/// @nodoc
class __$$ActionItemImplCopyWithImpl<$Res>
    extends _$ActionItemCopyWithImpl<$Res, _$ActionItemImpl>
    implements _$$ActionItemImplCopyWith<$Res> {
  __$$ActionItemImplCopyWithImpl(
      _$ActionItemImpl _value, $Res Function(_$ActionItemImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? icon = null,
    Object? title = null,
    Object? subtitle = freezed,
    Object? shortcut = freezed,
    Object? trailing = freezed,
    Object? intent = freezed,
    Object? actionStyle = freezed,
    Object? key = freezed,
    Object? feature = freezed,
  }) {
    return _then(_$ActionItemImpl(
      icon: null == icon
          ? _value.icon
          : icon // ignore: cast_nullable_to_non_nullable
              as Widget,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      subtitle: freezed == subtitle
          ? _value.subtitle
          : subtitle // ignore: cast_nullable_to_non_nullable
              as String?,
      shortcut: freezed == shortcut
          ? _value.shortcut
          : shortcut // ignore: cast_nullable_to_non_nullable
              as String?,
      trailing: freezed == trailing
          ? _value.trailing
          : trailing // ignore: cast_nullable_to_non_nullable
              as Widget?,
      intent: freezed == intent
          ? _value.intent
          : intent // ignore: cast_nullable_to_non_nullable
              as Intent?,
      actionStyle: freezed == actionStyle
          ? _value.actionStyle
          : actionStyle // ignore: cast_nullable_to_non_nullable
              as ActionStyle?,
      key: freezed == key
          ? _value.key
          : key // ignore: cast_nullable_to_non_nullable
              as Key?,
      feature: freezed == feature
          ? _value.feature
          : feature // ignore: cast_nullable_to_non_nullable
              as Feature?,
    ));
  }
}

/// @nodoc

class _$ActionItemImpl implements _ActionItem {
  _$ActionItemImpl(
      {required this.icon,
      required this.title,
      this.subtitle,
      this.shortcut,
      this.trailing,
      this.intent,
      this.actionStyle,
      this.key,
      this.feature});

  @override
  final Widget icon;
  @override
  final String title;
  @override
  final String? subtitle;
  @override
  final String? shortcut;
  @override
  final Widget? trailing;
  @override
  final Intent? intent;
  @override
  final ActionStyle? actionStyle;
  @override
  final Key? key;
  @override
  final Feature? feature;

  @override
  String toString() {
    return 'ActionItem(icon: $icon, title: $title, subtitle: $subtitle, shortcut: $shortcut, trailing: $trailing, intent: $intent, actionStyle: $actionStyle, key: $key, feature: $feature)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ActionItemImpl &&
            (identical(other.icon, icon) || other.icon == icon) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.subtitle, subtitle) ||
                other.subtitle == subtitle) &&
            (identical(other.shortcut, shortcut) ||
                other.shortcut == shortcut) &&
            (identical(other.trailing, trailing) ||
                other.trailing == trailing) &&
            (identical(other.intent, intent) || other.intent == intent) &&
            (identical(other.actionStyle, actionStyle) ||
                other.actionStyle == actionStyle) &&
            (identical(other.key, key) || other.key == key) &&
            (identical(other.feature, feature) || other.feature == feature));
  }

  @override
  int get hashCode => Object.hash(runtimeType, icon, title, subtitle, shortcut,
      trailing, intent, actionStyle, key, feature);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ActionItemImplCopyWith<_$ActionItemImpl> get copyWith =>
      __$$ActionItemImplCopyWithImpl<_$ActionItemImpl>(this, _$identity);
}

abstract class _ActionItem implements ActionItem {
  factory _ActionItem(
      {required final Widget icon,
      required final String title,
      final String? subtitle,
      final String? shortcut,
      final Widget? trailing,
      final Intent? intent,
      final ActionStyle? actionStyle,
      final Key? key,
      final Feature? feature}) = _$ActionItemImpl;

  @override
  Widget get icon;
  @override
  String get title;
  @override
  String? get subtitle;
  @override
  String? get shortcut;
  @override
  Widget? get trailing;
  @override
  Intent? get intent;
  @override
  ActionStyle? get actionStyle;
  @override
  Key? get key;
  @override
  Feature? get feature;
  @override
  @JsonKey(ignore: true)
  _$$ActionItemImplCopyWith<_$ActionItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$WindowState {
  bool get focused => throw _privateConstructorUsedError;
  bool get visible => throw _privateConstructorUsedError;
  bool get active => throw _privateConstructorUsedError;
  bool get hidden => throw _privateConstructorUsedError;

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
  $Res call({bool focused, bool visible, bool active, bool hidden});
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
    Object? hidden = null,
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
      hidden: null == hidden
          ? _value.hidden
          : hidden // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$WindowStateImplCopyWith<$Res>
    implements $WindowStateCopyWith<$Res> {
  factory _$$WindowStateImplCopyWith(
          _$WindowStateImpl value, $Res Function(_$WindowStateImpl) then) =
      __$$WindowStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({bool focused, bool visible, bool active, bool hidden});
}

/// @nodoc
class __$$WindowStateImplCopyWithImpl<$Res>
    extends _$WindowStateCopyWithImpl<$Res, _$WindowStateImpl>
    implements _$$WindowStateImplCopyWith<$Res> {
  __$$WindowStateImplCopyWithImpl(
      _$WindowStateImpl _value, $Res Function(_$WindowStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? focused = null,
    Object? visible = null,
    Object? active = null,
    Object? hidden = null,
  }) {
    return _then(_$WindowStateImpl(
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
      hidden: null == hidden
          ? _value.hidden
          : hidden // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$WindowStateImpl implements _WindowState {
  _$WindowStateImpl(
      {required this.focused,
      required this.visible,
      required this.active,
      this.hidden = false});

  @override
  final bool focused;
  @override
  final bool visible;
  @override
  final bool active;
  @override
  @JsonKey()
  final bool hidden;

  @override
  String toString() {
    return 'WindowState(focused: $focused, visible: $visible, active: $active, hidden: $hidden)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WindowStateImpl &&
            (identical(other.focused, focused) || other.focused == focused) &&
            (identical(other.visible, visible) || other.visible == visible) &&
            (identical(other.active, active) || other.active == active) &&
            (identical(other.hidden, hidden) || other.hidden == hidden));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, focused, visible, active, hidden);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$WindowStateImplCopyWith<_$WindowStateImpl> get copyWith =>
      __$$WindowStateImplCopyWithImpl<_$WindowStateImpl>(this, _$identity);
}

abstract class _WindowState implements WindowState {
  factory _WindowState(
      {required final bool focused,
      required final bool visible,
      required final bool active,
      final bool hidden}) = _$WindowStateImpl;

  @override
  bool get focused;
  @override
  bool get visible;
  @override
  bool get active;
  @override
  bool get hidden;
  @override
  @JsonKey(ignore: true)
  _$$WindowStateImplCopyWith<_$WindowStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
