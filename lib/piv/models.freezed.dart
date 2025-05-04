// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PinMetadata {

 bool get defaultValue; int get totalAttempts; int get attemptsRemaining;
/// Create a copy of PinMetadata
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PinMetadataCopyWith<PinMetadata> get copyWith => _$PinMetadataCopyWithImpl<PinMetadata>(this as PinMetadata, _$identity);

  /// Serializes this PinMetadata to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PinMetadata&&(identical(other.defaultValue, defaultValue) || other.defaultValue == defaultValue)&&(identical(other.totalAttempts, totalAttempts) || other.totalAttempts == totalAttempts)&&(identical(other.attemptsRemaining, attemptsRemaining) || other.attemptsRemaining == attemptsRemaining));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,defaultValue,totalAttempts,attemptsRemaining);

@override
String toString() {
  return 'PinMetadata(defaultValue: $defaultValue, totalAttempts: $totalAttempts, attemptsRemaining: $attemptsRemaining)';
}


}

/// @nodoc
abstract mixin class $PinMetadataCopyWith<$Res>  {
  factory $PinMetadataCopyWith(PinMetadata value, $Res Function(PinMetadata) _then) = _$PinMetadataCopyWithImpl;
@useResult
$Res call({
 bool defaultValue, int totalAttempts, int attemptsRemaining
});




}
/// @nodoc
class _$PinMetadataCopyWithImpl<$Res>
    implements $PinMetadataCopyWith<$Res> {
  _$PinMetadataCopyWithImpl(this._self, this._then);

  final PinMetadata _self;
  final $Res Function(PinMetadata) _then;

/// Create a copy of PinMetadata
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? defaultValue = null,Object? totalAttempts = null,Object? attemptsRemaining = null,}) {
  return _then(_self.copyWith(
defaultValue: null == defaultValue ? _self.defaultValue : defaultValue // ignore: cast_nullable_to_non_nullable
as bool,totalAttempts: null == totalAttempts ? _self.totalAttempts : totalAttempts // ignore: cast_nullable_to_non_nullable
as int,attemptsRemaining: null == attemptsRemaining ? _self.attemptsRemaining : attemptsRemaining // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _PinMetadata implements PinMetadata {
   _PinMetadata(this.defaultValue, this.totalAttempts, this.attemptsRemaining);
  factory _PinMetadata.fromJson(Map<String, dynamic> json) => _$PinMetadataFromJson(json);

@override final  bool defaultValue;
@override final  int totalAttempts;
@override final  int attemptsRemaining;

/// Create a copy of PinMetadata
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PinMetadataCopyWith<_PinMetadata> get copyWith => __$PinMetadataCopyWithImpl<_PinMetadata>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PinMetadataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PinMetadata&&(identical(other.defaultValue, defaultValue) || other.defaultValue == defaultValue)&&(identical(other.totalAttempts, totalAttempts) || other.totalAttempts == totalAttempts)&&(identical(other.attemptsRemaining, attemptsRemaining) || other.attemptsRemaining == attemptsRemaining));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,defaultValue,totalAttempts,attemptsRemaining);

@override
String toString() {
  return 'PinMetadata(defaultValue: $defaultValue, totalAttempts: $totalAttempts, attemptsRemaining: $attemptsRemaining)';
}


}

/// @nodoc
abstract mixin class _$PinMetadataCopyWith<$Res> implements $PinMetadataCopyWith<$Res> {
  factory _$PinMetadataCopyWith(_PinMetadata value, $Res Function(_PinMetadata) _then) = __$PinMetadataCopyWithImpl;
@override @useResult
$Res call({
 bool defaultValue, int totalAttempts, int attemptsRemaining
});




}
/// @nodoc
class __$PinMetadataCopyWithImpl<$Res>
    implements _$PinMetadataCopyWith<$Res> {
  __$PinMetadataCopyWithImpl(this._self, this._then);

  final _PinMetadata _self;
  final $Res Function(_PinMetadata) _then;

/// Create a copy of PinMetadata
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? defaultValue = null,Object? totalAttempts = null,Object? attemptsRemaining = null,}) {
  return _then(_PinMetadata(
null == defaultValue ? _self.defaultValue : defaultValue // ignore: cast_nullable_to_non_nullable
as bool,null == totalAttempts ? _self.totalAttempts : totalAttempts // ignore: cast_nullable_to_non_nullable
as int,null == attemptsRemaining ? _self.attemptsRemaining : attemptsRemaining // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$PinVerificationStatus {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PinVerificationStatus);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PinVerificationStatus()';
}


}

/// @nodoc
class $PinVerificationStatusCopyWith<$Res>  {
$PinVerificationStatusCopyWith(PinVerificationStatus _, $Res Function(PinVerificationStatus) __);
}


/// @nodoc


class PinSuccess implements PinVerificationStatus {
  const PinSuccess();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PinSuccess);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PinVerificationStatus.success()';
}


}




/// @nodoc


class PinFailure implements PinVerificationStatus {
   PinFailure(this.reason);
  

 final  PivPinFailureReason reason;

/// Create a copy of PinVerificationStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PinFailureCopyWith<PinFailure> get copyWith => _$PinFailureCopyWithImpl<PinFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PinFailure&&(identical(other.reason, reason) || other.reason == reason));
}


@override
int get hashCode => Object.hash(runtimeType,reason);

@override
String toString() {
  return 'PinVerificationStatus.failure(reason: $reason)';
}


}

/// @nodoc
abstract mixin class $PinFailureCopyWith<$Res> implements $PinVerificationStatusCopyWith<$Res> {
  factory $PinFailureCopyWith(PinFailure value, $Res Function(PinFailure) _then) = _$PinFailureCopyWithImpl;
@useResult
$Res call({
 PivPinFailureReason reason
});


$PivPinFailureReasonCopyWith<$Res> get reason;

}
/// @nodoc
class _$PinFailureCopyWithImpl<$Res>
    implements $PinFailureCopyWith<$Res> {
  _$PinFailureCopyWithImpl(this._self, this._then);

  final PinFailure _self;
  final $Res Function(PinFailure) _then;

/// Create a copy of PinVerificationStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? reason = null,}) {
  return _then(PinFailure(
null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as PivPinFailureReason,
  ));
}

/// Create a copy of PinVerificationStatus
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PivPinFailureReasonCopyWith<$Res> get reason {
  
  return $PivPinFailureReasonCopyWith<$Res>(_self.reason, (value) {
    return _then(_self.copyWith(reason: value));
  });
}
}

/// @nodoc
mixin _$PivPinFailureReason {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PivPinFailureReason);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PivPinFailureReason()';
}


}

/// @nodoc
class $PivPinFailureReasonCopyWith<$Res>  {
$PivPinFailureReasonCopyWith(PivPinFailureReason _, $Res Function(PivPinFailureReason) __);
}


/// @nodoc


class PivInvalidPin implements PivPinFailureReason {
   PivInvalidPin(this.attemptsRemaining);
  

 final  int attemptsRemaining;

/// Create a copy of PivPinFailureReason
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PivInvalidPinCopyWith<PivInvalidPin> get copyWith => _$PivInvalidPinCopyWithImpl<PivInvalidPin>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PivInvalidPin&&(identical(other.attemptsRemaining, attemptsRemaining) || other.attemptsRemaining == attemptsRemaining));
}


@override
int get hashCode => Object.hash(runtimeType,attemptsRemaining);

@override
String toString() {
  return 'PivPinFailureReason.invalidPin(attemptsRemaining: $attemptsRemaining)';
}


}

