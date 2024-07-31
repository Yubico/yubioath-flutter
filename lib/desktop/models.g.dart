// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SuccessImpl _$$SuccessImplFromJson(Map<String, dynamic> json) =>
    _$SuccessImpl(
      json['body'] as Map<String, dynamic>,
      $type: json['kind'] as String?,
    );

Map<String, dynamic> _$$SuccessImplToJson(_$SuccessImpl instance) =>
    <String, dynamic>{
      'body': instance.body,
      'kind': instance.$type,
    };

_$SignalImpl _$$SignalImplFromJson(Map<String, dynamic> json) => _$SignalImpl(
      json['status'] as String,
      json['body'] as Map<String, dynamic>,
      $type: json['kind'] as String?,
    );

Map<String, dynamic> _$$SignalImplToJson(_$SignalImpl instance) =>
    <String, dynamic>{
      'status': instance.status,
      'body': instance.body,
      'kind': instance.$type,
    };

_$RpcErrorImpl _$$RpcErrorImplFromJson(Map<String, dynamic> json) =>
    _$RpcErrorImpl(
      json['status'] as String,
      json['message'] as String,
      json['body'] as Map<String, dynamic>,
      $type: json['kind'] as String?,
    );

Map<String, dynamic> _$$RpcErrorImplToJson(_$RpcErrorImpl instance) =>
    <String, dynamic>{
      'status': instance.status,
      'message': instance.message,
      'body': instance.body,
      'kind': instance.$type,
    };

_$RpcStateImpl _$$RpcStateImplFromJson(Map<String, dynamic> json) =>
    _$RpcStateImpl(
      json['version'] as String,
      json['is_admin'] as bool,
    );

Map<String, dynamic> _$$RpcStateImplToJson(_$RpcStateImpl instance) =>
    <String, dynamic>{
      'version': instance.version,
      'is_admin': instance.isAdmin,
    };
