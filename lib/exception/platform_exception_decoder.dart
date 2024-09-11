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

import 'package:flutter/services.dart';

import 'apdu_exception.dart';
import 'cancellation_exception.dart';

extension Decoder on PlatformException {
  bool _isCancellation() => code == 'CancellationException';

  bool _isApduException() => code == 'ApduException';

  Exception decode() {
    if (_isCancellation()) {
      return CancellationException();
    }

    if (message != null && _isApduException()) {
      final regExp = RegExp(
          r'^com.yubico.yubikit.core.smartcard.ApduException: APDU error: 0x(.*)$');
      final firstMatch = regExp.firstMatch(message!);
      if (firstMatch != null) {
        final hexSw = firstMatch.group(1);
        final sw = int.tryParse(hexSw!, radix: 16);
        if (sw != null) {
          return ApduException(sw, 'SW: 0x$hexSw', details);
        }
      }
    }

    // original exception
    return this;
  }
}
