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

FidoState _$FidoStateFromJson(Map<String, dynamic> json) {
  return _FidoState.fromJson(json);
}

/// @nodoc
mixin _$FidoState {
  Map<String, dynamic> get info => throw _privateConstructorUsedError;
  bool get unlocked => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $FidoStateCopyWith<FidoState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FidoStateCopyWith<$Res> {
  factory $FidoStateCopyWith(FidoState value, $Res Function(FidoState) then) =
      _$FidoStateCopyWithImpl<$Res>;
  $Res call({Map<String, dynamic> info, bool unlocked});
}

/// @nodoc
class _$FidoStateCopyWithImpl<$Res> implements $FidoStateCopyWith<$Res> {
  _$FidoStateCopyWithImpl(this._value, this._then);

  final FidoState _value;
  // ignore: unused_field
  final $Res Function(FidoState) _then;

  @override
  $Res call({
    Object? info = freezed,
    Object? unlocked = freezed,
  }) {
    return _then(_value.copyWith(
      info: info == freezed
          ? _value.info
          : info // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      unlocked: unlocked == freezed
          ? _value.unlocked
          : unlocked // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
abstract class _$$_FidoStateCopyWith<$Res> implements $FidoStateCopyWith<$Res> {
  factory _$$_FidoStateCopyWith(
          _$_FidoState value, $Res Function(_$_FidoState) then) =
      __$$_FidoStateCopyWithImpl<$Res>;
  @override
  $Res call({Map<String, dynamic> info, bool unlocked});
}

/// @nodoc
class __$$_FidoStateCopyWithImpl<$Res> extends _$FidoStateCopyWithImpl<$Res>
    implements _$$_FidoStateCopyWith<$Res> {
  __$$_FidoStateCopyWithImpl(
      _$_FidoState _value, $Res Function(_$_FidoState) _then)
      : super(_value, (v) => _then(v as _$_FidoState));

  @override
  _$_FidoState get _value => super._value as _$_FidoState;

  @override
  $Res call({
    Object? info = freezed,
    Object? unlocked = freezed,
  }) {
    return _then(_$_FidoState(
      info: info == freezed
          ? _value._info
          : info // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      unlocked: unlocked == freezed
          ? _value.unlocked
          : unlocked // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$_FidoState extends _FidoState {
  _$_FidoState(
      {required final Map<String, dynamic> info, required this.unlocked})
      : _info = info,
        super._();

  factory _$_FidoState.fromJson(Map<String, dynamic> json) =>
      _$$_FidoStateFromJson(json);

  final Map<String, dynamic> _info;
  @override
  Map<String, dynamic> get info {
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_info);
  }

  @override
  final bool unlocked;

  @override
  String toString() {
    return 'FidoState(info: $info, unlocked: $unlocked)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_FidoState &&
            const DeepCollectionEquality().equals(other._info, _info) &&
            const DeepCollectionEquality().equals(other.unlocked, unlocked));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_info),
      const DeepCollectionEquality().hash(unlocked));

  @JsonKey(ignore: true)
  @override
  _$$_FidoStateCopyWith<_$_FidoState> get copyWith =>
      __$$_FidoStateCopyWithImpl<_$_FidoState>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_FidoStateToJson(
      this,
    );
  }
}

abstract class _FidoState extends FidoState {
  factory _FidoState(
      {required final Map<String, dynamic> info,
      required final bool unlocked}) = _$_FidoState;
  _FidoState._() : super._();

  factory _FidoState.fromJson(Map<String, dynamic> json) =
      _$_FidoState.fromJson;

  @override
  Map<String, dynamic> get info;
  @override
  bool get unlocked;
  @override
  @JsonKey(ignore: true)
  _$$_FidoStateCopyWith<_$_FidoState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$PinResult {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() success,
    required TResult Function(int retries, bool authBlocked) failed,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult Function()? success,
    TResult Function(int retries, bool authBlocked)? failed,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? success,
    TResult Function(int retries, bool authBlocked)? failed,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_PinSuccess value) success,
    required TResult Function(_PinFailure value) failed,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult Function(_PinSuccess value)? success,
    TResult Function(_PinFailure value)? failed,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_PinSuccess value)? success,
    TResult Function(_PinFailure value)? failed,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PinResultCopyWith<$Res> {
  factory $PinResultCopyWith(PinResult value, $Res Function(PinResult) then) =
      _$PinResultCopyWithImpl<$Res>;
}

/// @nodoc
class _$PinResultCopyWithImpl<$Res> implements $PinResultCopyWith<$Res> {
  _$PinResultCopyWithImpl(this._value, this._then);

  final PinResult _value;
  // ignore: unused_field
  final $Res Function(PinResult) _then;
}

/// @nodoc
abstract class _$$_PinSuccessCopyWith<$Res> {
  factory _$$_PinSuccessCopyWith(
          _$_PinSuccess value, $Res Function(_$_PinSuccess) then) =
      __$$_PinSuccessCopyWithImpl<$Res>;
}

/// @nodoc
class __$$_PinSuccessCopyWithImpl<$Res> extends _$PinResultCopyWithImpl<$Res>
    implements _$$_PinSuccessCopyWith<$Res> {
  __$$_PinSuccessCopyWithImpl(
      _$_PinSuccess _value, $Res Function(_$_PinSuccess) _then)
      : super(_value, (v) => _then(v as _$_PinSuccess));

  @override
  _$_PinSuccess get _value => super._value as _$_PinSuccess;
}

/// @nodoc

class _$_PinSuccess implements _PinSuccess {
  _$_PinSuccess();

  @override
  String toString() {
    return 'PinResult.success()';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$_PinSuccess);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() success,
    required TResult Function(int retries, bool authBlocked) failed,
  }) {
    return success();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult Function()? success,
    TResult Function(int retries, bool authBlocked)? failed,
  }) {
    return success?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? success,
    TResult Function(int retries, bool authBlocked)? failed,
    required TResult orElse(),
  }) {
    if (success != null) {
      return success();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_PinSuccess value) success,
    required TResult Function(_PinFailure value) failed,
  }) {
    return success(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult Function(_PinSuccess value)? success,
    TResult Function(_PinFailure value)? failed,
  }) {
    return success?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_PinSuccess value)? success,
    TResult Function(_PinFailure value)? failed,
    required TResult orElse(),
  }) {
    if (success != null) {
      return success(this);
    }
    return orElse();
  }
}