/// @nodoc
abstract mixin class $PivInvalidPinCopyWith<$Res> implements $PivPinFailureReasonCopyWith<$Res> {
  factory $PivInvalidPinCopyWith(PivInvalidPin value, $Res Function(PivInvalidPin) _then) = _$PivInvalidPinCopyWithImpl;
@useResult
$Res call({
 int attemptsRemaining
});




}
/// @nodoc
class _$PivInvalidPinCopyWithImpl<$Res>
    implements $PivInvalidPinCopyWith<$Res> {
  _$PivInvalidPinCopyWithImpl(this._self, this._then);

  final PivInvalidPin _self;
  final $Res Function(PivInvalidPin) _then;

/// Create a copy of PivPinFailureReason
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? attemptsRemaining = null,}) {
  return _then(PivInvalidPin(
null == attemptsRemaining ? _self.attemptsRemaining : attemptsRemaining // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class PivWeakPin implements PivPinFailureReason {
  const PivWeakPin();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PivWeakPin);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PivPinFailureReason.weakPin()';
}


}





/// @nodoc
mixin _$ManagementKeyMetadata {

 ManagementKeyType get keyType; bool get defaultValue; TouchPolicy get touchPolicy;
/// Create a copy of ManagementKeyMetadata
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ManagementKeyMetadataCopyWith<ManagementKeyMetadata> get copyWith => _$ManagementKeyMetadataCopyWithImpl<ManagementKeyMetadata>(this as ManagementKeyMetadata, _$identity);

  /// Serializes this ManagementKeyMetadata to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ManagementKeyMetadata&&(identical(other.keyType, keyType) || other.keyType == keyType)&&(identical(other.defaultValue, defaultValue) || other.defaultValue == defaultValue)&&(identical(other.touchPolicy, touchPolicy) || other.touchPolicy == touchPolicy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,keyType,defaultValue,touchPolicy);

@override
String toString() {
  return 'ManagementKeyMetadata(keyType: $keyType, defaultValue: $defaultValue, touchPolicy: $touchPolicy)';
}


}

/// @nodoc
abstract mixin class $ManagementKeyMetadataCopyWith<$Res>  {
  factory $ManagementKeyMetadataCopyWith(ManagementKeyMetadata value, $Res Function(ManagementKeyMetadata) _then) = _$ManagementKeyMetadataCopyWithImpl;
@useResult
$Res call({
 ManagementKeyType keyType, bool defaultValue, TouchPolicy touchPolicy
});




}
/// @nodoc
class _$ManagementKeyMetadataCopyWithImpl<$Res>
    implements $ManagementKeyMetadataCopyWith<$Res> {
  _$ManagementKeyMetadataCopyWithImpl(this._self, this._then);

  final ManagementKeyMetadata _self;
  final $Res Function(ManagementKeyMetadata) _then;

/// Create a copy of ManagementKeyMetadata
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? keyType = null,Object? defaultValue = null,Object? touchPolicy = null,}) {
  return _then(_self.copyWith(
keyType: null == keyType ? _self.keyType : keyType // ignore: cast_nullable_to_non_nullable
as ManagementKeyType,defaultValue: null == defaultValue ? _self.defaultValue : defaultValue // ignore: cast_nullable_to_non_nullable
as bool,touchPolicy: null == touchPolicy ? _self.touchPolicy : touchPolicy // ignore: cast_nullable_to_non_nullable
as TouchPolicy,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _ManagementKeyMetadata implements ManagementKeyMetadata {
   _ManagementKeyMetadata(this.keyType, this.defaultValue, this.touchPolicy);
  factory _ManagementKeyMetadata.fromJson(Map<String, dynamic> json) => _$ManagementKeyMetadataFromJson(json);

@override final  ManagementKeyType keyType;
@override final  bool defaultValue;
@override final  TouchPolicy touchPolicy;

/// Create a copy of ManagementKeyMetadata
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ManagementKeyMetadataCopyWith<_ManagementKeyMetadata> get copyWith => __$ManagementKeyMetadataCopyWithImpl<_ManagementKeyMetadata>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ManagementKeyMetadataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ManagementKeyMetadata&&(identical(other.keyType, keyType) || other.keyType == keyType)&&(identical(other.defaultValue, defaultValue) || other.defaultValue == defaultValue)&&(identical(other.touchPolicy, touchPolicy) || other.touchPolicy == touchPolicy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,keyType,defaultValue,touchPolicy);

@override
String toString() {
  return 'ManagementKeyMetadata(keyType: $keyType, defaultValue: $defaultValue, touchPolicy: $touchPolicy)';
}


}

/// @nodoc
abstract mixin class _$ManagementKeyMetadataCopyWith<$Res> implements $ManagementKeyMetadataCopyWith<$Res> {
  factory _$ManagementKeyMetadataCopyWith(_ManagementKeyMetadata value, $Res Function(_ManagementKeyMetadata) _then) = __$ManagementKeyMetadataCopyWithImpl;
@override @useResult
$Res call({
 ManagementKeyType keyType, bool defaultValue, TouchPolicy touchPolicy
});




}
/// @nodoc
class __$ManagementKeyMetadataCopyWithImpl<$Res>
    implements _$ManagementKeyMetadataCopyWith<$Res> {
  __$ManagementKeyMetadataCopyWithImpl(this._self, this._then);

  final _ManagementKeyMetadata _self;
  final $Res Function(_ManagementKeyMetadata) _then;

/// Create a copy of ManagementKeyMetadata
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? keyType = null,Object? defaultValue = null,Object? touchPolicy = null,}) {
  return _then(_ManagementKeyMetadata(
null == keyType ? _self.keyType : keyType // ignore: cast_nullable_to_non_nullable
as ManagementKeyType,null == defaultValue ? _self.defaultValue : defaultValue // ignore: cast_nullable_to_non_nullable
as bool,null == touchPolicy ? _self.touchPolicy : touchPolicy // ignore: cast_nullable_to_non_nullable
as TouchPolicy,
  ));
}


}


/// @nodoc
mixin _$SlotMetadata {

 KeyType get keyType; PinPolicy get pinPolicy; TouchPolicy get touchPolicy; bool get generated; String get publicKey;
/// Create a copy of SlotMetadata
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SlotMetadataCopyWith<SlotMetadata> get copyWith => _$SlotMetadataCopyWithImpl<SlotMetadata>(this as SlotMetadata, _$identity);

  /// Serializes this SlotMetadata to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SlotMetadata&&(identical(other.keyType, keyType) || other.keyType == keyType)&&(identical(other.pinPolicy, pinPolicy) || other.pinPolicy == pinPolicy)&&(identical(other.touchPolicy, touchPolicy) || other.touchPolicy == touchPolicy)&&(identical(other.generated, generated) || other.generated == generated)&&(identical(other.publicKey, publicKey) || other.publicKey == publicKey));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,keyType,pinPolicy,touchPolicy,generated,publicKey);

@override
String toString() {
  return 'SlotMetadata(keyType: $keyType, pinPolicy: $pinPolicy, touchPolicy: $touchPolicy, generated: $generated, publicKey: $publicKey)';
}


}

/// @nodoc
abstract mixin class $SlotMetadataCopyWith<$Res>  {
  factory $SlotMetadataCopyWith(SlotMetadata value, $Res Function(SlotMetadata) _then) = _$SlotMetadataCopyWithImpl;
@useResult
$Res call({
 KeyType keyType, PinPolicy pinPolicy, TouchPolicy touchPolicy, bool generated, String publicKey
});




}
/// @nodoc
class _$SlotMetadataCopyWithImpl<$Res>
    implements $SlotMetadataCopyWith<$Res> {
  _$SlotMetadataCopyWithImpl(this._self, this._then);

  final SlotMetadata _self;
  final $Res Function(SlotMetadata) _then;

/// Create a copy of SlotMetadata
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? keyType = null,Object? pinPolicy = null,Object? touchPolicy = null,Object? generated = null,Object? publicKey = null,}) {
  return _then(_self.copyWith(
keyType: null == keyType ? _self.keyType : keyType // ignore: cast_nullable_to_non_nullable
as KeyType,pinPolicy: null == pinPolicy ? _self.pinPolicy : pinPolicy // ignore: cast_nullable_to_non_nullable
as PinPolicy,touchPolicy: null == touchPolicy ? _self.touchPolicy : touchPolicy // ignore: cast_nullable_to_non_nullable
as TouchPolicy,generated: null == generated ? _self.generated : generated // ignore: cast_nullable_to_non_nullable
as bool,publicKey: null == publicKey ? _self.publicKey : publicKey // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _SlotMetadata implements SlotMetadata {
   _SlotMetadata(this.keyType, this.pinPolicy, this.touchPolicy, this.generated, this.publicKey);
  factory _SlotMetadata.fromJson(Map<String, dynamic> json) => _$SlotMetadataFromJson(json);

@override final  KeyType keyType;
@override final  PinPolicy pinPolicy;
@override final  TouchPolicy touchPolicy;
@override final  bool generated;
@override final  String publicKey;

/// Create a copy of SlotMetadata
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SlotMetadataCopyWith<_SlotMetadata> get copyWith => __$SlotMetadataCopyWithImpl<_SlotMetadata>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SlotMetadataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SlotMetadata&&(identical(other.keyType, keyType) || other.keyType == keyType)&&(identical(other.pinPolicy, pinPolicy) || other.pinPolicy == pinPolicy)&&(identical(other.touchPolicy, touchPolicy) || other.touchPolicy == touchPolicy)&&(identical(other.generated, generated) || other.generated == generated)&&(identical(other.publicKey, publicKey) || other.publicKey == publicKey));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,keyType,pinPolicy,touchPolicy,generated,publicKey);

@override
String toString() {
  return 'SlotMetadata(keyType: $keyType, pinPolicy: $pinPolicy, touchPolicy: $touchPolicy, generated: $generated, publicKey: $publicKey)';
}


}

