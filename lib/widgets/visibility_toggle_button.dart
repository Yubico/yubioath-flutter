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

import '../generated/l10n/app_localizations.dart';

/// A visibility toggle button with proper accessibility support for VoiceOver.
///
/// Use this widget as a suffixIcon in text fields that need a show/hide toggle.
class VisibilityToggleButton extends StatelessWidget {
  final bool isObscured;
  final VoidCallback onToggle;
  final String? showLabel;
  final String? hideLabel;

  const VisibilityToggleButton({
    super.key,
    required this.isObscured,
    required this.onToggle,
    this.showLabel,
    this.hideLabel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final label = isObscured
        ? (showLabel ?? l10n.s_show_password)
        : (hideLabel ?? l10n.s_hide_password);

    return Semantics(
      button: true,
      label: label,
      onTap: onToggle,
      child: IconButton(
        icon: Icon(
          isObscured ? Symbols.visibility : Symbols.visibility_off,
          semanticLabel: label,
        ),
        onPressed: onToggle,
        tooltip: label,
      ),
    );
  }
}