abstract class _PinSuccess implements PinResult {
  factory _PinSuccess() = _$_PinSuccess;
}

/// @nodoc
abstract class _$$_PinFailureCopyWith<$Res> {
  factory _$$_PinFailureCopyWith(
          _$_PinFailure value, $Res Function(_$_PinFailure) then) =
      __$$_PinFailureCopyWithImpl<$Res>;
  $Res call({int retries, bool authBlocked});
}

/// @nodoc
class __$$_PinFailureCopyWithImpl<$Res> extends _$PinResultCopyWithImpl<$Res>
    implements _$$_PinFailureCopyWith<$Res> {
  __$$_PinFailureCopyWithImpl(
      _$_PinFailure _value, $Res Function(_$_PinFailure) _then)
      : super(_value, (v) => _then(v as _$_PinFailure));

  @override
  _$_PinFailure get _value => super._value as _$_PinFailure;

  @override
  $Res call({
    Object? retries = freezed,
    Object? authBlocked = freezed,
  }) {
    return _then(_$_PinFailure(
      retries == freezed
          ? _value.retries
          : retries // ignore: cast_nullable_to_non_nullable
              as int,
      authBlocked == freezed
          ? _value.authBlocked
          : authBlocked // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$_PinFailure implements _PinFailure {
  _$_PinFailure(this.retries, this.authBlocked);

  @override
  final int retries;
  @override
  final bool authBlocked;

  @override
  String toString() {
    return 'PinResult.failed(retries: $retries, authBlocked: $authBlocked)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_PinFailure &&
            const DeepCollectionEquality().equals(other.retries, retries) &&
            const DeepCollectionEquality()
                .equals(other.authBlocked, authBlocked));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(retries),
      const DeepCollectionEquality().hash(authBlocked));

  @JsonKey(ignore: true)
  @override
  _$$_PinFailureCopyWith<_$_PinFailure> get copyWith =>
      __$$_PinFailureCopyWithImpl<_$_PinFailure>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() success,
    required TResult Function(int retries, bool authBlocked) failed,
  }) {
    return failed(retries, authBlocked);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult Function()? success,
    TResult Function(int retries, bool authBlocked)? failed,
  }) {
    return failed?.call(retries, authBlocked);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? success,
    TResult Function(int retries, bool authBlocked)? failed,
    required TResult orElse(),
  }) {
    if (failed != null) {
      return failed(retries, authBlocked);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_PinSuccess value) success,
    required TResult Function(_PinFailure value) failed,
  }) {
    return failed(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult Function(_PinSuccess value)? success,
    TResult Function(_PinFailure value)? failed,
  }) {
    return failed?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_PinSuccess value)? success,
    TResult Function(_PinFailure value)? failed,
    required TResult orElse(),
  }) {
    if (failed != null) {
      return failed(this);
    }
    return orElse();
  }
}