/// @nodoc
abstract mixin class _$SlotMetadataCopyWith<$Res> implements $SlotMetadataCopyWith<$Res> {
  factory _$SlotMetadataCopyWith(_SlotMetadata value, $Res Function(_SlotMetadata) _then) = __$SlotMetadataCopyWithImpl;
@override @useResult
$Res call({
 KeyType keyType, PinPolicy pinPolicy, TouchPolicy touchPolicy, bool generated, String publicKey
});




}
/// @nodoc
class __$SlotMetadataCopyWithImpl<$Res>
    implements _$SlotMetadataCopyWith<$Res> {
  __$SlotMetadataCopyWithImpl(this._self, this._then);

  final _SlotMetadata _self;
  final $Res Function(_SlotMetadata) _then;

/// Create a copy of SlotMetadata
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? keyType = null,Object? pinPolicy = null,Object? touchPolicy = null,Object? generated = null,Object? publicKey = null,}) {
  return _then(_SlotMetadata(
null == keyType ? _self.keyType : keyType // ignore: cast_nullable_to_non_nullable
as KeyType,null == pinPolicy ? _self.pinPolicy : pinPolicy // ignore: cast_nullable_to_non_nullable
as PinPolicy,null == touchPolicy ? _self.touchPolicy : touchPolicy // ignore: cast_nullable_to_non_nullable
as TouchPolicy,null == generated ? _self.generated : generated // ignore: cast_nullable_to_non_nullable
as bool,null == publicKey ? _self.publicKey : publicKey // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$PivStateMetadata {

 ManagementKeyMetadata get managementKeyMetadata; PinMetadata get pinMetadata; PinMetadata get pukMetadata;
/// Create a copy of PivStateMetadata
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PivStateMetadataCopyWith<PivStateMetadata> get copyWith => _$PivStateMetadataCopyWithImpl<PivStateMetadata>(this as PivStateMetadata, _$identity);

  /// Serializes this PivStateMetadata to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PivStateMetadata&&(identical(other.managementKeyMetadata, managementKeyMetadata) || other.managementKeyMetadata == managementKeyMetadata)&&(identical(other.pinMetadata, pinMetadata) || other.pinMetadata == pinMetadata)&&(identical(other.pukMetadata, pukMetadata) || other.pukMetadata == pukMetadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,managementKeyMetadata,pinMetadata,pukMetadata);

@override
String toString() {
  return 'PivStateMetadata(managementKeyMetadata: $managementKeyMetadata, pinMetadata: $pinMetadata, pukMetadata: $pukMetadata)';
}


}

/// @nodoc
abstract mixin class $PivStateMetadataCopyWith<$Res>  {
  factory $PivStateMetadataCopyWith(PivStateMetadata value, $Res Function(PivStateMetadata) _then) = _$PivStateMetadataCopyWithImpl;
@useResult
$Res call({
 ManagementKeyMetadata managementKeyMetadata, PinMetadata pinMetadata, PinMetadata pukMetadata
});


$ManagementKeyMetadataCopyWith<$Res> get managementKeyMetadata;$PinMetadataCopyWith<$Res> get pinMetadata;$PinMetadataCopyWith<$Res> get pukMetadata;

}
/// @nodoc
class _$PivStateMetadataCopyWithImpl<$Res>
    implements $PivStateMetadataCopyWith<$Res> {
  _$PivStateMetadataCopyWithImpl(this._self, this._then);

  final PivStateMetadata _self;
  final $Res Function(PivStateMetadata) _then;

/// Create a copy of PivStateMetadata
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? managementKeyMetadata = null,Object? pinMetadata = null,Object? pukMetadata = null,}) {
  return _then(_self.copyWith(
managementKeyMetadata: null == managementKeyMetadata ? _self.managementKeyMetadata : managementKeyMetadata // ignore: cast_nullable_to_non_nullable
as ManagementKeyMetadata,pinMetadata: null == pinMetadata ? _self.pinMetadata : pinMetadata // ignore: cast_nullable_to_non_nullable
as PinMetadata,pukMetadata: null == pukMetadata ? _self.pukMetadata : pukMetadata // ignore: cast_nullable_to_non_nullable
as PinMetadata,
  ));
}
/// Create a copy of PivStateMetadata
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ManagementKeyMetadataCopyWith<$Res> get managementKeyMetadata {
  
  return $ManagementKeyMetadataCopyWith<$Res>(_self.managementKeyMetadata, (value) {
    return _then(_self.copyWith(managementKeyMetadata: value));
  });
}/// Create a copy of PivStateMetadata
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PinMetadataCopyWith<$Res> get pinMetadata {
  
  return $PinMetadataCopyWith<$Res>(_self.pinMetadata, (value) {
    return _then(_self.copyWith(pinMetadata: value));
  });
}/// Create a copy of PivStateMetadata
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PinMetadataCopyWith<$Res> get pukMetadata {
  
  return $PinMetadataCopyWith<$Res>(_self.pukMetadata, (value) {
    return _then(_self.copyWith(pukMetadata: value));
  });
}
}


/// @nodoc
@JsonSerializable()

class _PivStateMetadata implements PivStateMetadata {
   _PivStateMetadata({required this.managementKeyMetadata, required this.pinMetadata, required this.pukMetadata});
  factory _PivStateMetadata.fromJson(Map<String, dynamic> json) => _$PivStateMetadataFromJson(json);

@override final  ManagementKeyMetadata managementKeyMetadata;
@override final  PinMetadata pinMetadata;
@override final  PinMetadata pukMetadata;

/// Create a copy of PivStateMetadata
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PivStateMetadataCopyWith<_PivStateMetadata> get copyWith => __$PivStateMetadataCopyWithImpl<_PivStateMetadata>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PivStateMetadataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PivStateMetadata&&(identical(other.managementKeyMetadata, managementKeyMetadata) || other.managementKeyMetadata == managementKeyMetadata)&&(identical(other.pinMetadata, pinMetadata) || other.pinMetadata == pinMetadata)&&(identical(other.pukMetadata, pukMetadata) || other.pukMetadata == pukMetadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,managementKeyMetadata,pinMetadata,pukMetadata);

@override
String toString() {
  return 'PivStateMetadata(managementKeyMetadata: $managementKeyMetadata, pinMetadata: $pinMetadata, pukMetadata: $pukMetadata)';
}


}

