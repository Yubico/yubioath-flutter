import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yubico_authenticator/otp/yubiotp_csv.dart';

base class _PickedFile extends PlatformFile {
  _PickedFile(this.uri);

  @override
  final Uri uri;

  @override
  String get name => uri.pathSegments.last;

  @override
  Never get xFile => throw UnimplementedError();

  @override
  Never lengthSync() => throw UnimplementedError();

  @override
  Never length() => throw UnimplementedError();

  @override
  Never readAsBytes() => throw UnimplementedError();

  @override
  Never readAsByteStream() => throw UnimplementedError();
}

class _CsvPicker extends FilePickerPlatform {
  PlatformFile? selection;
  int pickCount = 0;

  @override
  Future<PlatformFile?> pickFile({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    DarwinOptions darwinOptions = const DarwinOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    expect(dialogTitle, 'Select CSV');
    expect(type, FileType.custom);
    expect(allowedExtensions, ['csv']);
    expect(windowsOptions.lockParentWindow, isTrue);
    expect(linuxOptions.lockParentWindow, isTrue);
    pickCount++;
    return selection;
  }
}

void main() {
  late FilePickerPlatform originalPicker;
  late _CsvPicker picker;

  setUp(() {
    originalPicker = FilePickerPlatform.instance;
    picker = _CsvPicker();
    FilePickerPlatform.instance = picker;
  });
  tearDown(() => FilePickerPlatform.instance = originalPicker);

  test(
    'reselecting a CSV after restart preserves and appends prior rows',
    () async {
      final directory = await Directory.systemTemp.createTemp('yubiotp-csv-');
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/credentials.csv');
      final newline = Platform.lineTerminator;
      await file.writeAsString('previous$newline');
      picker.selection = _PickedFile(file.uri);

      final firstSession = await pickExistingYubiOtpCsv('Select CSV');
      expect(firstSession, isNotNull);
      await appendYubiOtpCsv(firstSession!, 'first');

      final nextSession = await pickExistingYubiOtpCsv('Select CSV');
      expect(nextSession, isNotNull);
      await appendYubiOtpCsv(nextSession!, 'second');

      expect(
        await file.readAsString(),
        'previous${newline}first${newline}second$newline',
      );
      expect(picker.pickCount, 2);
    },
  );

  test('cancelling file selection leaves an existing CSV untouched', () async {
    final directory = await Directory.systemTemp.createTemp('yubiotp-csv-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/credentials.csv');
    await file.writeAsString('previous');

    expect(await pickExistingYubiOtpCsv('Select CSV'), isNull);
    expect(await file.readAsString(), 'previous');
  });

  test('rejects a picked file without a local path', () async {
    picker.selection = _PickedFile(
      Uri.parse('content://example/credentials.csv'),
    );

    expect(pickExistingYubiOtpCsv('Select CSV'), throwsA(isA<StateError>()));
  });
}
