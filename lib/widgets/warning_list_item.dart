/*
 * Copyright (C) 2026 Yubico.
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

/// A list item on a warning background, for a problem the user can fix by
/// tapping it.
///
/// Uses the theme's tertiary container colors, which pair with the
/// [ColorScheme.tertiary] used for warning icons and text elsewhere in the app.
class WarningListItem extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget icon;
  final VoidCallback? onTap;
  final double borderRadius;

  const WarningListItem({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = const Icon(Symbols.warning_amber),
    this.onTap,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = colorScheme.onTertiaryContainer;
    return Material(
      color: colorScheme.tertiaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        iconColor: foreground,
        textColor: foreground,
        leading: CircleAvatar(
          backgroundColor: Colors.transparent,
          foregroundColor: foreground,
          child: icon,
        ),
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle!) : null,
        trailing: onTap != null ? const Icon(Symbols.open_in_new) : null,
        onTap: onTap,
      ),
    );
  }
}
