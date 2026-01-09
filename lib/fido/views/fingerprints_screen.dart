/*
 * Copyright (C) 2022-2025 Yubico.
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

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app/message.dart';
import '../../app/models.dart';
import '../../app/shortcuts.dart';
import '../../app/views/action_list.dart';
import '../../app/views/app_failure_page.dart';
import '../../app/views/app_list_item.dart';
import '../../app/views/app_page.dart';
import '../../app/views/message_page.dart';
import '../../app/views/message_page_not_initialized.dart';
import '../../core/models.dart';
import '../../core/state.dart';
import '../../exception/no_data_exception.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../management/models.dart';
import '../../widgets/list_title.dart';
import '../features.dart' as features;
import '../models.dart';
import '../state.dart';
import 'actions.dart';
import 'add_fingerprint_dialog.dart';
import 'fingerprint_dialog.dart';
import 'key_actions.dart';
import 'pin_dialog.dart';
import 'pin_entry_form.dart';

List<Capability> _getCapabilities(YubiKeyData deviceData) => [
  Capability.fido2,
  if (deviceData.info.config.enabledCapabilities[Transport.usb]! &
          Capability.piv.value !=
      0)
    Capability.piv,
];

class FingerprintsScreen extends ConsumerWidget {
  final YubiKeyData deviceData;

  const FingerprintsScreen(this.deviceData, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final capabilities = _getCapabilities(deviceData);
    return ref
        .watch(fidoStateProvider(deviceData.node.path))
        .when(
          loading: () => AppPage(
            title: l10n.s_fingerprints,
            capabilities: capabilities,
            centered: true,
            delayedContent: true,
            builder: (context, _) => const CircularProgressIndicator(),
          ),
          error: (error, _) {
            if (error is NoDataException) {
              return MessagePageNotInitialized(
                title: l10n.s_fingerprints,
                capabilities: capabilities,
              );
            }
            final enabled =
                deviceData.info.config.enabledCapabilities[deviceData
                    .node
                    .transport] ??
                0;
            if (Capability.fido2.value & enabled == 0) {
              return MessagePage(
                title: l10n.s_fingerprints,
                capabilities: capabilities,
                header: l10n.s_fido_disabled,
                message: l10n.l_webauthn_req_fido2,
              );
            }

            return AppFailurePage(cause: error);
          },
          data: (fidoState) {
            return fidoState.unlocked
                ? _FidoUnlockedPage(deviceData, fidoState)
                : _FidoLockedPage(deviceData, fidoState);
          },
        );
  }
}

class _FidoLockedPage extends ConsumerWidget {
  final YubiKeyData deviceData;
  final FidoState state;

  const _FidoLockedPage(this.deviceData, this.state);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final hasFeature = ref.watch(featureProvider);
    final hasActions = hasFeature(features.actions);

    final capabilities = [
      Capability.fido2,
      if (deviceData.info.config.enabledCapabilities[Transport.usb]! &
              Capability.piv.value !=
          0)
        Capability.piv,
    ];

    if (!state.hasPin) {
      return MessagePage(
        actionsBuilder: (context, expanded) => [
          if (!expanded)
            ActionChip(
              label: Text(l10n.s_set_pin),
              onPressed: () async {
                await showBlurDialog(
                  context: context,
                  builder: (context) =>
                      FidoPinDialog(deviceData.node.path, state),
                );
              },
              avatar: const Icon(Symbols.pin),
            ),
        ],
        title: l10n.s_fingerprints,
        capabilities: capabilities,
        header: l10n.s_fingerprints_get_started,
        message: l10n.p_set_fingerprints_desc,
        keyActionsBuilder: hasActions
            ? (context) => _buildActions(context, ref)
            : null,
        keyActionsBadge: fingerprintsShowActionsNotifier(state),
      );
    }

    if (state.forcePinChange) {
      return MessagePage(
        title: l10n.s_fingerprints,
        capabilities: capabilities,
        header: l10n.s_pin_change_required,
        message: l10n.l_pin_change_required_desc,
        keyActionsBuilder: hasActions
            ? (context) => _buildActions(context, ref)
            : null,
        keyActionsBadge: fingerprintsShowActionsNotifier(state),
        actionsBuilder: (context, expanded) => [
          if (!expanded)
            ActionChip(
              label: Text(l10n.s_change_pin),
              onPressed: () async {
                await showBlurDialog(
                  context: context,
                  builder: (context) =>
                      FidoPinDialog(deviceData.node.path, state),
                );
              },
              avatar: const Icon(Symbols.pin),
            ),
        ],
      );
    }

    return AppPage(
      title: l10n.s_fingerprints,
      capabilities: capabilities,
      keyActionsBuilder: hasActions
          ? (context) => _buildActions(context, ref)
          : null,
      builder: (context, _) =>
          Column(children: [PinEntryForm(state, deviceData)]),
    );
  }

  Widget _buildActions(BuildContext context, WidgetRef ref) =>
      fingerprintsBuildActions(context, ref, deviceData.node, state, -1);
}

class _FidoUnlockedPage extends ConsumerStatefulWidget {
  final YubiKeyData deviceData;
  final FidoState state;

  _FidoUnlockedPage(this.deviceData, this.state)
    : super(key: ObjectKey(deviceData.node.path));

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _FidoUnlockedPageState();
}

class _FidoUnlockedPageState extends ConsumerState<_FidoUnlockedPage> {
  Fingerprint? _selected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasFeature = ref.watch(featureProvider);
    final hasActions = hasFeature(features.actions);
    final capabilities = _getCapabilities(widget.deviceData);

    final data = ref
        .watch(fingerprintProvider(widget.deviceData.node.path))
        .asData;
    if (data == null) {
      return _buildLoadingPage(context, capabilities);
    }
    final fingerprints = data.value;
    if (fingerprints.isEmpty) {
      return MessagePage(
        actionsBuilder: (context, expanded) => [
          if (!expanded)
            ActionChip(
              label: Text(l10n.s_add_fingerprint),
              onPressed: () async {
                await showBlurDialog(
                  context: context,
                  builder: (context) =>
                      AddFingerprintDialog(widget.deviceData.node.path),
                );
              },
              avatar: const Icon(Symbols.fingerprint),
            ),
        ],
        title: l10n.s_fingerprints,
        capabilities: capabilities,
        header: l10n.s_fingerprints_get_started,
        message: l10n.l_add_one_or_more_fps,
        keyActionsBuilder: hasActions
            ? (context) => fingerprintsBuildActions(
                context,
                ref,
                widget.deviceData.node,
                widget.state,
                0,
              )
            : null,
        keyActionsBadge: fingerprintsShowActionsNotifier(widget.state),
      );
    }

    final fingerprint = _selected;
    return FidoActions(
      devicePath: widget.deviceData.node.path,
      state: widget.state,
      actions: (context) => {
        EscapeIntent: CallbackAction<EscapeIntent>(
          onInvoke: (intent) {
            if (_selected != null) {
              setState(() {
                _selected = null;
              });
            } else {
              Actions.invoke(context, intent);
            }
            return false;
          },
        ),
        OpenIntent<Fingerprint>: CallbackAction<OpenIntent<Fingerprint>>(
          onInvoke: (intent) {
            return showBlurDialog(
              context: context,
              barrierColor: Colors.transparent,
              builder: (context) =>
                  FingerprintDialog(intent.target, state: widget.state),
            );
          },
        ),
        if (hasFeature(features.fingerprintsEdit))
          EditIntent<Fingerprint>: CallbackAction<EditIntent<Fingerprint>>(
            onInvoke: (intent) async {
              final renamed =
                  await (Actions.invoke(context, intent) as Future<dynamic>?);
              if (_selected == intent.target && renamed is Fingerprint) {
                setState(() {
                  _selected = renamed;
                });
              }
              return renamed;
            },
          ),
        if (hasFeature(features.fingerprintsDelete))
          DeleteIntent<Fingerprint>: CallbackAction<DeleteIntent<Fingerprint>>(
            onInvoke: (intent) async {
              final deleted =
                  await (Actions.invoke(context, intent) as Future<dynamic>?);
              if (deleted == true && _selected == intent.target) {
                setState(() {
                  _selected = null;
                });
              }
              return deleted;
            },
          ),
      },
      builder: (context) => AppPage(
        title: l10n.s_fingerprints,
        capabilities: capabilities,
        detailViewBuilder: fingerprint != null
            ? (context) => Column(
                crossAxisAlignment: .stretch,
                children: [
                  ListTitle(l10n.s_details),
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: Card(
                      elevation: 0.0,
                      color: Theme.of(context).hoverColor,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 24,
                          horizontal: 16,
                        ),
                        // TODO: Reuse from fingerprint_dialog
                        child: Column(
                          children: [
                            Text(
                              fingerprint.label,
                              style: Theme.of(context).textTheme.headlineSmall,
                              softWrap: true,
                              textAlign: .center,
                            ),
                            const SizedBox(height: 16),
                            const Icon(Symbols.fingerprint, size: 72),
                          ],
                        ),
                      ),
                    ),
                  ),
                  ActionListSection.fromMenuActions(
                    context,
                    l10n.s_actions,
                    actions: buildFingerprintActions(fingerprint, l10n),
                  ),
                ],
              )
            : null,
        keyActionsBuilder: hasActions
            ? (context) => fingerprintsBuildActions(
                context,
                ref,
                widget.deviceData.node,
                widget.state,
                fingerprints.length,
              )
            : null,
        keyActionsBadge: fingerprintsShowActionsNotifier(widget.state),
        builder: (context, expanded) {
          // De-select if window is resized to be non-expanded.
          if (!expanded && _selected != null) {
            Timer.run(() {
              setState(() {
                _selected = null;
              });
            });
          }
          return Actions(
            actions: {
              if (expanded) ...{
                OpenIntent<Fingerprint>:
                    CallbackAction<OpenIntent<Fingerprint>>(
                      onInvoke: (intent) {
                        setState(() {
                          _selected = intent.target;
                        });
                        return null;
                      },
                    ),
              },
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Column(
                crossAxisAlignment: .start,
                children: fingerprints
                    .map(
                      (fp) => _FingerprintListItem(
                        fp,
                        expanded: expanded,
                        selected: fp == _selected,
                      ),
                    )
                    .toList(),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingPage(
    BuildContext context,
    List<Capability> capabilities,
  ) => AppPage(
    title: AppLocalizations.of(context).s_fingerprints,
    capabilities: capabilities,
    centered: true,
    delayedContent: true,
    builder: (context, _) => const CircularProgressIndicator(),
  );
}

class _FingerprintListItem extends StatelessWidget {
  final Fingerprint fingerprint;
  final bool selected;
  final bool expanded;

  const _FingerprintListItem(
    this.fingerprint, {
    required this.expanded,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return AppListItem(
      fingerprint,
      selected: selected,
      leading: CircleAvatar(
        foregroundColor: Theme.of(context).colorScheme.onSecondary,
        backgroundColor: Theme.of(context).colorScheme.secondary,
        child: const Icon(Symbols.fingerprint),
      ),
      title: fingerprint.label,
      trailing: expanded
          ? null
          : OutlinedButton(
              onPressed: Actions.handler(context, OpenIntent(fingerprint)),
              child: const Icon(Symbols.more_horiz),
            ),
      tapIntent: isDesktop && !expanded ? null : OpenIntent(fingerprint),
      doubleTapIntent: isDesktop && !expanded ? OpenIntent(fingerprint) : null,
      buildPopupActions: (context) =>
          buildFingerprintActions(fingerprint, AppLocalizations.of(context)),
    );
  }
}