/// @nodoc
abstract mixin class _$PivStateMetadataCopyWith<$Res> implements $PivStateMetadataCopyWith<$Res> {
  factory _$PivStateMetadataCopyWith(_PivStateMetadata value, $Res Function(_PivStateMetadata) _then) = __$PivStateMetadataCopyWithImpl;
@override @useResult
$Res call({
 ManagementKeyMetadata managementKeyMetadata, PinMetadata pinMetadata, PinMetadata pukMetadata
});


@override $ManagementKeyMetadataCopyWith<$Res> get managementKeyMetadata;@override $PinMetadataCopyWith<$Res> get pinMetadata;@override $PinMetadataCopyWith<$Res> get pukMetadata;

}
/// @nodoc
class __$PivStateMetadataCopyWithImpl<$Res>
    implements _$PivStateMetadataCopyWith<$Res> {
  __$PivStateMetadataCopyWithImpl(this._self, this._then);

  final _PivStateMetadata _self;
  final $Res Function(_PivStateMetadata) _then;

/// Create a copy of PivStateMetadata
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? managementKeyMetadata = null,Object? pinMetadata = null,Object? pukMetadata = null,}) {
  return _then(_PivStateMetadata(
managementKeyMetadata: null == managementKeyMetadata ? _self.managementKeyMetadata : managementKeyMetadata // ignore: cast_nullable_to_non_nullable
as ManagementKeyMetadata,pinMetadata: null == pinMetadata ? _self.pinMetadata : pinMetadata // ignore: cast_nullable_to_non_nullable
as PinMetadata,pukMetadata: null == pukMetadata ? _self.pukMetadata : pukMetadata // ignore: cast_nullable_to_non_nullable
as PinMetadata,
  ));
}

/// Create a copy of PivStateMetadata
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ManagementKeyMetadataCopyWith<$Res> get managementKeyMetadata {
  
  return $ManagementKeyMetadataCopyWith<$Res>(_self.managementKeyMetadata, (value) {
    return _then(_self.copyWith(managementKeyMetadata: value));
  });
}/// Create a copy of PivStateMetadata
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PinMetadataCopyWith<$Res> get pinMetadata {
  
  return $PinMetadataCopyWith<$Res>(_self.pinMetadata, (value) {
    return _then(_self.copyWith(pinMetadata: value));
  });
}/// Create a copy of PivStateMetadata
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PinMetadataCopyWith<$Res> get pukMetadata {
  
  return $PinMetadataCopyWith<$Res>(_self.pukMetadata, (value) {
    return _then(_self.copyWith(pukMetadata: value));
  });
}
}


/// @nodoc
mixin _$PivState {

 Version get version; bool get authenticated; bool get derivedKey; bool get storedKey; int get pinAttempts; bool get supportsBio; String? get chuid; String? get ccc; PivStateMetadata? get metadata;
/// Create a copy of PivState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PivStateCopyWith<PivState> get copyWith => _$PivStateCopyWithImpl<PivState>(this as PivState, _$identity);

  /// Serializes this PivState to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PivState&&(identical(other.version, version) || other.version == version)&&(identical(other.authenticated, authenticated) || other.authenticated == authenticated)&&(identical(other.derivedKey, derivedKey) || other.derivedKey == derivedKey)&&(identical(other.storedKey, storedKey) || other.storedKey == storedKey)&&(identical(other.pinAttempts, pinAttempts) || other.pinAttempts == pinAttempts)&&(identical(other.supportsBio, supportsBio) || other.supportsBio == supportsBio)&&(identical(other.chuid, chuid) || other.chuid == chuid)&&(identical(other.ccc, ccc) || other.ccc == ccc)&&(identical(other.metadata, metadata) || other.metadata == metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,version,authenticated,derivedKey,storedKey,pinAttempts,supportsBio,chuid,ccc,metadata);

@override
String toString() {
  return 'PivState(version: $version, authenticated: $authenticated, derivedKey: $derivedKey, storedKey: $storedKey, pinAttempts: $pinAttempts, supportsBio: $supportsBio, chuid: $chuid, ccc: $ccc, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class $PivStateCopyWith<$Res>  {
  factory $PivStateCopyWith(PivState value, $Res Function(PivState) _then) = _$PivStateCopyWithImpl;
@useResult
$Res call({
 Version version, bool authenticated, bool derivedKey, bool storedKey, int pinAttempts, bool supportsBio, String? chuid, String? ccc, PivStateMetadata? metadata
});


$VersionCopyWith<$Res> get version;$PivStateMetadataCopyWith<$Res>? get metadata;

}
/// @nodoc
class _$PivStateCopyWithImpl<$Res>
    implements $PivStateCopyWith<$Res> {
  _$PivStateCopyWithImpl(this._self, this._then);

  final PivState _self;
  final $Res Function(PivState) _then;

/// Create a copy of PivState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? version = null,Object? authenticated = null,Object? derivedKey = null,Object? storedKey = null,Object? pinAttempts = null,Object? supportsBio = null,Object? chuid = freezed,Object? ccc = freezed,Object? metadata = freezed,}) {
  return _then(_self.copyWith(
version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as Version,authenticated: null == authenticated ? _self.authenticated : authenticated // ignore: cast_nullable_to_non_nullable
as bool,derivedKey: null == derivedKey ? _self.derivedKey : derivedKey // ignore: cast_nullable_to_non_nullable
as bool,storedKey: null == storedKey ? _self.storedKey : storedKey // ignore: cast_nullable_to_non_nullable
as bool,pinAttempts: null == pinAttempts ? _self.pinAttempts : pinAttempts // ignore: cast_nullable_to_non_nullable
as int,supportsBio: null == supportsBio ? _self.supportsBio : supportsBio // ignore: cast_nullable_to_non_nullable
as bool,chuid: freezed == chuid ? _self.chuid : chuid // ignore: cast_nullable_to_non_nullable
as String?,ccc: freezed == ccc ? _self.ccc : ccc // ignore: cast_nullable_to_non_nullable
as String?,metadata: freezed == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as PivStateMetadata?,
  ));
}
/// Create a copy of PivState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VersionCopyWith<$Res> get version {
  
  return $VersionCopyWith<$Res>(_self.version, (value) {
    return _then(_self.copyWith(version: value));
  });
}/// Create a copy of PivState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PivStateMetadataCopyWith<$Res>? get metadata {
    if (_self.metadata == null) {
    return null;
  }

  return $PivStateMetadataCopyWith<$Res>(_self.metadata!, (value) {
    return _then(_self.copyWith(metadata: value));
  });
}
}


/// @nodoc
@JsonSerializable()

