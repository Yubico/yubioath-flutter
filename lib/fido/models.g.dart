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

_$_FidoState _$$_FidoStateFromJson(Map<String, dynamic> json) => _$_FidoState(
      info: json['info'] as Map<String, dynamic>,
      unlocked: json['unlocked'] as bool,
    );

Map<String, dynamic> _$$_FidoStateToJson(_$_FidoState instance) =>
    <String, dynamic>{
      'info': instance.info,
      'unlocked': instance.unlocked,
    };

_$_Fingerprint _$$_FingerprintFromJson(Map<String, dynamic> json) =>
    _$_Fingerprint(
      json['template_id'] as String,
      json['name'] as String?,
    );

Map<String, dynamic> _$$_FingerprintToJson(_$_Fingerprint instance) =>
    <String, dynamic>{
      'template_id': instance.templateId,
      'name': instance.name,
    };

_$_FidoCredential _$$_FidoCredentialFromJson(Map<String, dynamic> json) =>
    _$_FidoCredential(
      rpId: json['rp_id'] as String,
      credentialId: json['credential_id'] as String,
      userId: json['user_id'] as String,
      userName: json['user_name'] as String,
    );

Map<String, dynamic> _$$_FidoCredentialToJson(_$_FidoCredential instance) =>
    <String, dynamic>{
      'rp_id': instance.rpId,
      'credential_id': instance.credentialId,
      'user_id': instance.userId,
      'user_name': instance.userName,
    };
