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
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:yubico_authenticator/app/logging.dart';

import 'icon_cache.dart';
import 'icon_pack.dart';

final _log = Logger('icon_pack_manager');

class IconPackManager extends StateNotifier<AsyncValue<IconPack?>> {
  final IconCache _iconCache;

  String? _lastError;
  final _packSubDir = 'issuer_icons';

  IconPackManager(this._iconCache) : super(const AsyncValue.data(null)) {
    readPack();
  }

  String? get lastError => _lastError;

  void readPack() async {
    final packDirectory = await _packDirectory;
    final packFile = File(join(packDirectory.path, 'pack.json'));

    _log.debug('Looking for file: ${packFile.path}');

    if (!await packFile.exists()) {
      _log.debug('Failed to find icons pack ${packFile.path}');
      state = AsyncValue.error(
          'Failed to find icons pack ${packFile.path}', StackTrace.current);
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

    state = AsyncValue.data(IconPack(
        uuid: pack['uuid'],
        name: pack['name'],
        version: pack['version'],
        directory: packDirectory,
        icons: icons));

    _log.debug(
        'Parsed ${state.value?.name} with ${state.value?.icons.length} icons');
  }

  Future<bool> importPack(AppLocalizations l10n, String filePath) async {
    // remove existing pack first
    await removePack();

    final packFile = File(filePath);

    state = const AsyncValue.loading();

    if (!await packFile.exists()) {
      _log.error('Input file does not exist');
      _lastError = l10n.oath_custom_icons_err_file_not_found;
      state = AsyncValue.error('Input file does not exist', StackTrace.current);
      return false;
    }

    if (await packFile.length() > 5 * 1024 * 1024) {
      _log.error('File size too big.');
      _lastError = l10n.oath_custom_icons_err_file_too_big;
      state = AsyncValue.error('File size too big', StackTrace.current);
      return false;
    }

    // copy input file to temporary folder
    final tempDirectory = await Directory.systemTemp.createTemp('yubioath');
    final tempCopy =
        await packFile.copy(join(tempDirectory.path, basename(packFile.path)));
    final bytes = await File(tempCopy.path).readAsBytes();

    final unpackDirectory = Directory(join(tempDirectory.path, 'unpack'));

    final archive = ZipDecoder().decodeBytes(bytes, verify: true);
    for (final file in archive) {
      final filename = file.name;
      if (file.size > 0) {
        final data = file.content as List<int>;
        final extractedFile = File(join(unpackDirectory.path, filename));
        _log.debug('Writing file: ${extractedFile.path} (size: ${file.size})');
        final createdFile = await extractedFile.create(recursive: true);
        await createdFile.writeAsBytes(data);
      } else {
        final extractedDirectory =
            Directory(join(unpackDirectory.path, filename));
        _log.debug('Writing directory: ${extractedDirectory.path} '
            '(size: ${file.size})');
        extractedDirectory.createSync(recursive: true);
      }
    }

    // check that there is pack.json
    final packJsonFile = File(join(unpackDirectory.path, 'pack.json'));
    if (!await packJsonFile.exists()) {
      _log.error('File is not an icon pack: missing pack.json');
      _lastError = l10n.oath_custom_icons_err_invalid_icon_pack;
      state = AsyncValue.error('File is not an icon pack', StackTrace.current);
      await _deleteDirectory(tempDirectory);
      return false;
    }

    // remove old icons pack and icon pack cache
    final packDirectory = await _packDirectory;
    if (!await _deleteDirectory(packDirectory)) {
      _log.error('Failure when deleting original pack directory');
      _lastError = l10n.oath_custom_icons_err_filesystem_error;
      state = AsyncValue.error(
          'Failure deleting original pack directory', StackTrace.current);
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
    state = const AsyncValue.data(null);
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
    return Directory(join(supportDirectory.path, _packSubDir));
  }
}

final iconPackProvider =
    StateNotifierProvider<IconPackManager, AsyncValue<IconPack?>>(
        (ref) => IconPackManager(ref.watch(iconCacheProvider)));