class _PivState extends PivState {
   _PivState({required this.version, required this.authenticated, required this.derivedKey, required this.storedKey, required this.pinAttempts, required this.supportsBio, this.chuid, this.ccc, this.metadata}): super._();
  factory _PivState.fromJson(Map<String, dynamic> json) => _$PivStateFromJson(json);

@override final  Version version;
@override final  bool authenticated;
@override final  bool derivedKey;
@override final  bool storedKey;
@override final  int pinAttempts;
@override final  bool supportsBio;
@override final  String? chuid;
@override final  String? ccc;
@override final  PivStateMetadata? metadata;

/// Create a copy of PivState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PivStateCopyWith<_PivState> get copyWith => __$PivStateCopyWithImpl<_PivState>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PivStateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PivState&&(identical(other.version, version) || other.version == version)&&(identical(other.authenticated, authenticated) || other.authenticated == authenticated)&&(identical(other.derivedKey, derivedKey) || other.derivedKey == derivedKey)&&(identical(other.storedKey, storedKey) || other.storedKey == storedKey)&&(identical(other.pinAttempts, pinAttempts) || other.pinAttempts == pinAttempts)&&(identical(other.supportsBio, supportsBio) || other.supportsBio == supportsBio)&&(identical(other.chuid, chuid) || other.chuid == chuid)&&(identical(other.ccc, ccc) || other.ccc == ccc)&&(identical(other.metadata, metadata) || other.metadata == metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,version,authenticated,derivedKey,storedKey,pinAttempts,supportsBio,chuid,ccc,metadata);

@override
String toString() {
  return 'PivState(version: $version, authenticated: $authenticated, derivedKey: $derivedKey, storedKey: $storedKey, pinAttempts: $pinAttempts, supportsBio: $supportsBio, chuid: $chuid, ccc: $ccc, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class _$PivStateCopyWith<$Res> implements $PivStateCopyWith<$Res> {
  factory _$PivStateCopyWith(_PivState value, $Res Function(_PivState) _then) = __$PivStateCopyWithImpl;
@override @useResult
$Res call({
 Version version, bool authenticated, bool derivedKey, bool storedKey, int pinAttempts, bool supportsBio, String? chuid, String? ccc, PivStateMetadata? metadata
});


@override $VersionCopyWith<$Res> get version;@override $PivStateMetadataCopyWith<$Res>? get metadata;

}
/// @nodoc
class __$PivStateCopyWithImpl<$Res>
    implements _$PivStateCopyWith<$Res> {
  __$PivStateCopyWithImpl(this._self, this._then);

  final _PivState _self;
  final $Res Function(_PivState) _then;

/// Create a copy of PivState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? version = null,Object? authenticated = null,Object? derivedKey = null,Object? storedKey = null,Object? pinAttempts = null,Object? supportsBio = null,Object? chuid = freezed,Object? ccc = freezed,Object? metadata = freezed,}) {
  return _then(_PivState(
version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as Version,authenticated: null == authenticated ? _self.authenticated : authenticated // ignore: cast_nullable_to_non_nullable
as bool,derivedKey: null == derivedKey ? _self.derivedKey : derivedKey // ignore: cast_nullable_to_non_nullable
as bool,storedKey: null == storedKey ? _self.storedKey : storedKey // ignore: cast_nullable_to_non_nullable
as bool,pinAttempts: null == pinAttempts ? _self.pinAttempts : pinAttempts // ignore: cast_nullable_to_non_nullable
as int,supportsBio: null == supportsBio ? _self.supportsBio : supportsBio // ignore: cast_nullable_to_non_nullable
as bool,chuid: freezed == chuid ? _self.chuid : chuid // ignore: cast_nullable_to_non_nullable
as String?,ccc: freezed == ccc ? _self.ccc : ccc // ignore: cast_nullable_to_non_nullable
as String?,metadata: freezed == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as PivStateMetadata?,
  ));
}

/// Create a copy of PivState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VersionCopyWith<$Res> get version {
  
  return $VersionCopyWith<$Res>(_self.version, (value) {
    return _then(_self.copyWith(version: value));
  });
}/// Create a copy of PivState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PivStateMetadataCopyWith<$Res>? get metadata {
    if (_self.metadata == null) {
    return null;
  }

  return $PivStateMetadataCopyWith<$Res>(_self.metadata!, (value) {
    return _then(_self.copyWith(metadata: value));
  });
}
}


/// @nodoc
mixin _$CertInfo {

 KeyType? get keyType; String get subject; String get issuer; String get serial; String get notValidBefore; String get notValidAfter; String get fingerprint;
/// Create a copy of CertInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CertInfoCopyWith<CertInfo> get copyWith => _$CertInfoCopyWithImpl<CertInfo>(this as CertInfo, _$identity);

  /// Serializes this CertInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CertInfo&&(identical(other.keyType, keyType) || other.keyType == keyType)&&(identical(other.subject, subject) || other.subject == subject)&&(identical(other.issuer, issuer) || other.issuer == issuer)&&(identical(other.serial, serial) || other.serial == serial)&&(identical(other.notValidBefore, notValidBefore) || other.notValidBefore == notValidBefore)&&(identical(other.notValidAfter, notValidAfter) || other.notValidAfter == notValidAfter)&&(identical(other.fingerprint, fingerprint) || other.fingerprint == fingerprint));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,keyType,subject,issuer,serial,notValidBefore,notValidAfter,fingerprint);

@override
String toString() {
  return 'CertInfo(keyType: $keyType, subject: $subject, issuer: $issuer, serial: $serial, notValidBefore: $notValidBefore, notValidAfter: $notValidAfter, fingerprint: $fingerprint)';
}


}

