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
import '../../app/views/app_page.dart';
import '../../app/views/graphics.dart';
import '../../app/views/message_page.dart';
import '../../widgets/list_title.dart';
import '../models.dart';
import '../state.dart';
import 'add_fingerprint_dialog.dart';
import 'delete_credential_dialog.dart';
import 'delete_fingerprint_dialog.dart';
import 'pin_dialog.dart';
import 'rename_fingerprint_dialog.dart';
import 'reset_dialog.dart';

class FidoUnlockedPage extends ConsumerWidget {
  final DeviceNode node;
  final FidoState state;

  const FidoUnlockedPage(this.node, this.state, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    List<Widget> children = [];
    if (state.credMgmt) {
      final data = ref.watch(credentialProvider(node.path)).asData;
      if (data == null) {
        return _buildLoadingPage(context);
      }
      final creds = data.value;
      if (creds.isNotEmpty) {
        children.add(ListTitle(AppLocalizations.of(context)!.fido_credentials));
        children.addAll(
          creds.map(
            (cred) => ListTile(
              leading: CircleAvatar(
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: const Icon(Icons.person),
              ),
              title: Text(
                cred.userName,
                softWrap: false,
                overflow: TextOverflow.fade,
              ),
              subtitle: Text(
                cred.rpId,
                softWrap: false,
                overflow: TextOverflow.fade,
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                      onPressed: () {
                        showBlurDialog(
                          context: context,
                          builder: (context) =>
                              DeleteCredentialDialog(node.path, cred),
                        );
                      },
                      icon: const Icon(Icons.delete_outline)),
                ],
              ),
            ),
          ),
        );
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
        children
            .add(ListTitle(AppLocalizations.of(context)!.fido_fingerprints));
        children.addAll(fingerprints.map((fp) => ListTile(
              leading: CircleAvatar(
                foregroundColor: Theme.of(context).colorScheme.onSecondary,
                backgroundColor: Theme.of(context).colorScheme.secondary,
                child: const Icon(Icons.fingerprint),
              ),
              title: Text(
                fp.label,
                softWrap: false,
                overflow: TextOverflow.fade,
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                      onPressed: () {
                        showBlurDialog(
                          context: context,
                          builder: (context) =>
                              RenameFingerprintDialog(node.path, fp),
                        );
                      },
                      icon: const Icon(Icons.edit_outlined)),
                  IconButton(
                      onPressed: () {
                        showBlurDialog(
                          context: context,
                          builder: (context) =>
                              DeleteFingerprintDialog(node.path, fp),
                        );
                      },
                      icon: const Icon(Icons.delete_outline)),
                ],
              ),
            )));
      }
    }

    if (children.isNotEmpty) {
      return AppPage(
        title: Text(AppLocalizations.of(context)!.fido_webauthn),
        keyActionsBuilder: (context) =>
            _buildKeyActions(context, nFingerprints),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: children),
      );
    }

    if (state.bioEnroll != null) {
      return MessagePage(
        title: Text(AppLocalizations.of(context)!.fido_webauthn),
        graphic: noFingerprints,
        header: AppLocalizations.of(context)!.fido_no_fingerprints,
        message: AppLocalizations.of(context)!.fido_add_one_or_more,
        keyActionsBuilder: (context) => _buildKeyActions(context, 0),
      );
    }

    return MessagePage(
      title: Text(AppLocalizations.of(context)!.fido_webauthn),
      graphic: manageAccounts,
      header: AppLocalizations.of(context)!.fido_no_discoverable_acc,
      message: AppLocalizations.of(context)!.fido_register_as_a_key,
      keyActionsBuilder: (context) => _buildKeyActions(context, 0),
    );
  }

  Widget _buildLoadingPage(BuildContext context) => AppPage(
        title: Text(AppLocalizations.of(context)!.fido_webauthn),
        centered: true,
        delayedContent: true,
        child: const CircularProgressIndicator(),
      );

  Widget _buildKeyActions(BuildContext context, int fingerprints) {
    final theme =
        ButtonTheme.of(context).colorScheme ?? Theme.of(context).colorScheme;
    return SimpleDialog(children: [
      if (state.bioEnroll != null) ...[
        ListTitle('Setup', textStyle: Theme.of(context).textTheme.bodyLarge),
        ListTile(
          leading: const CircleAvatar(child: Icon(Icons.fingerprint_outlined)),
          title: Text(AppLocalizations.of(context)!.fido_add_fingerprint),
          subtitle: Text('$fingerprints/5 fingerprints registered'),
          enabled: fingerprints < 5,
          onTap: fingerprints < 5
              ? () {
                  Navigator.of(context).pop();
                  showBlurDialog(
                    context: context,
                    builder: (context) => AddFingerprintDialog(node.path),
                  );
                }
              : null,
        ),
      ],
      ListTitle('Manage', textStyle: Theme.of(context).textTheme.bodyLarge),
      ListTile(
        leading: const CircleAvatar(child: Icon(Icons.pin_outlined)),
        title: Text(AppLocalizations.of(context)!.fido_change_pin),
        subtitle: const Text('FIDO PIN protection'),
        onTap: () {
          Navigator.of(context).pop();
          showBlurDialog(
            context: context,
            builder: (context) => FidoPinDialog(node.path, state),
          );
        },
      ),
      ListTile(
        leading: CircleAvatar(
          foregroundColor: theme.onError,
          backgroundColor: theme.error,
          child: const Icon(Icons.delete_outline),
        ),
        title: Text(AppLocalizations.of(context)!.fido_reset_fido),
        subtitle: const Text('Factory reset this application'),
        onTap: () {
          Navigator.of(context).pop();
          showBlurDialog(
            context: context,
            builder: (context) => ResetDialog(node),
          );
        },
      ),
    ]);
  }
}
