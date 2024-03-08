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
import 'package:material_symbols_icons/symbols.dart';

import '../../app/message.dart';
import '../../app/models.dart';
import '../../app/shortcuts.dart';
import '../../app/state.dart';
import '../../app/views/action_list.dart';
import '../../app/views/app_failure_page.dart';
import '../../app/views/app_list_item.dart';
import '../../app/views/app_page.dart';
import '../../app/views/message_page.dart';
import '../../core/state.dart';
import '../../management/models.dart';
import '../../widgets/list_title.dart';
import '../features.dart' as features;
import '../models.dart';
import '../state.dart';
import 'actions.dart';
import 'credential_dialog.dart';
import 'key_actions.dart';
import 'pin_dialog.dart';
import 'pin_entry_form.dart';

class PasskeysScreen extends ConsumerWidget {
  final YubiKeyData deviceData;
  const PasskeysScreen(this.deviceData, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return ref.watch(fidoStateProvider(deviceData.node.path)).when(
        loading: () => AppPage(
              centered: true,
              delayedContent: true,
              builder: (context, _) => const CircularProgressIndicator(),
            ),
        error: (error, _) {
          final enabled = deviceData
                  .info.config.enabledCapabilities[deviceData.node.transport] ??
              0;

          if (Capability.fido2.value & enabled == 0) {
            return MessagePage(
              title: l10n.s_passkeys,
              capabilities: const [Capability.fido2],
              header: l10n.s_fido_disabled,
              message: l10n.l_webauthn_req_fido2,
            );
          }

          return AppFailurePage(
            cause: error,
          );
        },
        data: (fidoState) {
          return fidoState.unlocked
              ? _FidoUnlockedPage(deviceData.node, fidoState)
              : _FidoLockedPage(deviceData.node, fidoState);
        });
  }
}

class _FidoLockedPage extends ConsumerWidget {
  final DeviceNode node;
  final FidoState state;

  const _FidoLockedPage(this.node, this.state);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final hasFeature = ref.watch(featureProvider);
    final hasActions = hasFeature(features.actions);
    final isBio = state.bioEnroll != null;
    final alwaysUv = state.alwaysUv;

    if (!state.hasPin) {
      return MessagePage(
        title: l10n.s_passkeys,
        capabilities: const [Capability.fido2],
        actionsBuilder: (context, expanded) {
          return [
            if (isBio)
              ActionChip(
                label: Text(l10n.s_setup_fingerprints),
                onPressed: () async {
                  ref
                      .read(currentSectionProvider.notifier)
                      .setCurrentSection(Section.fingerprints);
                },
                avatar: const Icon(Symbols.fingerprint),
              ),
            if (!isBio && alwaysUv && !expanded)
              ActionChip(
                label: Text(l10n.s_set_pin),
                onPressed: () async {
                  await showBlurDialog(
                      context: context,
                      builder: (context) => FidoPinDialog(node.path, state));
                },
                avatar: const Icon(Symbols.pin),
              )
          ];
        },
        header: state.credMgmt
            ? l10n.l_no_discoverable_accounts
            : l10n.l_ready_to_use,
        message: isBio
            ? l10n.p_setup_fingerprints_desc
            : alwaysUv
                ? l10n.l_pin_change_required_desc
                : l10n.l_register_sk_on_websites,
        footnote: isBio ? null : l10n.l_non_passkeys_note,
        keyActionsBuilder: hasActions ? _buildActions : null,
        keyActionsBadge: passkeysShowActionsNotifier(state),
      );
    }

    if (!state.credMgmt && !isBio) {
      return MessagePage(
        title: l10n.s_passkeys,
        capabilities: const [Capability.fido2],
        header: l10n.l_ready_to_use,
        message: l10n.l_register_sk_on_websites,
        footnote: l10n.l_non_passkeys_note,
        keyActionsBuilder: hasActions ? _buildActions : null,
        keyActionsBadge: passkeysShowActionsNotifier(state),
      );
    }

    if (state.forcePinChange) {
      return MessagePage(
        actionsBuilder: (context, expanded) => [
          if (!expanded)
            ActionChip(
              label: Text(l10n.s_change_pin),
              onPressed: () async {
                await showBlurDialog(
                    context: context,
                    builder: (context) => FidoPinDialog(node.path, state));
              },
              avatar: const Icon(Symbols.pin),
            )
        ],
        title: l10n.s_passkeys,
        capabilities: const [Capability.fido2],
        header: l10n.s_pin_change_required,
        message: l10n.l_pin_change_required_desc,
        keyActionsBuilder: hasActions ? _buildActions : null,
        keyActionsBadge: passkeysShowActionsNotifier(state),
      );
    }