/// @nodoc
abstract mixin class $CertInfoCopyWith<$Res>  {
  factory $CertInfoCopyWith(CertInfo value, $Res Function(CertInfo) _then) = _$CertInfoCopyWithImpl;
@useResult
$Res call({
 KeyType? keyType, String subject, String issuer, String serial, String notValidBefore, String notValidAfter, String fingerprint
});




}
/// @nodoc
class _$CertInfoCopyWithImpl<$Res>
    implements $CertInfoCopyWith<$Res> {
  _$CertInfoCopyWithImpl(this._self, this._then);

  final CertInfo _self;
  final $Res Function(CertInfo) _then;

/// Create a copy of CertInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? keyType = freezed,Object? subject = null,Object? issuer = null,Object? serial = null,Object? notValidBefore = null,Object? notValidAfter = null,Object? fingerprint = null,}) {
  return _then(_self.copyWith(
keyType: freezed == keyType ? _self.keyType : keyType // ignore: cast_nullable_to_non_nullable
as KeyType?,subject: null == subject ? _self.subject : subject // ignore: cast_nullable_to_non_nullable
as String,issuer: null == issuer ? _self.issuer : issuer // ignore: cast_nullable_to_non_nullable
as String,serial: null == serial ? _self.serial : serial // ignore: cast_nullable_to_non_nullable
as String,notValidBefore: null == notValidBefore ? _self.notValidBefore : notValidBefore // ignore: cast_nullable_to_non_nullable
as String,notValidAfter: null == notValidAfter ? _self.notValidAfter : notValidAfter // ignore: cast_nullable_to_non_nullable
as String,fingerprint: null == fingerprint ? _self.fingerprint : fingerprint // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _CertInfo implements CertInfo {
   _CertInfo({required this.keyType, required this.subject, required this.issuer, required this.serial, required this.notValidBefore, required this.notValidAfter, required this.fingerprint});
  factory _CertInfo.fromJson(Map<String, dynamic> json) => _$CertInfoFromJson(json);

@override final  KeyType? keyType;
@override final  String subject;
@override final  String issuer;
@override final  String serial;
@override final  String notValidBefore;
@override final  String notValidAfter;
@override final  String fingerprint;

/// Create a copy of CertInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CertInfoCopyWith<_CertInfo> get copyWith => __$CertInfoCopyWithImpl<_CertInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CertInfoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CertInfo&&(identical(other.keyType, keyType) || other.keyType == keyType)&&(identical(other.subject, subject) || other.subject == subject)&&(identical(other.issuer, issuer) || other.issuer == issuer)&&(identical(other.serial, serial) || other.serial == serial)&&(identical(other.notValidBefore, notValidBefore) || other.notValidBefore == notValidBefore)&&(identical(other.notValidAfter, notValidAfter) || other.notValidAfter == notValidAfter)&&(identical(other.fingerprint, fingerprint) || other.fingerprint == fingerprint));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,keyType,subject,issuer,serial,notValidBefore,notValidAfter,fingerprint);

@override
String toString() {
  return 'CertInfo(keyType: $keyType, subject: $subject, issuer: $issuer, serial: $serial, notValidBefore: $notValidBefore, notValidAfter: $notValidAfter, fingerprint: $fingerprint)';
}


}

/// @nodoc
abstract mixin class _$CertInfoCopyWith<$Res> implements $CertInfoCopyWith<$Res> {
  factory _$CertInfoCopyWith(_CertInfo value, $Res Function(_CertInfo) _then) = __$CertInfoCopyWithImpl;
@override @useResult
$Res call({
 KeyType? keyType, String subject, String issuer, String serial, String notValidBefore, String notValidAfter, String fingerprint
});




}
/// @nodoc
class __$CertInfoCopyWithImpl<$Res>
    implements _$CertInfoCopyWith<$Res> {
  __$CertInfoCopyWithImpl(this._self, this._then);

  final _CertInfo _self;
  final $Res Function(_CertInfo) _then;

/// Create a copy of CertInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? keyType = freezed,Object? subject = null,Object? issuer = null,Object? serial = null,Object? notValidBefore = null,Object? notValidAfter = null,Object? fingerprint = null,}) {
  return _then(_CertInfo(
keyType: freezed == keyType ? _self.keyType : keyType // ignore: cast_nullable_to_non_nullable
as KeyType?,subject: null == subject ? _self.subject : subject // ignore: cast_nullable_to_non_nullable
as String,issuer: null == issuer ? _self.issuer : issuer // ignore: cast_nullable_to_non_nullable
as String,serial: null == serial ? _self.serial : serial // ignore: cast_nullable_to_non_nullable
as String,notValidBefore: null == notValidBefore ? _self.notValidBefore : notValidBefore // ignore: cast_nullable_to_non_nullable
as String,notValidAfter: null == notValidAfter ? _self.notValidAfter : notValidAfter // ignore: cast_nullable_to_non_nullable
as String,fingerprint: null == fingerprint ? _self.fingerprint : fingerprint // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$PivSlot {

 SlotId get slot; SlotMetadata? get metadata; CertInfo? get certInfo; bool? get publicKeyMatch;
/// Create a copy of PivSlot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PivSlotCopyWith<PivSlot> get copyWith => _$PivSlotCopyWithImpl<PivSlot>(this as PivSlot, _$identity);

  /// Serializes this PivSlot to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PivSlot&&(identical(other.slot, slot) || other.slot == slot)&&(identical(other.metadata, metadata) || other.metadata == metadata)&&(identical(other.certInfo, certInfo) || other.certInfo == certInfo)&&(identical(other.publicKeyMatch, publicKeyMatch) || other.publicKeyMatch == publicKeyMatch));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,slot,metadata,certInfo,publicKeyMatch);

@override
String toString() {
  return 'PivSlot(slot: $slot, metadata: $metadata, certInfo: $certInfo, publicKeyMatch: $publicKeyMatch)';
}


}

/// @nodoc
abstract mixin class $PivSlotCopyWith<$Res>  {
  factory $PivSlotCopyWith(PivSlot value, $Res Function(PivSlot) _then) = _$PivSlotCopyWithImpl;
@useResult
$Res call({
 SlotId slot, SlotMetadata? metadata, CertInfo? certInfo, bool? publicKeyMatch
});


$SlotMetadataCopyWith<$Res>? get metadata;$CertInfoCopyWith<$Res>? get certInfo;

}
/// @nodoc
class _$PivSlotCopyWithImpl<$Res>
    implements $PivSlotCopyWith<$Res> {
  _$PivSlotCopyWithImpl(this._self, this._then);

  final PivSlot _self;
  final $Res Function(PivSlot) _then;

/// Create a copy of PivSlot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? slot = null,Object? metadata = freezed,Object? certInfo = freezed,Object? publicKeyMatch = freezed,}) {
  return _then(_self.copyWith(
slot: null == slot ? _self.slot : slot // ignore: cast_nullable_to_non_nullable
as SlotId,metadata: freezed == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as SlotMetadata?,certInfo: freezed == certInfo ? _self.certInfo : certInfo // ignore: cast_nullable_to_non_nullable
as CertInfo?,publicKeyMatch: freezed == publicKeyMatch ? _self.publicKeyMatch : publicKeyMatch // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}
/// Create a copy of PivSlot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SlotMetadataCopyWith<$Res>? get metadata {
    if (_self.metadata == null) {
    return null;
  }

  return $SlotMetadataCopyWith<$Res>(_self.metadata!, (value) {
    return _then(_self.copyWith(metadata: value));
  });
}/// Create a copy of PivSlot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CertInfoCopyWith<$Res>? get certInfo {
    if (_self.certInfo == null) {
    return null;
  }

  return $CertInfoCopyWith<$Res>(_self.certInfo!, (value) {
    return _then(_self.copyWith(certInfo: value));
  });
}
}


/// @nodoc
@JsonSerializable()

class _PivSlot implements PivSlot {
   _PivSlot({required this.slot, this.metadata, this.certInfo, this.publicKeyMatch});
  factory _PivSlot.fromJson(Map<String, dynamic> json) => _$PivSlotFromJson(json);

@override final  SlotId slot;
@override final  SlotMetadata? metadata;
@override final  CertInfo? certInfo;
@override final  bool? publicKeyMatch;

/// Create a copy of PivSlot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PivSlotCopyWith<_PivSlot> get copyWith => __$PivSlotCopyWithImpl<_PivSlot>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PivSlotToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PivSlot&&(identical(other.slot, slot) || other.slot == slot)&&(identical(other.metadata, metadata) || other.metadata == metadata)&&(identical(other.certInfo, certInfo) || other.certInfo == certInfo)&&(identical(other.publicKeyMatch, publicKeyMatch) || other.publicKeyMatch == publicKeyMatch));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,slot,metadata,certInfo,publicKeyMatch);

@override
String toString() {
  return 'PivSlot(slot: $slot, metadata: $metadata, certInfo: $certInfo, publicKeyMatch: $publicKeyMatch)';
}


}

/// @nodoc
abstract mixin class _$PivSlotCopyWith<$Res> implements $PivSlotCopyWith<$Res> {
  factory _$PivSlotCopyWith(_PivSlot value, $Res Function(_PivSlot) _then) = __$PivSlotCopyWithImpl;
@override @useResult
$Res call({
 SlotId slot, SlotMetadata? metadata, CertInfo? certInfo, bool? publicKeyMatch
});


@override $SlotMetadataCopyWith<$Res>? get metadata;@override $CertInfoCopyWith<$Res>? get certInfo;

}
/// @nodoc
class __$PivSlotCopyWithImpl<$Res>
    implements _$PivSlotCopyWith<$Res> {
  __$PivSlotCopyWithImpl(this._self, this._then);

  final _PivSlot _self;
  final $Res Function(_PivSlot) _then;

/// Create a copy of PivSlot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? slot = null,Object? metadata = freezed,Object? certInfo = freezed,Object? publicKeyMatch = freezed,}) {
  return _then(_PivSlot(
slot: null == slot ? _self.slot : slot // ignore: cast_nullable_to_non_nullable
as SlotId,metadata: freezed == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as SlotMetadata?,certInfo: freezed == certInfo ? _self.certInfo : certInfo // ignore: cast_nullable_to_non_nullable
as CertInfo?,publicKeyMatch: freezed == publicKeyMatch ? _self.publicKeyMatch : publicKeyMatch // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

/// Create a copy of PivSlot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SlotMetadataCopyWith<$Res>? get metadata {
    if (_self.metadata == null) {
    return null;
  }

  return $SlotMetadataCopyWith<$Res>(_self.metadata!, (value) {
    return _then(_self.copyWith(metadata: value));
  });
}/// Create a copy of PivSlot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CertInfoCopyWith<$Res>? get certInfo {
    if (_self.certInfo == null) {
    return null;
  }

  return $CertInfoCopyWith<$Res>(_self.certInfo!, (value) {
    return _then(_self.copyWith(certInfo: value));
  });
}
}

PivExamineResult _$PivExamineResultFromJson(
  Map<String, dynamic> json
) {
        switch (json['runtimeType']) {
                  case 'result':
          return PivExamineResultResult.fromJson(
            json
          );
                case 'invalidPassword':
          return PivExamineResultInvalidPassword.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'runtimeType',
  'PivExamineResult',
  'Invalid union type "${json['runtimeType']}"!'
);
        }
      
}

/// @nodoc
mixin _$PivExamineResult {



  /// Serializes this PivExamineResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PivExamineResult);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PivExamineResult()';
}


}

/// @nodoc
class $PivExamineResultCopyWith<$Res>  {
$PivExamineResultCopyWith(PivExamineResult _, $Res Function(PivExamineResult) __);
}


/// @nodoc
@JsonSerializable()

class PivExamineResultResult implements PivExamineResult {
   PivExamineResultResult({required this.password, required this.keyType, required this.certInfo, this.publicKeyMatch, final  String? $type}): $type = $type ?? 'result';
  factory PivExamineResultResult.fromJson(Map<String, dynamic> json) => _$PivExamineResultResultFromJson(json);

 final  bool password;
 final  KeyType? keyType;
 final  CertInfo? certInfo;
 final  bool? publicKeyMatch;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of PivExamineResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PivExamineResultResultCopyWith<PivExamineResultResult> get copyWith => _$PivExamineResultResultCopyWithImpl<PivExamineResultResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PivExamineResultResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PivExamineResultResult&&(identical(other.password, password) || other.password == password)&&(identical(other.keyType, keyType) || other.keyType == keyType)&&(identical(other.certInfo, certInfo) || other.certInfo == certInfo)&&(identical(other.publicKeyMatch, publicKeyMatch) || other.publicKeyMatch == publicKeyMatch));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,password,keyType,certInfo,publicKeyMatch);

@override
String toString() {
  return 'PivExamineResult.result(password: $password, keyType: $keyType, certInfo: $certInfo, publicKeyMatch: $publicKeyMatch)';
}


}

