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
import '../../app/views/action_list.dart';
import '../../app/views/app_list_item.dart';
import '../../app/views/app_page.dart';
import '../../app/views/message_page.dart';
import '../../core/state.dart';
import '../../widgets/list_title.dart';
import '../features.dart' as features;
import '../models.dart';
import '../state.dart';
import 'actions.dart';
import 'credential_dialog.dart';
import 'fingerprint_dialog.dart';
import 'key_actions.dart';

class FidoUnlockedPage extends ConsumerStatefulWidget {
  final DeviceNode node;
  final FidoState state;

  FidoUnlockedPage(this.node, this.state) : super(key: ObjectKey(node.path));

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _FidoUnlockedPageState();
}

class _FidoUnlockedPageState extends ConsumerState<FidoUnlockedPage> {
  Object? _selected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    List<Widget Function(bool expanded)> children = [];

    if (widget.state.credMgmt) {
      final data = ref.watch(credentialProvider(widget.node.path)).asData;
      if (data == null) {
        return _buildLoadingPage(context);
      }
      final creds = data.value;
      if (creds.isNotEmpty) {
        children.add((_) => ListTitle(l10n.s_passkeys));
        children.addAll(creds.map(
          (cred) => (expanded) => _CredentialListItem(
                cred,
                expanded: expanded,
                selected: _selected == cred,
              ),
        ));
      }
    }

    int nFingerprints = 0;
    if (widget.state.bioEnroll != null) {
      final data = ref.watch(fingerprintProvider(widget.node.path)).asData;
      if (data == null) {
        return _buildLoadingPage(context);
      }
      final fingerprints = data.value;
      if (fingerprints.isNotEmpty) {
        nFingerprints = fingerprints.length;
        children.add((_) => ListTitle(l10n.s_fingerprints));
        children.addAll(fingerprints.map(
          (fp) => (expanded) => _FingerprintListItem(
                fp,
                expanded: expanded,
                selected: fp == _selected,
              ),
        ));
      }
    }

    final hasFeature = ref.watch(featureProvider);
    final hasActions = hasFeature(features.actions);

    if (children.isNotEmpty) {
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
          OpenIntent<Fingerprint>:
              CallbackAction<OpenIntent<Fingerprint>>(onInvoke: (intent) {
            return showBlurDialog(
              context: context,
              barrierColor: Colors.transparent,
              builder: (context) => FingerprintDialog(intent.target),
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
            }),
          if (hasFeature(features.fingerprintsDelete))
            DeleteIntent<Fingerprint>:
                CallbackAction<DeleteIntent<Fingerprint>>(
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
          title: Text(l10n.s_webauthn),
          detailViewBuilder: switch (_selected) {
            FidoCredential credential => (context) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ListTitle(l10n.s_details),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        // TODO: Reuse from credential_dialog
                        child: Column(
                          children: [
                            Text(
                              credential.userName,
                              style: Theme.of(context).textTheme.headlineSmall,
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
                            const Icon(Icons.person, size: 72),
                          ],
                        ),
                      ),
                    ),
                    ActionListSection.fromMenuActions(
                      context,
                      l10n.s_actions,
                      actions: buildCredentialActions(credential, l10n),
                    ),
                  ],
                ),
            Fingerprint fingerprint => (context) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ListTitle(l10n.s_details),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        // TODO: Reuse from fingerprint_dialog
                        child: Column(
                          children: [
                            Text(
                              fingerprint.label,
                              style: Theme.of(context).textTheme.headlineSmall,
                              softWrap: true,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            const Icon(Icons.fingerprint, size: 72),
                          ],
                        ),
                      ),
                    ),
                    ActionListSection.fromMenuActions(
                      context,
                      l10n.s_actions,
                      actions: buildFingerprintActions(fingerprint, l10n),
                    ),
                  ],
                ),
            _ => null
          },
          keyActionsBuilder: hasActions
              ? (context) => fidoBuildActions(
                  context, widget.node, widget.state, nFingerprints)
              : null,
          keyActionsBadge: fidoShowActionsNotifier(widget.state),
          builder: (context, expanded) => Actions(
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
                OpenIntent<Fingerprint>:
                    CallbackAction<OpenIntent<Fingerprint>>(onInvoke: (intent) {
                  setState(() {
                    _selected = intent.target;
                  });
                  return null;
                }),
              }
            },
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children.map((f) => f(expanded)).toList()),
          ),
        ),
      );
    }

    if (widget.state.bioEnroll != null) {
      return MessagePage(
        title: Text(l10n.s_webauthn),
        graphic: Icon(Icons.fingerprint,
            size: 96, color: Theme.of(context).colorScheme.primary),
        header: l10n.s_no_fingerprints,
        message: l10n.l_add_one_or_more_fps,
        keyActionsBuilder: hasActions
            ? (context) =>
                fidoBuildActions(context, widget.node, widget.state, 0)
            : null,
        keyActionsBadge: fidoShowActionsNotifier(widget.state),
      );
    }

    return MessagePage(
      title: Text(l10n.s_webauthn),
      graphic: Icon(Icons.security,
          size: 96, color: Theme.of(context).colorScheme.primary),
      header: l10n.l_no_discoverable_accounts,
      message: l10n.l_register_sk_on_websites,
      keyActionsBuilder: hasActions
          ? (context) => fidoBuildActions(context, widget.node, widget.state, 0)
          : null,
      keyActionsBadge: fidoShowActionsNotifier(widget.state),
    );
  }

  Widget _buildLoadingPage(BuildContext context) => AppPage(
        title: Text(AppLocalizations.of(context)!.s_webauthn),
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
        child: const Icon(Icons.person),
      ),
      title: credential.userName,
      subtitle: credential.rpId,
      trailing: expanded
          ? null
          : OutlinedButton(
              onPressed: Actions.handler(context, OpenIntent(credential)),
              child: const Icon(Icons.more_horiz),
            ),
      tapIntent: isDesktop && !expanded ? null : OpenIntent(credential),
      doubleTapIntent: isDesktop && !expanded ? OpenIntent(credential) : null,
      buildPopupActions: (context) =>
          buildCredentialActions(credential, AppLocalizations.of(context)!),
    );
  }
}

class _FingerprintListItem extends StatelessWidget {
  final Fingerprint fingerprint;
  final bool selected;
  final bool expanded;

  const _FingerprintListItem(this.fingerprint,
      {required this.expanded, required this.selected});

  @override
  Widget build(BuildContext context) {
    return AppListItem(
      fingerprint,
      selected: selected,
      leading: CircleAvatar(
        foregroundColor: Theme.of(context).colorScheme.onSecondary,
        backgroundColor: Theme.of(context).colorScheme.secondary,
        child: const Icon(Icons.fingerprint),
      ),
      title: fingerprint.label,
      trailing: expanded
          ? null
          : OutlinedButton(
              onPressed: Actions.handler(context, OpenIntent(fingerprint)),
              child: const Icon(Icons.more_horiz),
            ),
      tapIntent: isDesktop && !expanded ? null : OpenIntent(fingerprint),
      doubleTapIntent: isDesktop && !expanded ? OpenIntent(fingerprint) : null,
      buildPopupActions: (context) =>
          buildFingerprintActions(fingerprint, AppLocalizations.of(context)!),
    );
  }
}
