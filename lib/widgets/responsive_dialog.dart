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

class ResponsiveDialog extends StatefulWidget {
  final Widget? title;
  final Widget child;
  final List<Widget> actions;
  final Function()? onCancel;

  const ResponsiveDialog(
      {super.key,
      required this.child,
      this.title,
      this.actions = const [],
      this.onCancel});

  @override
  State<ResponsiveDialog> createState() => _ResponsiveDialogState();
}

class _ResponsiveDialogState extends State<ResponsiveDialog> {
  final Key _childKey = GlobalKey();

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: ((context, constraints) {
        final l10n = AppLocalizations.of(context)!;
        if (constraints.maxWidth < 540) {
          // Fullscreen
          return Scaffold(
            appBar: AppBar(
              title: widget.title,
              actions: widget.actions,
              leading: CloseButton(
                onPressed: () {
                  widget.onCancel?.call();
                  Navigator.of(context).pop();
                },
              ),
            ),
            body: SingleChildScrollView(
              child: SafeArea(
                  child: Container(key: _childKey, child: widget.child)),
            ),
          );
        } else {
          // Dialog
          final cancelText = widget.onCancel == null && widget.actions.isEmpty
              ? l10n.w_close
              : l10n.w_cancel;
          return AlertDialog(
            title: widget.title,
            titlePadding: const EdgeInsets.only(top: 24, left: 18, right: 18),
            scrollable: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            content: SizedBox(
              width: 380,
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
      }));
}
