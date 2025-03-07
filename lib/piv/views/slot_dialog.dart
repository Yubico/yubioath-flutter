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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app/shortcuts.dart';
import '../../app/state.dart';
import '../../app/views/action_list.dart';
import '../../app/views/fs_dialog.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../management/models.dart';
import '../models.dart';
import '../state.dart';
import 'actions.dart';
import 'cert_info_view.dart';

class SlotDialog extends ConsumerWidget {
  final SlotId pivSlot;

  const SlotDialog(this.pivSlot, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Solve this in a cleaner way
    var keyData = ref.watch(currentDeviceDataProvider).valueOrNull;
    if (keyData == null) {
      // The rest of this method assumes there is a device, and will throw an exception if not.
      // This will never be shown, as the dialog will be immediately closed
      return const SizedBox();
    }
    final devicePath = keyData.node.path;

    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    // This is what ListTile uses for subtitle
    final subtitleStyle = textTheme.bodyMedium!.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );

    final (fipsCapable, fipsApproved) =
        keyData.info.getFipsStatus(Capability.piv);

    final pivState = ref.watch(pivStateProvider(devicePath)).valueOrNull;
    final slotData = ref.watch(pivSlotsProvider(devicePath).select((value) =>
        value.whenOrNull(
            data: (data) =>
                data.firstWhere((element) => element.slot == pivSlot))));

    if (pivState == null || slotData == null) {
      return const FsDialog(child: CircularProgressIndicator());
    }

    final certInfo = slotData.certInfo;
    final metadata = slotData.metadata;
    return PivActions(
      devicePath: devicePath,
      pivState: pivState,
      builder: (context) => ItemShortcuts(
        item: slotData,
        child: FocusScope(
          autofocus: true,
          child: FsDialog(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 48, bottom: 32),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          pivSlot.getDisplayName(l10n),
                          style: textTheme.headlineSmall,
                          softWrap: true,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            if (certInfo != null || metadata != null) ...[
                              CertInfoTable(
                                certInfo,
                                metadata,
                                alwaysIncludePrivate: pivState.supportsMetadata,
                                supportsBio: pivState.supportsBio,
                              ),
                              if (slotData.publicKeyMatch == false) ...[
                                const SizedBox(height: 16.0),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Symbols.info,
                                      size: 16,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        l10n.l_warning_public_key_mismatch,
                                        style: textTheme.bodySmall?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if (certInfo == null) const SizedBox(height: 16),
                            ],
                            if (certInfo == null) ...[
                              Text(
                                l10n.l_no_certificate,
                                softWrap: true,
                                textAlign: TextAlign.center,
                                style: subtitleStyle,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                ActionListSection.fromMenuActions(
                  context,
                  l10n.s_actions,
                  actions: buildSlotActions(
                      pivState, slotData, fipsCapable && !fipsApproved, l10n),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
