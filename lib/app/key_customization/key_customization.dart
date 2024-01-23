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

import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../logging.dart';
import 'models.dart';

final _log = Logger('key_customization_manager');
const _prefKeyCustomizations = 'KEY_CUSTOMIZATIONS';

class KeyCustomizationManager {
  final SharedPreferences _prefs;
  final Map<String, dynamic> _customizations;

  KeyCustomizationManager(this._prefs)
      : _customizations =
            readCustomizations(_prefs.getString(_prefKeyCustomizations));

  static Map<String, dynamic> readCustomizations(String? pref) {
    if (pref == null) {
      return {};
    }

    try {
      return json.decode(utf8.decode(pref.codeUnits));
    } catch (e) {
      return {};
    }
  }

  KeyCustomization? get(String? serial) {
    _log.debug('Getting key customization for $serial');

    if (serial == null || serial.isEmpty) {
      return null;
    }

    if (_customizations.containsKey(serial)) {
      return KeyCustomization(serial, _customizations[serial]);
    }

    return null;
  }

  void set({required String serial, String? customName, Color? customColor}) {
    final properties = <String, String?>{
      'display_color': customColor?.value.toRadixString(16),
      'display_name': customName?.isNotEmpty == true ? customName : null
    };
    _log.debug('Setting key customization for $serial: $properties');
    _customizations[serial] = properties;
  }

  Future<void> write() async {
    await _prefs.setString(_prefKeyCustomizations,
        String.fromCharCodes(utf8.encode(json.encode(_customizations))));
  }
}
