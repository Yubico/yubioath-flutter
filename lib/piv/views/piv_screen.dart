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
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/message.dart';
import '../../app/models.dart';
import '../../app/shortcuts.dart';
import '../../app/views/app_failure_page.dart';
import '../../app/views/app_page.dart';
import '../../app/views/message_page.dart';
import '../models.dart';
import '../state.dart';
import 'key_actions.dart';
import 'slot_dialog.dart';

class PivScreen extends ConsumerWidget {
  final DevicePath devicePath;

  const PivScreen(this.devicePath, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return ref.watch(pivStateProvider(devicePath)).when(
          loading: () => MessagePage(
            title: Text(l10n.s_piv),
            graphic: const CircularProgressIndicator(),
            delayedContent: true,
          ),
          error: (error, _) => AppFailurePage(
            title: Text(l10n.s_piv),
            cause: error,
          ),
          data: (pivState) {
            final pivSlots = ref.watch(pivSlotsProvider(devicePath)).asData;
            return AppPage(
              title: Text(l10n.s_piv),
              keyActionsBuilder: (context) =>
                  pivBuildActions(context, devicePath, pivState, ref),
              child: Column(
                children: [
                  if (pivSlots?.hasValue == true)
                    ...pivSlots!.value.map((e) => Actions(
                          actions: {
                            OpenIntent:
                                CallbackAction<OpenIntent>(onInvoke: (_) async {
                              await showBlurDialog(
                                context: context,
                                builder: (context) => SlotDialog(e.slot),
                              );
                              return null;
                            }),
                          },
                          child: _CertificateListItem(e),
                        ))
                ],
              ),
            );
          },
        );
  }
}

class _CertificateListItem extends StatelessWidget {
  final PivSlot pivSlot;
  const _CertificateListItem(this.pivSlot);

  @override
  Widget build(BuildContext context) {
    final slot = pivSlot.slot;
    final certInfo = pivSlot.certInfo;
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: CircleAvatar(
        foregroundColor: colorScheme.onSecondary,
        backgroundColor: colorScheme.secondary,
        child: const Icon(Icons.approval),
      ),
      title: Text(
        slot.getDisplayName(l10n),
        softWrap: false,
        overflow: TextOverflow.fade,
      ),
      subtitle: certInfo != null
          ? Text(
              l10n.l_subject_issuer(certInfo.subject, certInfo.issuer),
              softWrap: false,
              overflow: TextOverflow.fade,
            )
          : Text(pivSlot.hasKey == true
              ? l10n.l_key_no_certificate
              : l10n.l_no_certificate),
      trailing: OutlinedButton(
        onPressed: () {
          Actions.maybeInvoke<OpenIntent>(context, const OpenIntent());
        },
        child: const Icon(Icons.more_horiz),
      ),
    );
  }
}
