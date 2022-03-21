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

RpcResponse _$RpcResponseFromJson(Map<String, dynamic> json) {
  switch (json['kind']) {
    case 'success':
      return Success.fromJson(json);
    case 'signal':
      return Signal.fromJson(json);
    case 'error':
      return RpcError.fromJson(json);

    default:
      throw CheckedFromJsonException(
          json, 'kind', 'RpcResponse', 'Invalid union type "${json['kind']}"!');
  }
}

/// @nodoc
class _$RpcResponseTearOff {
  const _$RpcResponseTearOff();

  Success success(Map<String, dynamic> body) {
    return Success(
      body,
    );
  }

  Signal signal(String status, Map<String, dynamic> body) {
    return Signal(
      status,
      body,
    );
  }

  RpcError error(String status, String message, Map<String, dynamic> body) {
    return RpcError(
      status,
      message,
      body,
    );
  }

  RpcResponse fromJson(Map<String, Object?> json) {
    return RpcResponse.fromJson(json);
  }
}

/// @nodoc
const $RpcResponse = _$RpcResponseTearOff();

/// @nodoc
mixin _$RpcResponse {
  Map<String, dynamic> get body => throw _privateConstructorUsedError;

  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(Map<String, dynamic> body) success,
    required TResult Function(String status, Map<String, dynamic> body) signal,
    required TResult Function(
            String status, String message, Map<String, dynamic> body)
        error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult Function(Map<String, dynamic> body)? success,
    TResult Function(String status, Map<String, dynamic> body)? signal,
    TResult Function(String status, String message, Map<String, dynamic> body)?
        error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(Map<String, dynamic> body)? success,
    TResult Function(String status, Map<String, dynamic> body)? signal,
    TResult Function(String status, String message, Map<String, dynamic> body)?
        error,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Success value) success,
    required TResult Function(Signal value) signal,
    required TResult Function(RpcError value) error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult Function(Success value)? success,
    TResult Function(Signal value)? signal,
    TResult Function(RpcError value)? error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Success value)? success,
    TResult Function(Signal value)? signal,
    TResult Function(RpcError value)? error,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $RpcResponseCopyWith<RpcResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RpcResponseCopyWith<$Res> {
  factory $RpcResponseCopyWith(
          RpcResponse value, $Res Function(RpcResponse) then) =
      _$RpcResponseCopyWithImpl<$Res>;
  $Res call({Map<String, dynamic> body});
}

/// @nodoc
class _$RpcResponseCopyWithImpl<$Res> implements $RpcResponseCopyWith<$Res> {
  _$RpcResponseCopyWithImpl(this._value, this._then);

  final RpcResponse _value;
  // ignore: unused_field
  final $Res Function(RpcResponse) _then;

