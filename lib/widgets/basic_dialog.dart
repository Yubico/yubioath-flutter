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

import 'package:flutter/material.dart';

import '../generated/l10n/app_localizations.dart';

class BasicDialog extends StatefulWidget {
  final Widget content;
  final List<Widget> actions;
  final bool allowCancel;
  final Function()? onCancel;
  final Widget? icon;
  final Widget? title;

  const BasicDialog({
    super.key,
    required this.content,
    this.actions = const [],
    this.onCancel,
    this.icon,
    this.title,
    this.allowCancel = true,
  });

  @override
  State<BasicDialog> createState() => _BasicDialogState();
}

class _BasicDialogState extends State<BasicDialog> {
  final Key _childKey = GlobalKey();
  final _focus = FocusScopeNode();
  bool _hasLostFocus = false;

  @override
  void dispose() {
    super.dispose();
    _focus.dispose();
  }

  String _getCancelText(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return widget.onCancel == null && widget.actions.isEmpty
        ? l10n.s_close
        : l10n.s_cancel;
  }

  @override
  Widget build(BuildContext context) {
    return FocusScope(
      node: _focus,
      autofocus: true,
      onFocusChange: (focused) {
        if (!focused && !_hasLostFocus) {
          _focus.requestFocus();
          _hasLostFocus = true;
        }
      },
      child: PopScope(
        canPop: widget.allowCancel,
        child: AlertDialog(
          title: widget.title,
          titlePadding: EdgeInsets.only(
            left: 18.0,
            top: widget.icon == null ? 24.0 : 0.0,
            right: 18.0,
          ),
          icon: widget.icon,
          scrollable: true,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 18.0,
          ),
          content: Container(
            key: _childKey,
            constraints: BoxConstraints(maxWidth: 350),
            child: widget.content,
          ),
          actions: [
            TextButton(
              onPressed:
                  widget.allowCancel
                      ? () {
                        Navigator.of(context).pop();
                      }
                      : null,
              child: Text(_getCancelText(context)),
            ),
            ...widget.actions,
          ],
        ),
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) {
            widget.onCancel?.call();
          }
        },
      ),
    );
  }
}
