import 'dart:io';

import 'package:flutter/material.dart';

import '../../app/icon_provider/icon_pack.dart';
import '../../app/icon_provider/icon_pack_icon.dart';

class PasskeyIcon extends StatelessWidget {
  final String rpId;
  final Widget defaultWidget;

  const PasskeyIcon(
      {super.key, required this.rpId, required this.defaultWidget});

  File? _getFileForRpID(IconPack iconPack) {
    final parts = rpId.split('.');
    final reversed = parts.reversed.toList();

    final matching = iconPack.icons.where((element) => element.issuer
        .any((element) => reversed.any((e) => e.toUpperCase() == element)));

    return iconPack.getFileFromMatching(matching);
  }

  @override
  Widget build(BuildContext context) {
    return IconPackIcon(
      defaultWidget: defaultWidget,
      matchFunction: (iconPack) => _getFileForRpID(iconPack),
    );
  }
}
