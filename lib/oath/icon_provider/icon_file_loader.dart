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

import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart';
import 'package:vector_graphics/vector_graphics.dart';
import 'package:vector_graphics_compiler/vector_graphics_compiler.dart';
import 'package:yubico_authenticator/app/logging.dart';

import 'icon_cache.dart';

final _log = Logger('icon_file_loader');

class IconFileLoader extends BytesLoader {
  final WidgetRef _ref;
  final File _file;

  const IconFileLoader(this._ref, this._file);

  @override
  Future<ByteData> loadBytes(BuildContext? context) async {
    final cacheFileName = basename(_file.path);

    final memCache = _ref.read(iconCacheProvider).memCache;

    // check if the requested file exists in memory cache
    var cachedData = memCache.read(cacheFileName);
    if (cachedData != null) {
      _log.debug('Returning $cacheFileName image data from memory cache');
      return cachedData;
    }

    final fsCache = _ref.read(iconCacheProvider).fsCache;

    // check if the requested file exists in fs cache
    cachedData = await fsCache.read(cacheFileName);
    if (cachedData != null) {
      memCache.write(cacheFileName, cachedData.buffer.asUint8List());
      _log.debug('Returning $cacheFileName image data from fs cache');
      return cachedData;
    }

    final decodedData = await compute((File file) async {
      final fileData = await file.readAsString();
      final TimelineTask task = TimelineTask()..start('encodeSvg');
      final Uint8List compiledBytes = encodeSvg(
        xml: fileData,
        debugName: file.path,
        enableClippingOptimizer: false,
        enableMaskingOptimizer: false,
        enableOverdrawOptimizer: false,
      );
      task.finish();
      // for testing try: await Future.delayed(const Duration(seconds: 5));
      return compiledBytes;
    }, _file, debugLabel: 'Process SVG data');

    memCache.write(cacheFileName, decodedData);
    await fsCache.write(cacheFileName, decodedData);
    return decodedData.buffer.asByteData();
  }
}