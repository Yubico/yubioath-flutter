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
    TResult? Function(Map<String, dynamic> body)? success,
    TResult? Function(String status, Map<String, dynamic> body)? signal,
    TResult? Function(String status, String message, Map<String, dynamic> body)?
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
    TResult? Function(Success value)? success,
    TResult? Function(Signal value)? signal,
    TResult? Function(RpcError value)? error,
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
      _$RpcResponseCopyWithImpl<$Res, RpcResponse>;
  @useResult
  $Res call({Map<String, dynamic> body});
}

/// @nodoc
class _$RpcResponseCopyWithImpl<$Res, $Val extends RpcResponse>
    implements $RpcResponseCopyWith<$Res> {
  _$RpcResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? body = null,
  }) {
    return _then(_value.copyWith(
      body: null == body
          ? _value.body
          : body // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SuccessImplCopyWith<$Res>
    implements $RpcResponseCopyWith<$Res> {
  factory _$$SuccessImplCopyWith(
          _$SuccessImpl value, $Res Function(_$SuccessImpl) then) =
      __$$SuccessImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({Map<String, dynamic> body});
}

/// @nodoc
class __$$SuccessImplCopyWithImpl<$Res>
    extends _$RpcResponseCopyWithImpl<$Res, _$SuccessImpl>
    implements _$$SuccessImplCopyWith<$Res> {
  __$$SuccessImplCopyWithImpl(
      _$SuccessImpl _value, $Res Function(_$SuccessImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? body = null,
  }) {
    return _then(_$SuccessImpl(
      null == body
          ? _value._body
          : body // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SuccessImpl implements Success {
  _$SuccessImpl(final Map<String, dynamic> body, {final String? $type})
      : _body = body,
        $type = $type ?? 'success';

  factory _$SuccessImpl.fromJson(Map<String, dynamic> json) =>
      _$$SuccessImplFromJson(json);

  final Map<String, dynamic> _body;
  @override
  Map<String, dynamic> get body {
    if (_body is EqualUnmodifiableMapView) return _body;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_body);
  }

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
            other is _$SuccessImpl &&
            const DeepCollectionEquality().equals(other._body, _body));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_body));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SuccessImplCopyWith<_$SuccessImpl> get copyWith =>
      __$$SuccessImplCopyWithImpl<_$SuccessImpl>(this, _$identity);

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
    TResult? Function(Map<String, dynamic> body)? success,
    TResult? Function(String status, Map<String, dynamic> body)? signal,
    TResult? Function(String status, String message, Map<String, dynamic> body)?
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
    TResult? Function(Success value)? success,
    TResult? Function(Signal value)? signal,
    TResult? Function(RpcError value)? error,
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
    return _$$SuccessImplToJson(
      this,
    );
  }
}

abstract class Success implements RpcResponse {
  factory Success(final Map<String, dynamic> body) = _$SuccessImpl;

  factory Success.fromJson(Map<String, dynamic> json) = _$SuccessImpl.fromJson;

  @override
  Map<String, dynamic> get body;
  @override
  @JsonKey(ignore: true)
  _$$SuccessImplCopyWith<_$SuccessImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SignalImplCopyWith<$Res>
    implements $RpcResponseCopyWith<$Res> {
  factory _$$SignalImplCopyWith(
          _$SignalImpl value, $Res Function(_$SignalImpl) then) =
      __$$SignalImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String status, Map<String, dynamic> body});
}

/// @nodoc
class __$$SignalImplCopyWithImpl<$Res>
    extends _$RpcResponseCopyWithImpl<$Res, _$SignalImpl>
    implements _$$SignalImplCopyWith<$Res> {
  __$$SignalImplCopyWithImpl(
      _$SignalImpl _value, $Res Function(_$SignalImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? body = null,
  }) {
    return _then(_$SignalImpl(
      null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      null == body
          ? _value._body
          : body // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SignalImpl implements Signal {
  _$SignalImpl(this.status, final Map<String, dynamic> body,
      {final String? $type})
      : _body = body,
        $type = $type ?? 'signal';

  factory _$SignalImpl.fromJson(Map<String, dynamic> json) =>
      _$$SignalImplFromJson(json);

  @override
  final String status;
  final Map<String, dynamic> _body;
  @override
  Map<String, dynamic> get body {
    if (_body is EqualUnmodifiableMapView) return _body;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_body);
  }

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
            other is _$SignalImpl &&
            (identical(other.status, status) || other.status == status) &&
            const DeepCollectionEquality().equals(other._body, _body));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, status, const DeepCollectionEquality().hash(_body));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SignalImplCopyWith<_$SignalImpl> get copyWith =>
      __$$SignalImplCopyWithImpl<_$SignalImpl>(this, _$identity);

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
    TResult? Function(Map<String, dynamic> body)? success,
    TResult? Function(String status, Map<String, dynamic> body)? signal,
    TResult? Function(String status, String message, Map<String, dynamic> body)?
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
    TResult? Function(Success value)? success,
    TResult? Function(Signal value)? signal,
    TResult? Function(RpcError value)? error,
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
    return _$$SignalImplToJson(
      this,
    );
  }
}

abstract class Signal implements RpcResponse {
  factory Signal(final String status, final Map<String, dynamic> body) =
      _$SignalImpl;

  factory Signal.fromJson(Map<String, dynamic> json) = _$SignalImpl.fromJson;

