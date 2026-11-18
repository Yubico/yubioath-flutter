import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:yubico_authenticator/app/icon_provider/icon_cache.dart';
import 'package:yubico_authenticator/app/icon_provider/icon_pack.dart';
import 'package:yubico_authenticator/app/icon_provider/icon_pack_manager.dart';
import 'package:yubico_authenticator/generated/l10n/app_localizations_en.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('plugins.flutter.io/path_provider');
  final l10n = AppLocalizationsEn();
  late Directory directory;
  late IconPackManager manager;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('icon_pack_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => directory.path);
    expect((await getApplicationSupportDirectory()).path, directory.path);
    manager = IconPackManager(IconCache(IconCacheMem(), IconCacheFs()));
    await manager.stream.first;
  });

  tearDown(() async {
    manager.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    await directory.delete(recursive: true);
  });

  Uint8List packBytes() {
    final content = utf8.encode(
      jsonEncode({
        'uuid': 'test-pack',
        'name': 'Test pack',
        'version': 1,
        'icons': [],
        'padding': List.filled(512, 'x').join(),
      }),
    );
    return Uint8List.fromList(
      ZipEncoder().encode(
        Archive()..add(ArchiveFile('pack.json', content.length, content)),
      ),
    );
  }

  Future<bool> importBytes(List<int> bytes) async {
    final file = await File(path.join(directory.path, 'input.zip'))
        .writeAsBytes(bytes);
    return IOOverrides.runZoned(
      () => manager.importPack(l10n, file.path),
      getSystemTempDirectory: () => directory,
    );
  }

  test('imports a valid compressed icon pack', () async {
    final loaded = manager.stream.firstWhere(
      (state) => state.value?.uuid == 'test-pack',
    );
    expect(await importBytes(packBytes()), isTrue);
    final pack = (await loaded.timeout(const Duration(seconds: 2))).value!;
    expect(pack.name, 'Test pack');
    expect(
      File(path.join(pack.directory.path, getLocalIconFileName('pack.json')))
          .existsSync(),
      isTrue,
    );
  });

  test('reports invalid ZIP headers as an invalid icon pack', () async {
    expect(await importBytes([0, 1, 2, 3]), isFalse);
    expect(manager.lastError, l10n.l_invalid_icon_pack);
    expect(manager.state.hasError, isTrue);
  });

  test(
    'reports lazy ZIP decompression failures as an invalid icon pack',
    () async {
      final bytes = packBytes();
      final header = ByteData.sublistView(bytes);
      expect(header.getUint16(8, Endian.little), 8);
      final contentOffset =
          30 +
          header.getUint16(26, Endian.little) +
          header.getUint16(28, Endian.little);
      bytes[contentOffset] = 0x07; // Invalid DEFLATE block type.
      expect(
        () => ZipDecoder().decodeBytes(bytes, verify: true),
        returnsNormally,
      );

      expect(await importBytes(bytes), isFalse);
      expect(manager.lastError, l10n.l_invalid_icon_pack);
      expect(manager.state.hasError, isTrue);
    },
  );
}
