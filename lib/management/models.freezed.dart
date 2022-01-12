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
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more informations: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

DeviceConfig _$DeviceConfigFromJson(Map<String, dynamic> json) {
  return _DeviceConfig.fromJson(json);
}

/// @nodoc
class _$DeviceConfigTearOff {
  const _$DeviceConfigTearOff();

  _DeviceConfig call(Map<Transport, int> enabledCapabilities,
      int? autoEjectTimeout, int? challengeResponseTimeout, int? deviceFlags) {
    return _DeviceConfig(
      enabledCapabilities,
      autoEjectTimeout,
      challengeResponseTimeout,
      deviceFlags,
    );
  }

  DeviceConfig fromJson(Map<String, Object?> json) {
    return DeviceConfig.fromJson(json);
  }
}

/// @nodoc
const $DeviceConfig = _$DeviceConfigTearOff();

/// @nodoc
mixin _$DeviceConfig {
  Map<Transport, int> get enabledCapabilities =>
      throw _privateConstructorUsedError;
  int? get autoEjectTimeout => throw _privateConstructorUsedError;
  int? get challengeResponseTimeout => throw _privateConstructorUsedError;
  int? get deviceFlags => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $DeviceConfigCopyWith<DeviceConfig> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DeviceConfigCopyWith<$Res> {
  factory $DeviceConfigCopyWith(
          DeviceConfig value, $Res Function(DeviceConfig) then) =
      _$DeviceConfigCopyWithImpl<$Res>;
  $Res call(
      {Map<Transport, int> enabledCapabilities,
      int? autoEjectTimeout,
      int? challengeResponseTimeout,
      int? deviceFlags});
}

/// @nodoc
class _$DeviceConfigCopyWithImpl<$Res> implements $DeviceConfigCopyWith<$Res> {
  _$DeviceConfigCopyWithImpl(this._value, this._then);

  final DeviceConfig _value;
  // ignore: unused_field
  final $Res Function(DeviceConfig) _then;

  @override
  $Res call({
    Object? enabledCapabilities = freezed,
    Object? autoEjectTimeout = freezed,
    Object? challengeResponseTimeout = freezed,
    Object? deviceFlags = freezed,
  }) {
    return _then(_value.copyWith(
      enabledCapabilities: enabledCapabilities == freezed
          ? _value.enabledCapabilities
          : enabledCapabilities // ignore: cast_nullable_to_non_nullable
              as Map<Transport, int>,
      autoEjectTimeout: autoEjectTimeout == freezed
          ? _value.autoEjectTimeout
          : autoEjectTimeout // ignore: cast_nullable_to_non_nullable
              as int?,
      challengeResponseTimeout: challengeResponseTimeout == freezed
          ? _value.challengeResponseTimeout
          : challengeResponseTimeout // ignore: cast_nullable_to_non_nullable
              as int?,
      deviceFlags: deviceFlags == freezed
          ? _value.deviceFlags
          : deviceFlags // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
abstract class _$DeviceConfigCopyWith<$Res>
    implements $DeviceConfigCopyWith<$Res> {
  factory _$DeviceConfigCopyWith(
          _DeviceConfig value, $Res Function(_DeviceConfig) then) =
      __$DeviceConfigCopyWithImpl<$Res>;
  @override
  $Res call(
      {Map<Transport, int> enabledCapabilities,
      int? autoEjectTimeout,
      int? challengeResponseTimeout,
      int? deviceFlags});
}

/// @nodoc
class __$DeviceConfigCopyWithImpl<$Res> extends _$DeviceConfigCopyWithImpl<$Res>
    implements _$DeviceConfigCopyWith<$Res> {
  __$DeviceConfigCopyWithImpl(
      _DeviceConfig _value, $Res Function(_DeviceConfig) _then)
      : super(_value, (v) => _then(v as _DeviceConfig));

  @override
  _DeviceConfig get _value => super._value as _DeviceConfig;

  @override
  $Res call({
    Object? enabledCapabilities = freezed,
    Object? autoEjectTimeout = freezed,
    Object? challengeResponseTimeout = freezed,
    Object? deviceFlags = freezed,
  }) {
    return _then(_DeviceConfig(
      enabledCapabilities == freezed
          ? _value.enabledCapabilities
          : enabledCapabilities // ignore: cast_nullable_to_non_nullable
              as Map<Transport, int>,
      autoEjectTimeout == freezed
          ? _value.autoEjectTimeout
          : autoEjectTimeout // ignore: cast_nullable_to_non_nullable
              as int?,
      challengeResponseTimeout == freezed
          ? _value.challengeResponseTimeout
          : challengeResponseTimeout // ignore: cast_nullable_to_non_nullable
              as int?,
      deviceFlags == freezed
          ? _value.deviceFlags
          : deviceFlags // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$_DeviceConfig implements _DeviceConfig {
  _$_DeviceConfig(this.enabledCapabilities, this.autoEjectTimeout,
      this.challengeResponseTimeout, this.deviceFlags);

  factory _$_DeviceConfig.fromJson(Map<String, dynamic> json) =>
      _$$_DeviceConfigFromJson(json);

  @override
  final Map<Transport, int> enabledCapabilities;
  @override
  final int? autoEjectTimeout;
  @override
  final int? challengeResponseTimeout;
  @override
  final int? deviceFlags;

  @override
  String toString() {
    return 'DeviceConfig(enabledCapabilities: $enabledCapabilities, autoEjectTimeout: $autoEjectTimeout, challengeResponseTimeout: $challengeResponseTimeout, deviceFlags: $deviceFlags)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _DeviceConfig &&
            const DeepCollectionEquality()
                .equals(other.enabledCapabilities, enabledCapabilities) &&
            const DeepCollectionEquality()
                .equals(other.autoEjectTimeout, autoEjectTimeout) &&
            const DeepCollectionEquality().equals(
                other.challengeResponseTimeout, challengeResponseTimeout) &&
            const DeepCollectionEquality()
                .equals(other.deviceFlags, deviceFlags));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(enabledCapabilities),
      const DeepCollectionEquality().hash(autoEjectTimeout),
      const DeepCollectionEquality().hash(challengeResponseTimeout),
      const DeepCollectionEquality().hash(deviceFlags));

  @JsonKey(ignore: true)
  @override
  _$DeviceConfigCopyWith<_DeviceConfig> get copyWith =>
      __$DeviceConfigCopyWithImpl<_DeviceConfig>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_DeviceConfigToJson(this);
  }
}

abstract class _DeviceConfig implements DeviceConfig {
  factory _DeviceConfig(
      Map<Transport, int> enabledCapabilities,
      int? autoEjectTimeout,
      int? challengeResponseTimeout,
      int? deviceFlags) = _$_DeviceConfig;

  factory _DeviceConfig.fromJson(Map<String, dynamic> json) =
      _$_DeviceConfig.fromJson;

  @override
  Map<Transport, int> get enabledCapabilities;
  @override
  int? get autoEjectTimeout;
  @override
  int? get challengeResponseTimeout;
  @override
  int? get deviceFlags;
  @override
  @JsonKey(ignore: true)
  _$DeviceConfigCopyWith<_DeviceConfig> get copyWith =>
      throw _privateConstructorUsedError;
}

DeviceInfo _$DeviceInfoFromJson(Map<String, dynamic> json) {
  return _DeviceInfo.fromJson(json);
}

/// @nodoc
class _$DeviceInfoTearOff {
  const _$DeviceInfoTearOff();

  _DeviceInfo call(
      DeviceConfig config,
      int? serial,
      Version version,
      FormFactor formFactor,
      Map<Transport, int> supportedCapabilities,
      bool isLocked,
      bool isFips,
      bool isSky) {
    return _DeviceInfo(
      config,
      serial,
      version,
      formFactor,
      supportedCapabilities,
      isLocked,
      isFips,
      isSky,
    );
  }

  DeviceInfo fromJson(Map<String, Object?> json) {
    return DeviceInfo.fromJson(json);
  }
}

/// @nodoc
const $DeviceInfo = _$DeviceInfoTearOff();

/// @nodoc
mixin _$DeviceInfo {
  DeviceConfig get config => throw _privateConstructorUsedError;
  int? get serial => throw _privateConstructorUsedError;
  Version get version => throw _privateConstructorUsedError;
  FormFactor get formFactor => throw _privateConstructorUsedError;
  Map<Transport, int> get supportedCapabilities =>
      throw _privateConstructorUsedError;
  bool get isLocked => throw _privateConstructorUsedError;
  bool get isFips => throw _privateConstructorUsedError;
  bool get isSky => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $DeviceInfoCopyWith<DeviceInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DeviceInfoCopyWith<$Res> {
  factory $DeviceInfoCopyWith(
          DeviceInfo value, $Res Function(DeviceInfo) then) =
      _$DeviceInfoCopyWithImpl<$Res>;
  $Res call(
      {DeviceConfig config,
      int? serial,
      Version version,
      FormFactor formFactor,
      Map<Transport, int> supportedCapabilities,
      bool isLocked,
      bool isFips,
      bool isSky});

  $DeviceConfigCopyWith<$Res> get config;
  $VersionCopyWith<$Res> get version;
}

/// @nodoc
class _$DeviceInfoCopyWithImpl<$Res> implements $DeviceInfoCopyWith<$Res> {
  _$DeviceInfoCopyWithImpl(this._value, this._then);

  final DeviceInfo _value;
  // ignore: unused_field
  final $Res Function(DeviceInfo) _then;

  @override
  $Res call({
    Object? config = freezed,
    Object? serial = freezed,
    Object? version = freezed,
    Object? formFactor = freezed,
    Object? supportedCapabilities = freezed,
    Object? isLocked = freezed,
    Object? isFips = freezed,
    Object? isSky = freezed,
  }) {
    return _then(_value.copyWith(
      config: config == freezed
          ? _value.config
          : config // ignore: cast_nullable_to_non_nullable
              as DeviceConfig,
      serial: serial == freezed
          ? _value.serial
          : serial // ignore: cast_nullable_to_non_nullable
              as int?,
      version: version == freezed
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as Version,
      formFactor: formFactor == freezed
          ? _value.formFactor
          : formFactor // ignore: cast_nullable_to_non_nullable
              as FormFactor,
      supportedCapabilities: supportedCapabilities == freezed
          ? _value.supportedCapabilities
          : supportedCapabilities // ignore: cast_nullable_to_non_nullable
              as Map<Transport, int>,
      isLocked: isLocked == freezed
          ? _value.isLocked
          : isLocked // ignore: cast_nullable_to_non_nullable
              as bool,
      isFips: isFips == freezed
          ? _value.isFips
          : isFips // ignore: cast_nullable_to_non_nullable
              as bool,
      isSky: isSky == freezed
          ? _value.isSky
          : isSky // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }

  @override
  $DeviceConfigCopyWith<$Res> get config {
    return $DeviceConfigCopyWith<$Res>(_value.config, (value) {
      return _then(_value.copyWith(config: value));
    });
  }

  @override
  $VersionCopyWith<$Res> get version {
    return $VersionCopyWith<$Res>(_value.version, (value) {
      return _then(_value.copyWith(version: value));
    });
  }
}

/// @nodoc
abstract class _$DeviceInfoCopyWith<$Res> implements $DeviceInfoCopyWith<$Res> {
  factory _$DeviceInfoCopyWith(
          _DeviceInfo value, $Res Function(_DeviceInfo) then) =
      __$DeviceInfoCopyWithImpl<$Res>;
  @override
  $Res call(
      {DeviceConfig config,
      int? serial,
      Version version,
      FormFactor formFactor,
      Map<Transport, int> supportedCapabilities,
      bool isLocked,
      bool isFips,
      bool isSky});

  @override
  $DeviceConfigCopyWith<$Res> get config;
  @override
  $VersionCopyWith<$Res> get version;
}

/// @nodoc
class __$DeviceInfoCopyWithImpl<$Res> extends _$DeviceInfoCopyWithImpl<$Res>
    implements _$DeviceInfoCopyWith<$Res> {
  __$DeviceInfoCopyWithImpl(
      _DeviceInfo _value, $Res Function(_DeviceInfo) _then)
      : super(_value, (v) => _then(v as _DeviceInfo));

  @override
  _DeviceInfo get _value => super._value as _DeviceInfo;

  @override
  $Res call({
    Object? config = freezed,
    Object? serial = freezed,
    Object? version = freezed,
    Object? formFactor = freezed,
    Object? supportedCapabilities = freezed,
    Object? isLocked = freezed,
    Object? isFips = freezed,
    Object? isSky = freezed,
  }) {
    return _then(_DeviceInfo(
      config == freezed
          ? _value.config
          : config // ignore: cast_nullable_to_non_nullable
              as DeviceConfig,
      serial == freezed
          ? _value.serial
          : serial // ignore: cast_nullable_to_non_nullable
              as int?,
      version == freezed
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as Version,
      formFactor == freezed
          ? _value.formFactor
          : formFactor // ignore: cast_nullable_to_non_nullable
              as FormFactor,
      supportedCapabilities == freezed
          ? _value.supportedCapabilities
          : supportedCapabilities // ignore: cast_nullable_to_non_nullable
              as Map<Transport, int>,
      isLocked == freezed
          ? _value.isLocked
          : isLocked // ignore: cast_nullable_to_non_nullable
              as bool,
      isFips == freezed
          ? _value.isFips
          : isFips // ignore: cast_nullable_to_non_nullable
              as bool,
      isSky == freezed
          ? _value.isSky
          : isSky // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$_DeviceInfo implements _DeviceInfo {
  _$_DeviceInfo(this.config, this.serial, this.version, this.formFactor,
      this.supportedCapabilities, this.isLocked, this.isFips, this.isSky);

  factory _$_DeviceInfo.fromJson(Map<String, dynamic> json) =>
      _$$_DeviceInfoFromJson(json);

  @override
  final DeviceConfig config;
  @override
  final int? serial;
  @override
  final Version version;
  @override
  final FormFactor formFactor;
  @override
  final Map<Transport, int> supportedCapabilities;
  @override
  final bool isLocked;
  @override
  final bool isFips;
  @override
  final bool isSky;

  @override
  String toString() {
    return 'DeviceInfo(config: $config, serial: $serial, version: $version, formFactor: $formFactor, supportedCapabilities: $supportedCapabilities, isLocked: $isLocked, isFips: $isFips, isSky: $isSky)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _DeviceInfo &&
            const DeepCollectionEquality().equals(other.config, config) &&
            const DeepCollectionEquality().equals(other.serial, serial) &&
            const DeepCollectionEquality().equals(other.version, version) &&
            const DeepCollectionEquality()
                .equals(other.formFactor, formFactor) &&
            const DeepCollectionEquality()
                .equals(other.supportedCapabilities, supportedCapabilities) &&
            const DeepCollectionEquality().equals(other.isLocked, isLocked) &&
            const DeepCollectionEquality().equals(other.isFips, isFips) &&
            const DeepCollectionEquality().equals(other.isSky, isSky));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(config),
      const DeepCollectionEquality().hash(serial),
      const DeepCollectionEquality().hash(version),
      const DeepCollectionEquality().hash(formFactor),
      const DeepCollectionEquality().hash(supportedCapabilities),
      const DeepCollectionEquality().hash(isLocked),
      const DeepCollectionEquality().hash(isFips),
      const DeepCollectionEquality().hash(isSky));

  @JsonKey(ignore: true)
  @override
  _$DeviceInfoCopyWith<_DeviceInfo> get copyWith =>
      __$DeviceInfoCopyWithImpl<_DeviceInfo>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_DeviceInfoToJson(this);
  }
}

abstract class _DeviceInfo implements DeviceInfo {
  factory _DeviceInfo(
      DeviceConfig config,
      int? serial,
      Version version,
      FormFactor formFactor,
      Map<Transport, int> supportedCapabilities,
      bool isLocked,
      bool isFips,
      bool isSky) = _$_DeviceInfo;

  factory _DeviceInfo.fromJson(Map<String, dynamic> json) =
      _$_DeviceInfo.fromJson;

  @override
  DeviceConfig get config;
  @override
  int? get serial;
  @override
  Version get version;
  @override
  FormFactor get formFactor;
  @override
  Map<Transport, int> get supportedCapabilities;
  @override
  bool get isLocked;
  @override
  bool get isFips;
  @override
  bool get isSky;
  @override
  @JsonKey(ignore: true)
  _$DeviceInfoCopyWith<_DeviceInfo> get copyWith =>
      throw _privateConstructorUsedError;
}
