/*
 * Copyright (C) 2022 Yubico.
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

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../management/models.dart';
import '../models.dart';

String getDeviceInfoString(DeviceInfo info) {
  final serial = info.serial;
  var subtitle = '';
  if (serial != null) {
    subtitle += 'S/N: $serial ';
  }
  if (info.version.isAtLeast(1)) {
    subtitle += 'F/W: ${info.version}';
  } else {
    subtitle += 'Unknown type';
  }
  return subtitle;
}

List<String> getDeviceMessages(DeviceNode? node, AsyncValue<YubiKeyData> data) {
  if (node == null) {
    return ['Insert a YubiKey', 'USB'];
  }
  final messages = data.whenOrNull(
        data: (data) => [getDeviceInfoString(data.info)],
        error: (error, _) {
          switch (error) {
            case 'unknown-device':
              return ['Unrecognized device'];
            case 'device-inaccessible':
              return ['Device inaccessible'];
          }
          return null;
        },
      ) ??
      ['No YubiKey present'];

  final name = data.asData?.value.name;
  if (name != null) {
    messages.insert(0, name);
  }

  if (node is NfcReaderNode) {
    messages.add(node.name);
  }

  return messages;
}
