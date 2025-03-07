/*
 * Copyright (C) 2023-2025 Yubico.
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

import '../../generated/l10n/app_localizations.dart';
import '../../widgets/basic_dialog.dart';
import '../models.dart';

class _OverwriteConfirmDialog extends StatelessWidget {
  final SlotId slot;
  final bool certificate;
  final bool? privateKey;

  const _OverwriteConfirmDialog({
    required this.certificate,
    required this.privateKey,
    required this.slot,
  });
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BasicDialog(
      icon: Icon(Symbols.warning),
      title: Text(l10n.q_overwrite_slot),
      actions: [
        TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: Text(l10n.s_overwrite)),
      ],
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.p_overwrite_slot_desc(slot.getDisplayName(l10n)),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          if (certificate) Text(l10n.l_bullet(l10n.l_overwrite_cert)),
          if (privateKey == true) Text(l10n.l_bullet(l10n.l_overwrite_key)),
          if (privateKey == null)
            Text(l10n.l_bullet(l10n.l_overwrite_key_maybe)),
        ],
      ),
    );
  }
}

Future<bool> confirmOverwrite(
  BuildContext context,
  PivSlot pivSlot, {
  required bool writeKey,
  required bool writeCert,
}) async {
  final overwritesCert = writeCert && pivSlot.certInfo != null;
  final overwritesKey = writeKey ? pivSlot.metadata != null : false;
  if (overwritesCert || overwritesKey != false) {
    return await showDialog(
            context: context,
            builder: (context) => _OverwriteConfirmDialog(
                  slot: pivSlot.slot,
                  certificate: overwritesCert,
                  privateKey: overwritesKey,
                )) ??
        false;
  }
  return true;
}