    return AppPage(
      title: l10n.s_passkeys,
      capabilities: const [Capability.fido2],
      keyActionsBuilder: hasActions ? _buildActions : null,
      builder: (context, _) => Column(
        children: [
          PinEntryForm(state, node),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) =>
      passkeysBuildActions(context, node, state);
}

class _FidoUnlockedPage extends ConsumerStatefulWidget {
  final DeviceNode node;
  final FidoState state;

  _FidoUnlockedPage(this.node, this.state) : super(key: ObjectKey(node.path));

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _FidoUnlockedPageState();
}

class _FidoUnlockedPageState extends ConsumerState<_FidoUnlockedPage> {
  FidoCredential? _selected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasFeature = ref.watch(featureProvider);
    final hasActions = hasFeature(features.actions);
    final noFingerprints = widget.state.bioEnroll == false;

    if (!widget.state.credMgmt) {
      // TODO: Special handling for credMgmt not supported
      return MessagePage(
        title: l10n.s_passkeys,
        capabilities: const [Capability.fido2],
        header: l10n.l_no_discoverable_accounts,
        message: l10n.l_register_sk_on_websites,
        footnote: l10n.l_non_passkeys_note,
        keyActionsBuilder: hasActions
            ? (context) =>
                passkeysBuildActions(context, widget.node, widget.state)
            : null,
        keyActionsBadge: passkeysShowActionsNotifier(widget.state),
      );
    }

    final data = ref.watch(credentialProvider(widget.node.path)).asData;
    if (data == null) {
      return _buildLoadingPage(context);
    }
    final credentials = data.value;

    if (credentials.isEmpty) {
      return MessagePage(
        title: l10n.s_passkeys,
        capabilities: const [Capability.fido2],
        actionsBuilder: noFingerprints
            ? (context, expanded) {
                return [
                  ActionChip(
                    label: Text(l10n.s_setup_fingerprints),
                    onPressed: () async {
                      ref
                          .read(currentSectionProvider.notifier)
                          .setCurrentSection(Section.fingerprints);
                    },
                    avatar: const Icon(Symbols.fingerprint),
                  )
                ];
              }
            : null,
        header: l10n.l_no_discoverable_accounts,
        message: noFingerprints
            ? l10n.p_setup_fingerprints_desc
            : l10n.l_register_sk_on_websites,
        keyActionsBuilder: hasActions
            ? (context) =>
                passkeysBuildActions(context, widget.node, widget.state)
            : null,
        keyActionsBadge: passkeysShowActionsNotifier(widget.state),
        footnote: l10n.l_non_passkeys_note,
      );
    }

    final credential = _selected;
    return FidoActions(
      devicePath: widget.node.path,
      actions: (context) => {
        EscapeIntent: CallbackAction<EscapeIntent>(onInvoke: (intent) {
          if (_selected != null) {
            setState(() {
              _selected = null;
            });
          } else {
            Actions.invoke(context, intent);
          }
          return false;
        }),
        OpenIntent<FidoCredential>:
            CallbackAction<OpenIntent<FidoCredential>>(onInvoke: (intent) {
          return showBlurDialog(
            context: context,
            barrierColor: Colors.transparent,
            builder: (context) => CredentialDialog(intent.target),
          );
        }),
        if (hasFeature(features.credentialsDelete))
          DeleteIntent<FidoCredential>:
              CallbackAction<DeleteIntent<FidoCredential>>(
                  onInvoke: (intent) async {
            final deleted =
                await (Actions.invoke(context, intent) as Future<dynamic>?);
            if (deleted == true && _selected == intent.target) {
              setState(() {
                _selected = null;
              });
            }
            return deleted;
          }),
      },
      builder: (context) => AppPage(
        title: l10n.s_passkeys,
        capabilities: const [Capability.fido2],
        footnote: l10n.l_non_passkeys_note,
        detailViewBuilder: credential != null
            ? (context) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ListTitle(l10n.s_details),
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: Card(
                        elevation: 0.0,
                        color: Theme.of(context).hoverColor,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          // TODO: Reuse from credential_dialog
                          child: Column(
                            children: [
                              Text(
                                credential.userName,
                                style:
                                    Theme.of(context).textTheme.headlineSmall,
                                softWrap: true,
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                credential.rpId,
                                softWrap: true,
                                textAlign: TextAlign.center,
                                // This is what ListTile uses for subtitle
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium!
                                    .copyWith(
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodySmall!
                                          .color,
                                    ),
                              ),
                              const SizedBox(height: 16),
                              const Icon(Symbols.person, size: 72),
                            ],
                          ),
                        ),
                      ),
                    ),
                    ActionListSection.fromMenuActions(
                      context,
                      l10n.s_actions,
                      actions: buildCredentialActions(credential, l10n),
                    ),
                  ],
                )
            : null,
        keyActionsBuilder: hasActions
            ? (context) =>
                passkeysBuildActions(context, widget.node, widget.state)
            : null,
        keyActionsBadge: passkeysShowActionsNotifier(widget.state),
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
                OpenIntent<FidoCredential>:
                    CallbackAction<OpenIntent<FidoCredential>>(
                        onInvoke: (intent) {
                  setState(() {
                    _selected = intent.target;
                  });
                  return null;
                }),
              }
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: credentials
                  .map(
                    (cred) => _CredentialListItem(
                      cred,
                      expanded: expanded,
                      selected: _selected == cred,
                    ),
                  )
                  .toList(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingPage(BuildContext context) => AppPage(
        centered: true,
        delayedContent: true,
        builder: (context, _) => const CircularProgressIndicator(),
      );
}

class _CredentialListItem extends StatelessWidget {
  final FidoCredential credential;
  final bool selected;
  final bool expanded;

  const _CredentialListItem(this.credential,
      {required this.expanded, required this.selected});

  @override
  Widget build(BuildContext context) {
    return AppListItem(
      credential,
      selected: selected,
      leading: CircleAvatar(
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Symbols.person),
      ),
      title: credential.userName,
      subtitle: credential.rpId,
      trailing: expanded
          ? null
          : OutlinedButton(
              onPressed: Actions.handler(context, OpenIntent(credential)),
              child: const Icon(Symbols.more_horiz),
            ),
      tapIntent: isDesktop && !expanded ? null : OpenIntent(credential),
      doubleTapIntent: isDesktop && !expanded ? OpenIntent(credential) : null,
      buildPopupActions: (context) =>
          buildCredentialActions(credential, AppLocalizations.of(context)!),
    );
  }
}