  @override
  $Res call({
    Object? body = freezed,
  }) {
    return _then(_value.copyWith(
      body: body == freezed
          ? _value.body
          : body // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// @nodoc
abstract class $SuccessCopyWith<$Res> implements $RpcResponseCopyWith<$Res> {
  factory $SuccessCopyWith(Success value, $Res Function(Success) then) =
      _$SuccessCopyWithImpl<$Res>;
  @override
  $Res call({Map<String, dynamic> body});
}

/// @nodoc
class _$SuccessCopyWithImpl<$Res> extends _$RpcResponseCopyWithImpl<$Res>
    implements $SuccessCopyWith<$Res> {
  _$SuccessCopyWithImpl(Success _value, $Res Function(Success) _then)
      : super(_value, (v) => _then(v as Success));

  @override
  Success get _value => super._value as Success;

  @override
  $Res call({
    Object? body = freezed,
  }) {
    return _then(Success(
      body == freezed
          ? _value.body
          : body // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$Success implements Success {
  _$Success(this.body, {String? $type}) : $type = $type ?? 'success';

  factory _$Success.fromJson(Map<String, dynamic> json) =>
      _$$SuccessFromJson(json);

  @override
  final Map<String, dynamic> body;

  @JsonKey(name: 'kind')
  final String $type;

  @override
  String toString() {
    return 'RpcResponse.success(body: $body)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Success &&
            const DeepCollectionEquality().equals(other.body, body));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(body));

  @JsonKey(ignore: true)
  @override
  $SuccessCopyWith<Success> get copyWith =>
      _$SuccessCopyWithImpl<Success>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(Map<String, dynamic> body) success,
    required TResult Function(String status, Map<String, dynamic> body) signal,
    required TResult Function(
            String status, String message, Map<String, dynamic> body)
        error,
  }) {
    return success(body);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult Function(Map<String, dynamic> body)? success,
    TResult Function(String status, Map<String, dynamic> body)? signal,
    TResult Function(String status, String message, Map<String, dynamic> body)?
        error,
  }) {
    return success?.call(body);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(Map<String, dynamic> body)? success,
    TResult Function(String status, Map<String, dynamic> body)? signal,
    TResult Function(String status, String message, Map<String, dynamic> body)?
        error,
    required TResult orElse(),
  }) {
    if (success != null) {
      return success(body);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Success value) success,
    required TResult Function(Signal value) signal,
    required TResult Function(RpcError value) error,
  }) {
    return success(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult Function(Success value)? success,
    TResult Function(Signal value)? signal,
    TResult Function(RpcError value)? error,
  }) {
    return success?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Success value)? success,
    TResult Function(Signal value)? signal,
    TResult Function(RpcError value)? error,
    required TResult orElse(),
  }) {
    if (success != null) {
      return success(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$SuccessToJson(this);
  }
}

abstract class Success implements RpcResponse {
  factory Success(Map<String, dynamic> body) = _$Success;

  factory Success.fromJson(Map<String, dynamic> json) = _$Success.fromJson;

  @override
  Map<String, dynamic> get body;
  @override
  @JsonKey(ignore: true)
  $SuccessCopyWith<Success> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SignalCopyWith<$Res> implements $RpcResponseCopyWith<$Res> {
  factory $SignalCopyWith(Signal value, $Res Function(Signal) then) =
      _$SignalCopyWithImpl<$Res>;
  @override
  $Res call({String status, Map<String, dynamic> body});
}

/// @nodoc
class _$SignalCopyWithImpl<$Res> extends _$RpcResponseCopyWithImpl<$Res>
    implements $SignalCopyWith<$Res> {
  _$SignalCopyWithImpl(Signal _value, $Res Function(Signal) _then)
      : super(_value, (v) => _then(v as Signal));

  @override
  Signal get _value => super._value as Signal;

  @override
  $Res call({
    Object? status = freezed,
    Object? body = freezed,
  }) {
    return _then(Signal(
      status == freezed
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      body == freezed
          ? _value.body
          : body // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$Signal implements Signal {
  _$Signal(this.status, this.body, {String? $type}) : $type = $type ?? 'signal';

  factory _$Signal.fromJson(Map<String, dynamic> json) =>
      _$$SignalFromJson(json);

  @override
  final String status;
  @override
  final Map<String, dynamic> body;

  @JsonKey(name: 'kind')
  final String $type;

  @override
  String toString() {
    return 'RpcResponse.signal(status: $status, body: $body)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Signal &&
            const DeepCollectionEquality().equals(other.status, status) &&
            const DeepCollectionEquality().equals(other.body, body));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(status),
      const DeepCollectionEquality().hash(body));

  @JsonKey(ignore: true)
  @override
  $SignalCopyWith<Signal> get copyWith =>
      _$SignalCopyWithImpl<Signal>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(Map<String, dynamic> body) success,
    required TResult Function(String status, Map<String, dynamic> body) signal,
    required TResult Function(
            String status, String message, Map<String, dynamic> body)
        error,
  }) {
    return signal(status, body);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult Function(Map<String, dynamic> body)? success,
    TResult Function(String status, Map<String, dynamic> body)? signal,
    TResult Function(String status, String message, Map<String, dynamic> body)?
        error,
  }) {
    return signal?.call(status, body);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(Map<String, dynamic> body)? success,
    TResult Function(String status, Map<String, dynamic> body)? signal,
    TResult Function(String status, String message, Map<String, dynamic> body)?
        error,
    required TResult orElse(),
  }) {
    if (signal != null) {
      return signal(status, body);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Success value) success,
    required TResult Function(Signal value) signal,
    required TResult Function(RpcError value) error,
  }) {
    return signal(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult Function(Success value)? success,
    TResult Function(Signal value)? signal,
    TResult Function(RpcError value)? error,
  }) {
    return signal?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Success value)? success,
    TResult Function(Signal value)? signal,
    TResult Function(RpcError value)? error,
    required TResult orElse(),
  }) {
    if (signal != null) {
      return signal(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$SignalToJson(this);
  }
}

abstract class Signal implements RpcResponse {
  factory Signal(String status, Map<String, dynamic> body) = _$Signal;

  factory Signal.fromJson(Map<String, dynamic> json) = _$Signal.fromJson;

  String get status;
  @override
  Map<String, dynamic> get body;
  @override
  @JsonKey(ignore: true)
  $SignalCopyWith<Signal> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RpcErrorCopyWith<$Res> implements $RpcResponseCopyWith<$Res> {
  factory $RpcErrorCopyWith(RpcError value, $Res Function(RpcError) then) =
      _$RpcErrorCopyWithImpl<$Res>;
  @override
  $Res call({String status, String message, Map<String, dynamic> body});
}

/// @nodoc
class _$RpcErrorCopyWithImpl<$Res> extends _$RpcResponseCopyWithImpl<$Res>
    implements $RpcErrorCopyWith<$Res> {
  _$RpcErrorCopyWithImpl(RpcError _value, $Res Function(RpcError) _then)
      : super(_value, (v) => _then(v as RpcError));

  @override
  RpcError get _value => super._value as RpcError;

  @override
  $Res call({
    Object? status = freezed,
    Object? message = freezed,
    Object? body = freezed,
  }) {
    return _then(RpcError(
      status == freezed
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      message == freezed
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      body == freezed
          ? _value.body
          : body // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RpcError implements RpcError {
  _$RpcError(this.status, this.message, this.body, {String? $type})
      : $type = $type ?? 'error';

  factory _$RpcError.fromJson(Map<String, dynamic> json) =>
      _$$RpcErrorFromJson(json);

  @override
  final String status;
  @override
  final String message;
  @override
  final Map<String, dynamic> body;

  @JsonKey(name: 'kind')
  final String $type;

  @override
  String toString() {
    return 'RpcResponse.error(status: $status, message: $message, body: $body)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is RpcError &&
            const DeepCollectionEquality().equals(other.status, status) &&
            const DeepCollectionEquality().equals(other.message, message) &&
            const DeepCollectionEquality().equals(other.body, body));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(status),
      const DeepCollectionEquality().hash(message),
      const DeepCollectionEquality().hash(body));

  @JsonKey(ignore: true)
  @override
  $RpcErrorCopyWith<RpcError> get copyWith =>
      _$RpcErrorCopyWithImpl<RpcError>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(Map<String, dynamic> body) success,
    required TResult Function(String status, Map<String, dynamic> body) signal,
    required TResult Function(
            String status, String message, Map<String, dynamic> body)
        error,
  }) {
    return error(status, message, body);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult Function(Map<String, dynamic> body)? success,
    TResult Function(String status, Map<String, dynamic> body)? signal,
    TResult Function(String status, String message, Map<String, dynamic> body)?
        error,
  }) {
    return error?.call(status, message, body);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(Map<String, dynamic> body)? success,
    TResult Function(String status, Map<String, dynamic> body)? signal,
    TResult Function(String status, String message, Map<String, dynamic> body)?
        error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(status, message, body);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Success value) success,
    required TResult Function(Signal value) signal,
    required TResult Function(RpcError value) error,
  }) {
    return error(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult Function(Success value)? success,
    TResult Function(Signal value)? signal,
    TResult Function(RpcError value)? error,
  }) {
    return error?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Success value)? success,
    TResult Function(Signal value)? signal,
    TResult Function(RpcError value)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$RpcErrorToJson(this);
  }
}

