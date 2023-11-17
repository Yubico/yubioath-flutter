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

OathCredential _$OathCredentialFromJson(Map<String, dynamic> json) {
  return _OathCredential.fromJson(json);
}

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
      _$OathCredentialCopyWithImpl<$Res, OathCredential>;
  @useResult
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
class _$OathCredentialCopyWithImpl<$Res, $Val extends OathCredential>
    implements $OathCredentialCopyWith<$Res> {
  _$OathCredentialCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? deviceId = null,
    Object? id = null,
    Object? issuer = freezed,
    Object? name = null,
    Object? oathType = null,
    Object? period = null,
    Object? touchRequired = null,
  }) {
    return _then(_value.copyWith(
      deviceId: null == deviceId
          ? _value.deviceId
          : deviceId // ignore: cast_nullable_to_non_nullable
              as String,
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      issuer: freezed == issuer
          ? _value.issuer
          : issuer // ignore: cast_nullable_to_non_nullable
              as String?,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      oathType: null == oathType
          ? _value.oathType
          : oathType // ignore: cast_nullable_to_non_nullable
              as OathType,
      period: null == period
          ? _value.period
          : period // ignore: cast_nullable_to_non_nullable
              as int,
      touchRequired: null == touchRequired
          ? _value.touchRequired
          : touchRequired // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$OathCredentialImplCopyWith<$Res>
    implements $OathCredentialCopyWith<$Res> {
  factory _$$OathCredentialImplCopyWith(_$OathCredentialImpl value,
          $Res Function(_$OathCredentialImpl) then) =
      __$$OathCredentialImplCopyWithImpl<$Res>;
  @override
  @useResult
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
class __$$OathCredentialImplCopyWithImpl<$Res>
    extends _$OathCredentialCopyWithImpl<$Res, _$OathCredentialImpl>
    implements _$$OathCredentialImplCopyWith<$Res> {
  __$$OathCredentialImplCopyWithImpl(
      _$OathCredentialImpl _value, $Res Function(_$OathCredentialImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? deviceId = null,
    Object? id = null,
    Object? issuer = freezed,
    Object? name = null,
    Object? oathType = null,
    Object? period = null,
    Object? touchRequired = null,
  }) {
    return _then(_$OathCredentialImpl(
      null == deviceId
          ? _value.deviceId
          : deviceId // ignore: cast_nullable_to_non_nullable
              as String,
      null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      freezed == issuer
          ? _value.issuer
          : issuer // ignore: cast_nullable_to_non_nullable
              as String?,
      null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      null == oathType
          ? _value.oathType
          : oathType // ignore: cast_nullable_to_non_nullable
              as OathType,
      null == period
          ? _value.period
          : period // ignore: cast_nullable_to_non_nullable
              as int,
      null == touchRequired
          ? _value.touchRequired
          : touchRequired // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$OathCredentialImpl implements _OathCredential {
  _$OathCredentialImpl(this.deviceId, this.id, this.issuer, this.name,
      this.oathType, this.period, this.touchRequired);

  factory _$OathCredentialImpl.fromJson(Map<String, dynamic> json) =>
      _$$OathCredentialImplFromJson(json);

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
            other is _$OathCredentialImpl &&
            (identical(other.deviceId, deviceId) ||
                other.deviceId == deviceId) &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.issuer, issuer) || other.issuer == issuer) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.oathType, oathType) ||
                other.oathType == oathType) &&
            (identical(other.period, period) || other.period == period) &&
            (identical(other.touchRequired, touchRequired) ||
                other.touchRequired == touchRequired));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, deviceId, id, issuer, name, oathType, period, touchRequired);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$OathCredentialImplCopyWith<_$OathCredentialImpl> get copyWith =>
      __$$OathCredentialImplCopyWithImpl<_$OathCredentialImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OathCredentialImplToJson(
      this,
    );
  }
}

abstract class _OathCredential implements OathCredential {
  factory _OathCredential(
      final String deviceId,
      final String id,
      final String? issuer,
      final String name,
      final OathType oathType,
      final int period,
      final bool touchRequired) = _$OathCredentialImpl;

  factory _OathCredential.fromJson(Map<String, dynamic> json) =
      _$OathCredentialImpl.fromJson;

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
  _$$OathCredentialImplCopyWith<_$OathCredentialImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

OathCode _$OathCodeFromJson(Map<String, dynamic> json) {
  return _OathCode.fromJson(json);
}

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
      _$OathCodeCopyWithImpl<$Res, OathCode>;
  @useResult
  $Res call({String value, int validFrom, int validTo});
}

