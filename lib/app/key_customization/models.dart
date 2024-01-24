/*
 * Copyright (C) 2024 Yubico.
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

import 'dart:ui';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'models.freezed.dart';

part 'models.g.dart';

@freezed
class KeyCustomization with _$KeyCustomization {
  factory KeyCustomization({
    required int serial,
    @JsonKey(includeIfNull: false) String? name,
    @JsonKey(includeIfNull: false) @_ColorConverter() Color? color,
  }) = _KeyCustomization;

  factory KeyCustomization.fromJson(Map<String, dynamic> json) =>
      _$KeyCustomizationFromJson(json);
}

class _ColorConverter implements JsonConverter<Color?, int?> {
  const _ColorConverter();

  @override
  Color? fromJson(int? json) => json != null ? Color(json) : null;

  @override
  int? toJson(Color? object) => object?.value;
}
