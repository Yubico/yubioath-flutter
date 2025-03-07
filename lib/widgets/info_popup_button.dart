/*
 * Copyright (C) 2025-2025 Yubico.
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

import 'package:flutter/material.dart';

import 'package:material_symbols_icons/symbols.dart';

import '../generated/l10n/app_localizations.dart';
import 'basic_dialog.dart';

class InfoPopupButton extends StatelessWidget {
  final RichText infoText;
  final bool displayDialog;
  final double? iconSize;
  final double? size;
  const InfoPopupButton({
    super.key,
    required this.infoText,
    this.displayDialog = false,
    this.iconSize,
    this.size,
  });

  Widget _buildInfoContent(BuildContext context) {
    return SingleChildScrollView(child: infoText);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (!displayDialog) {
      return PopupMenuButton(
        tooltip: l10n.s_more_info,
        constraints: BoxConstraints(maxWidth: 250, maxHeight: 400),
        popUpAnimationStyle: AnimationStyle(duration: Duration.zero),
        borderRadius: BorderRadius.circular(25),
        child: SizedBox(
          height: size,
          width: size,
          child: Icon(
            Symbols.help,
            size: iconSize,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        itemBuilder: (context) {
          return [
            PopupMenuItem(enabled: false, child: _buildInfoContent(context))
          ];
        },
      );
    } else {
      return SizedBox(
        height: size,
        width: size,
        child: IconButton(
          tooltip: l10n.s_more_info,
          onPressed: () {
            // Show info content in dialog on smaller screens and mobile
            showDialog(
              context: context,
              builder: (context) => BasicDialog(
                content: _buildInfoContent(context),
              ),
            );
          },
          icon: Icon(
            Symbols.help,
            size: iconSize,
            color: Theme.of(context).colorScheme.primary,
          ),
          padding: EdgeInsets.zero,
        ),
      );
    }
  }
}
