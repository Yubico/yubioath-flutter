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
import 'package:io/io.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yubico_authenticator/app/logging.dart';

import 'icon_cache.dart';
import 'icon_pack.dart';

part 'icon_pack_manager.g.dart';

final _log = Logger('icon_pack_manager');

@riverpod
class LastIconPackError extends _$LastIconPackError {
  @override
  String? build() => null;

  void set(String? error) => state = error;
}

@riverpod
class IconPackManager extends _$IconPackManager {
  final _packSubDir = 'issuer_icons';

  @override
  FutureOr<IconPack?> build() async {
    readPack();
    return null;
  }

  void readPack() async {
    final packDirectory = await _packDirectory;
    final packFile =
        File(join(packDirectory.path, getLocalIconFileName('pack.json')));

    _log.debug('Looking for file: ${packFile.path}');

    if (!await packFile.exists()) {
      _log.debug('Failed to find icons pack ${packFile.path}');
      state = AsyncValue.error(
          'Failed to find icon pack ${packFile.path}', StackTrace.current);
      return;
    }

    try {
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
    } catch (e) {
      _log.debug('Failed to parse icons pack ${packFile.path}');
      state = AsyncValue.error(
          'Failed to parse icon pack ${packFile.path}', StackTrace.current);
      return;
    }
  }

  Future<bool> importPack(AppLocalizations l10n, String filePath) async {
    // remove existing pack first
    await removePack();

    final packFile = File(filePath);

    state = const AsyncValue.loading();

    if (!await packFile.exists()) {
      _log.error('Input file does not exist');
      ref.read(lastIconPackErrorProvider.notifier).set(l10n.l_file_not_found);
      state = AsyncValue.error('Input file does not exist', StackTrace.current);
      return false;
    }

    if (await packFile.length() > 5 * 1024 * 1024) {
      _log.error('File size too big.');
      ref.read(lastIconPackErrorProvider.notifier).set(l10n.l_file_too_big);
      state = AsyncValue.error('File size too big', StackTrace.current);
      return false;
    }

    // copy input file to temporary folder
    final tempDirectory = await Directory.systemTemp.createTemp('yubioath');
    final tempCopy =
        await packFile.copy(join(tempDirectory.path, basename(packFile.path)));
    final bytes = await File(tempCopy.path).readAsBytes();

    final unpackDirectory = Directory(join(tempDirectory.path, 'unpack'));

    Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes, verify: true);
    } on Exception catch (_) {
      _log.error('File is not an icon pack: zip decoding failed');
      ref
          .read(lastIconPackErrorProvider.notifier)
          .set(l10n.l_invalid_icon_pack);
      state = AsyncValue.error('File is not an icon pack', StackTrace.current);
      return false;
    }

    for (final file in archive) {
      final filename = file.name;
      if (file.size > 0) {
        final data = file.content as List<int>;
        final extractedFile =
            File(join(unpackDirectory.path, getLocalIconFileName(filename)));
        _log.debug('Writing file: ${extractedFile.path} (size: ${file.size})');
        final createdFile = await extractedFile.create(recursive: true);
        await createdFile.writeAsBytes(data);
      }
    }

    // check that there is pack.json
    final packJsonFile =
        File(join(unpackDirectory.path, getLocalIconFileName('pack.json')));
    if (!await packJsonFile.exists()) {
      _log.error('File is not an icon pack: missing pack.json');
      ref
          .read(lastIconPackErrorProvider.notifier)
          .set(l10n.l_invalid_icon_pack);
      state = AsyncValue.error('File is not an icon pack', StackTrace.current);
      await _deleteDirectory(tempDirectory);
      return false;
    }

    // test pack.json
    try {
      var packContent = await packJsonFile.readAsString();
      const JsonDecoder().convert(packContent);
    } catch (e) {
      _log.error('Failed to parse pack.json: $e');
      ref
          .read(lastIconPackErrorProvider.notifier)
          .set(l10n.l_invalid_icon_pack);
      state = AsyncValue.error('File is not an icon pack', StackTrace.current);
      await _deleteDirectory(tempDirectory);
      return false;
    }

    // remove old icon pack and icon pack cache
    final packDirectory = await _packDirectory;
    if (!await _deleteDirectory(packDirectory)) {
      _log.error('Failure when deleting original pack directory');
      ref.read(lastIconPackErrorProvider.notifier).set(l10n.l_filesystem_error);
      state = AsyncValue.error(
          'Failure deleting original pack directory', StackTrace.current);
      await _deleteDirectory(tempDirectory);
      return false;
    }

    final iconCache = ref.read(iconCacheProvider);
    await iconCache.fsCache.clear();
    iconCache.memCache.clear();

    // copy unpacked files from temporary directory to the icon pack directory
    try {
      await copyPath(unpackDirectory.path, packDirectory.path);
    } catch (e) {
      _log.error('Failed to copy icon pack files to destination: $e');
      ref
          .read(lastIconPackErrorProvider.notifier)
          .set(l10n.l_icon_pack_copy_failed);
      state = AsyncValue.error(
          'Failed to copy icon pack files.', StackTrace.current);
      return false;
    }

    readPack();

    await _deleteDirectory(tempDirectory);
    return true;
  }

  /// removes imported icon pack
  Future<bool> removePack() async {
    final iconCache = ref.watch(iconCacheProvider);
    iconCache.memCache.clear();
    await iconCache.fsCache.clear();
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