abstract class _PinFailure implements PinResult {
  factory _PinFailure(final int retries, final bool authBlocked) =
      _$_PinFailure;

  int get retries;
  bool get authBlocked;
  @JsonKey(ignore: true)
  _$$_PinFailureCopyWith<_$_PinFailure> get copyWith =>
      throw _privateConstructorUsedError;
}

Fingerprint _$FingerprintFromJson(Map<String, dynamic> json) {
  return _Fingerprint.fromJson(json);
}

/// @nodoc
mixin _$Fingerprint {
  String get templateId => throw _privateConstructorUsedError;
  String? get name => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $FingerprintCopyWith<Fingerprint> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FingerprintCopyWith<$Res> {
  factory $FingerprintCopyWith(
          Fingerprint value, $Res Function(Fingerprint) then) =
      _$FingerprintCopyWithImpl<$Res>;
  $Res call({String templateId, String? name});
}

/// @nodoc
class _$FingerprintCopyWithImpl<$Res> implements $FingerprintCopyWith<$Res> {
  _$FingerprintCopyWithImpl(this._value, this._then);

  final Fingerprint _value;
  // ignore: unused_field
  final $Res Function(Fingerprint) _then;

  @override
  $Res call({
    Object? templateId = freezed,
    Object? name = freezed,
  }) {
    return _then(_value.copyWith(
      templateId: templateId == freezed
          ? _value.templateId
          : templateId // ignore: cast_nullable_to_non_nullable
              as String,
      name: name == freezed
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
abstract class _$$_FingerprintCopyWith<$Res>
    implements $FingerprintCopyWith<$Res> {
  factory _$$_FingerprintCopyWith(
          _$_Fingerprint value, $Res Function(_$_Fingerprint) then) =
      __$$_FingerprintCopyWithImpl<$Res>;
  @override
  $Res call({String templateId, String? name});
}

/// @nodoc
class __$$_FingerprintCopyWithImpl<$Res> extends _$FingerprintCopyWithImpl<$Res>
    implements _$$_FingerprintCopyWith<$Res> {
  __$$_FingerprintCopyWithImpl(
      _$_Fingerprint _value, $Res Function(_$_Fingerprint) _then)
      : super(_value, (v) => _then(v as _$_Fingerprint));

  @override
  _$_Fingerprint get _value => super._value as _$_Fingerprint;

  @override
  $Res call({
    Object? templateId = freezed,
    Object? name = freezed,
  }) {
    return _then(_$_Fingerprint(
      templateId == freezed
          ? _value.templateId
          : templateId // ignore: cast_nullable_to_non_nullable
              as String,
      name == freezed
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$_Fingerprint extends _Fingerprint {
  _$_Fingerprint(this.templateId, this.name) : super._();

  factory _$_Fingerprint.fromJson(Map<String, dynamic> json) =>
      _$$_FingerprintFromJson(json);

  @override
  final String templateId;
  @override
  final String? name;

  @override
  String toString() {
    return 'Fingerprint(templateId: $templateId, name: $name)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_Fingerprint &&
            const DeepCollectionEquality()
                .equals(other.templateId, templateId) &&
            const DeepCollectionEquality().equals(other.name, name));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(templateId),
      const DeepCollectionEquality().hash(name));

  @JsonKey(ignore: true)
  @override
  _$$_FingerprintCopyWith<_$_Fingerprint> get copyWith =>
      __$$_FingerprintCopyWithImpl<_$_Fingerprint>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_FingerprintToJson(
      this,
    );
  }
}

abstract class _Fingerprint extends Fingerprint {
  factory _Fingerprint(final String templateId, final String? name) =
      _$_Fingerprint;
  _Fingerprint._() : super._();

  factory _Fingerprint.fromJson(Map<String, dynamic> json) =
      _$_Fingerprint.fromJson;

  @override
  String get templateId;
  @override
  String? get name;
  @override
  @JsonKey(ignore: true)
  _$$_FingerprintCopyWith<_$_Fingerprint> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$FingerprintEvent {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int remaining) capture,
    required TResult Function(Fingerprint fingerprint) complete,
    required TResult Function(int code) error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult Function(int remaining)? capture,
    TResult Function(Fingerprint fingerprint)? complete,
    TResult Function(int code)? error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int remaining)? capture,
    TResult Function(Fingerprint fingerprint)? complete,
    TResult Function(int code)? error,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_EventCapture value) capture,
    required TResult Function(_EventComplete value) complete,
    required TResult Function(_EventError value) error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult Function(_EventCapture value)? capture,
    TResult Function(_EventComplete value)? complete,
    TResult Function(_EventError value)? error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_EventCapture value)? capture,
    TResult Function(_EventComplete value)? complete,
    TResult Function(_EventError value)? error,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FingerprintEventCopyWith<$Res> {
  factory $FingerprintEventCopyWith(
          FingerprintEvent value, $Res Function(FingerprintEvent) then) =
      _$FingerprintEventCopyWithImpl<$Res>;
}

/// @nodoc
class _$FingerprintEventCopyWithImpl<$Res>
    implements $FingerprintEventCopyWith<$Res> {
  _$FingerprintEventCopyWithImpl(this._value, this._then);

  final FingerprintEvent _value;
  // ignore: unused_field
  final $Res Function(FingerprintEvent) _then;
}

/// @nodoc
abstract class _$$_EventCaptureCopyWith<$Res> {
  factory _$$_EventCaptureCopyWith(
          _$_EventCapture value, $Res Function(_$_EventCapture) then) =
      __$$_EventCaptureCopyWithImpl<$Res>;
  $Res call({int remaining});
}

/// @nodoc
class __$$_EventCaptureCopyWithImpl<$Res>
    extends _$FingerprintEventCopyWithImpl<$Res>
    implements _$$_EventCaptureCopyWith<$Res> {
  __$$_EventCaptureCopyWithImpl(
      _$_EventCapture _value, $Res Function(_$_EventCapture) _then)
      : super(_value, (v) => _then(v as _$_EventCapture));

  @override
  _$_EventCapture get _value => super._value as _$_EventCapture;

  @override
  $Res call({
    Object? remaining = freezed,
  }) {
    return _then(_$_EventCapture(
      remaining == freezed
          ? _value.remaining
          : remaining // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class _$_EventCapture implements _EventCapture {
  _$_EventCapture(this.remaining);

  @override
  final int remaining;

  @override
  String toString() {
    return 'FingerprintEvent.capture(remaining: $remaining)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_EventCapture &&
            const DeepCollectionEquality().equals(other.remaining, remaining));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(remaining));

  @JsonKey(ignore: true)
  @override
  _$$_EventCaptureCopyWith<_$_EventCapture> get copyWith =>
      __$$_EventCaptureCopyWithImpl<_$_EventCapture>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int remaining) capture,
    required TResult Function(Fingerprint fingerprint) complete,
    required TResult Function(int code) error,
  }) {
    return capture(remaining);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult Function(int remaining)? capture,
    TResult Function(Fingerprint fingerprint)? complete,
    TResult Function(int code)? error,
  }) {
    return capture?.call(remaining);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int remaining)? capture,
    TResult Function(Fingerprint fingerprint)? complete,
    TResult Function(int code)? error,
    required TResult orElse(),
  }) {
    if (capture != null) {
      return capture(remaining);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_EventCapture value) capture,
    required TResult Function(_EventComplete value) complete,
    required TResult Function(_EventError value) error,
  }) {
    return capture(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult Function(_EventCapture value)? capture,
    TResult Function(_EventComplete value)? complete,
    TResult Function(_EventError value)? error,
  }) {
    return capture?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_EventCapture value)? capture,
    TResult Function(_EventComplete value)? complete,
    TResult Function(_EventError value)? error,
    required TResult orElse(),
  }) {
    if (capture != null) {
      return capture(this);
    }
    return orElse();
  }
}

