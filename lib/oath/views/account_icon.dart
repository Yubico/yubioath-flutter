import 'dart:io';

import 'package:flutter/material.dart';

import '../../app/icon_provider/icon_pack.dart';
import '../../app/icon_provider/icon_pack_icon.dart';

class AccountIcon extends StatelessWidget {
  final String? issuer;
  final Widget defaultWidget;

  const AccountIcon(
      {super.key, required this.issuer, required this.defaultWidget});

  File? _getFileForIssuer(IconPack iconPack) {
    if (issuer == null) {
      return null;
    }

    final matching = iconPack.icons.where((element) =>
        element.issuer.any((element) => element == issuer?.toUpperCase()));

    return iconPack.getFileFromMatching(matching);
  }

  @override
  Widget build(BuildContext context) {
    return IconPackIcon(
      defaultWidget: defaultWidget,
      matchFunction: (iconPack) => _getFileForIssuer(iconPack),
    );
  }
}