/// @nodoc
abstract mixin class $PivExamineResultResultCopyWith<$Res> implements $PivExamineResultCopyWith<$Res> {
  factory $PivExamineResultResultCopyWith(PivExamineResultResult value, $Res Function(PivExamineResultResult) _then) = _$PivExamineResultResultCopyWithImpl;
@useResult
$Res call({
 bool password, KeyType? keyType, CertInfo? certInfo, bool? publicKeyMatch
});


$CertInfoCopyWith<$Res>? get certInfo;

}
/// @nodoc
class _$PivExamineResultResultCopyWithImpl<$Res>
    implements $PivExamineResultResultCopyWith<$Res> {
  _$PivExamineResultResultCopyWithImpl(this._self, this._then);

  final PivExamineResultResult _self;
  final $Res Function(PivExamineResultResult) _then;

/// Create a copy of PivExamineResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? password = null,Object? keyType = freezed,Object? certInfo = freezed,Object? publicKeyMatch = freezed,}) {
  return _then(PivExamineResultResult(
password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as bool,keyType: freezed == keyType ? _self.keyType : keyType // ignore: cast_nullable_to_non_nullable
as KeyType?,certInfo: freezed == certInfo ? _self.certInfo : certInfo // ignore: cast_nullable_to_non_nullable
as CertInfo?,publicKeyMatch: freezed == publicKeyMatch ? _self.publicKeyMatch : publicKeyMatch // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

/// Create a copy of PivExamineResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CertInfoCopyWith<$Res>? get certInfo {
    if (_self.certInfo == null) {
    return null;
  }

  return $CertInfoCopyWith<$Res>(_self.certInfo!, (value) {
    return _then(_self.copyWith(certInfo: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class PivExamineResultInvalidPassword implements PivExamineResult {
   PivExamineResultInvalidPassword({final  String? $type}): $type = $type ?? 'invalidPassword';
  factory PivExamineResultInvalidPassword.fromJson(Map<String, dynamic> json) => _$PivExamineResultInvalidPasswordFromJson(json);



@JsonKey(name: 'runtimeType')
final String $type;



@override
Map<String, dynamic> toJson() {
  return _$PivExamineResultInvalidPasswordToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PivExamineResultInvalidPassword);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PivExamineResult.invalidPassword()';
}


}




/// @nodoc
mixin _$PivGenerateParameters {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PivGenerateParameters);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PivGenerateParameters()';
}


}

/// @nodoc
class $PivGenerateParametersCopyWith<$Res>  {
$PivGenerateParametersCopyWith(PivGenerateParameters _, $Res Function(PivGenerateParameters) __);
}


/// @nodoc


class PivGeneratePublicKeyParameters implements PivGenerateParameters {
   PivGeneratePublicKeyParameters();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PivGeneratePublicKeyParameters);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PivGenerateParameters.publicKey()';
}


}




/// @nodoc


class PivGenerateCertificateParameters implements PivGenerateParameters {
   PivGenerateCertificateParameters({required this.subject, required this.validFrom, required this.validTo});
  

 final  String subject;
 final  DateTime validFrom;
 final  DateTime validTo;

/// Create a copy of PivGenerateParameters
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PivGenerateCertificateParametersCopyWith<PivGenerateCertificateParameters> get copyWith => _$PivGenerateCertificateParametersCopyWithImpl<PivGenerateCertificateParameters>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PivGenerateCertificateParameters&&(identical(other.subject, subject) || other.subject == subject)&&(identical(other.validFrom, validFrom) || other.validFrom == validFrom)&&(identical(other.validTo, validTo) || other.validTo == validTo));
}


@override
int get hashCode => Object.hash(runtimeType,subject,validFrom,validTo);

@override
String toString() {
  return 'PivGenerateParameters.certificate(subject: $subject, validFrom: $validFrom, validTo: $validTo)';
}


}

