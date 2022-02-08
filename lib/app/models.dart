import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../management/models.dart';

part 'models.freezed.dart';

enum SubPage { authenticator, yubikey }

@freezed
class YubiKeyData with _$YubiKeyData {
  factory YubiKeyData(DeviceNode node, String name, DeviceInfo info) =
      _YubiKeyData;
}

const _listEquality = ListEquality();

class DevicePath {
  final List<String> segments;

  DevicePath(List<String> path) : segments = List.unmodifiable(path);

  @override
  bool operator ==(Object other) =>
      other is DevicePath && _listEquality.equals(segments, other.segments);

  @override
  int get hashCode => Object.hashAll(segments);
}

@freezed
class DeviceNode with _$DeviceNode {
  factory DeviceNode.usbYubiKey(
      DevicePath path, String name, int pid, DeviceInfo info) = UsbYubiKeyNode;
  factory DeviceNode.nfcReader(DevicePath path, String name) = NfcReaderNode;
}

@freezed
class MenuAction with _$MenuAction {
  factory MenuAction(
      {required String text,
      required Icon icon,
      void Function(BuildContext context)? action}) = _MenuAction;
}

@freezed
class WindowState with _$WindowState {
  factory WindowState({
    required bool focused,
    required bool visible,
    required bool active,
  }) = _WindowState;
}
