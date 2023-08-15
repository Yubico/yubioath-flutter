/*
 * Copyright (C) 2023 Yubico.
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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/message.dart';
import '../../app/state.dart';
import '../../app/views/fs_dialog.dart';
import '../../app/views/action_list.dart';
import '../../widgets/tooltip_if_truncated.dart';
import '../models.dart';
import '../state.dart';
import 'actions.dart';

class SlotDialog extends ConsumerWidget {
  final SlotId pivSlot;
  const SlotDialog(this.pivSlot, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Solve this in a cleaner way
    final node = ref.watch(currentDeviceDataProvider).valueOrNull?.node;
    if (node == null) {
      // The rest of this method assumes there is a device, and will throw an exception if not.
      // This will never be shown, as the dialog will be immediately closed
      return const SizedBox();
    }

    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    // This is what ListTile uses for subtitle
    final subtitleStyle = textTheme.bodyMedium!.copyWith(
      color: textTheme.bodySmall!.color,
    );
    final clipboard = ref.watch(clipboardProvider);
    final withContext = ref.read(withContextProvider);

    final pivState = ref.watch(pivStateProvider(node.path)).valueOrNull;
    final slotData = ref.watch(pivSlotsProvider(node.path).select((value) =>
        value.whenOrNull(
            data: (data) =>
                data.firstWhere((element) => element.slot == pivSlot))));

    if (pivState == null || slotData == null) {
      return const FsDialog(child: CircularProgressIndicator());
    }

    TableRow detailRow(String title, String value) {
      return TableRow(
        children: [
          Text(
            l10n.s_definition(title),
            textAlign: TextAlign.right,
          ),
          const SizedBox(width: 8.0),
          GestureDetector(
            onDoubleTap: () async {
              await clipboard.setText(value);
              if (!clipboard.platformGivesFeedback()) {
                await withContext((context) async {
                  showMessage(context, l10n.p_target_copied_clipboard(title));
                });
              }
            },
            child: TooltipIfTruncated(
              text: value,
              style: subtitleStyle,
            ),
          ),
        ],
      );
    }

    final certInfo = slotData.certInfo;
    return registerPivActions(
      node.path,
      pivState,
      slotData,
      ref: ref,
      builder: (context) => FocusScope(
        autofocus: true,
        child: FsDialog(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 48, bottom: 16),
                child: Column(
                  children: [
                    Text(
                      pivSlot.getDisplayName(l10n),
                      style: textTheme.headlineSmall,
                      softWrap: true,
                      textAlign: TextAlign.center,
                    ),
                    if (certInfo != null) ...[
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Table(
                          defaultColumnWidth: const IntrinsicColumnWidth(),
                          columnWidths: const {2: FlexColumnWidth()},
                          children: [
                            detailRow(l10n.s_subject, certInfo.subject),
                            detailRow(l10n.s_issuer, certInfo.issuer),
                            detailRow(l10n.s_serial, certInfo.serial),
                            detailRow(l10n.s_certificate_fingerprint,
                                certInfo.fingerprint),
                            detailRow(
                              l10n.s_valid_from,
                              DateFormat.yMMMEd().format(
                                  DateTime.parse(certInfo.notValidBefore)),
                            ),
                            detailRow(
                              l10n.s_valid_to,
                              DateFormat.yMMMEd().format(
                                  DateTime.parse(certInfo.notValidAfter)),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Text(
                          l10n.l_no_certificate,
                          softWrap: true,
                          textAlign: TextAlign.center,
                          style: subtitleStyle,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
              ActionListSection.fromMenuActions(
                context,
                l10n.s_actions,
                actions: buildSlotActions(certInfo != null, l10n),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