abstract class _EventCapture implements FingerprintEvent {
  factory _EventCapture(final int remaining) = _$_EventCapture;

  int get remaining;
  @JsonKey(ignore: true)
  _$$_EventCaptureCopyWith<_$_EventCapture> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$_EventCompleteCopyWith<$Res> {
  factory _$$_EventCompleteCopyWith(
          _$_EventComplete value, $Res Function(_$_EventComplete) then) =
      __$$_EventCompleteCopyWithImpl<$Res>;
  $Res call({Fingerprint fingerprint});

  $FingerprintCopyWith<$Res> get fingerprint;
}

/// @nodoc
class __$$_EventCompleteCopyWithImpl<$Res>
    extends _$FingerprintEventCopyWithImpl<$Res>
    implements _$$_EventCompleteCopyWith<$Res> {
  __$$_EventCompleteCopyWithImpl(
      _$_EventComplete _value, $Res Function(_$_EventComplete) _then)
      : super(_value, (v) => _then(v as _$_EventComplete));

  @override
  _$_EventComplete get _value => super._value as _$_EventComplete;

  @override
  $Res call({
    Object? fingerprint = freezed,
  }) {
    return _then(_$_EventComplete(
      fingerprint == freezed
          ? _value.fingerprint
          : fingerprint // ignore: cast_nullable_to_non_nullable
              as Fingerprint,
    ));
  }

  @override
  $FingerprintCopyWith<$Res> get fingerprint {
    return $FingerprintCopyWith<$Res>(_value.fingerprint, (value) {
      return _then(_value.copyWith(fingerprint: value));
    });
  }
}

/// @nodoc

class _$_EventComplete implements _EventComplete {
  _$_EventComplete(this.fingerprint);

