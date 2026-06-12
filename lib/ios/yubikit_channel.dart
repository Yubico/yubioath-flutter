/*
 * Copyright (C) 2026 Yubico.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *       http://www.apache.org/licenses/LICENSE-2.0
 */

import 'package:flutter/services.dart';

class YubiKitChannel {
  static const _channel = MethodChannel('com.yubico.authenticator/yubikit');

  static Future<String> readSerial({required String via}) async {
    final result = await _channel.invokeMethod<String>('readSerial', {
      'via': via,
    });
    return result ?? '(no serial)';
  }
}
