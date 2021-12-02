import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../management/models.dart';

part 'models.freezed.dart';
part 'models.g.dart';

enum SubPage { authenticator, yubikey }

@freezed
class DeviceNode with _$DeviceNode {
  factory DeviceNode(
    List<String> path,
    int pid,
    Transport transport,
    String name,
    DeviceInfo info,
  ) = _DeviceNode;

  factory DeviceNode.fromJson(Map<String, dynamic> json) =>
      _$DeviceNodeFromJson(json);
}

@freezed
class MenuAction with _$MenuAction {
  factory MenuAction(
      {required String text,
      required Icon icon,
      void Function()? action}) = _MenuAction;
}
