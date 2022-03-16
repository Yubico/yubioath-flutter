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

FidoState _$FidoStateFromJson(Map<String, dynamic> json) {
  return _FidoState.fromJson(json);
}

/// @nodoc
class _$FidoStateTearOff {
  const _$FidoStateTearOff();

  _FidoState call({required Map<String, dynamic> info, required bool locked}) {
    return _FidoState(
      info: info,
      locked: locked,
    );
  }

  FidoState fromJson(Map<String, Object?> json) {
    return FidoState.fromJson(json);
  }
}

/// @nodoc
const $FidoState = _$FidoStateTearOff();

/// @nodoc
mixin _$FidoState {
  Map<String, dynamic> get info => throw _privateConstructorUsedError;
  bool get locked => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $FidoStateCopyWith<FidoState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FidoStateCopyWith<$Res> {
  factory $FidoStateCopyWith(FidoState value, $Res Function(FidoState) then) =
      _$FidoStateCopyWithImpl<$Res>;
  $Res call({Map<String, dynamic> info, bool locked});
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
    Object? locked = freezed,
  }) {
    return _then(_value.copyWith(
      info: info == freezed
          ? _value.info
          : info // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      locked: locked == freezed
          ? _value.locked
          : locked // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
abstract class _$FidoStateCopyWith<$Res> implements $FidoStateCopyWith<$Res> {
  factory _$FidoStateCopyWith(
          _FidoState value, $Res Function(_FidoState) then) =
      __$FidoStateCopyWithImpl<$Res>;
  @override
  $Res call({Map<String, dynamic> info, bool locked});
}

/// @nodoc
class __$FidoStateCopyWithImpl<$Res> extends _$FidoStateCopyWithImpl<$Res>
    implements _$FidoStateCopyWith<$Res> {
  __$FidoStateCopyWithImpl(_FidoState _value, $Res Function(_FidoState) _then)
      : super(_value, (v) => _then(v as _FidoState));

  @override
  _FidoState get _value => super._value as _FidoState;

  @override
  $Res call({
    Object? info = freezed,
    Object? locked = freezed,
  }) {
    return _then(_FidoState(
      info: info == freezed
          ? _value.info
          : info // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      locked: locked == freezed
          ? _value.locked
          : locked // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$_FidoState extends _FidoState {
  _$_FidoState({required this.info, required this.locked}) : super._();

  factory _$_FidoState.fromJson(Map<String, dynamic> json) =>
      _$$_FidoStateFromJson(json);

  @override
  final Map<String, dynamic> info;
  @override
  final bool locked;

  @override
  String toString() {
    return 'FidoState(info: $info, locked: $locked)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _FidoState &&
            const DeepCollectionEquality().equals(other.info, info) &&
            const DeepCollectionEquality().equals(other.locked, locked));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(info),
      const DeepCollectionEquality().hash(locked));

  @JsonKey(ignore: true)
  @override
  _$FidoStateCopyWith<_FidoState> get copyWith =>
      __$FidoStateCopyWithImpl<_FidoState>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_FidoStateToJson(this);
  }
}

abstract class _FidoState extends FidoState {
  factory _FidoState(
      {required Map<String, dynamic> info,
      required bool locked}) = _$_FidoState;
  _FidoState._() : super._();

  factory _FidoState.fromJson(Map<String, dynamic> json) =
      _$_FidoState.fromJson;

  @override
  Map<String, dynamic> get info;
  @override
  bool get locked;
  @override
  @JsonKey(ignore: true)
  _$FidoStateCopyWith<_FidoState> get copyWith =>
      throw _privateConstructorUsedError;
}
