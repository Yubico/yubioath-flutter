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
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$NfcView {
  bool get isShowing => throw _privateConstructorUsedError;
  Widget get child => throw _privateConstructorUsedError;
  bool? get showCloseButton => throw _privateConstructorUsedError;

  /// Create a copy of NfcView
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $NfcViewCopyWith<NfcView> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NfcViewCopyWith<$Res> {
  factory $NfcViewCopyWith(NfcView value, $Res Function(NfcView) then) =
      _$NfcViewCopyWithImpl<$Res, NfcView>;
  @useResult
  $Res call({bool isShowing, Widget child, bool? showCloseButton});
}

/// @nodoc
class _$NfcViewCopyWithImpl<$Res, $Val extends NfcView>
    implements $NfcViewCopyWith<$Res> {
  _$NfcViewCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of NfcView
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isShowing = null,
    Object? child = null,
    Object? showCloseButton = freezed,
  }) {
    return _then(_value.copyWith(
      isShowing: null == isShowing
          ? _value.isShowing
          : isShowing // ignore: cast_nullable_to_non_nullable
              as bool,
      child: null == child
          ? _value.child
          : child // ignore: cast_nullable_to_non_nullable
              as Widget,
      showCloseButton: freezed == showCloseButton
          ? _value.showCloseButton
          : showCloseButton // ignore: cast_nullable_to_non_nullable
              as bool?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$NfcViewImplCopyWith<$Res> implements $NfcViewCopyWith<$Res> {
  factory _$$NfcViewImplCopyWith(
          _$NfcViewImpl value, $Res Function(_$NfcViewImpl) then) =
      __$$NfcViewImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({bool isShowing, Widget child, bool? showCloseButton});
}

/// @nodoc
class __$$NfcViewImplCopyWithImpl<$Res>
    extends _$NfcViewCopyWithImpl<$Res, _$NfcViewImpl>
    implements _$$NfcViewImplCopyWith<$Res> {
  __$$NfcViewImplCopyWithImpl(
      _$NfcViewImpl _value, $Res Function(_$NfcViewImpl) _then)
      : super(_value, _then);

  /// Create a copy of NfcView
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isShowing = null,
    Object? child = null,
    Object? showCloseButton = freezed,
  }) {
    return _then(_$NfcViewImpl(
      isShowing: null == isShowing
          ? _value.isShowing
          : isShowing // ignore: cast_nullable_to_non_nullable
              as bool,
      child: null == child
          ? _value.child
          : child // ignore: cast_nullable_to_non_nullable
              as Widget,
      showCloseButton: freezed == showCloseButton
          ? _value.showCloseButton
          : showCloseButton // ignore: cast_nullable_to_non_nullable
              as bool?,
    ));
  }
}

/// @nodoc

class _$NfcViewImpl implements _NfcView {
  _$NfcViewImpl(
      {required this.isShowing, required this.child, this.showCloseButton});

  @override
  final bool isShowing;
  @override
  final Widget child;
  @override
  final bool? showCloseButton;

  @override
  String toString() {
    return 'NfcView(isShowing: $isShowing, child: $child, showCloseButton: $showCloseButton)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NfcViewImpl &&
            (identical(other.isShowing, isShowing) ||
                other.isShowing == isShowing) &&
            (identical(other.child, child) || other.child == child) &&
            (identical(other.showCloseButton, showCloseButton) ||
                other.showCloseButton == showCloseButton));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, isShowing, child, showCloseButton);

  /// Create a copy of NfcView
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NfcViewImplCopyWith<_$NfcViewImpl> get copyWith =>
      __$$NfcViewImplCopyWithImpl<_$NfcViewImpl>(this, _$identity);
}

abstract class _NfcView implements NfcView {
  factory _NfcView(
      {required final bool isShowing,
      required final Widget child,
      final bool? showCloseButton}) = _$NfcViewImpl;

  @override
  bool get isShowing;
  @override
  Widget get child;
  @override
  bool? get showCloseButton;

  /// Create a copy of NfcView
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NfcViewImplCopyWith<_$NfcViewImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$NfcEventCommand {
  NfcEvent get event => throw _privateConstructorUsedError;

  /// Create a copy of NfcEventCommand
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $NfcEventCommandCopyWith<NfcEventCommand> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NfcEventCommandCopyWith<$Res> {
  factory $NfcEventCommandCopyWith(
          NfcEventCommand value, $Res Function(NfcEventCommand) then) =
      _$NfcEventCommandCopyWithImpl<$Res, NfcEventCommand>;
  @useResult
  $Res call({NfcEvent event});
}

/// @nodoc
class _$NfcEventCommandCopyWithImpl<$Res, $Val extends NfcEventCommand>
    implements $NfcEventCommandCopyWith<$Res> {
  _$NfcEventCommandCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of NfcEventCommand
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? event = null,
  }) {
    return _then(_value.copyWith(
      event: null == event
          ? _value.event
          : event // ignore: cast_nullable_to_non_nullable
              as NfcEvent,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$NfcEventCommandImplCopyWith<$Res>
    implements $NfcEventCommandCopyWith<$Res> {
  factory _$$NfcEventCommandImplCopyWith(_$NfcEventCommandImpl value,
          $Res Function(_$NfcEventCommandImpl) then) =
      __$$NfcEventCommandImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({NfcEvent event});
}

/// @nodoc
class __$$NfcEventCommandImplCopyWithImpl<$Res>
    extends _$NfcEventCommandCopyWithImpl<$Res, _$NfcEventCommandImpl>
    implements _$$NfcEventCommandImplCopyWith<$Res> {
  __$$NfcEventCommandImplCopyWithImpl(
      _$NfcEventCommandImpl _value, $Res Function(_$NfcEventCommandImpl) _then)
      : super(_value, _then);

  /// Create a copy of NfcEventCommand
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? event = null,
  }) {
    return _then(_$NfcEventCommandImpl(
      event: null == event
          ? _value.event
          : event // ignore: cast_nullable_to_non_nullable
              as NfcEvent,
    ));
  }
}

/// @nodoc

class _$NfcEventCommandImpl implements _NfcEventCommand {
  _$NfcEventCommandImpl({this.event = const NfcEvent()});

  @override
  @JsonKey()
  final NfcEvent event;

  @override
  String toString() {
    return 'NfcEventCommand(event: $event)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NfcEventCommandImpl &&
            (identical(other.event, event) || other.event == event));
  }

  @override
  int get hashCode => Object.hash(runtimeType, event);

  /// Create a copy of NfcEventCommand
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NfcEventCommandImplCopyWith<_$NfcEventCommandImpl> get copyWith =>
      __$$NfcEventCommandImplCopyWithImpl<_$NfcEventCommandImpl>(
          this, _$identity);
}

abstract class _NfcEventCommand implements NfcEventCommand {
  factory _NfcEventCommand({final NfcEvent event}) = _$NfcEventCommandImpl;

  @override
  NfcEvent get event;

  /// Create a copy of NfcEventCommand
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NfcEventCommandImplCopyWith<_$NfcEventCommandImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
