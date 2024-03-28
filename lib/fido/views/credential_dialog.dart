import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app/shortcuts.dart';
import '../../app/state.dart';
import '../../app/views/action_list.dart';
import '../../app/views/fs_dialog.dart';
import '../../core/state.dart';
import '../features.dart' as features;
import '../models.dart';
import 'actions.dart';
import 'credential_info_view.dart';

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
    final hasFeature = ref.watch(featureProvider);

    return FidoActions(
      devicePath: node.path,
      actions: (context) => {
        if (hasFeature(features.credentialsDelete))
          DeleteIntent<FidoCredential>:
              CallbackAction<DeleteIntent<FidoCredential>>(
                  onInvoke: (intent) async {
            final deleted =
                await (Actions.invoke(context, intent) as Future<dynamic>?);
            // Pop the account dialog if deleted
            if (deleted == true) {
              await ref.read(withContextProvider)((context) async {
                Navigator.of(context).pop();
              });
            }
            return deleted;
          }),
      },
      builder: (context) => ItemShortcuts(
        item: credential,
        child: FocusScope(
          autofocus: true,
          child: FsDialog(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                      top: 48, bottom: 32, left: 16, right: 16),
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Icon(Symbols.passkey, size: 72),
                      ),
                      CredentialInfoTable(credential),
                    ],
                  ),
                ),
                ActionListSection.fromMenuActions(
                  context,
                  l10n.s_actions,
                  actions: buildCredentialActions(credential, l10n),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
