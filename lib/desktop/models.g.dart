/*
 * Copyright (C) 2022 Yubico.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *       http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

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

_$_RpcState _$$_RpcStateFromJson(Map<String, dynamic> json) => _$_RpcState(
      json['version'] as String,
      json['is_admin'] as bool,
    );

Map<String, dynamic> _$$_RpcStateToJson(_$_RpcState instance) =>
    <String, dynamic>{
      'version': instance.version,
      'is_admin': instance.isAdmin,
    };
