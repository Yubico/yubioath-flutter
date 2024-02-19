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

KeyCustomization _$KeyCustomizationFromJson(Map<String, dynamic> json) {
  return _KeyCustomization.fromJson(json);
}

/// @nodoc
mixin _$KeyCustomization {
  int get serial => throw _privateConstructorUsedError;
  @JsonKey(includeIfNull: false)
  String? get name => throw _privateConstructorUsedError;
  @JsonKey(includeIfNull: false)
  @_ColorConverter()
  Color? get color => throw _privateConstructorUsedError;

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
      {int serial,
      @JsonKey(includeIfNull: false) String? name,
      @JsonKey(includeIfNull: false) @_ColorConverter() Color? color});
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
    Object? name = freezed,
    Object? color = freezed,
  }) {
    return _then(_value.copyWith(
      serial: null == serial
          ? _value.serial
          : serial // ignore: cast_nullable_to_non_nullable
              as int,
      name: freezed == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
      color: freezed == color
          ? _value.color
          : color // ignore: cast_nullable_to_non_nullable
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
      {int serial,
      @JsonKey(includeIfNull: false) String? name,
      @JsonKey(includeIfNull: false) @_ColorConverter() Color? color});
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
    Object? name = freezed,
    Object? color = freezed,
  }) {
    return _then(_$KeyCustomizationImpl(
      serial: null == serial
          ? _value.serial
          : serial // ignore: cast_nullable_to_non_nullable
              as int,
      name: freezed == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
      color: freezed == color
          ? _value.color
          : color // ignore: cast_nullable_to_non_nullable
              as Color?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$KeyCustomizationImpl implements _KeyCustomization {
  _$KeyCustomizationImpl(
      {required this.serial,
      @JsonKey(includeIfNull: false) this.name,
      @JsonKey(includeIfNull: false) @_ColorConverter() this.color});

  factory _$KeyCustomizationImpl.fromJson(Map<String, dynamic> json) =>
      _$$KeyCustomizationImplFromJson(json);

  @override
  final int serial;
  @override
  @JsonKey(includeIfNull: false)
  final String? name;
  @override
  @JsonKey(includeIfNull: false)
  @_ColorConverter()
  final Color? color;

  @override
  String toString() {
    return 'KeyCustomization(serial: $serial, name: $name, color: $color)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$KeyCustomizationImpl &&
            (identical(other.serial, serial) || other.serial == serial) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.color, color) || other.color == color));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, serial, name, color);

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
      {required final int serial,
      @JsonKey(includeIfNull: false) final String? name,
      @JsonKey(includeIfNull: false)
      @_ColorConverter()
      final Color? color}) = _$KeyCustomizationImpl;

  factory _KeyCustomization.fromJson(Map<String, dynamic> json) =
      _$KeyCustomizationImpl.fromJson;

  @override
  int get serial;
  @override
  @JsonKey(includeIfNull: false)
  String? get name;
  @override
  @JsonKey(includeIfNull: false)
  @_ColorConverter()
  Color? get color;
  @override
  @JsonKey(ignore: true)
  _$$KeyCustomizationImplCopyWith<_$KeyCustomizationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
