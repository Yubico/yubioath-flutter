/*
 * Copyright (C) 2025 Yubico.
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

class PasskeyIcon extends StatelessWidget {
  final String rpId;
  final Widget defaultWidget;

  const PasskeyIcon({
    super.key,
    required this.rpId,
    required this.defaultWidget,
  });

  File? _getFileForRpID(IconPack iconPack) {
    final parts = rpId.split('.');
    final reversed = parts.reversed.toList();

    final matching = iconPack.icons.where(
      (element) => element.issuer.any(
        (element) => reversed.any((e) => e.toUpperCase() == element),
      ),
    );

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
