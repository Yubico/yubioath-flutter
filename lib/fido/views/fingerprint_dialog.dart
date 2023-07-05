import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/message.dart';
import '../../app/shortcuts.dart';
import '../../app/state.dart';
import '../../app/views/fs_dialog.dart';
import '../../app/views/action_list.dart';
import '../models.dart';
import 'actions.dart';
import 'delete_fingerprint_dialog.dart';
import 'rename_fingerprint_dialog.dart';

class FingerprintDialog extends ConsumerWidget {
  final Fingerprint fingerprint;
  const FingerprintDialog(this.fingerprint, {super.key});

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
    return Actions(
      actions: {
        EditIntent: CallbackAction<EditIntent>(onInvoke: (_) async {
          final withContext = ref.read(withContextProvider);
          final Fingerprint? renamed =
              await withContext((context) async => await showBlurDialog(
                    context: context,
                    builder: (context) => RenameFingerprintDialog(
                      node.path,
                      fingerprint,
                    ),
                  ));
          if (renamed != null) {
            // Replace the dialog with the renamed credential
            await withContext((context) async {
              Navigator.of(context).pop();
              await showBlurDialog(
                context: context,
                builder: (context) {
                  return FingerprintDialog(renamed);
                },
              );
            });
          }
          return renamed;
        }),
        DeleteIntent: CallbackAction<DeleteIntent>(onInvoke: (_) async {
          final withContext = ref.read(withContextProvider);
          final bool? deleted =
              await ref.read(withContextProvider)((context) async =>
                  await showBlurDialog(
                    context: context,
                    builder: (context) => DeleteFingerprintDialog(
                      node.path,
                      fingerprint,
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
              ActionListSection.fromMenuActions(
                context,
                l10n.s_actions,
                actions: buildFingerprintActions(l10n),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
