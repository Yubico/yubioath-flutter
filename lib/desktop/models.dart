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

import 'package:freezed_annotation/freezed_annotation.dart';

part 'models.freezed.dart';
part 'models.g.dart';

@Freezed(unionKey: 'kind')
class RpcResponse with _$RpcResponse {
  factory RpcResponse.success(Map<String, dynamic> body) = Success;
  factory RpcResponse.signal(String status, Map<String, dynamic> body) = Signal;
  factory RpcResponse.error(
      String status, String message, Map<String, dynamic> body) = RpcError;

  factory RpcResponse.fromJson(Map<String, dynamic> json) =>
      _$RpcResponseFromJson(json);
}

@freezed
class RpcState with _$RpcState {
  const factory RpcState(String version, bool isAdmin) = _RpcState;

  factory RpcState.fromJson(Map<String, dynamic> json) =>
      _$RpcStateFromJson(json);
}
