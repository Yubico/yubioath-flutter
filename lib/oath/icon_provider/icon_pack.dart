/*
 * Copyright (C) 2023 Yubico.
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

import 'dart:io';

class IconPackIcon {
  final String filename;
  final String? category;
  final List<String> issuer;

  const IconPackIcon({
    required this.filename,
    required this.category,
    required this.issuer,
  });
}

class IconPack {
  final String uuid;
  final String name;
  final int version;
  final Directory directory;
  final List<IconPackIcon> icons;

  const IconPack({
    required this.uuid,
    required this.name,
    required this.version,
    required this.directory,
    required this.icons,
  });

  File? getFileForIssuer(String? issuer) {
    if (issuer == null) {
      return null;
    }

    final matching = icons.where((element) =>
        element.issuer.any((element) => element == issuer.toUpperCase()));

    final issuerImageFile = matching.isNotEmpty
        ? File('${directory.path}${matching.first.filename}')
        : null;

    if (issuerImageFile != null && !issuerImageFile.existsSync()) {
      return null;
    }

    return issuerImageFile;
  }
}
