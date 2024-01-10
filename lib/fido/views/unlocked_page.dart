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
import '../../app/state.dart';
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
import 'delete_credential_dialog.dart';
import 'delete_fingerprint_dialog.dart';
import 'fingerprint_dialog.dart';
import 'key_actions.dart';
import 'rename_fingerprint_dialog.dart';

final _selectedItem = StateProvider<Object?>(
  (ref) => null,
);

Widget _registerFingerprintActions(
  DevicePath devicePath,
  Fingerprint fingerprint, {
  required WidgetRef ref,
  required Widget Function(BuildContext context) builder,
  Map<Type, Action<Intent>> actions = const {},
}) {
  final hasFeature = ref.watch(featureProvider);
  return Actions(
    actions: {
      if (hasFeature(features.fingerprintsEdit))
        EditIntent: CallbackAction<EditIntent>(onInvoke: (_) async {
          final renamed = await ref.read(withContextProvider)(
              (context) => showBlurDialog<Fingerprint>(
                    context: context,
                    builder: (context) => RenameFingerprintDialog(
                      devicePath,
                      fingerprint,
                    ),
                  ));
          if (renamed != null && ref.read(_selectedItem) == fingerprint) {
            ref.read(_selectedItem.notifier).state = renamed;
          }
          return renamed;
        }),
      if (hasFeature(features.fingerprintsDelete))
        DeleteIntent: CallbackAction<DeleteIntent>(onInvoke: (_) async {
          final deleted = await ref.read(withContextProvider)(
              (context) => showBlurDialog<bool?>(
                    context: context,
                    builder: (context) => DeleteFingerprintDialog(
                      devicePath,
                      fingerprint,
                    ),
                  ));
          if (deleted == true && ref.read(_selectedItem) == fingerprint) {
            ref.read(_selectedItem.notifier).state = null;
          }
          return deleted;
        }),
      ...actions,
    },
    child: Builder(builder: builder),
  );
}

Widget _registerCredentialActions(
  DevicePath devicePath,
  FidoCredential credential, {
  required WidgetRef ref,
  required Widget Function(BuildContext context) builder,
  Map<Type, Action<Intent>> actions = const {},
}) {
  final hasFeature = ref.watch(featureProvider);
  return Actions(
    actions: {
      if (hasFeature(features.credentialsDelete))
        DeleteIntent: CallbackAction<DeleteIntent>(onInvoke: (_) async {
          final deleted = await ref.read(withContextProvider)(
            (context) => showBlurDialog<bool?>(
              context: context,
              builder: (context) => DeleteCredentialDialog(
                devicePath,
                credential,
              ),
            ),
          );
          if (deleted == true && ref.read(_selectedItem) == credential) {
            ref.read(_selectedItem.notifier).state = null;
          }
          return deleted;
        }),
      ...actions,
    },
    child: Builder(builder: builder),
  );
}

class FidoUnlockedPage extends ConsumerWidget {
  final DeviceNode node;
  final FidoState state;

