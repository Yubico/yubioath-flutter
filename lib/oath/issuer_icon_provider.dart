import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vector_graphics/vector_graphics.dart';
import 'package:vector_graphics_compiler/vector_graphics_compiler.dart';
import 'package:yubico_authenticator/app/logging.dart';

final _log = Logger('issuer_icon_provider');

class IssuerIcon {
  final String filename;
  final String? category;
  final List<String> issuer;

  const IssuerIcon(
      {required this.filename, required this.category, required this.issuer});
}

class IssuerIconPack {
  final String uuid;
  final String name;
  final int version;
  final Directory directory;
  final List<IssuerIcon> icons;

  const IssuerIconPack(
      {required this.uuid,
      required this.name,
      required this.version,
      required this.directory,
      required this.icons});
}

class FileSystemCache {

  late Directory cacheDirectory;

  FileSystemCache();

  void initialize() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    cacheDirectory = Directory('${documentsDirectory.path}${Platform.pathSeparator}issuer_icons_cache${Platform.pathSeparator}');
  }

  File _cachedFile(String fileName) => File('${cacheDirectory.path}${fileName}_cached');

  Future<Uint8List?> getCachedFileData(String fileName) async {
    final file = _cachedFile(fileName);
    final exists = await file.exists();
    if (exists) {
      _log.debug('File $fileName exists in cache');
    } else {
      _log.debug('File $fileName does not exist in cache');
    }
    return (exists) ? file.readAsBytes() : null;
  }

  Future<void> writeFileData(String fileName, Uint8List data) async {
    final file = _cachedFile(fileName);
    _log.debug('Storing $fileName to cache');
    if (!await file.exists()) {
      await file.create(recursive: true, exclusive: false);
    }
    await file.writeAsBytes(data, flush: true);
  }

}

class CachingFileLoader extends BytesLoader {
  final File _file;
  final FileSystemCache _cache;

  const CachingFileLoader(this._cache, this._file);

  @override
  Future<ByteData> loadBytes(BuildContext? context) async {
    _log.debug('Reading ${_file.path}');

    final cacheFileName = 'cache_${basename(_file.path)}';
    final cachedData = await _cache.getCachedFileData(cacheFileName);

    if (cachedData != null) {
      return cachedData.buffer.asByteData();
    }

    return await compute((File file) async {
      final fileData = await _file.readAsString();
      final TimelineTask task = TimelineTask()..start('encodeSvg');
      final Uint8List compiledBytes = encodeSvg(
        xml: fileData,
        debugName: _file.path,
        enableClippingOptimizer: false,
        enableMaskingOptimizer: false,
        enableOverdrawOptimizer: false,
      );
      task.finish();
      // for testing: await Future.delayed(const Duration(seconds: 5));

      await _cache.writeFileData(cacheFileName, compiledBytes);

      // sendAndExit will make sure this isn't copied.
      return compiledBytes.buffer.asByteData();
    }, _file, debugLabel: 'Load Bytes');
  }
}

class IssuerIconProvider {
  final FileSystemCache _cache;
  late IssuerIconPack _issuerIconPack;

  IssuerIconProvider(this._cache) {
    _cache.initialize();
  }
  
  void readPack(String relativePackPath) async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final packDirectory = Directory(
        '${documentsDirectory.path}${Platform.pathSeparator}$relativePackPath${Platform.pathSeparator}');
    final packFile = File('${packDirectory.path}pack.json');

    _log.debug('Looking for file: ${packFile.path}');

    if (!await packFile.exists()) {
      _log.debug('Failed to find icons pack ${packFile.path}');
      return;
    }

    var packContent = await packFile.readAsString();
    Map<String, dynamic> pack = const JsonDecoder().convert(packContent);

    final icons = List<IssuerIcon>.from(pack['icons'].map((icon) => IssuerIcon(
        filename: icon['filename'],
        category: icon['category'],
        issuer: List<String>.from(icon['issuer']))));

    _issuerIconPack = IssuerIconPack(
        uuid: pack['uuid'],
        name: pack['name'],
        version: pack['version'],
        directory: packDirectory,
        icons: icons);
    _log.debug(
        'Parsed ${_issuerIconPack.name} with ${_issuerIconPack.icons.length} icons');
  }

  VectorGraphic? issuerVectorGraphic(String issuer, Widget placeHolder) {
    final matching = _issuerIconPack.icons
        .where((element) => element.issuer.any((element) => element == issuer));
    final issuerImageFile = matching.isNotEmpty
        ? File('${_issuerIconPack.directory.path}${matching.first.filename}')
        : null;
    return issuerImageFile != null && issuerImageFile.existsSync()
        ? VectorGraphic(
            width: 40,
            height: 40,
            fit: BoxFit.fill,
            loader: CachingFileLoader(_cache, issuerImageFile),
            placeholderBuilder: (BuildContext _) => placeHolder,
          )
        : null;
  }

  Image? issuerImage(String issuer) {
    final matching = _issuerIconPack.icons
        .where((element) => element.issuer.any((element) => element == issuer));
    return matching.isNotEmpty
        ? Image.file(
            File(
                '${_issuerIconPack.directory.path}${matching.first.filename}.png'),
            filterQuality: FilterQuality.medium)
        : null;
  }
}
