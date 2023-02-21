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

import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:yubico_authenticator/app/logging.dart';

import 'icon_cache.dart';

final _log = Logger('icon_pack_manager');

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
}

class IconPackManager extends ChangeNotifier {
  final IconCache _iconCache;

  IconPack? _pack;
  String? _lastError;
  final _packSubDir = 'issuer_icons';

  IconPackManager(this._iconCache);

  bool get hasIconPack => _pack != null;

  String? get iconPackName => _pack?.name;

  int? get iconPackVersion => _pack?.version;

  String? get lastError => _lastError;

  File? getFileForIssuer(String? issuer) {
    if (_pack == null || issuer == null) {
      return null;
    }

    final pack = _pack!;
    final matching = pack.icons.where((element) =>
        element.issuer.any((element) => element == issuer.toUpperCase()));

    final issuerImageFile = matching.isNotEmpty
        ? File('${pack.directory.path}${matching.first.filename}')
        : null;

    if (issuerImageFile != null && !issuerImageFile.existsSync()) {
      return null;
    }

    return issuerImageFile;
  }

  void readPack() async {
    final packDirectory = await _packDirectory;
    final packFile = File('${packDirectory.path}pack.json');

    _log.debug('Looking for file: ${packFile.path}');

    if (!await packFile.exists()) {
      _log.debug('Failed to find icons pack ${packFile.path}');
      _pack = null;
      return;
    }

    var packContent = await packFile.readAsString();
    Map<String, dynamic> pack = const JsonDecoder().convert(packContent);

    final icons = List<IconPackIcon>.from(pack['icons'].map((icon) =>
        IconPackIcon(
            filename: icon['filename'],
            category: icon['category'],
            issuer: List<String>.from(icon['issuer'])
                .map((e) => e.toUpperCase())
                .toList(growable: false))));

    _pack = IconPack(
        uuid: pack['uuid'],
        name: pack['name'],
        version: pack['version'],
        directory: packDirectory,
        icons: icons);

    _log.debug('Parsed ${_pack!.name} with ${_pack!.icons.length} icons');

    notifyListeners();
  }

  Future<bool> importPack(String filePath) async {
    final packFile = File(filePath);
    if (!await packFile.exists()) {
      _log.error('Input file does not exist');
      _lastError = 'File not found';
      return false;
    }

    if (await packFile.length() > 3 * 1024 * 1024) {
      _log.error('File exceeds size. Max 3MB.');
      _lastError = 'File exceeds size. Max 3MB.';
      return false;
    }

    // copy input file to temporary folder
    final tempDirectory = await Directory.systemTemp.createTemp('yubioath');
    final tempCopy = await packFile.copy('${tempDirectory.path}'
        '${Platform.pathSeparator}'
        '${basename(packFile.path)}');
    final bytes = await File(tempCopy.path).readAsBytes();

    final unpackDirectory =
        Directory('${tempDirectory.path}${Platform.pathSeparator}'
            'unpack${Platform.pathSeparator}');

    final archive = ZipDecoder().decodeBytes(bytes, verify: true);
    for (final file in archive) {
      final filename = file.name;
      if (file.size > 0) {
        final data = file.content as List<int>;
        _log.debug(
            'Writing file: ${unpackDirectory.path}$filename (size: ${file.size})');
        final extractedFile = File('${unpackDirectory.path}$filename');
        final createdFile = await extractedFile.create(recursive: true);
        await createdFile.writeAsBytes(data);
      } else {
        _log.debug(
            'Writing directory: ${unpackDirectory.path}$filename (size: ${file.size})');
        Directory('${unpackDirectory.path}$filename')
            .createSync(recursive: true);
      }
    }

    // check that there is pack.json
    final packJsonFile = File('${unpackDirectory.path}pack.json');
    if (!await packJsonFile.exists()) {
      _log.error('File is not a icon pack: missing pack.json');
      _lastError = 'pack.json missing';
      await _deleteDirectory(tempDirectory);
      return false;
    }

    // remove old icons pack and icon pack cache
    final packDirectory = await _packDirectory;
    if (!await _deleteDirectory(packDirectory)) {
      _log.error('FS operation failed(2)');
      _lastError = 'FS failure(2)';
      await _deleteDirectory(tempDirectory);
      return false;
    }

    await _iconCache.fsCache.clear();
    _iconCache.memCache.clear();

    // moves unpacked files to the directory final directory
    await unpackDirectory.rename(packDirectory.path);

    readPack();

    await _deleteDirectory(tempDirectory);
    return true;
  }

  /// removes imported icon pack
  Future<bool> removePack() async {
    _iconCache.memCache.clear();
    await _iconCache.fsCache.clear();
    final cleanupStatus = await _deleteDirectory(await _packDirectory);
    _pack = null;
    notifyListeners();
    return cleanupStatus;
  }

  Future<bool> _deleteDirectory(Directory directory) async {
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }

    if (await directory.exists()) {
      _log.error('Failed to delete directory');
      return false;
    }

    return true;
  }

  Future<Directory> get _packDirectory async {
    final supportDirectory = await getApplicationSupportDirectory();
    return Directory(
        '${supportDirectory.path}${Platform.pathSeparator}$_packSubDir${Platform.pathSeparator}');
  }
}

final iconPackManager = ChangeNotifierProvider<IconPackManager>((ref) {
  final manager = IconPackManager(ref.watch(iconCacheProvider));
  manager.readPack();
  return manager;
});