  @override
  final Fingerprint fingerprint;

  @override
  String toString() {
    return 'FingerprintEvent.complete(fingerprint: $fingerprint)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_EventComplete &&
            const DeepCollectionEquality()
                .equals(other.fingerprint, fingerprint));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, const DeepCollectionEquality().hash(fingerprint));

  @JsonKey(ignore: true)
  @override
  _$$_EventCompleteCopyWith<_$_EventComplete> get copyWith =>
      __$$_EventCompleteCopyWithImpl<_$_EventComplete>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int remaining) capture,
    required TResult Function(Fingerprint fingerprint) complete,
    required TResult Function(int code) error,
  }) {
    return complete(fingerprint);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult Function(int remaining)? capture,
    TResult Function(Fingerprint fingerprint)? complete,
    TResult Function(int code)? error,
  }) {
    return complete?.call(fingerprint);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int remaining)? capture,
    TResult Function(Fingerprint fingerprint)? complete,
    TResult Function(int code)? error,
    required TResult orElse(),
  }) {
    if (complete != null) {
      return complete(fingerprint);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_EventCapture value) capture,
    required TResult Function(_EventComplete value) complete,
    required TResult Function(_EventError value) error,
  }) {
    return complete(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult Function(_EventCapture value)? capture,
    TResult Function(_EventComplete value)? complete,
    TResult Function(_EventError value)? error,
  }) {
    return complete?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_EventCapture value)? capture,
    TResult Function(_EventComplete value)? complete,
    TResult Function(_EventError value)? error,
    required TResult orElse(),
  }) {
    if (complete != null) {
      return complete(this);
    }
    return orElse();
  }
}

