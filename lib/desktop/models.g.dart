// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Success _$SuccessFromJson(Map<String, dynamic> json) => Success(
  json['body'] as Map<String, dynamic>,
  (json['flags'] as List<dynamic>).map((e) => e as String).toList(),
  $type: json['kind'] as String?,
);

Map<String, dynamic> _$SuccessToJson(Success instance) => <String, dynamic>{
  'body': instance.body,
  'flags': instance.flags,
  'kind': instance.$type,
};

Signal _$SignalFromJson(Map<String, dynamic> json) => Signal(
  json['status'] as String,
  json['body'] as Map<String, dynamic>,
  $type: json['kind'] as String?,
);

Map<String, dynamic> _$SignalToJson(Signal instance) => <String, dynamic>{
  'status': instance.status,
  'body': instance.body,
  'kind': instance.$type,
};

RpcError _$RpcErrorFromJson(Map<String, dynamic> json) => RpcError(
  json['status'] as String,
  json['message'] as String,
  json['body'] as Map<String, dynamic>,
  $type: json['kind'] as String?,
);

Map<String, dynamic> _$RpcErrorToJson(RpcError instance) => <String, dynamic>{
  'status': instance.status,
  'message': instance.message,
  'body': instance.body,
  'kind': instance.$type,
};

_RpcState _$RpcStateFromJson(Map<String, dynamic> json) =>
    _RpcState(json['version'] as String, json['is_admin'] as bool);

Map<String, dynamic> _$RpcStateToJson(_RpcState instance) => <String, dynamic>{
  'version': instance.version,
  'is_admin': instance.isAdmin,
};
