import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/message.dart';
import '../../app/shortcuts.dart';
import '../../app/state.dart';
import '../../app/views/fs_dialog.dart';
import '../../app/views/action_list.dart';
import '../models.dart';
import 'delete_credential_dialog.dart';

class CredentialDialog extends ConsumerWidget {
  final FidoCredential credential;
  const CredentialDialog(this.credential, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Solve this in a cleaner way
    final node = ref.watch(currentDeviceDataProvider).valueOrNull?.node;
    if (node == null) {
      // The rest of this method assumes there is a device, and will throw an exception if not.
      // This will never be shown, as the dialog will be immediately closed
      return const SizedBox();
    }

    final l10n = AppLocalizations.of(context)!;
    final theme =
        ButtonTheme.of(context).colorScheme ?? Theme.of(context).colorScheme;
    return Actions(
      actions: {
        DeleteIntent: CallbackAction<DeleteIntent>(onInvoke: (_) async {
          final withContext = ref.read(withContextProvider);
          final bool? deleted =
              await ref.read(withContextProvider)((context) async =>
                  await showBlurDialog(
                    context: context,
                    builder: (context) => DeleteCredentialDialog(
                      node.path,
                      credential,
                    ),
                  ) ??
                  false);

          // Pop the account dialog if deleted
          if (deleted == true) {
            await withContext((context) async {
              Navigator.of(context).pop();
            });
          }
          return deleted;
        }),
      },
      child: FocusScope(
        autofocus: true,
        child: FsDialog(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 48, bottom: 32),
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
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            color: Theme.of(context).textTheme.bodySmall!.color,
                          ),
                    ),
                    const SizedBox(height: 16),
                    const Icon(Icons.person, size: 72),
                  ],
                ),
              ),
              ActionListSection(
                l10n.s_actions,
                children: [
                  ActionListItem(
                    backgroundColor: theme.error,
                    foregroundColor: theme.onError,
                    icon: const Icon(Icons.delete),
                    title: l10n.s_delete_passkey,
                    subtitle: l10n.l_delete_account_desc,
                    onTap: () {
                      Actions.invoke(context, const DeleteIntent());
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
