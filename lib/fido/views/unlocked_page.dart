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
import '../../app/views/app_list_item.dart';
import '../../app/views/app_page.dart';
import '../../app/views/graphics.dart';
import '../../app/views/message_page.dart';
import '../../core/state.dart';
import '../../widgets/list_title.dart';
import '../models.dart';
import '../state.dart';
import '../features.dart' as features;
import 'actions.dart';
import 'credential_dialog.dart';
import 'delete_credential_dialog.dart';
import 'delete_fingerprint_dialog.dart';
import 'fingerprint_dialog.dart';
import 'key_actions.dart';
import 'rename_fingerprint_dialog.dart';

class FidoUnlockedPage extends ConsumerWidget {
  final DeviceNode node;
  final FidoState state;

  const FidoUnlockedPage(this.node, this.state, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final hasFeature = ref.watch(featureProvider);
    List<Widget> children = [];

    if (state.credMgmt) {
      final data = ref.watch(credentialProvider(node.path)).asData;
      if (data == null) {
        return _buildLoadingPage(context);
      }
      final creds = data.value;
      if (creds.isNotEmpty) {
        children.add(ListTitle(l10n.s_passkeys));
        children.addAll(creds.map((cred) => Actions(
              actions: {
                OpenIntent: CallbackAction<OpenIntent>(
                    onInvoke: (_) => showBlurDialog(
                          context: context,
                          barrierColor: Colors.transparent,
                          builder: (context) => CredentialDialog(cred),
                        )),
                if (hasFeature(features.credentialsDelete))
                  DeleteIntent: CallbackAction<DeleteIntent>(
                    onInvoke: (_) => showBlurDialog(
                      context: context,
                      builder: (context) => DeleteCredentialDialog(
                        node.path,
                        cred,
                      ),
                    ),
                  ),
              },
              child: _CredentialListItem(cred),
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
        children.add(ListTitle(l10n.s_fingerprints));
        children.addAll(fingerprints.map((fp) => Actions(
              actions: {
                OpenIntent: CallbackAction<OpenIntent>(
                    onInvoke: (_) => showBlurDialog(
                          context: context,
                          barrierColor: Colors.transparent,
                          builder: (context) => FingerprintDialog(fp),
                        )),
                if (hasFeature(features.fingerprintsEdit))
                  EditIntent: CallbackAction<EditIntent>(
                      onInvoke: (_) => showBlurDialog(
                            context: context,
                            builder: (context) => RenameFingerprintDialog(
                              node.path,
                              fp,
                            ),
                          )),
                if (hasFeature(features.fingerprintsDelete))
                  DeleteIntent: CallbackAction<DeleteIntent>(
                      onInvoke: (_) => showBlurDialog(
                            context: context,
                            builder: (context) => DeleteFingerprintDialog(
                              node.path,
                              fp,
                            ),
                          )),
              },
              child: _FingerprintListItem(fp),
            )));
      }
    }

    final hasActions = ref.watch(featureProvider)(features.actions);

    if (children.isNotEmpty) {
      return AppPage(
        title: Text(l10n.s_webauthn),
        keyActionsBuilder: hasActions
            ? (context) => fidoBuildActions(context, node, state, nFingerprints)
            : null,
        keyActionsBadge: fidoShowActionsNotifier(state),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: children),
      );
    }

    if (state.bioEnroll != null) {
      return MessagePage(
        title: Text(l10n.s_webauthn),
        graphic: noFingerprints,
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
      graphic: manageAccounts,
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
  const _CredentialListItem(this.credential);

  @override
  Widget build(BuildContext context) {
    return AppListItem(
      leading: CircleAvatar(
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.person),
      ),
      title: credential.userName,
      subtitle: credential.rpId,
      trailing: OutlinedButton(
        onPressed: Actions.handler(context, const OpenIntent()),
        child: const Icon(Icons.more_horiz),
      ),
      buildPopupActions: (context) =>
          buildCredentialActions(AppLocalizations.of(context)!),
    );
  }
}

class _FingerprintListItem extends StatelessWidget {
  final Fingerprint fingerprint;
  const _FingerprintListItem(this.fingerprint);

  @override
  Widget build(BuildContext context) {
    return AppListItem(
      leading: CircleAvatar(
        foregroundColor: Theme.of(context).colorScheme.onSecondary,
        backgroundColor: Theme.of(context).colorScheme.secondary,
        child: const Icon(Icons.fingerprint),
      ),
      title: fingerprint.label,
      trailing: OutlinedButton(
        onPressed: Actions.handler(context, const OpenIntent()),
        child: const Icon(Icons.more_horiz),
      ),
      buildPopupActions: (context) =>
          buildFingerprintActions(AppLocalizations.of(context)!),
    );
  }
}
