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

import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/models.dart';
import '../../app/shortcuts.dart';
import '../../app/state.dart';
import '../../core/state.dart';
import '../../widgets/circle_timer.dart';
import '../../widgets/custom_icons.dart';
import '../models.dart';
import '../state.dart';
import 'actions.dart';

/// Support class for presenting an OATH account.
class AccountHelper {
  final BuildContext _context;
  final WidgetRef _ref;
  final OathCredential credential;
  final OathCode? code;
  final bool expired;
  const AccountHelper._(
      this._context, this._ref, this.credential, this.code, this.expired);

  factory AccountHelper(
      BuildContext context, WidgetRef ref, OathCredential credential) {
    final code = ref.watch(codeProvider(credential));
    final expired = code == null ||
        (credential.oathType == OathType.totp &&
            ref.watch(expiredProvider(code.validTo)));
    return AccountHelper._(context, ref, credential, code, expired);
  }

  String get title => credential.issuer ?? credential.name;
  String? get subtitle => credential.issuer != null ? credential.name : null;

  List<MenuAction> buildActions() => _ref
      .watch(currentDeviceDataProvider)
      .maybeWhen(
        data: (data) {
          final manual =
              credential.touchRequired || credential.oathType == OathType.hotp;
          final ready = expired || credential.oathType == OathType.hotp;
          final pinned = _ref.watch(favoritesProvider).contains(credential.id);

          final l10n = AppLocalizations.of(_context)!;
          final shortcut = Platform.isMacOS ? '\u2318 C' : 'Ctrl+C';
          return [
            MenuAction(
              text: l10n.oath_copy_to_clipboard,
              icon: const Icon(Icons.copy),
              intent: code == null || expired ? null : const CopyIntent(),
              trailing: shortcut,
            ),
            if (manual)
              MenuAction(
                text: l10n.oath_calculate,
                icon: const Icon(Icons.refresh),
                intent: ready ? const CalculateIntent() : null,
              ),
            MenuAction(
              text: pinned ? l10n.oath_unpin_account : l10n.oath_pin_account,
              icon: pinned
                  ? pushPinStrokeIcon
                  : const Icon(Icons.push_pin_outlined),
              intent: const TogglePinIntent(),
            ),
            if (data.info.version.isAtLeast(5, 3))
              MenuAction(
                icon: const Icon(Icons.edit_outlined),
                text: l10n.oath_rename_account,
                intent: const EditIntent(),
              ),
            MenuAction(
              text: l10n.oath_delete_account,
              icon: const Icon(Icons.delete_outline),
              intent: const DeleteIntent(),
            ),
          ];
        },
        orElse: () => [],
      );

  Widget buildCodeIcon() => AnimatedSize(
        alignment: Alignment.centerRight,
        duration: const Duration(milliseconds: 100),
        child: Opacity(
          opacity: 0.4,
          child: (credential.oathType == OathType.hotp
                  ? (expired ? const Icon(Icons.refresh) : null)
                  : (expired || code == null
                      ? (credential.touchRequired
                          ? const Icon(Icons.touch_app)
                          : null)
                      : Builder(builder: (context) {
                          return SizedBox.square(
                            dimension: (IconTheme.of(context).size ?? 18) * 0.8,
                            child: CircleTimer(
                              code!.validFrom * 1000,
                              code!.validTo * 1000,
                            ),
                          );
                        }))) ??
              const SizedBox(),
        ),
      );

  Widget buildCodeLabel() => _CodeLabel(code, expired);
}

class _CodeLabel extends StatelessWidget {
  final OathCode? code;
  final bool expired;
  const _CodeLabel(this.code, this.expired);

  String _formatCode(OathCode? code) {
    final value = code?.value;
    if (value == null) {
      return '';
    } else if (value.length < 6) {
      return value;
    } else {
      var i = value.length ~/ 2;
      return '${value.substring(0, i)} ${value.substring(i)}';
    }
  }

  @override
  Widget build(BuildContext context) => Opacity(
        opacity: expired ? 0.4 : 1.0,
        child: Text(
          _formatCode(code),
          style: const TextStyle(
            fontFeatures: [FontFeature.tabularFigures()],
            //fontWeight: FontWeight.w400,
          ),
          textHeightBehavior: TextHeightBehavior(
            // This helps with vertical centering on desktop
            applyHeightToFirstAscent: !isDesktop,
          ),
        ),
      );
}
