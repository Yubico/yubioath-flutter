import 'dart:io';
import 'dart:async';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  await Process.run('adb' , ['shell' ,'pm', 'grant', 'com.yubico.yubioath', 'android.permission.CAMERA']);
  await Process.run('adb' , ['shell' ,'pm', 'grant', 'com.yubico.yubioath', 'android.permission.WRITE_EXTERNAL_STORAGE']);

  await integrationDriver();
}