/// @nodoc
abstract mixin class $PivGenerateCertificateParametersCopyWith<$Res> implements $PivGenerateParametersCopyWith<$Res> {
  factory $PivGenerateCertificateParametersCopyWith(PivGenerateCertificateParameters value, $Res Function(PivGenerateCertificateParameters) _then) = _$PivGenerateCertificateParametersCopyWithImpl;
@useResult
$Res call({
 String subject, DateTime validFrom, DateTime validTo
});




}
/// @nodoc
class _$PivGenerateCertificateParametersCopyWithImpl<$Res>
    implements $PivGenerateCertificateParametersCopyWith<$Res> {
  _$PivGenerateCertificateParametersCopyWithImpl(this._self, this._then);

  final PivGenerateCertificateParameters _self;
  final $Res Function(PivGenerateCertificateParameters) _then;

/// Create a copy of PivGenerateParameters
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? subject = null,Object? validFrom = null,Object? validTo = null,}) {
  return _then(PivGenerateCertificateParameters(
subject: null == subject ? _self.subject : subject // ignore: cast_nullable_to_non_nullable
as String,validFrom: null == validFrom ? _self.validFrom : validFrom // ignore: cast_nullable_to_non_nullable
as DateTime,validTo: null == validTo ? _self.validTo : validTo // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

/// @nodoc


class PivGenerateCsrParameters implements PivGenerateParameters {
   PivGenerateCsrParameters({required this.subject});
  

 final  String subject;

/// Create a copy of PivGenerateParameters
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PivGenerateCsrParametersCopyWith<PivGenerateCsrParameters> get copyWith => _$PivGenerateCsrParametersCopyWithImpl<PivGenerateCsrParameters>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PivGenerateCsrParameters&&(identical(other.subject, subject) || other.subject == subject));
}


@override
int get hashCode => Object.hash(runtimeType,subject);

@override
String toString() {
  return 'PivGenerateParameters.csr(subject: $subject)';
}


}

/// @nodoc
abstract mixin class $PivGenerateCsrParametersCopyWith<$Res> implements $PivGenerateParametersCopyWith<$Res> {
  factory $PivGenerateCsrParametersCopyWith(PivGenerateCsrParameters value, $Res Function(PivGenerateCsrParameters) _then) = _$PivGenerateCsrParametersCopyWithImpl;
@useResult
$Res call({
 String subject
});




}
/// @nodoc
class _$PivGenerateCsrParametersCopyWithImpl<$Res>
    implements $PivGenerateCsrParametersCopyWith<$Res> {
  _$PivGenerateCsrParametersCopyWithImpl(this._self, this._then);

  final PivGenerateCsrParameters _self;
  final $Res Function(PivGenerateCsrParameters) _then;

/// Create a copy of PivGenerateParameters
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? subject = null,}) {
  return _then(PivGenerateCsrParameters(
subject: null == subject ? _self.subject : subject // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$PivGenerateResult {

 GenerateType get generateType; String get publicKey; String? get result;
/// Create a copy of PivGenerateResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PivGenerateResultCopyWith<PivGenerateResult> get copyWith => _$PivGenerateResultCopyWithImpl<PivGenerateResult>(this as PivGenerateResult, _$identity);

  /// Serializes this PivGenerateResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PivGenerateResult&&(identical(other.generateType, generateType) || other.generateType == generateType)&&(identical(other.publicKey, publicKey) || other.publicKey == publicKey)&&(identical(other.result, result) || other.result == result));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,generateType,publicKey,result);

@override
String toString() {
  return 'PivGenerateResult(generateType: $generateType, publicKey: $publicKey, result: $result)';
}


}

/// @nodoc
abstract mixin class $PivGenerateResultCopyWith<$Res>  {
  factory $PivGenerateResultCopyWith(PivGenerateResult value, $Res Function(PivGenerateResult) _then) = _$PivGenerateResultCopyWithImpl;
@useResult
$Res call({
 GenerateType generateType, String publicKey, String? result
});




}
/// @nodoc
class _$PivGenerateResultCopyWithImpl<$Res>
    implements $PivGenerateResultCopyWith<$Res> {
  _$PivGenerateResultCopyWithImpl(this._self, this._then);

  final PivGenerateResult _self;
  final $Res Function(PivGenerateResult) _then;

/// Create a copy of PivGenerateResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? generateType = null,Object? publicKey = null,Object? result = freezed,}) {
  return _then(_self.copyWith(
generateType: null == generateType ? _self.generateType : generateType // ignore: cast_nullable_to_non_nullable
as GenerateType,publicKey: null == publicKey ? _self.publicKey : publicKey // ignore: cast_nullable_to_non_nullable
as String,result: freezed == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _PivGenerateResult implements PivGenerateResult {
   _PivGenerateResult({required this.generateType, required this.publicKey, this.result});
  factory _PivGenerateResult.fromJson(Map<String, dynamic> json) => _$PivGenerateResultFromJson(json);

@override final  GenerateType generateType;
@override final  String publicKey;
@override final  String? result;

/// Create a copy of PivGenerateResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PivGenerateResultCopyWith<_PivGenerateResult> get copyWith => __$PivGenerateResultCopyWithImpl<_PivGenerateResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PivGenerateResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PivGenerateResult&&(identical(other.generateType, generateType) || other.generateType == generateType)&&(identical(other.publicKey, publicKey) || other.publicKey == publicKey)&&(identical(other.result, result) || other.result == result));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,generateType,publicKey,result);

@override
String toString() {
  return 'PivGenerateResult(generateType: $generateType, publicKey: $publicKey, result: $result)';
}


}

/// @nodoc
abstract mixin class _$PivGenerateResultCopyWith<$Res> implements $PivGenerateResultCopyWith<$Res> {
  factory _$PivGenerateResultCopyWith(_PivGenerateResult value, $Res Function(_PivGenerateResult) _then) = __$PivGenerateResultCopyWithImpl;
@override @useResult
$Res call({
 GenerateType generateType, String publicKey, String? result
});




}
/// @nodoc
class __$PivGenerateResultCopyWithImpl<$Res>
    implements _$PivGenerateResultCopyWith<$Res> {
  __$PivGenerateResultCopyWithImpl(this._self, this._then);

  final _PivGenerateResult _self;
  final $Res Function(_PivGenerateResult) _then;

/// Create a copy of PivGenerateResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? generateType = null,Object? publicKey = null,Object? result = freezed,}) {
  return _then(_PivGenerateResult(
generateType: null == generateType ? _self.generateType : generateType // ignore: cast_nullable_to_non_nullable
as GenerateType,publicKey: null == publicKey ? _self.publicKey : publicKey // ignore: cast_nullable_to_non_nullable
as String,result: freezed == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$PivImportResult {

 SlotMetadata? get metadata; String? get publicKey; String? get certificate;
/// Create a copy of PivImportResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PivImportResultCopyWith<PivImportResult> get copyWith => _$PivImportResultCopyWithImpl<PivImportResult>(this as PivImportResult, _$identity);

  /// Serializes this PivImportResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PivImportResult&&(identical(other.metadata, metadata) || other.metadata == metadata)&&(identical(other.publicKey, publicKey) || other.publicKey == publicKey)&&(identical(other.certificate, certificate) || other.certificate == certificate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,metadata,publicKey,certificate);

@override
String toString() {
  return 'PivImportResult(metadata: $metadata, publicKey: $publicKey, certificate: $certificate)';
}


}

/// @nodoc
abstract mixin class $PivImportResultCopyWith<$Res>  {
  factory $PivImportResultCopyWith(PivImportResult value, $Res Function(PivImportResult) _then) = _$PivImportResultCopyWithImpl;
@useResult
$Res call({
 SlotMetadata? metadata, String? publicKey, String? certificate
});


$SlotMetadataCopyWith<$Res>? get metadata;

}
/// @nodoc
class _$PivImportResultCopyWithImpl<$Res>
    implements $PivImportResultCopyWith<$Res> {
  _$PivImportResultCopyWithImpl(this._self, this._then);

  final PivImportResult _self;
  final $Res Function(PivImportResult) _then;

/// Create a copy of PivImportResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? metadata = freezed,Object? publicKey = freezed,Object? certificate = freezed,}) {
  return _then(_self.copyWith(
metadata: freezed == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as SlotMetadata?,publicKey: freezed == publicKey ? _self.publicKey : publicKey // ignore: cast_nullable_to_non_nullable
as String?,certificate: freezed == certificate ? _self.certificate : certificate // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of PivImportResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SlotMetadataCopyWith<$Res>? get metadata {
    if (_self.metadata == null) {
    return null;
  }

  return $SlotMetadataCopyWith<$Res>(_self.metadata!, (value) {
    return _then(_self.copyWith(metadata: value));
  });
}
}


/// @nodoc
@JsonSerializable()

class _PivImportResult implements PivImportResult {
   _PivImportResult({required this.metadata, required this.publicKey, required this.certificate});
  factory _PivImportResult.fromJson(Map<String, dynamic> json) => _$PivImportResultFromJson(json);

@override final  SlotMetadata? metadata;
@override final  String? publicKey;
@override final  String? certificate;

/// Create a copy of PivImportResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PivImportResultCopyWith<_PivImportResult> get copyWith => __$PivImportResultCopyWithImpl<_PivImportResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PivImportResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PivImportResult&&(identical(other.metadata, metadata) || other.metadata == metadata)&&(identical(other.publicKey, publicKey) || other.publicKey == publicKey)&&(identical(other.certificate, certificate) || other.certificate == certificate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,metadata,publicKey,certificate);

@override
String toString() {
  return 'PivImportResult(metadata: $metadata, publicKey: $publicKey, certificate: $certificate)';
}


}

/// @nodoc
abstract mixin class _$PivImportResultCopyWith<$Res> implements $PivImportResultCopyWith<$Res> {
  factory _$PivImportResultCopyWith(_PivImportResult value, $Res Function(_PivImportResult) _then) = __$PivImportResultCopyWithImpl;
@override @useResult
$Res call({
 SlotMetadata? metadata, String? publicKey, String? certificate
});


@override $SlotMetadataCopyWith<$Res>? get metadata;

}
/// @nodoc
class __$PivImportResultCopyWithImpl<$Res>
    implements _$PivImportResultCopyWith<$Res> {
  __$PivImportResultCopyWithImpl(this._self, this._then);

  final _PivImportResult _self;
  final $Res Function(_PivImportResult) _then;

/// Create a copy of PivImportResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? metadata = freezed,Object? publicKey = freezed,Object? certificate = freezed,}) {
  return _then(_PivImportResult(
metadata: freezed == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as SlotMetadata?,publicKey: freezed == publicKey ? _self.publicKey : publicKey // ignore: cast_nullable_to_non_nullable
as String?,certificate: freezed == certificate ? _self.certificate : certificate // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of PivImportResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SlotMetadataCopyWith<$Res>? get metadata {
    if (_self.metadata == null) {
    return null;
  }

  return $SlotMetadataCopyWith<$Res>(_self.metadata!, (value) {
    return _then(_self.copyWith(metadata: value));
  });
}
}

// dart format on
