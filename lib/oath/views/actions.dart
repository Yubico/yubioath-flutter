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

import '../../app/message.dart';
import '../../app/models.dart';
import '../../app/shortcuts.dart';
import '../../app/state.dart';
import '../../core/state.dart';
import '../../exception/cancellation_exception.dart';
import '../features.dart' as features;
import '../models.dart';
import '../state.dart';
import 'delete_account_dialog.dart';
import 'rename_account_dialog.dart';

class TogglePinIntent extends Intent {
  final OathCredential target;
  const TogglePinIntent(this.target);
}

Future<OathCode?> _calculateCode(
    OathCredential credential, WidgetRef ref) async {
  final node = ref.read(currentDeviceProvider)!;
  try {
    return await ref
        .read(credentialListProvider(node.path).notifier)
        .calculate(credential);
  } on CancellationException catch (_) {
    return null;
  }
}

class OathActions extends ConsumerWidget {
  final DevicePath devicePath;
  final Map<Type, Action<Intent>> Function(BuildContext context)? actions;
  final Widget Function(BuildContext context) builder;
  const OathActions(
      {super.key,
      required this.devicePath,
      this.actions,
      required this.builder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final withContext = ref.read(withContextProvider);
    final hasFeature = ref.read(featureProvider);

    return Actions(
      actions: {
        RefreshIntent<OathCredential>:
            CallbackAction<RefreshIntent<OathCredential>>(onInvoke: (intent) {
          final credential = intent.target;
          final code = ref.read(codeProvider(credential));
          if (!(credential.oathType == OathType.totp &&
              code != null &&
              !ref.read(expiredProvider(code.validTo)))) {
            return _calculateCode(credential, ref);
          }
          return code;
        }),
        if (hasFeature(features.accountsClipboard))
          CopyIntent<OathCredential>:
              CallbackAction<CopyIntent<OathCredential>>(
                  onInvoke: (intent) async {
            final credential = intent.target;
            var code = ref.read(codeProvider(credential));
            if (code == null ||
                (credential.oathType == OathType.totp &&
                    ref.read(expiredProvider(code.validTo)))) {
              code = await _calculateCode(credential, ref);
            }
            if (code != null) {
              final clipboard = ref.watch(clipboardProvider);
              await clipboard.setText(code.value, isSensitive: true);
              if (!clipboard.platformGivesFeedback()) {
                await withContext((context) async {
                  showMessage(context,
                      AppLocalizations.of(context)!.l_code_copied_clipboard);
                });
              }
            }
            return code;
          }),
        if (hasFeature(features.accountsPin))
          TogglePinIntent: CallbackAction<TogglePinIntent>(onInvoke: (intent) {
            ref
                .read(favoritesProvider.notifier)
                .toggleFavorite(intent.target.id);
            return null;
          }),
        if (hasFeature(features.accountsRename))
          EditIntent<OathCredential>:
              CallbackAction<EditIntent<OathCredential>>(onInvoke: (intent) {
            final credentials = ref.read(credentialsProvider);
            return withContext((context) => showBlurDialog(
                context: context,
                builder: (context) => RenameAccountDialog.forOathCredential(
                      ref,
                      devicePath,
                      intent.target,
                      credentials?.map((e) => (e.issuer, e.name)).toList() ??
                          [],
                    )));
          }),
        if (hasFeature(features.accountsDelete))
          DeleteIntent<OathCredential>:
              CallbackAction<DeleteIntent<OathCredential>>(
            onInvoke: (intent) {
              return withContext((context) async =>
                  await showBlurDialog(
                    context: context,
                    builder: (context) => DeleteAccountDialog(
                      devicePath,
                      intent.target,
                    ),
                  ) ??
                  false);
            },
          ),
      },
      child: Builder(
        // Builder to ensure new scope for actions, they can invoke parent actions
        builder: (context) {
          final child = Builder(builder: builder);
          return actions != null
              ? Actions(actions: actions!(context), child: child)
              : child;
        },
      ),
    );
  }
}
