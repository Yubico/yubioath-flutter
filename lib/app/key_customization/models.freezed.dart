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

KeyCustomization _$KeyCustomizationFromJson(Map<String, dynamic> json) {
  return _KeyCustomization.fromJson(json);
}

/// @nodoc
mixin _$KeyCustomization {
  String get serial => throw _privateConstructorUsedError;
  String? get customName => throw _privateConstructorUsedError;
  @_ColorConverter()
  Color? get customColor => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $KeyCustomizationCopyWith<KeyCustomization> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $KeyCustomizationCopyWith<$Res> {
  factory $KeyCustomizationCopyWith(
          KeyCustomization value, $Res Function(KeyCustomization) then) =
      _$KeyCustomizationCopyWithImpl<$Res, KeyCustomization>;
  @useResult
  $Res call(
      {String serial,
      String? customName,
      @_ColorConverter() Color? customColor});
}

/// @nodoc
class _$KeyCustomizationCopyWithImpl<$Res, $Val extends KeyCustomization>
    implements $KeyCustomizationCopyWith<$Res> {
  _$KeyCustomizationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? serial = null,
    Object? customName = freezed,
    Object? customColor = freezed,
  }) {
    return _then(_value.copyWith(
      serial: null == serial
          ? _value.serial
          : serial // ignore: cast_nullable_to_non_nullable
              as String,
      customName: freezed == customName
          ? _value.customName
          : customName // ignore: cast_nullable_to_non_nullable
              as String?,
      customColor: freezed == customColor
          ? _value.customColor
          : customColor // ignore: cast_nullable_to_non_nullable
              as Color?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$KeyCustomizationImplCopyWith<$Res>
    implements $KeyCustomizationCopyWith<$Res> {
  factory _$$KeyCustomizationImplCopyWith(_$KeyCustomizationImpl value,
          $Res Function(_$KeyCustomizationImpl) then) =
      __$$KeyCustomizationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String serial,
      String? customName,
      @_ColorConverter() Color? customColor});
}

/// @nodoc
class __$$KeyCustomizationImplCopyWithImpl<$Res>
    extends _$KeyCustomizationCopyWithImpl<$Res, _$KeyCustomizationImpl>
    implements _$$KeyCustomizationImplCopyWith<$Res> {
  __$$KeyCustomizationImplCopyWithImpl(_$KeyCustomizationImpl _value,
      $Res Function(_$KeyCustomizationImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? serial = null,
    Object? customName = freezed,
    Object? customColor = freezed,
  }) {
    return _then(_$KeyCustomizationImpl(
      serial: null == serial
          ? _value.serial
          : serial // ignore: cast_nullable_to_non_nullable
              as String,
      customName: freezed == customName
          ? _value.customName
          : customName // ignore: cast_nullable_to_non_nullable
              as String?,
      customColor: freezed == customColor
          ? _value.customColor
          : customColor // ignore: cast_nullable_to_non_nullable
              as Color?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$KeyCustomizationImpl implements _KeyCustomization {
  _$KeyCustomizationImpl(
      {required this.serial,
      this.customName,
      @_ColorConverter() this.customColor});

  factory _$KeyCustomizationImpl.fromJson(Map<String, dynamic> json) =>
      _$$KeyCustomizationImplFromJson(json);

  @override
  final String serial;
  @override
  final String? customName;
  @override
  @_ColorConverter()
  final Color? customColor;

  @override
  String toString() {
    return 'KeyCustomization(serial: $serial, customName: $customName, customColor: $customColor)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$KeyCustomizationImpl &&
            (identical(other.serial, serial) || other.serial == serial) &&
            (identical(other.customName, customName) ||
                other.customName == customName) &&
            (identical(other.customColor, customColor) ||
                other.customColor == customColor));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, serial, customName, customColor);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$KeyCustomizationImplCopyWith<_$KeyCustomizationImpl> get copyWith =>
      __$$KeyCustomizationImplCopyWithImpl<_$KeyCustomizationImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$KeyCustomizationImplToJson(
      this,
    );
  }
}

abstract class _KeyCustomization implements KeyCustomization {
  factory _KeyCustomization(
      {required final String serial,
      final String? customName,
      @_ColorConverter() final Color? customColor}) = _$KeyCustomizationImpl;

  factory _KeyCustomization.fromJson(Map<String, dynamic> json) =
      _$KeyCustomizationImpl.fromJson;

  @override
  String get serial;
  @override
  String? get customName;
  @override
  @_ColorConverter()
  Color? get customColor;
  @override
  @JsonKey(ignore: true)
  _$$KeyCustomizationImplCopyWith<_$KeyCustomizationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
