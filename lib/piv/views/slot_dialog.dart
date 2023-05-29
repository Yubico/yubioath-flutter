import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/shortcuts.dart';
import '../../app/state.dart';
import '../../app/views/fs_dialog.dart';
import '../../widgets/list_title.dart';
import '../models.dart';
import 'actions.dart';

class SlotDialog extends ConsumerWidget {
  final PivState pivState;
  final PivSlot pivSlot;
  const SlotDialog(this.pivState, this.pivSlot, {super.key});

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
    final textTheme = Theme.of(context).textTheme;
    final certInfo = pivSlot.certInfo;
    return registerPivActions(
      node.path,
      pivState,
      pivSlot,
      ref: ref,
      builder: (context) => FocusScope(
        autofocus: true,
        child: FsDialog(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 48, bottom: 32),
                child: Column(
                  children: [
                    Text(
                      '${pivSlot.slot.getDisplayName(l10n)} (Slot ${pivSlot.slot.id.toRadixString(16).padLeft(2, '0')})',
                      style: textTheme.headlineSmall,
                      softWrap: true,
                      textAlign: TextAlign.center,
                    ),
                    if (certInfo != null) ...[
                      Text(
                        'Subject: ${certInfo.subject}, Issuer: ${certInfo.issuer}',
                        softWrap: true,
                        textAlign: TextAlign.center,
                        // This is what ListTile uses for subtitle
                        style: textTheme.bodyMedium!.copyWith(
                          color: textTheme.bodySmall!.color,
                        ),
                      ),
                      Text(
                        'Serial: ${certInfo.serial}',
                        softWrap: true,
                        textAlign: TextAlign.center,
                        // This is what ListTile uses for subtitle
                        style: textTheme.bodyMedium!.copyWith(
                          color: textTheme.bodySmall!.color,
                        ),
                      ),
                      Text(
                        'Fingerprint: ${certInfo.fingerprint}',
                        softWrap: true,
                        textAlign: TextAlign.center,
                        // This is what ListTile uses for subtitle
                        style: textTheme.bodyMedium!.copyWith(
                          color: textTheme.bodySmall!.color,
                        ),
                      ),
                      Text(
                        'Not before: ${certInfo.notValidBefore}, Not after: ${certInfo.notValidAfter}',
                        softWrap: true,
                        textAlign: TextAlign.center,
                        // This is what ListTile uses for subtitle
                        style: textTheme.bodyMedium!.copyWith(
                          color: textTheme.bodySmall!.color,
                        ),
                      ),
                    ] else ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Text(
                          'No certificate loaded',
                          softWrap: true,
                          textAlign: TextAlign.center,
                          // This is what ListTile uses for subtitle
                          style: textTheme.bodyMedium!.copyWith(
                            color: textTheme.bodySmall!.color,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              ListTitle(AppLocalizations.of(context)!.s_actions,
                  textStyle: textTheme.bodyLarge),
              _SlotDialogActions(certInfo),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlotDialogActions extends StatelessWidget {
  final CertInfo? certInfo;
  const _SlotDialogActions(this.certInfo);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme =
        ButtonTheme.of(context).colorScheme ?? Theme.of(context).colorScheme;
    return Column(
      children: [
        ListTile(
          leading: CircleAvatar(
            backgroundColor: theme.primary,
            foregroundColor: theme.onPrimary,
            child: const Icon(Icons.add_outlined),
          ),
          title: Text('Generate key'),
          subtitle: Text('Generate a new certificate or CSR'),
          onTap: () {
            Actions.invoke(context, const GenerateIntent());
          },
        ),
        ListTile(
          leading: CircleAvatar(
            backgroundColor: theme.secondary,
            foregroundColor: theme.onSecondary,
            child: const Icon(Icons.file_download_outlined),
          ),
          title: Text('Import file'),
          subtitle: Text('Import a key and/or certificate from file'),
          onTap: () {
            Actions.invoke(context, const ImportIntent());
          },
        ),
        if (certInfo != null) ...[
          ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.secondary,
              foregroundColor: theme.onSecondary,
              child: const Icon(Icons.file_upload_outlined),
            ),
            title: Text('Export certificate'),
            subtitle: Text('Export the certificate to file'),
            onTap: () {
              Actions.invoke(context, const ExportIntent());
            },
          ),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.error,
              foregroundColor: theme.onError,
              child: const Icon(Icons.delete_outline),
            ),
            title: Text('Delete certificate'),
            subtitle: Text('Remove the certificate from the YubiKey'),
            onTap: () {
              Actions.invoke(context, const DeleteIntent());
            },
          ),
        ],
      ],
    );
  }
}
