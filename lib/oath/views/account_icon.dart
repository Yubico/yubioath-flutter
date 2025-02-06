/*
 * Copyright (C) 2023, 2025 Yubico.
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