abstract class _EventComplete implements FingerprintEvent {
  factory _EventComplete(final Fingerprint fingerprint) = _$_EventComplete;

  Fingerprint get fingerprint;
  @JsonKey(ignore: true)
  _$$_EventCompleteCopyWith<_$_EventComplete> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$_EventErrorCopyWith<$Res> {
  factory _$$_EventErrorCopyWith(
          _$_EventError value, $Res Function(_$_EventError) then) =
      __$$_EventErrorCopyWithImpl<$Res>;
  $Res call({int code});
}

/// @nodoc
class __$$_EventErrorCopyWithImpl<$Res>
    extends _$FingerprintEventCopyWithImpl<$Res>
    implements _$$_EventErrorCopyWith<$Res> {
  __$$_EventErrorCopyWithImpl(
      _$_EventError _value, $Res Function(_$_EventError) _then)
      : super(_value, (v) => _then(v as _$_EventError));

  @override
  _$_EventError get _value => super._value as _$_EventError;

  @override
  $Res call({
    Object? code = freezed,
  }) {
    return _then(_$_EventError(
      code == freezed
          ? _value.code
          : code // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class _$_EventError implements _EventError {
  _$_EventError(this.code);

  @override
  final int code;

  @override
  String toString() {
    return 'FingerprintEvent.error(code: $code)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_EventError &&
            const DeepCollectionEquality().equals(other.code, code));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(code));

  @JsonKey(ignore: true)
  @override
  _$$_EventErrorCopyWith<_$_EventError> get copyWith =>
      __$$_EventErrorCopyWithImpl<_$_EventError>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int remaining) capture,
    required TResult Function(Fingerprint fingerprint) complete,
    required TResult Function(int code) error,
  }) {
    return error(code);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult Function(int remaining)? capture,
    TResult Function(Fingerprint fingerprint)? complete,
    TResult Function(int code)? error,
  }) {
    return error?.call(code);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int remaining)? capture,
    TResult Function(Fingerprint fingerprint)? complete,
    TResult Function(int code)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(code);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_EventCapture value) capture,
    required TResult Function(_EventComplete value) complete,
    required TResult Function(_EventError value) error,
  }) {
    return error(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult Function(_EventCapture value)? capture,
    TResult Function(_EventComplete value)? complete,
    TResult Function(_EventError value)? error,
  }) {
    return error?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_EventCapture value)? capture,
    TResult Function(_EventComplete value)? complete,
    TResult Function(_EventError value)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(this);
    }
    return orElse();
  }
}

abstract class _EventError implements FingerprintEvent {
  factory _EventError(final int code) = _$_EventError;

  int get code;
  @JsonKey(ignore: true)
  _$$_EventErrorCopyWith<_$_EventError> get copyWith =>
      throw _privateConstructorUsedError;
}

FidoCredential _$FidoCredentialFromJson(Map<String, dynamic> json) {
  return _FidoCredential.fromJson(json);
}

