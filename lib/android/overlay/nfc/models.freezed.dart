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
mixin _$NfcOverlayWidgetProperties {
  Widget get child => throw _privateConstructorUsedError;
  bool get visible => throw _privateConstructorUsedError;
  bool get hasCloseButton => throw _privateConstructorUsedError;

  /// Create a copy of NfcOverlayWidgetProperties
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $NfcOverlayWidgetPropertiesCopyWith<NfcOverlayWidgetProperties>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NfcOverlayWidgetPropertiesCopyWith<$Res> {
  factory $NfcOverlayWidgetPropertiesCopyWith(NfcOverlayWidgetProperties value,
          $Res Function(NfcOverlayWidgetProperties) then) =
      _$NfcOverlayWidgetPropertiesCopyWithImpl<$Res,
          NfcOverlayWidgetProperties>;
  @useResult
  $Res call({Widget child, bool visible, bool hasCloseButton});
}

/// @nodoc
class _$NfcOverlayWidgetPropertiesCopyWithImpl<$Res,
        $Val extends NfcOverlayWidgetProperties>
    implements $NfcOverlayWidgetPropertiesCopyWith<$Res> {
  _$NfcOverlayWidgetPropertiesCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of NfcOverlayWidgetProperties
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? child = null,
    Object? visible = null,
    Object? hasCloseButton = null,
  }) {
    return _then(_value.copyWith(
      child: null == child
          ? _value.child
          : child // ignore: cast_nullable_to_non_nullable
              as Widget,
      visible: null == visible
          ? _value.visible
          : visible // ignore: cast_nullable_to_non_nullable
              as bool,
      hasCloseButton: null == hasCloseButton
          ? _value.hasCloseButton
          : hasCloseButton // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$NfcOverlayWidgetPropertiesImplCopyWith<$Res>
    implements $NfcOverlayWidgetPropertiesCopyWith<$Res> {
  factory _$$NfcOverlayWidgetPropertiesImplCopyWith(
          _$NfcOverlayWidgetPropertiesImpl value,
          $Res Function(_$NfcOverlayWidgetPropertiesImpl) then) =
      __$$NfcOverlayWidgetPropertiesImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({Widget child, bool visible, bool hasCloseButton});
}

/// @nodoc
class __$$NfcOverlayWidgetPropertiesImplCopyWithImpl<$Res>
    extends _$NfcOverlayWidgetPropertiesCopyWithImpl<$Res,
        _$NfcOverlayWidgetPropertiesImpl>
    implements _$$NfcOverlayWidgetPropertiesImplCopyWith<$Res> {
  __$$NfcOverlayWidgetPropertiesImplCopyWithImpl(
      _$NfcOverlayWidgetPropertiesImpl _value,
      $Res Function(_$NfcOverlayWidgetPropertiesImpl) _then)
      : super(_value, _then);

  /// Create a copy of NfcOverlayWidgetProperties
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? child = null,
    Object? visible = null,
    Object? hasCloseButton = null,
  }) {
    return _then(_$NfcOverlayWidgetPropertiesImpl(
      child: null == child
          ? _value.child
          : child // ignore: cast_nullable_to_non_nullable
              as Widget,
      visible: null == visible
          ? _value.visible
          : visible // ignore: cast_nullable_to_non_nullable
              as bool,
      hasCloseButton: null == hasCloseButton
          ? _value.hasCloseButton
          : hasCloseButton // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$NfcOverlayWidgetPropertiesImpl implements _NfcOverlayWidgetProperties {
  _$NfcOverlayWidgetPropertiesImpl(
      {required this.child, this.visible = false, this.hasCloseButton = false});

  @override
  final Widget child;
  @override
  @JsonKey()
  final bool visible;
  @override
  @JsonKey()
  final bool hasCloseButton;

  @override
  String toString() {
    return 'NfcOverlayWidgetProperties(child: $child, visible: $visible, hasCloseButton: $hasCloseButton)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NfcOverlayWidgetPropertiesImpl &&
            (identical(other.child, child) || other.child == child) &&
            (identical(other.visible, visible) || other.visible == visible) &&
            (identical(other.hasCloseButton, hasCloseButton) ||
                other.hasCloseButton == hasCloseButton));
  }

  @override
  int get hashCode => Object.hash(runtimeType, child, visible, hasCloseButton);

  /// Create a copy of NfcOverlayWidgetProperties
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NfcOverlayWidgetPropertiesImplCopyWith<_$NfcOverlayWidgetPropertiesImpl>
      get copyWith => __$$NfcOverlayWidgetPropertiesImplCopyWithImpl<
          _$NfcOverlayWidgetPropertiesImpl>(this, _$identity);
}

abstract class _NfcOverlayWidgetProperties
    implements NfcOverlayWidgetProperties {
  factory _NfcOverlayWidgetProperties(
      {required final Widget child,
      final bool visible,
      final bool hasCloseButton}) = _$NfcOverlayWidgetPropertiesImpl;

  @override
  Widget get child;
  @override
  bool get visible;
  @override
  bool get hasCloseButton;

  /// Create a copy of NfcOverlayWidgetProperties
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NfcOverlayWidgetPropertiesImplCopyWith<_$NfcOverlayWidgetPropertiesImpl>
      get copyWith => throw _privateConstructorUsedError;
}
