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
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import 'logging.dart';
import 'models.dart';

final _log = Logger('key_customization');

final keyCustomizationManagerProvider =
    Provider<KeyCustomizationManager>((ref) {
  final retval = KeyCustomizationManager();
  retval.read();
  return retval;
});

class KeyCustomizationManager {
  var _customizations = <String, dynamic>{};

  void read() async {
    final customizationFile = await _customizationFile;
    // get content
    if (!await customizationFile.exists()) {
      return;
    }

    try {
      var customizationContent = await customizationFile.readAsString();
      final jsonString =
          String.fromCharCodes(base64Decode(customizationContent));
      _customizations = json.decode(utf8.decode(jsonString.codeUnits));
    } catch (e) {
      return;
    }
  }

  KeyCustomization? get(String? serialNumber) {
    _log.debug('Getting customization for: $serialNumber');

    if (serialNumber == null || serialNumber.isEmpty) {
      return null;
    }

    final sha = getSerialSha(serialNumber);

    if (_customizations.containsKey(sha)) {
      return KeyCustomization(serialNumber, _customizations[sha]);
    }

    return null;
  }

  void set(KeyCustomization customization) {
    _log.debug(
        'Added: ${customization.serialNumber}: ${customization.properties}');
    final sha = getSerialSha(customization.serialNumber);
    _customizations[sha] = customization.properties;
  }

  Future<void> write() async {
    final customizationFile = await _customizationFile;

    try {
      await customizationFile.writeAsString(
          base64UrlEncode(utf8.encode(json.encode(_customizations))),
          flush: true);
    } catch (e) {
      _log.error('Error writing customization file: $e');
      return;
    }
  }

  final _dataSubDir = 'customizations';

  Future<Directory> get _dataDir async {
    final supportDirectory = await getApplicationSupportDirectory();
    return Directory(join(supportDirectory.path, _dataSubDir));
  }

  Future<File> get _customizationFile async {
    final dataDir = await _dataDir;
    if (!await dataDir.exists()) {
      await dataDir.create();
    }
    return File(join(dataDir.path, 'key_customizations.dat'));
  }

  String getSerialSha(String serialNumber) =>
      sha256.convert(utf8.encode(serialNumber)).toString();
}
