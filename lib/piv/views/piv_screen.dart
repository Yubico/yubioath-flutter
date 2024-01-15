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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/message.dart';
import '../../app/models.dart';
import '../../app/shortcuts.dart';
import '../../app/views/action_list.dart';
import '../../app/views/app_failure_page.dart';
import '../../app/views/app_list_item.dart';
import '../../app/views/app_page.dart';
import '../../app/views/message_page.dart';
import '../../core/state.dart';
import '../../widgets/list_title.dart';
import '../features.dart' as features;
import '../keys.dart';
import '../models.dart';
import '../state.dart';
import 'actions.dart';
import 'cert_info_view.dart';
import 'key_actions.dart';
import 'slot_dialog.dart';

class PivScreen extends ConsumerStatefulWidget {
  final DevicePath devicePath;

  PivScreen(this.devicePath) : super(key: ObjectKey(devicePath));

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _PivScreenState();
}

class _PivScreenState extends ConsumerState<PivScreen> {
  SlotId? _selected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasFeature = ref.watch(featureProvider);
    return ref.watch(pivStateProvider(widget.devicePath)).when(
          loading: () => const MessagePage(
            graphic: CircularProgressIndicator(),
            delayedContent: true,
          ),
          error: (error, _) => AppFailurePage(
            cause: error,
          ),
          data: (pivState) {
            final pivSlots =
                ref.watch(pivSlotsProvider(widget.devicePath)).asData;
            final selected = _selected != null
                ? pivSlots?.value.firstWhere((e) => e.slot == _selected)
                : null;
            final theme = Theme.of(context);
            final textTheme = theme.textTheme;
            // This is what ListTile uses for subtitle
            final subtitleStyle = textTheme.bodyMedium!.copyWith(
              color: textTheme.bodySmall!.color,
            );
            return PivActions(
              devicePath: widget.devicePath,
              pivState: pivState,
              builder: (context) => Actions(
                actions: {
                  EscapeIntent:
                      CallbackAction<EscapeIntent>(onInvoke: (intent) {
                    if (selected != null) {
                      setState(() {
                        _selected = null;
                      });
                    } else {
                      Actions.invoke(context, intent);
                    }
                    return false;
                  }),
                  OpenIntent<PivSlot>: CallbackAction<OpenIntent<PivSlot>>(
                    onInvoke: (intent) async {
                      await showBlurDialog(
                        context: context,
                        barrierColor: Colors.transparent,
                        builder: (context) => SlotDialog(intent.target.slot),
                      );
                      return null;
                    },
                  ),
                },
                child: AppPage(
                  title: l10n.s_certificates,
                  detailViewBuilder: selected != null
                      ? (context) => Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ListTitle(l10n.s_details),
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    children: [
                                      Text(
                                        selected.slot.getDisplayName(l10n),
                                        style: textTheme.headlineSmall,
                                        softWrap: true,
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 16),
                                      selected.certInfo != null
                                          ? CertInfoTable(selected.certInfo!)
                                          : Text(
                                              l10n.l_no_certificate,
                                              softWrap: true,
                                              textAlign: TextAlign.center,
                                              style: subtitleStyle,
                                            ),
                                    ],
                                  ),
                                ),
                              ),
                              ActionListSection.fromMenuActions(
                                context,
                                l10n.s_actions,
                                actions: buildSlotActions(selected, l10n),
                              ),
                            ],
                          )
                      : null,
                  keyActionsBuilder: hasFeature(features.actions)
                      ? (context) => pivBuildActions(
                          context, widget.devicePath, pivState, ref)
                      : null,
                  builder: (context, expanded) {
                    // De-select if window is resized to be non-expanded.
                    if (!expanded) {
                      Timer.run(() {
                        setState(() {
                          _selected = null;
                        });
                      });
                    }
                    return Actions(
                      actions: {
                        if (expanded)
                          OpenIntent<PivSlot>:
                              CallbackAction<OpenIntent<PivSlot>>(
                                  onInvoke: (intent) async {
                            setState(() {
                              _selected = intent.target.slot;
                            });
                            return null;
                          }),
                      },
                      child: Column(
                        children: [
                          ListTitle(l10n.s_certificates),
                          if (pivSlots?.hasValue == true)
                            ...pivSlots!.value.map(
                              (e) => _CertificateListItem(
                                e,
                                expanded: expanded,
                                selected: e == selected,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
  }
}

class _CertificateListItem extends ConsumerWidget {
  final PivSlot pivSlot;
  final bool expanded;
  final bool selected;

  const _CertificateListItem(this.pivSlot,
      {required this.expanded, required this.selected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slot = pivSlot.slot;
    final certInfo = pivSlot.certInfo;
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final hasFeature = ref.watch(featureProvider);

    return AppListItem(
      pivSlot,
      selected: selected,
      key: _getAppListItemKey(slot),
      leading: CircleAvatar(
        foregroundColor: colorScheme.onSecondary,
        backgroundColor: colorScheme.secondary,
        child: const Icon(Icons.approval),
      ),
      title: slot.getDisplayName(l10n),
      subtitle: certInfo != null
          // Simplify subtitle by stripping "CN=", etc.
          ? certInfo.subject.replaceAll(RegExp(r'[A-Z]+='), ' ').trimLeft()
          : pivSlot.hasKey == true
              ? l10n.l_key_no_certificate
              : l10n.l_no_certificate,
      trailing: expanded
          ? null
          : OutlinedButton(
              key: _getMeatballKey(slot),
              onPressed: Actions.handler(context, OpenIntent(pivSlot)),
              child: const Icon(Icons.more_horiz),
            ),
      tapIntent: isDesktop && !expanded ? null : OpenIntent(pivSlot),
      doubleTapIntent: isDesktop && !expanded ? OpenIntent(pivSlot) : null,
      buildPopupActions: hasFeature(features.slots)
          ? (context) => buildSlotActions(pivSlot, l10n)
          : null,
    );
  }

  Key _getMeatballKey(SlotId slotId) => switch (slotId) {
        SlotId.authentication => meatballButton9a,
        SlotId.signature => meatballButton9c,
        SlotId.keyManagement => meatballButton9d,
        SlotId.cardAuth => meatballButton9e,
      };

  Key _getAppListItemKey(SlotId slotId) => switch (slotId) {
        SlotId.authentication => appListItem9a,
        SlotId.signature => appListItem9c,
        SlotId.keyManagement => appListItem9d,
        SlotId.cardAuth => appListItem9e
      };
}
