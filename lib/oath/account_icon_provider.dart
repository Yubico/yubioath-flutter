import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vector_graphics/vector_graphics.dart';
import 'package:vector_graphics_compiler/vector_graphics_compiler.dart';
import 'package:yubico_authenticator/app/logging.dart';

final _log = Logger('account_icon_provider');

class IconPackIcon {
  final String filename;
  final String? category;
  final List<String> issuer;

  const IconPackIcon(
      {required this.filename, required this.category, required this.issuer});
}

class IconPack {
  final String uuid;
  final String name;
  final int version;
  final Directory directory;
  final List<IconPackIcon> icons;

  const IconPack(
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
    cacheDirectory = Directory('${documentsDirectory.path}${Platform.pathSeparator}account_icons_cache${Platform.pathSeparator}');
  }

  File _cachedFile(String fileName) => File('${cacheDirectory.path}${fileName}_cached');

  File? getFile(String fileName) {
    final file = _cachedFile(fileName);
    final exists = file.existsSync();
    return exists ? file : null;
  }

  Future<Uint8List?> getCachedFileData(String fileName) async {
    final file = getFile(fileName);
    if (file != null) {
      _log.debug('File $fileName exists in cache');
    } else {
      _log.debug('File $fileName does not exist in cache');
    }
    return file?.readAsBytes();
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

class AccountIconProvider extends ChangeNotifier {
  final FileSystemCache _cache;
  late IconPack _iconPack;

  AccountIconProvider(this._cache) {
    _cache.initialize();
  }
  
  void readIconPack(String relativePackPath) async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final packDirectory = Directory(
        '${documentsDirectory.path}${Platform.pathSeparator}$relativePackPath${Platform.pathSeparator}');
    final packFile = File('${packDirectory.path}pack.json');

    _log.debug('Looking for file: ${packFile.path}');

    if (!await packFile.exists()) {
      _log.debug('Failed to find icons pack ${packFile.path}');
      _iconPack = IconPack(
          uuid: '',
          name: '',
          version: 0,
          directory: Directory(''),
          icons: []);
      return;
    }

    var packContent = await packFile.readAsString();
    Map<String, dynamic> pack = const JsonDecoder().convert(packContent);

    final icons = List<IconPackIcon>.from(pack['icons'].map((icon) => IconPackIcon(
        filename: icon['filename'],
        category: icon['category'],
        issuer: List<String>.from(icon['issuer']))));

    _iconPack = IconPack(
        uuid: pack['uuid'],
        name: pack['name'],
        version: pack['version'],
        directory: packDirectory,
        icons: icons);
    _log.debug(
        'Parsed ${_iconPack.name} with ${_iconPack.icons.length} icons');
  }

  Future<bool> _cleanTempDirectory(Directory tempDirectory) async {
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }

    if (await tempDirectory.exists()) {
      _log.error('Failed to remove temp directory');
      return false;
    }

    return true;
  }

  Future<bool> importIconPack(String filePath) async {

    final packFile = File(filePath);
    if (!await packFile.exists()) {
      _log.error('Input file does not exist');
      return false;
    }

    // copy input file to temporary folder
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final tempDirectory = Directory('${documentsDirectory.path}${Platform.pathSeparator}temp${Platform.pathSeparator}');

    if (!await _cleanTempDirectory(tempDirectory)) {
      _log.error('Failed to cleanup temp directory');
      return false;
    }

    await tempDirectory.create(recursive: true);
    final tempCopy = await packFile.copy('${tempDirectory.path}${basename(packFile.path)}');
    final bytes = await File(tempCopy.path).readAsBytes();

    final destination = Directory('${tempDirectory.path}ex${Platform.pathSeparator}');

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
        Directory('${destination.path}$filename')
        .createSync(recursive: true);
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
        '${documentsDirectory.path}${Platform.pathSeparator}default_icon_pack${Platform.pathSeparator}');
    if (!await _cleanTempDirectory(packDirectory)) {
      _log.error('Could not remove old pack directory');
      await _cleanTempDirectory(tempDirectory);
      return false;
    }

    final packCacheDirectory = _cache.cacheDirectory;
    if (!await _cleanTempDirectory(packCacheDirectory)) {
      _log.error('Could not remove old cache directory');
      await _cleanTempDirectory(tempDirectory);
      return false;
    }

    await destination.rename(packDirectory.path);
    readIconPack('default_icon_pack');

    notifyListeners();

    await _cleanTempDirectory(tempDirectory);
    return true;
  }

  Future<bool> importCustomAccountImage(String accountName, String? issuer, String filePath) async {

    final requestedFile = File(filePath);
    final customAccountImageFilename = '${_cache.cacheDirectory.path}${_getCustomAccountImageFilename(accountName, issuer)}_cached';

    _log.debug('Copying custom image file $customAccountImageFilename');
    final customAccountImageFile = await requestedFile.copy(customAccountImageFilename);

    await FileImage(customAccountImageFile).evict();
    notifyListeners();

    return await customAccountImageFile.exists();
  }

  String _getCustomAccountImageFilename(String accountName, String? issuer) => base64Encode(utf8.encode('$accountName:$issuer'));

  Widget? getAccountIcon(String accountName, String? issuer, Widget placeHolder) {

    final customAccountImageFileName = _getCustomAccountImageFilename(accountName, issuer);

    _log.info('Checking if custom account image for $accountName:$issuer '
        '($customAccountImageFileName) exists...');

    final customFile = _cache.getFile(customAccountImageFileName);
    if (customFile != null) {
      _log.debug('Using custom account image for $accountName:$issuer');
      return Image.file(customFile, filterQuality: FilterQuality.medium);
    }

    final matching = _iconPack.icons
        .where((element) => element.issuer.any((element) => element == issuer));
    final issuerImageFile = matching.isNotEmpty
        ? File('${_iconPack.directory.path}${matching.first.filename}')
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
}
