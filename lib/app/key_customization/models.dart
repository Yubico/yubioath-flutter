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

import 'dart:convert';
import 'dart:ui';

class KeyCustomization {
  final String serialNumber;
  final Map<String, dynamic> _properties;

  const KeyCustomization(this.serialNumber, this._properties);

  String? getName() => _properties['display_name'] as String?;

  Color? getColor() {
    var customColor = _properties['display_color'] as String?;
    if (customColor == null) {
      return null;
    }

    var intValue = int.tryParse(customColor, radix: 16);

    if (intValue == null) {
      return null;
    }
    return Color(intValue);
  }

  factory KeyCustomization.fromString(String serialNumber, String encodedJson) {
    final data = json.decode(String.fromCharCodes(base64Decode(encodedJson)));
    return KeyCustomization(serialNumber, data);
  }
}