  const FidoUnlockedPage(this.node, this.state, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final selected = ref.watch(_selectedItem);
    List<Widget Function(bool expanded)> children = [];

    if (state.credMgmt) {
      final data = ref.watch(credentialProvider(node.path)).asData;
      if (data == null) {
        return _buildLoadingPage(context);
      }
      final creds = data.value;
      if (creds.isNotEmpty) {
        children.add((_) => ListTitle(l10n.s_passkeys));
        children.addAll(
            creds.map((cred) => (expanded) => _registerCredentialActions(
                  node.path,
                  cred,
                  ref: ref,
                  actions: {
                    OpenIntent: CallbackAction<OpenIntent>(onInvoke: (_) {
                      if (expanded) {
                        ref.read(_selectedItem.notifier).state = cred;
                        return null;
                      } else {
                        return showBlurDialog(
                          context: context,
                          barrierColor: Colors.transparent,
                          builder: (context) => CredentialDialog(cred),
                        );
                      }
                    }),
                  },
                  builder: (context) => _CredentialListItem(
                    cred,
                    expanded: expanded,
                    selected: selected == cred,
                  ),
                )));
      }
    }

    int nFingerprints = 0;
    if (state.bioEnroll != null) {
      final data = ref.watch(fingerprintProvider(node.path)).asData;
      if (data == null) {
        return _buildLoadingPage(context);
      }
      final fingerprints = data.value;
      if (fingerprints.isNotEmpty) {
        nFingerprints = fingerprints.length;
        children.add((_) => ListTitle(l10n.s_fingerprints));
        children.addAll(
            fingerprints.map((fp) => (expanded) => _registerFingerprintActions(
                  node.path,
                  fp,
                  ref: ref,
                  actions: {
                    OpenIntent: CallbackAction<OpenIntent>(onInvoke: (_) {
                      if (expanded) {
                        ref.read(_selectedItem.notifier).state = fp;
                        return null;
                      } else {
                        return showBlurDialog(
                          context: context,
                          barrierColor: Colors.transparent,
                          builder: (context) => FingerprintDialog(fp),
                        );
                      }
                    }),
                  },
                  builder: (context) => _FingerprintListItem(
                    fp,
                    expanded: expanded,
                    selected: fp == selected,
                  ),
                )));
      }
    }

    final hasActions = ref.watch(featureProvider)(features.actions);

    if (children.isNotEmpty) {
      return Actions(
        actions: {
          EscapeIntent: CallbackAction<EscapeIntent>(onInvoke: (intent) {
            if (selected != null) {
              ref.read(_selectedItem.notifier).state = null;
            } else {
              Actions.invoke(context, intent);
            }
            return false;
          }),
        },
        child: AppPage(
          title: Text(l10n.s_webauthn),
          keyActionsBuilder: switch (selected) {
            FidoCredential credential => (context) =>
                _registerCredentialActions(node.path, credential,
                    ref: ref,
                    builder: (context) => Column(
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
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall,
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
                              actions: buildCredentialActions(l10n),
                            ),
                          ],
                        )),
            Fingerprint fingerprint => (context) => _registerFingerprintActions(
                  node.path,
                  fingerprint,
                  ref: ref,
                  builder: (context) => Column(
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
                                style:
                                    Theme.of(context).textTheme.headlineSmall,
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
                        actions: buildFingerprintActions(l10n),
                      ),
                    ],
                  ),
                ),
            _ => hasActions
                ? (context) =>
                    fidoBuildActions(context, node, state, nFingerprints)
                : null
          },
          keyActionsBadge: fidoShowActionsNotifier(state),
          builder: (context, expanded) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children.map((f) => f(expanded)).toList()),
        ),
      );
    }

    if (state.bioEnroll != null) {
      return MessagePage(
        title: Text(l10n.s_webauthn),
        graphic: Icon(Icons.fingerprint,
            size: 96, color: Theme.of(context).colorScheme.primary),
        header: l10n.s_no_fingerprints,
        message: l10n.l_add_one_or_more_fps,
        keyActionsBuilder: hasActions
            ? (context) => fidoBuildActions(context, node, state, 0)
            : null,
        keyActionsBadge: fidoShowActionsNotifier(state),
      );
    }

    return MessagePage(
      title: Text(l10n.s_webauthn),
      graphic: Icon(Icons.security,
          size: 96, color: Theme.of(context).colorScheme.primary),
      header: l10n.l_no_discoverable_accounts,
      message: l10n.l_register_sk_on_websites,
      keyActionsBuilder: hasActions
          ? (context) => fidoBuildActions(context, node, state, 0)
          : null,
      keyActionsBadge: fidoShowActionsNotifier(state),
    );
  }

  Widget _buildLoadingPage(BuildContext context) => AppPage(
        title: Text(AppLocalizations.of(context)!.s_webauthn),
        centered: true,
        delayedContent: true,
        child: const CircularProgressIndicator(),
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
              onPressed: Actions.handler(context, const OpenIntent()),
              child: const Icon(Icons.more_horiz),
            ),
      openOnSingleTap: expanded,
      buildPopupActions: (context) =>
          buildCredentialActions(AppLocalizations.of(context)!),
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
              onPressed: Actions.handler(context, const OpenIntent()),
              child: const Icon(Icons.more_horiz),
            ),
      openOnSingleTap: expanded,
      buildPopupActions: (context) =>
          buildFingerprintActions(AppLocalizations.of(context)!),
    );
  }
}
