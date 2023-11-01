/*
 * Copyright (C) 2022 Yubico.
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
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:yubico_authenticator/core/state.dart';

class ResponsiveDialog extends StatefulWidget {
  final Widget? title;
  final Widget child;
  final List<Widget> actions;
  final Function()? onCancel;
  final bool allowCancel;

  const ResponsiveDialog({
    super.key,
    required this.child,
    this.title,
    this.actions = const [],
    this.onCancel,
    this.allowCancel = true,
  });

  @override
  State<ResponsiveDialog> createState() => _ResponsiveDialogState();
}

class _ResponsiveDialogState extends State<ResponsiveDialog> {
  final Key _childKey = GlobalKey();
  final _focus = FocusScopeNode();
  bool _hasLostFocus = false;

  @override
  void dispose() {
    super.dispose();
    _focus.dispose();
  }

  Widget _buildFullscreen(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: widget.title,
          actions: widget.actions,
          leading: IconButton(
              tooltip: AppLocalizations.of(context)!.s_close,
              icon: const Icon(Icons.close),
              onPressed: widget.allowCancel
                  ? () {
                      widget.onCancel?.call();
                      Navigator.of(context).pop();
                    }
                  : null),
        ),
        body: SingleChildScrollView(
          child:
              SafeArea(child: Container(key: _childKey, child: widget.child)),
        ),
      );

  Widget _buildDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cancelText = widget.onCancel == null && widget.actions.isEmpty
        ? l10n.s_close
        : l10n.s_cancel;
    return AlertDialog(
      title: widget.title,
      titlePadding: const EdgeInsets.only(top: 24, left: 18, right: 18),
      scrollable: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      content: SizedBox(
        width: 550,
        child: Container(key: _childKey, child: widget.child),
      ),
      actions: [
        TextButton(
          child: Text(cancelText),
          onPressed: () {
            widget.onCancel?.call();
            Navigator.of(context).pop();
          },
        ),
        ...widget.actions
      ],
    );
  }

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: ((context, constraints) {
        var maxWidth = isDesktop ? 400 : 600;
        // This keeps the focus in the dialog, even if the underlying page changes.
        return FocusScope(
          node: _focus,
          autofocus: true,
          onFocusChange: (focused) {
            if (!focused && !_hasLostFocus) {
              _focus.requestFocus();
              _hasLostFocus = true;
            }
          },
          child: constraints.maxWidth < maxWidth
              ? _buildFullscreen(context)
              : _buildDialog(context),
        );
      }));
}
