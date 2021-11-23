// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$Success _$$SuccessFromJson(Map<String, dynamic> json) => _$Success(
      json['body'] as Map<String, dynamic>,
      $type: json['kind'] as String?,
    );

Map<String, dynamic> _$$SuccessToJson(_$Success instance) => <String, dynamic>{
      'body': instance.body,
      'kind': instance.$type,
    };

_$Signal _$$SignalFromJson(Map<String, dynamic> json) => _$Signal(
      json['status'] as String,
      json['body'] as Map<String, dynamic>,
      $type: json['kind'] as String?,
    );

Map<String, dynamic> _$$SignalToJson(_$Signal instance) => <String, dynamic>{
      'status': instance.status,
      'body': instance.body,
      'kind': instance.$type,
    };

_$RpcError _$$RpcErrorFromJson(Map<String, dynamic> json) => _$RpcError(
      json['status'] as String,
      json['message'] as String,
      json['body'] as Map<String, dynamic>,
      $type: json['kind'] as String?,
    );

Map<String, dynamic> _$$RpcErrorToJson(_$RpcError instance) =>
    <String, dynamic>{
      'status': instance.status,
      'message': instance.message,
      'body': instance.body,
      'kind': instance.$type,
    };
