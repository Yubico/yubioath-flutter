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