/// @nodoc
class _$OathCodeCopyWithImpl<$Res, $Val extends OathCode>
    implements $OathCodeCopyWith<$Res> {
  _$OathCodeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? value = null,
    Object? validFrom = null,
    Object? validTo = null,
  }) {
    return _then(_value.copyWith(
      value: null == value
          ? _value.value
          : value // ignore: cast_nullable_to_non_nullable
              as String,
      validFrom: null == validFrom
          ? _value.validFrom
          : validFrom // ignore: cast_nullable_to_non_nullable
              as int,
      validTo: null == validTo
          ? _value.validTo
          : validTo // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$OathCodeImplCopyWith<$Res>
    implements $OathCodeCopyWith<$Res> {
  factory _$$OathCodeImplCopyWith(
          _$OathCodeImpl value, $Res Function(_$OathCodeImpl) then) =
      __$$OathCodeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String value, int validFrom, int validTo});
}

/// @nodoc
class __$$OathCodeImplCopyWithImpl<$Res>
    extends _$OathCodeCopyWithImpl<$Res, _$OathCodeImpl>
    implements _$$OathCodeImplCopyWith<$Res> {
  __$$OathCodeImplCopyWithImpl(
      _$OathCodeImpl _value, $Res Function(_$OathCodeImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? value = null,
    Object? validFrom = null,
    Object? validTo = null,
  }) {
    return _then(_$OathCodeImpl(
      null == value
          ? _value.value
          : value // ignore: cast_nullable_to_non_nullable
              as String,
      null == validFrom
          ? _value.validFrom
          : validFrom // ignore: cast_nullable_to_non_nullable
              as int,
      null == validTo
          ? _value.validTo
          : validTo // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$OathCodeImpl implements _OathCode {
  _$OathCodeImpl(this.value, this.validFrom, this.validTo);

  factory _$OathCodeImpl.fromJson(Map<String, dynamic> json) =>
      _$$OathCodeImplFromJson(json);

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
            other is _$OathCodeImpl &&
            (identical(other.value, value) || other.value == value) &&
            (identical(other.validFrom, validFrom) ||
                other.validFrom == validFrom) &&
            (identical(other.validTo, validTo) || other.validTo == validTo));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, value, validFrom, validTo);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$OathCodeImplCopyWith<_$OathCodeImpl> get copyWith =>
      __$$OathCodeImplCopyWithImpl<_$OathCodeImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OathCodeImplToJson(
      this,
    );
  }
}

abstract class _OathCode implements OathCode {
  factory _OathCode(
          final String value, final int validFrom, final int validTo) =
      _$OathCodeImpl;

  factory _OathCode.fromJson(Map<String, dynamic> json) =
      _$OathCodeImpl.fromJson;

  @override
  String get value;
  @override
  int get validFrom;
  @override
  int get validTo;
  @override
  @JsonKey(ignore: true)
  _$$OathCodeImplCopyWith<_$OathCodeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

OathPair _$OathPairFromJson(Map<String, dynamic> json) {
  return _OathPair.fromJson(json);
}

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
      _$OathPairCopyWithImpl<$Res, OathPair>;
  @useResult
  $Res call({OathCredential credential, OathCode? code});

  $OathCredentialCopyWith<$Res> get credential;
  $OathCodeCopyWith<$Res>? get code;
}

/// @nodoc
class _$OathPairCopyWithImpl<$Res, $Val extends OathPair>
    implements $OathPairCopyWith<$Res> {
  _$OathPairCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? credential = null,
    Object? code = freezed,
  }) {
    return _then(_value.copyWith(
      credential: null == credential
          ? _value.credential
          : credential // ignore: cast_nullable_to_non_nullable
              as OathCredential,
      code: freezed == code
          ? _value.code
          : code // ignore: cast_nullable_to_non_nullable
              as OathCode?,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $OathCredentialCopyWith<$Res> get credential {
    return $OathCredentialCopyWith<$Res>(_value.credential, (value) {
      return _then(_value.copyWith(credential: value) as $Val);
    });
  }

  @override
  @pragma('vm:prefer-inline')
  $OathCodeCopyWith<$Res>? get code {
    if (_value.code == null) {
      return null;
    }

    return $OathCodeCopyWith<$Res>(_value.code!, (value) {
      return _then(_value.copyWith(code: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$OathPairImplCopyWith<$Res>
    implements $OathPairCopyWith<$Res> {
  factory _$$OathPairImplCopyWith(
          _$OathPairImpl value, $Res Function(_$OathPairImpl) then) =
      __$$OathPairImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({OathCredential credential, OathCode? code});

  @override
  $OathCredentialCopyWith<$Res> get credential;
  @override
  $OathCodeCopyWith<$Res>? get code;
}

/// @nodoc
class __$$OathPairImplCopyWithImpl<$Res>
    extends _$OathPairCopyWithImpl<$Res, _$OathPairImpl>
    implements _$$OathPairImplCopyWith<$Res> {
  __$$OathPairImplCopyWithImpl(
      _$OathPairImpl _value, $Res Function(_$OathPairImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? credential = null,
    Object? code = freezed,
  }) {
    return _then(_$OathPairImpl(
      null == credential
          ? _value.credential
          : credential // ignore: cast_nullable_to_non_nullable
              as OathCredential,
      freezed == code
          ? _value.code
          : code // ignore: cast_nullable_to_non_nullable
              as OathCode?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$OathPairImpl implements _OathPair {
  _$OathPairImpl(this.credential, this.code);

  factory _$OathPairImpl.fromJson(Map<String, dynamic> json) =>
      _$$OathPairImplFromJson(json);

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
            other is _$OathPairImpl &&
            (identical(other.credential, credential) ||
                other.credential == credential) &&
            (identical(other.code, code) || other.code == code));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, credential, code);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$OathPairImplCopyWith<_$OathPairImpl> get copyWith =>
      __$$OathPairImplCopyWithImpl<_$OathPairImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OathPairImplToJson(
      this,
    );
  }
}

abstract class _OathPair implements OathPair {
  factory _OathPair(final OathCredential credential, final OathCode? code) =
      _$OathPairImpl;

  factory _OathPair.fromJson(Map<String, dynamic> json) =
      _$OathPairImpl.fromJson;

  @override
  OathCredential get credential;
  @override
  OathCode? get code;
  @override
  @JsonKey(ignore: true)
  _$$OathPairImplCopyWith<_$OathPairImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

OathState _$OathStateFromJson(Map<String, dynamic> json) {
  return _OathState.fromJson(json);
}

/// @nodoc
mixin _$OathState {
  String get deviceId => throw _privateConstructorUsedError;
  Version get version => throw _privateConstructorUsedError;
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
      _$OathStateCopyWithImpl<$Res, OathState>;
  @useResult
  $Res call(
      {String deviceId,
      Version version,
      bool hasKey,
      bool remembered,
      bool locked,
      KeystoreState keystore});

  $VersionCopyWith<$Res> get version;
}

/// @nodoc
class _$OathStateCopyWithImpl<$Res, $Val extends OathState>
    implements $OathStateCopyWith<$Res> {
  _$OathStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? deviceId = null,
    Object? version = null,
    Object? hasKey = null,
    Object? remembered = null,
    Object? locked = null,
    Object? keystore = null,
  }) {
    return _then(_value.copyWith(
      deviceId: null == deviceId
          ? _value.deviceId
          : deviceId // ignore: cast_nullable_to_non_nullable
              as String,
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as Version,
      hasKey: null == hasKey
          ? _value.hasKey
          : hasKey // ignore: cast_nullable_to_non_nullable
              as bool,
      remembered: null == remembered
          ? _value.remembered
          : remembered // ignore: cast_nullable_to_non_nullable
              as bool,
      locked: null == locked
          ? _value.locked
          : locked // ignore: cast_nullable_to_non_nullable
              as bool,
      keystore: null == keystore
          ? _value.keystore
          : keystore // ignore: cast_nullable_to_non_nullable
              as KeystoreState,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $VersionCopyWith<$Res> get version {
    return $VersionCopyWith<$Res>(_value.version, (value) {
      return _then(_value.copyWith(version: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$OathStateImplCopyWith<$Res>
    implements $OathStateCopyWith<$Res> {
  factory _$$OathStateImplCopyWith(
          _$OathStateImpl value, $Res Function(_$OathStateImpl) then) =
      __$$OathStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String deviceId,
      Version version,
      bool hasKey,
      bool remembered,
      bool locked,
      KeystoreState keystore});

  @override
  $VersionCopyWith<$Res> get version;
}

/// @nodoc
class __$$OathStateImplCopyWithImpl<$Res>
    extends _$OathStateCopyWithImpl<$Res, _$OathStateImpl>
    implements _$$OathStateImplCopyWith<$Res> {
  __$$OathStateImplCopyWithImpl(
      _$OathStateImpl _value, $Res Function(_$OathStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? deviceId = null,
    Object? version = null,
    Object? hasKey = null,
    Object? remembered = null,
    Object? locked = null,
    Object? keystore = null,
  }) {
    return _then(_$OathStateImpl(
      null == deviceId
          ? _value.deviceId
          : deviceId // ignore: cast_nullable_to_non_nullable
              as String,
      null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as Version,
      hasKey: null == hasKey
          ? _value.hasKey
          : hasKey // ignore: cast_nullable_to_non_nullable
              as bool,
      remembered: null == remembered
          ? _value.remembered
          : remembered // ignore: cast_nullable_to_non_nullable
              as bool,
      locked: null == locked
          ? _value.locked
          : locked // ignore: cast_nullable_to_non_nullable
              as bool,
      keystore: null == keystore
          ? _value.keystore
          : keystore // ignore: cast_nullable_to_non_nullable
              as KeystoreState,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$OathStateImpl implements _OathState {
  _$OathStateImpl(this.deviceId, this.version,
      {required this.hasKey,
      required this.remembered,
      required this.locked,
      required this.keystore});

  factory _$OathStateImpl.fromJson(Map<String, dynamic> json) =>
      _$$OathStateImplFromJson(json);

  @override
  final String deviceId;
  @override
  final Version version;
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
    return 'OathState(deviceId: $deviceId, version: $version, hasKey: $hasKey, remembered: $remembered, locked: $locked, keystore: $keystore)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OathStateImpl &&
            (identical(other.deviceId, deviceId) ||
                other.deviceId == deviceId) &&
            (identical(other.version, version) || other.version == version) &&
            (identical(other.hasKey, hasKey) || other.hasKey == hasKey) &&
            (identical(other.remembered, remembered) ||
                other.remembered == remembered) &&
            (identical(other.locked, locked) || other.locked == locked) &&
            (identical(other.keystore, keystore) ||
                other.keystore == keystore));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, deviceId, version, hasKey, remembered, locked, keystore);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$OathStateImplCopyWith<_$OathStateImpl> get copyWith =>
      __$$OathStateImplCopyWithImpl<_$OathStateImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OathStateImplToJson(
      this,
    );
  }
}

abstract class _OathState implements OathState {
  factory _OathState(final String deviceId, final Version version,
      {required final bool hasKey,
      required final bool remembered,
      required final bool locked,
      required final KeystoreState keystore}) = _$OathStateImpl;

  factory _OathState.fromJson(Map<String, dynamic> json) =
      _$OathStateImpl.fromJson;

  @override
  String get deviceId;
  @override
  Version get version;
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
  _$$OathStateImplCopyWith<_$OathStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CredentialData _$CredentialDataFromJson(Map<String, dynamic> json) {
  return _CredentialData.fromJson(json);
}

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
      _$CredentialDataCopyWithImpl<$Res, CredentialData>;
  @useResult
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
class _$CredentialDataCopyWithImpl<$Res, $Val extends CredentialData>
    implements $CredentialDataCopyWith<$Res> {
  _$CredentialDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? issuer = freezed,
    Object? name = null,
    Object? secret = null,
    Object? oathType = null,
    Object? hashAlgorithm = null,
    Object? digits = null,
    Object? period = null,
    Object? counter = null,
  }) {
    return _then(_value.copyWith(
      issuer: freezed == issuer
          ? _value.issuer
          : issuer // ignore: cast_nullable_to_non_nullable
              as String?,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      secret: null == secret
          ? _value.secret
          : secret // ignore: cast_nullable_to_non_nullable
              as String,
      oathType: null == oathType
          ? _value.oathType
          : oathType // ignore: cast_nullable_to_non_nullable
              as OathType,
      hashAlgorithm: null == hashAlgorithm
          ? _value.hashAlgorithm
          : hashAlgorithm // ignore: cast_nullable_to_non_nullable
              as HashAlgorithm,
      digits: null == digits
          ? _value.digits
          : digits // ignore: cast_nullable_to_non_nullable
              as int,
      period: null == period
          ? _value.period
          : period // ignore: cast_nullable_to_non_nullable
              as int,
      counter: null == counter
          ? _value.counter
          : counter // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CredentialDataImplCopyWith<$Res>
    implements $CredentialDataCopyWith<$Res> {
  factory _$$CredentialDataImplCopyWith(_$CredentialDataImpl value,
          $Res Function(_$CredentialDataImpl) then) =
      __$$CredentialDataImplCopyWithImpl<$Res>;
  @override
  @useResult
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
class __$$CredentialDataImplCopyWithImpl<$Res>
    extends _$CredentialDataCopyWithImpl<$Res, _$CredentialDataImpl>
    implements _$$CredentialDataImplCopyWith<$Res> {
  __$$CredentialDataImplCopyWithImpl(
      _$CredentialDataImpl _value, $Res Function(_$CredentialDataImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? issuer = freezed,
    Object? name = null,
    Object? secret = null,
    Object? oathType = null,
    Object? hashAlgorithm = null,
    Object? digits = null,
    Object? period = null,
    Object? counter = null,
  }) {
    return _then(_$CredentialDataImpl(
      issuer: freezed == issuer
          ? _value.issuer
          : issuer // ignore: cast_nullable_to_non_nullable
              as String?,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      secret: null == secret
          ? _value.secret
          : secret // ignore: cast_nullable_to_non_nullable
              as String,
      oathType: null == oathType
          ? _value.oathType
          : oathType // ignore: cast_nullable_to_non_nullable
              as OathType,
      hashAlgorithm: null == hashAlgorithm
          ? _value.hashAlgorithm
          : hashAlgorithm // ignore: cast_nullable_to_non_nullable
              as HashAlgorithm,
      digits: null == digits
          ? _value.digits
          : digits // ignore: cast_nullable_to_non_nullable
              as int,
      period: null == period
          ? _value.period
          : period // ignore: cast_nullable_to_non_nullable
              as int,
      counter: null == counter
          ? _value.counter
          : counter // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CredentialDataImpl extends _CredentialData {
  _$CredentialDataImpl(
      {this.issuer,
      required this.name,
      required this.secret,
      this.oathType = defaultOathType,
      this.hashAlgorithm = defaultHashAlgorithm,
      this.digits = defaultDigits,
      this.period = defaultPeriod,
      this.counter = defaultCounter})
      : super._();

  factory _$CredentialDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$CredentialDataImplFromJson(json);

  @override
  final String? issuer;
  @override
  final String name;
  @override
  final String secret;
  @override
  @JsonKey()
  final OathType oathType;
  @override
  @JsonKey()
  final HashAlgorithm hashAlgorithm;
  @override
  @JsonKey()
  final int digits;
  @override
  @JsonKey()
  final int period;
  @override
  @JsonKey()
  final int counter;

  @override
  String toString() {
    return 'CredentialData(issuer: $issuer, name: $name, secret: $secret, oathType: $oathType, hashAlgorithm: $hashAlgorithm, digits: $digits, period: $period, counter: $counter)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CredentialDataImpl &&
            (identical(other.issuer, issuer) || other.issuer == issuer) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.secret, secret) || other.secret == secret) &&
            (identical(other.oathType, oathType) ||
                other.oathType == oathType) &&
            (identical(other.hashAlgorithm, hashAlgorithm) ||
                other.hashAlgorithm == hashAlgorithm) &&
            (identical(other.digits, digits) || other.digits == digits) &&
            (identical(other.period, period) || other.period == period) &&
            (identical(other.counter, counter) || other.counter == counter));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, issuer, name, secret, oathType,
      hashAlgorithm, digits, period, counter);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$CredentialDataImplCopyWith<_$CredentialDataImpl> get copyWith =>
      __$$CredentialDataImplCopyWithImpl<_$CredentialDataImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CredentialDataImplToJson(
      this,
    );
  }
}

abstract class _CredentialData extends CredentialData {
  factory _CredentialData(
      {final String? issuer,
      required final String name,
      required final String secret,
      final OathType oathType,
      final HashAlgorithm hashAlgorithm,
      final int digits,
      final int period,
      final int counter}) = _$CredentialDataImpl;
  _CredentialData._() : super._();

  factory _CredentialData.fromJson(Map<String, dynamic> json) =
      _$CredentialDataImpl.fromJson;

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
  _$$CredentialDataImplCopyWith<_$CredentialDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
