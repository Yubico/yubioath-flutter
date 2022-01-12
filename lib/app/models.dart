import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../management/models.dart';

part 'models.freezed.dart';
//part 'models.g.dart';

enum SubPage { authenticator, yubikey }

@freezed
class YubiKeyData with _$YubiKeyData {
  factory YubiKeyData(DeviceNode node, String name, DeviceInfo info) =
      _YubiKeyData;
}

@freezed
class DeviceNode with _$DeviceNode {
  factory DeviceNode.usbYubiKey(
          List<String> path, String name, int pid, DeviceInfo info) =
      UsbYubiKeyNode;
  factory DeviceNode.nfcReader(List<String> path, String name) = NfcReaderNode;
}

/*
@freezed
class DeviceNode with _$DeviceNode {
  factory DeviceNode(
    List<String> path,
    int pid,
    Transport transport,
    String name,
    DeviceInfo info,
  ) = _DeviceNode;
}
*/

@freezed
class MenuAction with _$MenuAction {
  factory MenuAction(
      {required String text,
      required Icon icon,
      void Function()? action}) = _MenuAction;
}

@freezed
class WindowState with _$WindowState {
  factory WindowState({
    required bool focused,
    required bool visible,
    required bool active,
  }) = _WindowState;
}
