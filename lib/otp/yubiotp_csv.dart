import 'dart:io';

import 'package:file_picker/file_picker.dart';

Future<File?> pickExistingYubiOtpCsv(String dialogTitle) async {
  final selected = await FilePicker.pickFile(
    dialogTitle: dialogTitle,
    type: FileType.custom,
    allowedExtensions: ['csv'],
    windowsOptions: const WindowsOptions(lockParentWindow: true),
    linuxOptions: const LinuxOptions(lockParentWindow: true),
  );
  if (selected == null) {
    return null;
  }
  return File(
    selected.path ??
        (throw StateError('Selected OTP export file has no local path')),
  );
}

Future<void> appendYubiOtpCsv(File file, String csv) =>
    file.writeAsString('$csv${Platform.lineTerminator}', mode: FileMode.append);
