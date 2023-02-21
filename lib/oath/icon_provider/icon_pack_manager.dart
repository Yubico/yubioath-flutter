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

final _log = Logger('icon_pack_provider');

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

  IconPackManager(this._iconCache);

  String? iconPackName() =>
      _pack != null ? '${_pack!.name} (${_pack!.version})' : null;

  /// removes imported icon pack
  Future<bool> removePack(String relativePackPath) async {
    _iconCache.memCache.clear();
    await _iconCache.fsCache.clear();
    final cleanupStatus =
        await _deleteDirectory(await _getPackDirectory(relativePackPath));
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

  Future<Directory> _getPackDirectory(String relativePackPath) async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    return Directory(
        '${documentsDirectory.path}${Platform.pathSeparator}$relativePackPath${Platform.pathSeparator}');
  }

  void readPack(String relativePackPath) async {
    final packDirectory = await _getPackDirectory(relativePackPath);
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
            issuer: List<String>.from(icon['issuer']))));

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
      return false;
    }

    // copy input file to temporary folder
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final tempDirectory = Directory(
        '${documentsDirectory.path}${Platform.pathSeparator}temp${Platform.pathSeparator}');

    if (!await _deleteDirectory(tempDirectory)) {
      _log.error('Failed to cleanup temp directory');
      return false;
    }

    await tempDirectory.create(recursive: true);
    final tempCopy =
        await packFile.copy('${tempDirectory.path}${basename(packFile.path)}');
    final bytes = await File(tempCopy.path).readAsBytes();

    final destination =
        Directory('${tempDirectory.path}ex${Platform.pathSeparator}');

    final archive = ZipDecoder().decodeBytes(bytes);
    for (final file in archive) {
      final filename = file.name;
      if (file.isFile) {
        final data = file.content as List<int>;
        _log.debug('Writing file: ${destination.path}$filename');
        final extractedFile = File('${destination.path}$filename');
        final createdFile = await extractedFile.create(recursive: true);
        await createdFile.writeAsBytes(data);
      } else {
        _log.debug('Writing directory: ${destination.path}$filename');
        Directory('${destination.path}$filename').createSync(recursive: true);
      }
    }

    // check that there is pack.json
    final packJsonFile = File('${destination.path}pack.json');
    if (!await packJsonFile.exists()) {
      _log.error('File is not a icon pack.');
      //await _cleanTempDirectory(tempDirectory);
      return false;
    }

    // remove old icons pack and icon pack cache
    final packDirectory = Directory(
        '${documentsDirectory.path}${Platform.pathSeparator}issuer_icons${Platform.pathSeparator}');
    if (!await _deleteDirectory(packDirectory)) {
      _log.error('Could not remove old pack directory');
      await _deleteDirectory(tempDirectory);
      return false;
    }

    await _iconCache.fsCache.clear();
    _iconCache.memCache.clear();

    await destination.rename(packDirectory.path);
    readPack('issuer_icons');

    await _deleteDirectory(tempDirectory);
    return true;
  }

  IconPack? getIconPack() => _pack;
}

final iconPackManager = ChangeNotifierProvider<IconPackManager>((ref) {
  final manager = IconPackManager(ref.watch(iconCacheProvider));
  manager.readPack('issuer_icons');
  return manager;
});