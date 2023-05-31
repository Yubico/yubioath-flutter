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

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:yubico_authenticator/app/logging.dart';

final _log = Logger('icon_cache');

class IconCacheFs {
  Future<ByteData?> read(String fileName) async {
    final file = await _getFile(fileName);
    final exists = await file.exists();
    if (exists) {
      _log.traffic('File $fileName exists in cache');
    } else {
      _log.traffic('File $fileName does not exist in cache');
    }
    return exists ? (await file.readAsBytes()).buffer.asByteData() : null;
  }

  Future<void> write(String fileName, Uint8List data) async {
    _log.traffic('Writing $fileName to cache');
    final file = await _getFile(fileName);
    if (!await file.exists()) {
      await file.create(recursive: true, exclusive: false);
    }
    await file.writeAsBytes(data, flush: true);
  }

  Future<void> clear() async {
    final cacheDirectory = await _cacheDirectory;
    if (await cacheDirectory.exists()) {
      try {
        await cacheDirectory.delete(recursive: true);
      } catch (e) {
        _log.traffic(
            'Failed to delete cache directory ${cacheDirectory.path}', e);
      }
    }
  }

  String _buildCacheDirectoryPath(String supportDirectory) =>
      join(supportDirectory, 'issuer_icons_cache');

  Future<Directory> get _cacheDirectory async {
    final supportDirectory = await getApplicationSupportDirectory();
    return Directory(_buildCacheDirectoryPath(supportDirectory.path));
  }

  Future<File> _getFile(String fileName) async {
    final supportDirectory = await getApplicationSupportDirectory();
    final cacheDirectoryPath = _buildCacheDirectoryPath(supportDirectory.path);
    return File(
        join(cacheDirectoryPath, '${basenameWithoutExtension(fileName)}.dat'));
  }
}

class IconCacheMem {
  final _cache = <String, ByteData>{};

  ByteData? read(String fileName) {
    return _cache[fileName];
  }

  void write(String fileName, Uint8List data) {
    _cache.putIfAbsent(fileName, () => data.buffer.asByteData());
  }

  void clear() async {
    _cache.clear();
  }
}

class IconCache {
  final IconCacheMem memCache;
  final IconCacheFs fsCache;

  const IconCache(this.memCache, this.fsCache);
}

final iconCacheProvider =
    Provider<IconCache>((ref) => IconCache(IconCacheMem(), IconCacheFs()));