  String get status;
  @override
  Map<String, dynamic> get body;
  @override
  @JsonKey(ignore: true)
  _$$SignalImplCopyWith<_$SignalImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$RpcErrorImplCopyWith<$Res>
    implements $RpcResponseCopyWith<$Res> {
  factory _$$RpcErrorImplCopyWith(
          _$RpcErrorImpl value, $Res Function(_$RpcErrorImpl) then) =
      __$$RpcErrorImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String status, String message, Map<String, dynamic> body});
}

/// @nodoc
class __$$RpcErrorImplCopyWithImpl<$Res>
    extends _$RpcResponseCopyWithImpl<$Res, _$RpcErrorImpl>
    implements _$$RpcErrorImplCopyWith<$Res> {
  __$$RpcErrorImplCopyWithImpl(
      _$RpcErrorImpl _value, $Res Function(_$RpcErrorImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? message = null,
    Object? body = null,
  }) {
    return _then(_$RpcErrorImpl(
      null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      null == body
          ? _value._body
          : body // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RpcErrorImpl implements RpcError {
  _$RpcErrorImpl(this.status, this.message, final Map<String, dynamic> body,
      {final String? $type})
      : _body = body,
        $type = $type ?? 'error';

  factory _$RpcErrorImpl.fromJson(Map<String, dynamic> json) =>
      _$$RpcErrorImplFromJson(json);

  @override
  final String status;
  @override
  final String message;
  final Map<String, dynamic> _body;
  @override
  Map<String, dynamic> get body {
    if (_body is EqualUnmodifiableMapView) return _body;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_body);
  }

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
            other is _$RpcErrorImpl &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.message, message) || other.message == message) &&
            const DeepCollectionEquality().equals(other._body, _body));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, status, message, const DeepCollectionEquality().hash(_body));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$RpcErrorImplCopyWith<_$RpcErrorImpl> get copyWith =>
      __$$RpcErrorImplCopyWithImpl<_$RpcErrorImpl>(this, _$identity);

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
    TResult? Function(Map<String, dynamic> body)? success,
    TResult? Function(String status, Map<String, dynamic> body)? signal,
    TResult? Function(String status, String message, Map<String, dynamic> body)?
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
    TResult? Function(Success value)? success,
    TResult? Function(Signal value)? signal,
    TResult? Function(RpcError value)? error,
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
    return _$$RpcErrorImplToJson(
      this,
    );
  }
}

abstract class RpcError implements RpcResponse {
  factory RpcError(final String status, final String message,
      final Map<String, dynamic> body) = _$RpcErrorImpl;

  factory RpcError.fromJson(Map<String, dynamic> json) =
      _$RpcErrorImpl.fromJson;

  String get status;
  String get message;
  @override
  Map<String, dynamic> get body;
  @override
  @JsonKey(ignore: true)
  _$$RpcErrorImplCopyWith<_$RpcErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

RpcState _$RpcStateFromJson(Map<String, dynamic> json) {
  return _RpcState.fromJson(json);
}

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
      _$RpcStateCopyWithImpl<$Res, RpcState>;
  @useResult
  $Res call({String version, bool isAdmin});
}

/// @nodoc
class _$RpcStateCopyWithImpl<$Res, $Val extends RpcState>
    implements $RpcStateCopyWith<$Res> {
  _$RpcStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? version = null,
    Object? isAdmin = null,
  }) {
    return _then(_value.copyWith(
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as String,
      isAdmin: null == isAdmin
          ? _value.isAdmin
          : isAdmin // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RpcStateImplCopyWith<$Res>
    implements $RpcStateCopyWith<$Res> {
  factory _$$RpcStateImplCopyWith(
          _$RpcStateImpl value, $Res Function(_$RpcStateImpl) then) =
      __$$RpcStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String version, bool isAdmin});
}

/// @nodoc
class __$$RpcStateImplCopyWithImpl<$Res>
    extends _$RpcStateCopyWithImpl<$Res, _$RpcStateImpl>
    implements _$$RpcStateImplCopyWith<$Res> {
  __$$RpcStateImplCopyWithImpl(
      _$RpcStateImpl _value, $Res Function(_$RpcStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? version = null,
    Object? isAdmin = null,
  }) {
    return _then(_$RpcStateImpl(
      null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as String,
      null == isAdmin
          ? _value.isAdmin
          : isAdmin // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RpcStateImpl implements _RpcState {
  const _$RpcStateImpl(this.version, this.isAdmin);

  factory _$RpcStateImpl.fromJson(Map<String, dynamic> json) =>
      _$$RpcStateImplFromJson(json);

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
            other is _$RpcStateImpl &&
            (identical(other.version, version) || other.version == version) &&
            (identical(other.isAdmin, isAdmin) || other.isAdmin == isAdmin));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, version, isAdmin);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$RpcStateImplCopyWith<_$RpcStateImpl> get copyWith =>
      __$$RpcStateImplCopyWithImpl<_$RpcStateImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RpcStateImplToJson(
      this,
    );
  }
}

abstract class _RpcState implements RpcState {
  const factory _RpcState(final String version, final bool isAdmin) =
      _$RpcStateImpl;

  factory _RpcState.fromJson(Map<String, dynamic> json) =
      _$RpcStateImpl.fromJson;

  @override
  String get version;
  @override
  bool get isAdmin;
  @override
  @JsonKey(ignore: true)
  _$$RpcStateImplCopyWith<_$RpcStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
