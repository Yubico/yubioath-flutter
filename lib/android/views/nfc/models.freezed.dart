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
mixin _$NfcActivityWidgetProperties {
  Widget get child => throw _privateConstructorUsedError;
  bool get visible => throw _privateConstructorUsedError;
  bool get hasCloseButton => throw _privateConstructorUsedError;

  /// Create a copy of NfcActivityWidgetProperties
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $NfcActivityWidgetPropertiesCopyWith<NfcActivityWidgetProperties>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NfcActivityWidgetPropertiesCopyWith<$Res> {
  factory $NfcActivityWidgetPropertiesCopyWith(
          NfcActivityWidgetProperties value,
          $Res Function(NfcActivityWidgetProperties) then) =
      _$NfcActivityWidgetPropertiesCopyWithImpl<$Res,
          NfcActivityWidgetProperties>;
  @useResult
  $Res call({Widget child, bool visible, bool hasCloseButton});
}

/// @nodoc
class _$NfcActivityWidgetPropertiesCopyWithImpl<$Res,
        $Val extends NfcActivityWidgetProperties>
    implements $NfcActivityWidgetPropertiesCopyWith<$Res> {
  _$NfcActivityWidgetPropertiesCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of NfcActivityWidgetProperties
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
abstract class _$$NfcActivityWidgetPropertiesImplCopyWith<$Res>
    implements $NfcActivityWidgetPropertiesCopyWith<$Res> {
  factory _$$NfcActivityWidgetPropertiesImplCopyWith(
          _$NfcActivityWidgetPropertiesImpl value,
          $Res Function(_$NfcActivityWidgetPropertiesImpl) then) =
      __$$NfcActivityWidgetPropertiesImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({Widget child, bool visible, bool hasCloseButton});
}

/// @nodoc
class __$$NfcActivityWidgetPropertiesImplCopyWithImpl<$Res>
    extends _$NfcActivityWidgetPropertiesCopyWithImpl<$Res,
        _$NfcActivityWidgetPropertiesImpl>
    implements _$$NfcActivityWidgetPropertiesImplCopyWith<$Res> {
  __$$NfcActivityWidgetPropertiesImplCopyWithImpl(
      _$NfcActivityWidgetPropertiesImpl _value,
      $Res Function(_$NfcActivityWidgetPropertiesImpl) _then)
      : super(_value, _then);

  /// Create a copy of NfcActivityWidgetProperties
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? child = null,
    Object? visible = null,
    Object? hasCloseButton = null,
  }) {
    return _then(_$NfcActivityWidgetPropertiesImpl(
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

class _$NfcActivityWidgetPropertiesImpl
    implements _NfcActivityWidgetProperties {
  _$NfcActivityWidgetPropertiesImpl(
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
    return 'NfcActivityWidgetProperties(child: $child, visible: $visible, hasCloseButton: $hasCloseButton)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NfcActivityWidgetPropertiesImpl &&
            (identical(other.child, child) || other.child == child) &&
            (identical(other.visible, visible) || other.visible == visible) &&
            (identical(other.hasCloseButton, hasCloseButton) ||
                other.hasCloseButton == hasCloseButton));
  }

  @override
  int get hashCode => Object.hash(runtimeType, child, visible, hasCloseButton);

  /// Create a copy of NfcActivityWidgetProperties
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NfcActivityWidgetPropertiesImplCopyWith<_$NfcActivityWidgetPropertiesImpl>
      get copyWith => __$$NfcActivityWidgetPropertiesImplCopyWithImpl<
          _$NfcActivityWidgetPropertiesImpl>(this, _$identity);
}

abstract class _NfcActivityWidgetProperties
    implements NfcActivityWidgetProperties {
  factory _NfcActivityWidgetProperties(
      {required final Widget child,
      final bool visible,
      final bool hasCloseButton}) = _$NfcActivityWidgetPropertiesImpl;

  @override
  Widget get child;
  @override
  bool get visible;
  @override
  bool get hasCloseButton;

  /// Create a copy of NfcActivityWidgetProperties
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NfcActivityWidgetPropertiesImplCopyWith<_$NfcActivityWidgetPropertiesImpl>
      get copyWith => throw _privateConstructorUsedError;
}