abstract class RpcError implements RpcResponse {
  factory RpcError(String status, String message, Map<String, dynamic> body) =
      _$RpcError;

  factory RpcError.fromJson(Map<String, dynamic> json) = _$RpcError.fromJson;

  String get status;
  String get message;
  @override
  Map<String, dynamic> get body;
  @override
  @JsonKey(ignore: true)
  $RpcErrorCopyWith<RpcError> get copyWith =>
      throw _privateConstructorUsedError;
}

RpcState _$RpcStateFromJson(Map<String, dynamic> json) {
  return _RpcState.fromJson(json);
}

/// @nodoc
class _$RpcStateTearOff {
  const _$RpcStateTearOff();

  _RpcState call(String version, bool isAdmin) {
    return _RpcState(
      version,
      isAdmin,
    );
  }

  RpcState fromJson(Map<String, Object?> json) {
    return RpcState.fromJson(json);
  }
}

/// @nodoc
const $RpcState = _$RpcStateTearOff();

/// @nodoc
mixin _$RpcState {
  String get version => throw _privateConstructorUsedError;
  bool get isAdmin => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $RpcStateCopyWith<RpcState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RpcStateCopyWith<$Res> {
  factory $RpcStateCopyWith(RpcState value, $Res Function(RpcState) then) =
      _$RpcStateCopyWithImpl<$Res>;
  $Res call({String version, bool isAdmin});
}

/// @nodoc
class _$RpcStateCopyWithImpl<$Res> implements $RpcStateCopyWith<$Res> {
  _$RpcStateCopyWithImpl(this._value, this._then);

  final RpcState _value;
  // ignore: unused_field
  final $Res Function(RpcState) _then;

  @override
  $Res call({
    Object? version = freezed,
    Object? isAdmin = freezed,
  }) {
    return _then(_value.copyWith(
      version: version == freezed
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as String,
      isAdmin: isAdmin == freezed
          ? _value.isAdmin
          : isAdmin // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
abstract class _$RpcStateCopyWith<$Res> implements $RpcStateCopyWith<$Res> {
  factory _$RpcStateCopyWith(_RpcState value, $Res Function(_RpcState) then) =
      __$RpcStateCopyWithImpl<$Res>;
  @override
  $Res call({String version, bool isAdmin});
}

/// @nodoc
class __$RpcStateCopyWithImpl<$Res> extends _$RpcStateCopyWithImpl<$Res>
    implements _$RpcStateCopyWith<$Res> {
  __$RpcStateCopyWithImpl(_RpcState _value, $Res Function(_RpcState) _then)
      : super(_value, (v) => _then(v as _RpcState));

  @override
  _RpcState get _value => super._value as _RpcState;

  @override
  $Res call({
    Object? version = freezed,
    Object? isAdmin = freezed,
  }) {
    return _then(_RpcState(
      version == freezed
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as String,
      isAdmin == freezed
          ? _value.isAdmin
          : isAdmin // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$_RpcState implements _RpcState {
  const _$_RpcState(this.version, this.isAdmin);

  factory _$_RpcState.fromJson(Map<String, dynamic> json) =>
      _$$_RpcStateFromJson(json);

  @override
  final String version;
  @override
  final bool isAdmin;

  @override
  String toString() {
    return 'RpcState(version: $version, isAdmin: $isAdmin)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _RpcState &&
            const DeepCollectionEquality().equals(other.version, version) &&
            const DeepCollectionEquality().equals(other.isAdmin, isAdmin));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(version),
      const DeepCollectionEquality().hash(isAdmin));

  @JsonKey(ignore: true)
  @override
  _$RpcStateCopyWith<_RpcState> get copyWith =>
      __$RpcStateCopyWithImpl<_RpcState>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_RpcStateToJson(this);
  }
}

abstract class _RpcState implements RpcState {
  const factory _RpcState(String version, bool isAdmin) = _$_RpcState;

  factory _RpcState.fromJson(Map<String, dynamic> json) = _$_RpcState.fromJson;

  @override
  String get version;
  @override
  bool get isAdmin;
  @override
  @JsonKey(ignore: true)
  _$RpcStateCopyWith<_RpcState> get copyWith =>
      throw _privateConstructorUsedError;
}