/// @nodoc
mixin _$FidoCredential {
  String get rpId => throw _privateConstructorUsedError;
  String get credentialId => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get userName => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $FidoCredentialCopyWith<FidoCredential> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FidoCredentialCopyWith<$Res> {
  factory $FidoCredentialCopyWith(
          FidoCredential value, $Res Function(FidoCredential) then) =
      _$FidoCredentialCopyWithImpl<$Res>;
  $Res call({String rpId, String credentialId, String userId, String userName});
}

/// @nodoc
class _$FidoCredentialCopyWithImpl<$Res>
    implements $FidoCredentialCopyWith<$Res> {
  _$FidoCredentialCopyWithImpl(this._value, this._then);

  final FidoCredential _value;
  // ignore: unused_field
  final $Res Function(FidoCredential) _then;

  @override
  $Res call({
    Object? rpId = freezed,
    Object? credentialId = freezed,
    Object? userId = freezed,
    Object? userName = freezed,
  }) {
    return _then(_value.copyWith(
      rpId: rpId == freezed
          ? _value.rpId
          : rpId // ignore: cast_nullable_to_non_nullable
              as String,
      credentialId: credentialId == freezed
          ? _value.credentialId
          : credentialId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: userId == freezed
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      userName: userName == freezed
          ? _value.userName
          : userName // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
abstract class _$$_FidoCredentialCopyWith<$Res>
    implements $FidoCredentialCopyWith<$Res> {
  factory _$$_FidoCredentialCopyWith(
          _$_FidoCredential value, $Res Function(_$_FidoCredential) then) =
      __$$_FidoCredentialCopyWithImpl<$Res>;
  @override
  $Res call({String rpId, String credentialId, String userId, String userName});
}

/// @nodoc
class __$$_FidoCredentialCopyWithImpl<$Res>
    extends _$FidoCredentialCopyWithImpl<$Res>
    implements _$$_FidoCredentialCopyWith<$Res> {
  __$$_FidoCredentialCopyWithImpl(
      _$_FidoCredential _value, $Res Function(_$_FidoCredential) _then)
      : super(_value, (v) => _then(v as _$_FidoCredential));

  @override
  _$_FidoCredential get _value => super._value as _$_FidoCredential;

  @override
  $Res call({
    Object? rpId = freezed,
    Object? credentialId = freezed,
    Object? userId = freezed,
    Object? userName = freezed,
  }) {
    return _then(_$_FidoCredential(
      rpId: rpId == freezed
          ? _value.rpId
          : rpId // ignore: cast_nullable_to_non_nullable
              as String,
      credentialId: credentialId == freezed
          ? _value.credentialId
          : credentialId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: userId == freezed
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      userName: userName == freezed
          ? _value.userName
          : userName // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$_FidoCredential implements _FidoCredential {
  _$_FidoCredential(
      {required this.rpId,
      required this.credentialId,
      required this.userId,
      required this.userName});

  factory _$_FidoCredential.fromJson(Map<String, dynamic> json) =>
      _$$_FidoCredentialFromJson(json);

  @override
  final String rpId;
  @override
  final String credentialId;
  @override
  final String userId;
  @override
  final String userName;

  @override
  String toString() {
    return 'FidoCredential(rpId: $rpId, credentialId: $credentialId, userId: $userId, userName: $userName)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_FidoCredential &&
            const DeepCollectionEquality().equals(other.rpId, rpId) &&
            const DeepCollectionEquality()
                .equals(other.credentialId, credentialId) &&
            const DeepCollectionEquality().equals(other.userId, userId) &&
            const DeepCollectionEquality().equals(other.userName, userName));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(rpId),
      const DeepCollectionEquality().hash(credentialId),
      const DeepCollectionEquality().hash(userId),
      const DeepCollectionEquality().hash(userName));

  @JsonKey(ignore: true)
  @override
  _$$_FidoCredentialCopyWith<_$_FidoCredential> get copyWith =>
      __$$_FidoCredentialCopyWithImpl<_$_FidoCredential>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_FidoCredentialToJson(
      this,
    );
  }
}

abstract class _FidoCredential implements FidoCredential {
  factory _FidoCredential(
      {required final String rpId,
      required final String credentialId,
      required final String userId,
      required final String userName}) = _$_FidoCredential;

  factory _FidoCredential.fromJson(Map<String, dynamic> json) =
      _$_FidoCredential.fromJson;

  @override
  String get rpId;
  @override
  String get credentialId;
  @override
  String get userId;
  @override
  String get userName;
  @override
  @JsonKey(ignore: true)
  _$$_FidoCredentialCopyWith<_$_FidoCredential> get copyWith =>
      throw _privateConstructorUsedError;
}
