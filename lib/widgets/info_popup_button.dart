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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:material_symbols_icons/symbols.dart';

import '../app/accessibility_announcer.dart';
import '../generated/l10n/app_localizations.dart';
import 'basic_dialog.dart';

class InfoPopupButton extends StatelessWidget {
  final Text infoText;
  final bool displayDialog;
  final double? iconSize;
  final double? size;
  final IconData icon;
  final Color? iconColor;
  const InfoPopupButton({
    super.key,
    required this.infoText,
    this.displayDialog = false,
    this.iconSize,
    this.size,
    this.icon = Symbols.info,
    this.iconColor,
  });

  static String _plainTextFromSpan(InlineSpan span) {
    final buffer = StringBuffer();
    void visit(InlineSpan current) {
      if (current is TextSpan) {
        final text = current.text;
        if (text != null) {
          buffer.write(text);
        }
        final children = current.children;
        if (children != null) {
          for (final child in children) {
            visit(child);
          }
        }
      }
    }

    visit(span);
    return buffer.toString();
  }

  String _plainInfoText() {
    final data = infoText.data;
    if (data != null) {
      return data;
    }
    final span = infoText.textSpan;
    if (span != null) {
      return _plainTextFromSpan(span);
    }
    return '';
  }

  Widget _buildInfoContent(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final defaultTextStyle = displayDialog
        ? textTheme.bodyMedium
        : textTheme.bodySmall;
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: DefaultTextStyle(
          style: defaultTextStyle ?? TextStyle(),
          child: infoText,
        ),
      ),
    );
  }

  void _showPopupMenu(BuildContext context) {
    final RenderBox chipBox = context.findRenderObject()! as RenderBox;
    final RenderBox overlay =
        Navigator.of(context).overlay!.context.findRenderObject()! as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        chipBox.localToGlobal(
          chipBox.size.bottomLeft(Offset.zero),
          ancestor: overlay,
        ),
        chipBox.localToGlobal(
          chipBox.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    showMenu(
      context: context,
      constraints: BoxConstraints(maxWidth: 250, maxHeight: 400),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      position: position,
      popUpAnimationStyle: AnimationStyle(duration: Duration.zero),
      items: [PopupMenuItem(enabled: false, child: _buildInfoContent(context))],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mediaQuery = MediaQuery.maybeOf(context);
    final useDialog =
        displayDialog ||
        mediaQuery?.accessibleNavigation == true ||
        SemanticsBinding.instance.semanticsEnabled;
    final announceInfo =
        mediaQuery?.accessibleNavigation == true ||
        SemanticsBinding.instance.semanticsEnabled;

    return SizedBox(
      height: size,
      width: size,
      child: IconButton(
        tooltip: l10n.s_more_info,
        onPressed: () {
          // Show info content in dialog on smaller screens and mobile
          if (useDialog) {
            showDialog(
              context: context,
              builder: (context) => BasicDialog(
                icon: Icon(icon),
                title: Text(l10n.s_more_info),
                content: _buildInfoContent(context),
              ),
            );
          } else {
            _showPopupMenu(context);
          }

          if (announceInfo) {
            final text = _plainInfoText().replaceAll(RegExp(r'\s+'), ' ').trim();
            if (text.isNotEmpty) {
              unawaited(AccessibilityAnnouncer.announce(context, text));
            }
          }
        },
        icon: Icon(
          icon,
          size: iconSize,
          color: iconColor ?? Theme.of(context).colorScheme.primary,
        ),
        padding: EdgeInsets.zero,
      ),
    );
  }
}
