/*
 * Copyright (C) 2022-2023 Yubico.
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

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/message.dart';
import '../../app/shortcuts.dart';
import '../../app/state.dart';
import '../../app/views/app_list_item.dart';
import '../../core/state.dart';
import '../features.dart' as features;
import '../models.dart';
import '../state.dart';
import 'account_dialog.dart';
import 'account_helper.dart';
import 'account_icon.dart';
import 'actions.dart';
import 'delete_account_dialog.dart';
import 'rename_account_dialog.dart';

class AccountView extends ConsumerStatefulWidget {
  final OathCredential credential;
  const AccountView(this.credential, {super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _AccountViewState();
}

String _a11yCredentialLabel(String? issuer, String name, String? code) {
  return [issuer, name, code].whereNotNull().join(' ');
}

class _AccountViewState extends ConsumerState<AccountView> {
  OathCredential get credential => widget.credential;

  Color _iconColor(int shade) {
    final colors = [
      Colors.red[shade],
      Colors.pink[shade],
      Colors.purple[shade],
      Colors.deepPurple[shade],
      Colors.indigo[shade],
      Colors.blue[shade],
      Colors.lightBlue[shade],
      Colors.cyan[shade],
      Colors.teal[shade],
      Colors.green[shade],
      Colors.lightGreen[shade],
      Colors.lime[shade],
      Colors.yellow[shade],
      Colors.amber[shade],
      Colors.orange[shade],
      Colors.deepOrange[shade],
      Colors.brown[shade],
      Colors.grey[shade],
      Colors.blueGrey[shade],
    ];

    final label = credential.issuer != null
        ? '${credential.issuer} (${credential.name})'
        : credential.name;

    return colors[label.hashCode % colors.length]!;
  }

  @override
  Widget build(BuildContext context) {
    final hasFeature = ref.watch(featureProvider);

    return registerOathActions(
      credential,
      ref: ref,
      actions: {
        OpenIntent: CallbackAction<OpenIntent>(onInvoke: (_) async {
          await showBlurDialog(
            context: context,
            barrierColor: Colors.transparent,
            builder: (context) => AccountDialog(credential),
          );
          return null;
        }),
        if (hasFeature(features.accountsRename))
          EditIntent: CallbackAction<EditIntent>(onInvoke: (_) async {
            final node = ref.read(currentDeviceProvider)!;
            final credentials = ref.read(credentialsProvider);
            final withContext = ref.read(withContextProvider);
            return await withContext((context) async => await showBlurDialog(
                  context: context,
                  builder: (context) => RenameAccountDialog.forOathCredential(
                    ref,
                    node,
                    credential,
                    credentials?.map((e) => (e.issuer, e.name)).toList() ?? [],
                  ),
                ));
          }),
        if (hasFeature(features.accountsDelete))
          DeleteIntent: CallbackAction<DeleteIntent>(onInvoke: (_) async {
            final node = ref.read(currentDeviceProvider)!;
            return await ref.read(withContextProvider)((context) async =>
                await showBlurDialog(
                  context: context,
                  builder: (context) => DeleteAccountDialog(node, credential),
                ) ??
                false);
          }),
      },
      builder: (context) {
        final helper = AccountHelper(context, ref, credential);
        return LayoutBuilder(builder: (context, constraints) {
          final showAvatar = constraints.maxWidth >= 315;
          final subtitle = helper.subtitle;
          final circleAvatar = CircleAvatar(
            foregroundColor: Theme.of(context).colorScheme.background,
            backgroundColor: _iconColor(400),
            child: Text(
              (credential.issuer ?? credential.name)
                  .characters
                  .first
                  .toUpperCase(),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w300),
            ),
          );

          return Shortcuts(
              shortcuts: {
                LogicalKeySet(LogicalKeyboardKey.enter): const OpenIntent(),
                LogicalKeySet(LogicalKeyboardKey.space): const OpenIntent(),
              },
              child: AppListItem(
                leading: showAvatar
                    ? AccountIcon(
                        issuer: credential.issuer, defaultWidget: circleAvatar)
                    : null,
                title: helper.title,
                subtitle: subtitle,
                semanticTitle: _a11yCredentialLabel(
                    credential.issuer, credential.name, helper.code?.value),
                trailing: helper.code != null
                    ? FilledButton.tonalIcon(
                        icon: helper.buildCodeIcon(),
                        label: helper.buildCodeLabel(),
                        onPressed: Actions.handler(context, const OpenIntent()),
                      )
                    : FilledButton.tonal(
                        onPressed: Actions.handler(context, const OpenIntent()),
                        child: helper.buildCodeIcon()),
                activationIntent: hasFeature(features.accountsClipboard)
                    ? const CopyIntent()
                    : const OpenIntent(),
                buildPopupActions: (_) => helper.buildActions(),
              ));
        });
      },
    );
  }
}
