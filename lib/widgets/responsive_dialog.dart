/*
 * Copyright (C) 2022-2026 Yubico.
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

import '../app/views/keys.dart';
import '../core/state.dart';
import '../generated/l10n/app_localizations.dart';
import 'ensure_focus_visible.dart';

class ResponsiveDialog extends StatefulWidget {
  final Widget? title;
  final Widget Function(BuildContext context, bool fullScreen) builder;
  final List<Widget> actions;
  final Function()? onCancel;
  final bool allowCancel;
  final double dialogMaxWidth;
  final bool showDialogCloseButton;

  const ResponsiveDialog({
    super.key,
    required this.builder,
    this.title,
    this.actions = const [],
    this.onCancel,
    this.allowCancel = true,
    this.dialogMaxWidth = 600,
    this.showDialogCloseButton = true,
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

  String _getCancelText(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return widget.onCancel == null && widget.actions.isEmpty
        ? l10n.s_close
        : l10n.s_cancel;
  }

  String? _extractTitleText() {
    final title = widget.title;
    if (title is Text) {
      return title.data;
    }
    return null;
  }

  Widget _buildFullscreen(BuildContext context) => Semantics(
    scopesRoute: true,
    namesRoute: true,
    explicitChildNodes: true,
    label: _extractTitleText(),
    child: Scaffold(
      appBar: AppBar(
        title: widget.title,
        actions: widget.actions,
        leading: IconButton(
          key: closeButton,
          tooltip: _getCancelText(context),
          icon: const Icon(Symbols.close),
          onPressed: widget.allowCancel
              ? () {
                  widget.onCancel?.call();
                  Navigator.of(context).pop();
                }
              : null,
        ),
      ),
      body: SingleChildScrollView(
        child: SafeArea(
          child: EnsureFocusVisible(
            child: Container(
              key: _childKey,
              child: widget.builder(context, true),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _buildCompactDialog(BuildContext context) {
    return PopScope(
      canPop: widget.allowCancel,
      child: Dialog.fullscreen(
        child: Semantics(
          scopesRoute: true,
          namesRoute: true,
          explicitChildNodes: true,
          label: _extractTitleText(),
          child: Scaffold(
            appBar: AppBar(
              title: widget.title,
              actions: widget.actions,
              leading: IconButton(
                key: closeButton,
                tooltip: _getCancelText(context),
                icon: const Icon(Symbols.close),
                onPressed: widget.allowCancel
                    ? () {
                        widget.onCancel?.call();
                        Navigator.of(context).pop();
                      }
                    : null,
              ),
            ),
            body: Center(
              child: SingleChildScrollView(
                child: EnsureFocusVisible(
                  child: Container(
                    key: _childKey,
                    child: widget.builder(context, true),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          widget.onCancel?.call();
        }
      },
    );
  }

  Widget _buildDialog(BuildContext context) {
    return PopScope(
      canPop: widget.allowCancel,
      child: Theme(
        data: Theme.of(context).copyWith(
          chipTheme: Theme.of(context).chipTheme.copyWith(
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest,
          ),
        ),
        child: AlertDialog(
          semanticLabel: _extractTitleText(),
          title: widget.title,
          titlePadding: const EdgeInsets.only(top: 24, left: 18, right: 18),
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          content: SizedBox(
            width: widget.dialogMaxWidth,
            child: Container(
              key: _childKey,
              child: SingleChildScrollView(
                child: EnsureFocusVisible(
                  child: widget.builder(context, false),
                ),
              ),
            ),
          ),
          actions: [
            if (widget.showDialogCloseButton)
              TextButton(
                key: closeButton,
                onPressed: widget.allowCancel
                    ? () {
                        Navigator.of(context).pop();
                      }
                    : null,
                child: Text(_getCancelText(context)),
              ),
            ...widget.actions,
          ],
        ),
      ),
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          widget.onCancel?.call();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: ((context, constraints) {
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
        child: () {
          if (constraints.maxWidth < maxWidth) {
            return _buildFullscreen(context);
          }
          // On Android in landscape, use compact layout so forms
          // remain usable when the software keyboard appears.
          if (isAndroid) {
            final orientation = MediaQuery.of(context).orientation;
            if (orientation == Orientation.landscape) {
              return _buildCompactDialog(context);
            }
          }
          return _buildDialog(context);
        }(),
      );
    }),
  );
}
