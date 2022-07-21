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

DeviceConfig _$DeviceConfigFromJson(Map<String, dynamic> json) {
  return _DeviceConfig.fromJson(json);
}

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
abstract class _$$_DeviceConfigCopyWith<$Res>
    implements $DeviceConfigCopyWith<$Res> {
  factory _$$_DeviceConfigCopyWith(
          _$_DeviceConfig value, $Res Function(_$_DeviceConfig) then) =
      __$$_DeviceConfigCopyWithImpl<$Res>;
  @override
  $Res call(
      {Map<Transport, int> enabledCapabilities,
      int? autoEjectTimeout,
      int? challengeResponseTimeout,
      int? deviceFlags});
}

/// @nodoc
class __$$_DeviceConfigCopyWithImpl<$Res>
    extends _$DeviceConfigCopyWithImpl<$Res>
    implements _$$_DeviceConfigCopyWith<$Res> {
  __$$_DeviceConfigCopyWithImpl(
      _$_DeviceConfig _value, $Res Function(_$_DeviceConfig) _then)
      : super(_value, (v) => _then(v as _$_DeviceConfig));

  @override
  _$_DeviceConfig get _value => super._value as _$_DeviceConfig;

  @override
  $Res call({
    Object? enabledCapabilities = freezed,
    Object? autoEjectTimeout = freezed,
    Object? challengeResponseTimeout = freezed,
    Object? deviceFlags = freezed,
  }) {
    return _then(_$_DeviceConfig(
      enabledCapabilities == freezed
          ? _value._enabledCapabilities
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
  _$_DeviceConfig(final Map<Transport, int> enabledCapabilities,
      this.autoEjectTimeout, this.challengeResponseTimeout, this.deviceFlags)
      : _enabledCapabilities = enabledCapabilities;

  factory _$_DeviceConfig.fromJson(Map<String, dynamic> json) =>
      _$$_DeviceConfigFromJson(json);

  final Map<Transport, int> _enabledCapabilities;
  @override
  Map<Transport, int> get enabledCapabilities {
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_enabledCapabilities);
  }

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
            other is _$_DeviceConfig &&
            const DeepCollectionEquality()
                .equals(other._enabledCapabilities, _enabledCapabilities) &&
            const DeepCollectionEquality()
                .equals(other.autoEjectTimeout, autoEjectTimeout) &&
            const DeepCollectionEquality().equals(
                other.challengeResponseTimeout, challengeResponseTimeout) &&
            const DeepCollectionEquality()
                .equals(other.deviceFlags, deviceFlags));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_enabledCapabilities),
      const DeepCollectionEquality().hash(autoEjectTimeout),
      const DeepCollectionEquality().hash(challengeResponseTimeout),
      const DeepCollectionEquality().hash(deviceFlags));

  @JsonKey(ignore: true)
  @override
  _$$_DeviceConfigCopyWith<_$_DeviceConfig> get copyWith =>
      __$$_DeviceConfigCopyWithImpl<_$_DeviceConfig>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_DeviceConfigToJson(this);
  }
}

abstract class _DeviceConfig implements DeviceConfig {
  factory _DeviceConfig(
      final Map<Transport, int> enabledCapabilities,
      final int? autoEjectTimeout,
      final int? challengeResponseTimeout,
      final int? deviceFlags) = _$_DeviceConfig;

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
  _$$_DeviceConfigCopyWith<_$_DeviceConfig> get copyWith =>
      throw _privateConstructorUsedError;
}

DeviceInfo _$DeviceInfoFromJson(Map<String, dynamic> json) {
  return _DeviceInfo.fromJson(json);
}

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
abstract class _$$_DeviceInfoCopyWith<$Res>
    implements $DeviceInfoCopyWith<$Res> {
  factory _$$_DeviceInfoCopyWith(
          _$_DeviceInfo value, $Res Function(_$_DeviceInfo) then) =
      __$$_DeviceInfoCopyWithImpl<$Res>;
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
class __$$_DeviceInfoCopyWithImpl<$Res> extends _$DeviceInfoCopyWithImpl<$Res>
    implements _$$_DeviceInfoCopyWith<$Res> {
  __$$_DeviceInfoCopyWithImpl(
      _$_DeviceInfo _value, $Res Function(_$_DeviceInfo) _then)
      : super(_value, (v) => _then(v as _$_DeviceInfo));

  @override
  _$_DeviceInfo get _value => super._value as _$_DeviceInfo;

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
    return _then(_$_DeviceInfo(
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
          ? _value._supportedCapabilities
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
  _$_DeviceInfo(
      this.config,
      this.serial,
      this.version,
      this.formFactor,
      final Map<Transport, int> supportedCapabilities,
      this.isLocked,
      this.isFips,
      this.isSky)
      : _supportedCapabilities = supportedCapabilities;

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
  final Map<Transport, int> _supportedCapabilities;
  @override
  Map<Transport, int> get supportedCapabilities {
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_supportedCapabilities);
  }

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
            other is _$_DeviceInfo &&
            const DeepCollectionEquality().equals(other.config, config) &&
            const DeepCollectionEquality().equals(other.serial, serial) &&
            const DeepCollectionEquality().equals(other.version, version) &&
            const DeepCollectionEquality()
                .equals(other.formFactor, formFactor) &&
            const DeepCollectionEquality()
                .equals(other._supportedCapabilities, _supportedCapabilities) &&
            const DeepCollectionEquality().equals(other.isLocked, isLocked) &&
            const DeepCollectionEquality().equals(other.isFips, isFips) &&
            const DeepCollectionEquality().equals(other.isSky, isSky));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(config),
      const DeepCollectionEquality().hash(serial),
      const DeepCollectionEquality().hash(version),
      const DeepCollectionEquality().hash(formFactor),
      const DeepCollectionEquality().hash(_supportedCapabilities),
      const DeepCollectionEquality().hash(isLocked),
      const DeepCollectionEquality().hash(isFips),
      const DeepCollectionEquality().hash(isSky));

  @JsonKey(ignore: true)
  @override
  _$$_DeviceInfoCopyWith<_$_DeviceInfo> get copyWith =>
      __$$_DeviceInfoCopyWithImpl<_$_DeviceInfo>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_DeviceInfoToJson(this);
  }
}

abstract class _DeviceInfo implements DeviceInfo {
  factory _DeviceInfo(
      final DeviceConfig config,
      final int? serial,
      final Version version,
      final FormFactor formFactor,
      final Map<Transport, int> supportedCapabilities,
      final bool isLocked,
      final bool isFips,
      final bool isSky) = _$_DeviceInfo;

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
  _$$_DeviceInfoCopyWith<_$_DeviceInfo> get copyWith =>
      throw _privateConstructorUsedError;
}
