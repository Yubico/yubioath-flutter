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
import '../features.dart' as features;
import '../models.dart';
import '../state.dart';
import '../keys.dart' as keys;
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

  List<ActionItem> buildActions() => _ref
      .watch(currentDeviceDataProvider)
      .maybeWhen(
        data: (data) {
          final manual =
              credential.touchRequired || credential.oathType == OathType.hotp;
          final ready = expired || credential.oathType == OathType.hotp;
          final pinned = _ref.watch(favoritesProvider).contains(credential.id);
          final l10n = AppLocalizations.of(_context)!;
          final canCopy = code != null && !expired;

          return [
            ActionItem(
              key: keys.copyAction,
              feature: features.accountsClipboard,
              icon: const Icon(Icons.copy),
              title: l10n.l_copy_to_clipboard,
              subtitle: l10n.l_copy_code_desc,
              shortcut: Platform.isMacOS ? '\u2318 C' : 'Ctrl+C',
              actionStyle: canCopy ? ActionStyle.primary : null,
              intent: canCopy ? const CopyIntent() : null,
            ),
            if (manual)
              ActionItem(
                key: keys.calculateAction,
                actionStyle: !canCopy ? ActionStyle.primary : null,
                icon: const Icon(Icons.refresh),
                title: l10n.s_calculate,
                subtitle: l10n.l_calculate_code_desc,
                shortcut: Platform.isMacOS ? '\u2318 R' : 'Ctrl+R',
                intent: ready ? const RefreshIntent() : null,
              ),
            ActionItem(
              key: keys.togglePinAction,
              feature: features.accountsPin,
              icon: pinned
                  ? pushPinStrokeIcon
                  : const Icon(Icons.push_pin_outlined),
              title: pinned ? l10n.s_unpin_account : l10n.s_pin_account,
              subtitle: l10n.l_pin_account_desc,
              intent: const TogglePinIntent(),
            ),
            if (data.info.version.isAtLeast(5, 3))
              ActionItem(
                key: keys.editAction,
                feature: features.accountsRename,
                icon: const Icon(Icons.edit_outlined),
                title: l10n.s_rename_account,
                subtitle: l10n.l_rename_account_desc,
                intent: const EditIntent(),
              ),
            ActionItem(
              key: keys.deleteAction,
              feature: features.accountsDelete,
              actionStyle: ActionStyle.error,
              icon: const Icon(Icons.delete_outline),
              title: l10n.s_delete_account,
              subtitle: l10n.l_delete_account_desc,
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
          semanticsLabel: code?.value.characters.map((c) => '$c ').toString(),
        ),
      );
}
