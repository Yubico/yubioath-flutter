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

OathCredential _$OathCredentialFromJson(Map<String, dynamic> json) {
  return _OathCredential.fromJson(json);
}

/// @nodoc
class _$OathCredentialTearOff {
  const _$OathCredentialTearOff();

  _OathCredential call(String deviceId, String id, String? issuer, String name,
      OathType oathType, int period, bool touchRequired) {
    return _OathCredential(
      deviceId,
      id,
      issuer,
      name,
      oathType,
      period,
      touchRequired,
    );
  }

  OathCredential fromJson(Map<String, Object?> json) {
    return OathCredential.fromJson(json);
  }
}

/// @nodoc
const $OathCredential = _$OathCredentialTearOff();

/// @nodoc
mixin _$OathCredential {
  String get deviceId => throw _privateConstructorUsedError;
  String get id => throw _privateConstructorUsedError;
  String? get issuer => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  OathType get oathType => throw _privateConstructorUsedError;
  int get period => throw _privateConstructorUsedError;
  bool get touchRequired => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $OathCredentialCopyWith<OathCredential> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OathCredentialCopyWith<$Res> {
  factory $OathCredentialCopyWith(
          OathCredential value, $Res Function(OathCredential) then) =
      _$OathCredentialCopyWithImpl<$Res>;
  $Res call(
      {String deviceId,
      String id,
      String? issuer,
      String name,
      OathType oathType,
      int period,
      bool touchRequired});
}

/// @nodoc
class _$OathCredentialCopyWithImpl<$Res>
    implements $OathCredentialCopyWith<$Res> {
  _$OathCredentialCopyWithImpl(this._value, this._then);

  final OathCredential _value;
  // ignore: unused_field
  final $Res Function(OathCredential) _then;

  @override
  $Res call({
    Object? deviceId = freezed,
    Object? id = freezed,
    Object? issuer = freezed,
    Object? name = freezed,
    Object? oathType = freezed,
    Object? period = freezed,
    Object? touchRequired = freezed,
  }) {
    return _then(_value.copyWith(
      deviceId: deviceId == freezed
          ? _value.deviceId
          : deviceId // ignore: cast_nullable_to_non_nullable
              as String,
      id: id == freezed
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      issuer: issuer == freezed
          ? _value.issuer
          : issuer // ignore: cast_nullable_to_non_nullable
              as String?,
      name: name == freezed
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      oathType: oathType == freezed
          ? _value.oathType
          : oathType // ignore: cast_nullable_to_non_nullable
              as OathType,
      period: period == freezed
          ? _value.period
          : period // ignore: cast_nullable_to_non_nullable
              as int,
      touchRequired: touchRequired == freezed
          ? _value.touchRequired
          : touchRequired // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
abstract class _$OathCredentialCopyWith<$Res>
    implements $OathCredentialCopyWith<$Res> {
  factory _$OathCredentialCopyWith(
          _OathCredential value, $Res Function(_OathCredential) then) =
      __$OathCredentialCopyWithImpl<$Res>;
  @override
  $Res call(
      {String deviceId,
      String id,
      String? issuer,
      String name,
      OathType oathType,
      int period,
      bool touchRequired});
}

/// @nodoc
class __$OathCredentialCopyWithImpl<$Res>
    extends _$OathCredentialCopyWithImpl<$Res>
    implements _$OathCredentialCopyWith<$Res> {
  __$OathCredentialCopyWithImpl(
      _OathCredential _value, $Res Function(_OathCredential) _then)
      : super(_value, (v) => _then(v as _OathCredential));

  @override
  _OathCredential get _value => super._value as _OathCredential;

  @override
  $Res call({
    Object? deviceId = freezed,
    Object? id = freezed,
    Object? issuer = freezed,
    Object? name = freezed,
    Object? oathType = freezed,
    Object? period = freezed,
    Object? touchRequired = freezed,
  }) {
    return _then(_OathCredential(
      deviceId == freezed
          ? _value.deviceId
          : deviceId // ignore: cast_nullable_to_non_nullable
              as String,
      id == freezed
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      issuer == freezed
          ? _value.issuer
          : issuer // ignore: cast_nullable_to_non_nullable
              as String?,
      name == freezed
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      oathType == freezed
          ? _value.oathType
          : oathType // ignore: cast_nullable_to_non_nullable
              as OathType,
      period == freezed
          ? _value.period
          : period // ignore: cast_nullable_to_non_nullable
              as int,
      touchRequired == freezed
          ? _value.touchRequired
          : touchRequired // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$_OathCredential implements _OathCredential {
  _$_OathCredential(this.deviceId, this.id, this.issuer, this.name,
      this.oathType, this.period, this.touchRequired);

  factory _$_OathCredential.fromJson(Map<String, dynamic> json) =>
      _$$_OathCredentialFromJson(json);

  @override
  final String deviceId;
  @override
  final String id;
  @override
  final String? issuer;
  @override
  final String name;
  @override
  final OathType oathType;
  @override
  final int period;
  @override
  final bool touchRequired;

  @override
  String toString() {
    return 'OathCredential(deviceId: $deviceId, id: $id, issuer: $issuer, name: $name, oathType: $oathType, period: $period, touchRequired: $touchRequired)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _OathCredential &&
            const DeepCollectionEquality().equals(other.deviceId, deviceId) &&
            const DeepCollectionEquality().equals(other.id, id) &&
            const DeepCollectionEquality().equals(other.issuer, issuer) &&
            const DeepCollectionEquality().equals(other.name, name) &&
            const DeepCollectionEquality().equals(other.oathType, oathType) &&
            const DeepCollectionEquality().equals(other.period, period) &&
            const DeepCollectionEquality()
                .equals(other.touchRequired, touchRequired));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(deviceId),
      const DeepCollectionEquality().hash(id),
      const DeepCollectionEquality().hash(issuer),
      const DeepCollectionEquality().hash(name),
      const DeepCollectionEquality().hash(oathType),
      const DeepCollectionEquality().hash(period),
      const DeepCollectionEquality().hash(touchRequired));

  @JsonKey(ignore: true)
  @override
  _$OathCredentialCopyWith<_OathCredential> get copyWith =>
      __$OathCredentialCopyWithImpl<_OathCredential>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_OathCredentialToJson(this);
  }
}

abstract class _OathCredential implements OathCredential {
  factory _OathCredential(
      String deviceId,
      String id,
      String? issuer,
      String name,
      OathType oathType,
      int period,
      bool touchRequired) = _$_OathCredential;

  factory _OathCredential.fromJson(Map<String, dynamic> json) =
      _$_OathCredential.fromJson;

  @override
  String get deviceId;
  @override
  String get id;
  @override
  String? get issuer;
  @override
  String get name;
  @override
  OathType get oathType;
  @override
  int get period;
  @override
  bool get touchRequired;
  @override
  @JsonKey(ignore: true)
  _$OathCredentialCopyWith<_OathCredential> get copyWith =>
      throw _privateConstructorUsedError;
}

OathCode _$OathCodeFromJson(Map<String, dynamic> json) {
  return _OathCode.fromJson(json);
}

/// @nodoc
class _$OathCodeTearOff {
  const _$OathCodeTearOff();

  _OathCode call(String value, int validFrom, int validTo) {
    return _OathCode(
      value,
      validFrom,
      validTo,
    );
  }

  OathCode fromJson(Map<String, Object?> json) {
    return OathCode.fromJson(json);
  }
}

/// @nodoc
const $OathCode = _$OathCodeTearOff();

/// @nodoc
mixin _$OathCode {
  String get value => throw _privateConstructorUsedError;
  int get validFrom => throw _privateConstructorUsedError;
  int get validTo => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $OathCodeCopyWith<OathCode> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OathCodeCopyWith<$Res> {
  factory $OathCodeCopyWith(OathCode value, $Res Function(OathCode) then) =
      _$OathCodeCopyWithImpl<$Res>;
  $Res call({String value, int validFrom, int validTo});
}

/// @nodoc
class _$OathCodeCopyWithImpl<$Res> implements $OathCodeCopyWith<$Res> {
  _$OathCodeCopyWithImpl(this._value, this._then);

  final OathCode _value;
  // ignore: unused_field
  final $Res Function(OathCode) _then;

  @override
  $Res call({
    Object? value = freezed,
    Object? validFrom = freezed,
    Object? validTo = freezed,
  }) {
    return _then(_value.copyWith(
      value: value == freezed
          ? _value.value
          : value // ignore: cast_nullable_to_non_nullable
              as String,
      validFrom: validFrom == freezed
          ? _value.validFrom
          : validFrom // ignore: cast_nullable_to_non_nullable
              as int,
      validTo: validTo == freezed
          ? _value.validTo
          : validTo // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
abstract class _$OathCodeCopyWith<$Res> implements $OathCodeCopyWith<$Res> {
  factory _$OathCodeCopyWith(_OathCode value, $Res Function(_OathCode) then) =
      __$OathCodeCopyWithImpl<$Res>;
  @override
  $Res call({String value, int validFrom, int validTo});
}

/// @nodoc
class __$OathCodeCopyWithImpl<$Res> extends _$OathCodeCopyWithImpl<$Res>
    implements _$OathCodeCopyWith<$Res> {
  __$OathCodeCopyWithImpl(_OathCode _value, $Res Function(_OathCode) _then)
      : super(_value, (v) => _then(v as _OathCode));

  @override
  _OathCode get _value => super._value as _OathCode;

  @override
  $Res call({
    Object? value = freezed,
    Object? validFrom = freezed,
    Object? validTo = freezed,
  }) {
    return _then(_OathCode(
      value == freezed
          ? _value.value
          : value // ignore: cast_nullable_to_non_nullable
              as String,
      validFrom == freezed
          ? _value.validFrom
          : validFrom // ignore: cast_nullable_to_non_nullable
              as int,
      validTo == freezed
          ? _value.validTo
          : validTo // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$_OathCode implements _OathCode {
  _$_OathCode(this.value, this.validFrom, this.validTo);

  factory _$_OathCode.fromJson(Map<String, dynamic> json) =>
      _$$_OathCodeFromJson(json);

  @override
  final String value;
  @override
  final int validFrom;
  @override
  final int validTo;

  @override
  String toString() {
    return 'OathCode(value: $value, validFrom: $validFrom, validTo: $validTo)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _OathCode &&
            const DeepCollectionEquality().equals(other.value, value) &&
            const DeepCollectionEquality().equals(other.validFrom, validFrom) &&
            const DeepCollectionEquality().equals(other.validTo, validTo));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(value),
      const DeepCollectionEquality().hash(validFrom),
      const DeepCollectionEquality().hash(validTo));

  @JsonKey(ignore: true)
  @override
  _$OathCodeCopyWith<_OathCode> get copyWith =>
      __$OathCodeCopyWithImpl<_OathCode>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_OathCodeToJson(this);
  }
}

abstract class _OathCode implements OathCode {
  factory _OathCode(String value, int validFrom, int validTo) = _$_OathCode;

  factory _OathCode.fromJson(Map<String, dynamic> json) = _$_OathCode.fromJson;

  @override
  String get value;
  @override
  int get validFrom;
  @override
  int get validTo;
  @override
  @JsonKey(ignore: true)
  _$OathCodeCopyWith<_OathCode> get copyWith =>
      throw _privateConstructorUsedError;
}

OathPair _$OathPairFromJson(Map<String, dynamic> json) {
  return _OathPair.fromJson(json);
}

/// @nodoc
class _$OathPairTearOff {
  const _$OathPairTearOff();

  _OathPair call(OathCredential credential, OathCode? code) {
    return _OathPair(
      credential,
      code,
    );
  }

  OathPair fromJson(Map<String, Object?> json) {
    return OathPair.fromJson(json);
  }
}

/// @nodoc
const $OathPair = _$OathPairTearOff();

/// @nodoc
mixin _$OathPair {
  OathCredential get credential => throw _privateConstructorUsedError;
  OathCode? get code => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $OathPairCopyWith<OathPair> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OathPairCopyWith<$Res> {
  factory $OathPairCopyWith(OathPair value, $Res Function(OathPair) then) =
      _$OathPairCopyWithImpl<$Res>;
  $Res call({OathCredential credential, OathCode? code});

  $OathCredentialCopyWith<$Res> get credential;
  $OathCodeCopyWith<$Res>? get code;
}

/// @nodoc
class _$OathPairCopyWithImpl<$Res> implements $OathPairCopyWith<$Res> {
  _$OathPairCopyWithImpl(this._value, this._then);

  final OathPair _value;
  // ignore: unused_field
  final $Res Function(OathPair) _then;

  @override
  $Res call({
    Object? credential = freezed,
    Object? code = freezed,
  }) {
    return _then(_value.copyWith(
      credential: credential == freezed
          ? _value.credential
          : credential // ignore: cast_nullable_to_non_nullable
              as OathCredential,
      code: code == freezed
          ? _value.code
          : code // ignore: cast_nullable_to_non_nullable
              as OathCode?,
    ));
  }

  @override
  $OathCredentialCopyWith<$Res> get credential {
    return $OathCredentialCopyWith<$Res>(_value.credential, (value) {
      return _then(_value.copyWith(credential: value));
    });
  }

  @override
  $OathCodeCopyWith<$Res>? get code {
    if (_value.code == null) {
      return null;
    }

    return $OathCodeCopyWith<$Res>(_value.code!, (value) {
      return _then(_value.copyWith(code: value));
    });
  }
}

/// @nodoc
abstract class _$OathPairCopyWith<$Res> implements $OathPairCopyWith<$Res> {
  factory _$OathPairCopyWith(_OathPair value, $Res Function(_OathPair) then) =
      __$OathPairCopyWithImpl<$Res>;
  @override
  $Res call({OathCredential credential, OathCode? code});

  @override
  $OathCredentialCopyWith<$Res> get credential;
  @override
  $OathCodeCopyWith<$Res>? get code;
}

/// @nodoc
class __$OathPairCopyWithImpl<$Res> extends _$OathPairCopyWithImpl<$Res>
    implements _$OathPairCopyWith<$Res> {
  __$OathPairCopyWithImpl(_OathPair _value, $Res Function(_OathPair) _then)
      : super(_value, (v) => _then(v as _OathPair));

  @override
  _OathPair get _value => super._value as _OathPair;

  @override
  $Res call({
    Object? credential = freezed,
    Object? code = freezed,
  }) {
    return _then(_OathPair(
      credential == freezed
          ? _value.credential
          : credential // ignore: cast_nullable_to_non_nullable
              as OathCredential,
      code == freezed
          ? _value.code
          : code // ignore: cast_nullable_to_non_nullable
              as OathCode?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$_OathPair implements _OathPair {
  _$_OathPair(this.credential, this.code);

  factory _$_OathPair.fromJson(Map<String, dynamic> json) =>
      _$$_OathPairFromJson(json);

  @override
  final OathCredential credential;
  @override
  final OathCode? code;

  @override
  String toString() {
    return 'OathPair(credential: $credential, code: $code)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _OathPair &&
            const DeepCollectionEquality()
                .equals(other.credential, credential) &&
            const DeepCollectionEquality().equals(other.code, code));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(credential),
      const DeepCollectionEquality().hash(code));

  @JsonKey(ignore: true)
  @override
  _$OathPairCopyWith<_OathPair> get copyWith =>
      __$OathPairCopyWithImpl<_OathPair>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_OathPairToJson(this);
  }
}

abstract class _OathPair implements OathPair {
  factory _OathPair(OathCredential credential, OathCode? code) = _$_OathPair;

  factory _OathPair.fromJson(Map<String, dynamic> json) = _$_OathPair.fromJson;

  @override
  OathCredential get credential;
  @override
  OathCode? get code;
  @override
  @JsonKey(ignore: true)
  _$OathPairCopyWith<_OathPair> get copyWith =>
      throw _privateConstructorUsedError;
}

OathState _$OathStateFromJson(Map<String, dynamic> json) {
  return _OathState.fromJson(json);
}

/// @nodoc
class _$OathStateTearOff {
  const _$OathStateTearOff();

  _OathState call(String deviceId,
      {required bool hasKey,
      required bool remembered,
      required bool locked,
      required KeystoreState keystore}) {
    return _OathState(
      deviceId,
      hasKey: hasKey,
      remembered: remembered,
      locked: locked,
      keystore: keystore,
    );
  }

  OathState fromJson(Map<String, Object?> json) {
    return OathState.fromJson(json);
  }
}

/// @nodoc
const $OathState = _$OathStateTearOff();

/// @nodoc
mixin _$OathState {
  String get deviceId => throw _privateConstructorUsedError;
  bool get hasKey => throw _privateConstructorUsedError;
  bool get remembered => throw _privateConstructorUsedError;
  bool get locked => throw _privateConstructorUsedError;
  KeystoreState get keystore => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $OathStateCopyWith<OathState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OathStateCopyWith<$Res> {
  factory $OathStateCopyWith(OathState value, $Res Function(OathState) then) =
      _$OathStateCopyWithImpl<$Res>;
  $Res call(
      {String deviceId,
      bool hasKey,
      bool remembered,
      bool locked,
      KeystoreState keystore});
}

/// @nodoc
class _$OathStateCopyWithImpl<$Res> implements $OathStateCopyWith<$Res> {
  _$OathStateCopyWithImpl(this._value, this._then);

  final OathState _value;
  // ignore: unused_field
  final $Res Function(OathState) _then;

  @override
  $Res call({
    Object? deviceId = freezed,
    Object? hasKey = freezed,
    Object? remembered = freezed,
    Object? locked = freezed,
    Object? keystore = freezed,
  }) {
    return _then(_value.copyWith(
      deviceId: deviceId == freezed
          ? _value.deviceId
          : deviceId // ignore: cast_nullable_to_non_nullable
              as String,
      hasKey: hasKey == freezed
          ? _value.hasKey
          : hasKey // ignore: cast_nullable_to_non_nullable
              as bool,
      remembered: remembered == freezed
          ? _value.remembered
          : remembered // ignore: cast_nullable_to_non_nullable
              as bool,
      locked: locked == freezed
          ? _value.locked
          : locked // ignore: cast_nullable_to_non_nullable
              as bool,
      keystore: keystore == freezed
          ? _value.keystore
          : keystore // ignore: cast_nullable_to_non_nullable
              as KeystoreState,
    ));
  }
}

/// @nodoc
abstract class _$OathStateCopyWith<$Res> implements $OathStateCopyWith<$Res> {
  factory _$OathStateCopyWith(
          _OathState value, $Res Function(_OathState) then) =
      __$OathStateCopyWithImpl<$Res>;
  @override
  $Res call(
      {String deviceId,
      bool hasKey,
      bool remembered,
      bool locked,
      KeystoreState keystore});
}

/// @nodoc
class __$OathStateCopyWithImpl<$Res> extends _$OathStateCopyWithImpl<$Res>
    implements _$OathStateCopyWith<$Res> {
  __$OathStateCopyWithImpl(_OathState _value, $Res Function(_OathState) _then)
      : super(_value, (v) => _then(v as _OathState));

  @override
  _OathState get _value => super._value as _OathState;

  @override
  $Res call({
    Object? deviceId = freezed,
    Object? hasKey = freezed,
    Object? remembered = freezed,
    Object? locked = freezed,
    Object? keystore = freezed,
  }) {
    return _then(_OathState(
      deviceId == freezed
          ? _value.deviceId
          : deviceId // ignore: cast_nullable_to_non_nullable
              as String,
      hasKey: hasKey == freezed
          ? _value.hasKey
          : hasKey // ignore: cast_nullable_to_non_nullable
              as bool,
      remembered: remembered == freezed
          ? _value.remembered
          : remembered // ignore: cast_nullable_to_non_nullable
              as bool,
      locked: locked == freezed
          ? _value.locked
          : locked // ignore: cast_nullable_to_non_nullable
              as bool,
      keystore: keystore == freezed
          ? _value.keystore
          : keystore // ignore: cast_nullable_to_non_nullable
              as KeystoreState,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$_OathState implements _OathState {
  _$_OathState(this.deviceId,
      {required this.hasKey,
      required this.remembered,
      required this.locked,
      required this.keystore});

  factory _$_OathState.fromJson(Map<String, dynamic> json) =>
      _$$_OathStateFromJson(json);

  @override
  final String deviceId;
  @override
  final bool hasKey;
  @override
  final bool remembered;
  @override
  final bool locked;
  @override
  final KeystoreState keystore;

  @override
  String toString() {
    return 'OathState(deviceId: $deviceId, hasKey: $hasKey, remembered: $remembered, locked: $locked, keystore: $keystore)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _OathState &&
            const DeepCollectionEquality().equals(other.deviceId, deviceId) &&
            const DeepCollectionEquality().equals(other.hasKey, hasKey) &&
            const DeepCollectionEquality()
                .equals(other.remembered, remembered) &&
            const DeepCollectionEquality().equals(other.locked, locked) &&
            const DeepCollectionEquality().equals(other.keystore, keystore));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(deviceId),
      const DeepCollectionEquality().hash(hasKey),
      const DeepCollectionEquality().hash(remembered),
      const DeepCollectionEquality().hash(locked),
      const DeepCollectionEquality().hash(keystore));

  @JsonKey(ignore: true)
  @override
  _$OathStateCopyWith<_OathState> get copyWith =>
      __$OathStateCopyWithImpl<_OathState>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_OathStateToJson(this);
  }
}

abstract class _OathState implements OathState {
  factory _OathState(String deviceId,
      {required bool hasKey,
      required bool remembered,
      required bool locked,
      required KeystoreState keystore}) = _$_OathState;

  factory _OathState.fromJson(Map<String, dynamic> json) =
      _$_OathState.fromJson;

  @override
  String get deviceId;
  @override
  bool get hasKey;
  @override
  bool get remembered;
  @override
  bool get locked;
  @override
  KeystoreState get keystore;
  @override
  @JsonKey(ignore: true)
  _$OathStateCopyWith<_OathState> get copyWith =>
      throw _privateConstructorUsedError;
}

CredentialData _$CredentialDataFromJson(Map<String, dynamic> json) {
  return _CredentialData.fromJson(json);
}

/// @nodoc
class _$CredentialDataTearOff {
  const _$CredentialDataTearOff();

  _CredentialData call(
      {String? issuer,
      required String name,
      required String secret,
      OathType oathType = defaultOathType,
      HashAlgorithm hashAlgorithm = defaultHashAlgorithm,
      int digits = defaultDigits,
      int period = defaultPeriod,
      int counter = defaultCounter}) {
    return _CredentialData(
      issuer: issuer,
      name: name,
      secret: secret,
      oathType: oathType,
      hashAlgorithm: hashAlgorithm,
      digits: digits,
      period: period,
      counter: counter,
    );
  }

  CredentialData fromJson(Map<String, Object?> json) {
    return CredentialData.fromJson(json);
  }
}

/// @nodoc
const $CredentialData = _$CredentialDataTearOff();

/// @nodoc
mixin _$CredentialData {
  String? get issuer => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get secret => throw _privateConstructorUsedError;
  OathType get oathType => throw _privateConstructorUsedError;
  HashAlgorithm get hashAlgorithm => throw _privateConstructorUsedError;
  int get digits => throw _privateConstructorUsedError;
  int get period => throw _privateConstructorUsedError;
  int get counter => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $CredentialDataCopyWith<CredentialData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CredentialDataCopyWith<$Res> {
  factory $CredentialDataCopyWith(
          CredentialData value, $Res Function(CredentialData) then) =
      _$CredentialDataCopyWithImpl<$Res>;
  $Res call(
      {String? issuer,
      String name,
      String secret,
      OathType oathType,
      HashAlgorithm hashAlgorithm,
      int digits,
      int period,
      int counter});
}

/// @nodoc
class _$CredentialDataCopyWithImpl<$Res>
    implements $CredentialDataCopyWith<$Res> {
  _$CredentialDataCopyWithImpl(this._value, this._then);

  final CredentialData _value;
  // ignore: unused_field
  final $Res Function(CredentialData) _then;

  @override
  $Res call({
    Object? issuer = freezed,
    Object? name = freezed,
    Object? secret = freezed,
    Object? oathType = freezed,
    Object? hashAlgorithm = freezed,
    Object? digits = freezed,
    Object? period = freezed,
    Object? counter = freezed,
  }) {
    return _then(_value.copyWith(
      issuer: issuer == freezed
          ? _value.issuer
          : issuer // ignore: cast_nullable_to_non_nullable
              as String?,
      name: name == freezed
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      secret: secret == freezed
          ? _value.secret
          : secret // ignore: cast_nullable_to_non_nullable
              as String,
      oathType: oathType == freezed
          ? _value.oathType
          : oathType // ignore: cast_nullable_to_non_nullable
              as OathType,
      hashAlgorithm: hashAlgorithm == freezed
          ? _value.hashAlgorithm
          : hashAlgorithm // ignore: cast_nullable_to_non_nullable
              as HashAlgorithm,
      digits: digits == freezed
          ? _value.digits
          : digits // ignore: cast_nullable_to_non_nullable
              as int,
      period: period == freezed
          ? _value.period
          : period // ignore: cast_nullable_to_non_nullable
              as int,
      counter: counter == freezed
          ? _value.counter
          : counter // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
abstract class _$CredentialDataCopyWith<$Res>
    implements $CredentialDataCopyWith<$Res> {
  factory _$CredentialDataCopyWith(
          _CredentialData value, $Res Function(_CredentialData) then) =
      __$CredentialDataCopyWithImpl<$Res>;
  @override
  $Res call(
      {String? issuer,
      String name,
      String secret,
      OathType oathType,
      HashAlgorithm hashAlgorithm,
      int digits,
      int period,
      int counter});
}

/// @nodoc
class __$CredentialDataCopyWithImpl<$Res>
    extends _$CredentialDataCopyWithImpl<$Res>
    implements _$CredentialDataCopyWith<$Res> {
  __$CredentialDataCopyWithImpl(
      _CredentialData _value, $Res Function(_CredentialData) _then)
      : super(_value, (v) => _then(v as _CredentialData));

  @override
  _CredentialData get _value => super._value as _CredentialData;

  @override
  $Res call({
    Object? issuer = freezed,
    Object? name = freezed,
    Object? secret = freezed,
    Object? oathType = freezed,
    Object? hashAlgorithm = freezed,
    Object? digits = freezed,
    Object? period = freezed,
    Object? counter = freezed,
  }) {
    return _then(_CredentialData(
      issuer: issuer == freezed
          ? _value.issuer
          : issuer // ignore: cast_nullable_to_non_nullable
              as String?,
      name: name == freezed
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      secret: secret == freezed
          ? _value.secret
          : secret // ignore: cast_nullable_to_non_nullable
              as String,
      oathType: oathType == freezed
          ? _value.oathType
          : oathType // ignore: cast_nullable_to_non_nullable
              as OathType,
      hashAlgorithm: hashAlgorithm == freezed
          ? _value.hashAlgorithm
          : hashAlgorithm // ignore: cast_nullable_to_non_nullable
              as HashAlgorithm,
      digits: digits == freezed
          ? _value.digits
          : digits // ignore: cast_nullable_to_non_nullable
              as int,
      period: period == freezed
          ? _value.period
          : period // ignore: cast_nullable_to_non_nullable
              as int,
      counter: counter == freezed
          ? _value.counter
          : counter // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$_CredentialData extends _CredentialData {
  _$_CredentialData(
      {this.issuer,
      required this.name,
      required this.secret,
      this.oathType = defaultOathType,
      this.hashAlgorithm = defaultHashAlgorithm,
      this.digits = defaultDigits,
      this.period = defaultPeriod,
      this.counter = defaultCounter})
      : super._();

  factory _$_CredentialData.fromJson(Map<String, dynamic> json) =>
      _$$_CredentialDataFromJson(json);

  @override
  final String? issuer;
  @override
  final String name;
  @override
  final String secret;
  @JsonKey()
  @override
  final OathType oathType;
  @JsonKey()
  @override
  final HashAlgorithm hashAlgorithm;
  @JsonKey()
  @override
  final int digits;
  @JsonKey()
  @override
  final int period;
  @JsonKey()
  @override
  final int counter;

  @override
  String toString() {
    return 'CredentialData(issuer: $issuer, name: $name, secret: $secret, oathType: $oathType, hashAlgorithm: $hashAlgorithm, digits: $digits, period: $period, counter: $counter)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _CredentialData &&
            const DeepCollectionEquality().equals(other.issuer, issuer) &&
            const DeepCollectionEquality().equals(other.name, name) &&
            const DeepCollectionEquality().equals(other.secret, secret) &&
            const DeepCollectionEquality().equals(other.oathType, oathType) &&
            const DeepCollectionEquality()
                .equals(other.hashAlgorithm, hashAlgorithm) &&
            const DeepCollectionEquality().equals(other.digits, digits) &&
            const DeepCollectionEquality().equals(other.period, period) &&
            const DeepCollectionEquality().equals(other.counter, counter));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(issuer),
      const DeepCollectionEquality().hash(name),
      const DeepCollectionEquality().hash(secret),
      const DeepCollectionEquality().hash(oathType),
      const DeepCollectionEquality().hash(hashAlgorithm),
      const DeepCollectionEquality().hash(digits),
      const DeepCollectionEquality().hash(period),
      const DeepCollectionEquality().hash(counter));

  @JsonKey(ignore: true)
  @override
  _$CredentialDataCopyWith<_CredentialData> get copyWith =>
      __$CredentialDataCopyWithImpl<_CredentialData>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_CredentialDataToJson(this);
  }
}

abstract class _CredentialData extends CredentialData {
  factory _CredentialData(
      {String? issuer,
      required String name,
      required String secret,
      OathType oathType,
      HashAlgorithm hashAlgorithm,
      int digits,
      int period,
      int counter}) = _$_CredentialData;
  _CredentialData._() : super._();

  factory _CredentialData.fromJson(Map<String, dynamic> json) =
      _$_CredentialData.fromJson;

  @override
  String? get issuer;
  @override
  String get name;
  @override
  String get secret;
  @override
  OathType get oathType;
  @override
  HashAlgorithm get hashAlgorithm;
  @override
  int get digits;
  @override
  int get period;
  @override
  int get counter;
  @override
  @JsonKey(ignore: true)
  _$CredentialDataCopyWith<_CredentialData> get copyWith =>
      throw _privateConstructorUsedError;
}
