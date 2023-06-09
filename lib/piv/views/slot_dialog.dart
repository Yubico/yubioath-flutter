import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/shortcuts.dart';
import '../../app/state.dart';
import '../../app/views/fs_dialog.dart';
import '../../app/views/action_list.dart';
import '../models.dart';
import '../state.dart';
import 'actions.dart';

class SlotDialog extends ConsumerWidget {
  final PivState pivState;
  final SlotId pivSlot;
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
    final theme =
        ButtonTheme.of(context).colorScheme ?? Theme.of(context).colorScheme;

    final slotData = ref.watch(pivSlotsProvider(node.path).select((value) =>
        value.whenOrNull(
            data: (data) =>
                data.firstWhere((element) => element.slot == pivSlot))));

    if (slotData == null) {
      return const FsDialog(child: CircularProgressIndicator());
    }

    final certInfo = slotData.certInfo;
    return registerPivActions(
      node.path,
      pivState,
      slotData,
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
                      pivSlot.getDisplayName(l10n),
                      style: textTheme.headlineSmall,
                      softWrap: true,
                      textAlign: TextAlign.center,
                    ),
                    if (certInfo != null) ...[
                      Text(
                        l10n.l_subject_issuer(
                            certInfo.subject, certInfo.issuer),
                        softWrap: true,
                        textAlign: TextAlign.center,
                        // This is what ListTile uses for subtitle
                        style: textTheme.bodyMedium!.copyWith(
                          color: textTheme.bodySmall!.color,
                        ),
                      ),
                      Text(
                        l10n.l_serial(certInfo.serial),
                        softWrap: true,
                        textAlign: TextAlign.center,
                        // This is what ListTile uses for subtitle
                        style: textTheme.bodyMedium!.copyWith(
                          color: textTheme.bodySmall!.color,
                        ),
                      ),
                      Text(
                        l10n.l_certificate_fingerprint(certInfo.fingerprint),
                        softWrap: true,
                        textAlign: TextAlign.center,
                        // This is what ListTile uses for subtitle
                        style: textTheme.bodyMedium!.copyWith(
                          color: textTheme.bodySmall!.color,
                        ),
                      ),
                      Text(
                        l10n.l_valid(
                            certInfo.notValidBefore, certInfo.notValidAfter),
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
                          l10n.l_no_certificate,
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
              ActionListSection(
                l10n.s_actions,
                children: [
                  ActionListItem(
                    backgroundColor: theme.primary,
                    foregroundColor: theme.onPrimary,
                    icon: const Icon(Icons.add_outlined),
                    title: l10n.s_generate_key,
                    subtitle: l10n.l_generate_desc,
                    onTap: () {
                      Actions.invoke(context, const GenerateIntent());
                    },
                  ),
                  ActionListItem(
                    icon: const Icon(Icons.file_download_outlined),
                    title: l10n.l_import_file,
                    subtitle: l10n.l_import_desc,
                    onTap: () {
                      Actions.invoke(context, const ImportIntent());
                    },
                  ),
                  if (certInfo != null) ...[
                    ActionListItem(
                      icon: const Icon(Icons.file_upload_outlined),
                      title: l10n.l_export_certificate,
                      subtitle: l10n.l_export_certificate_desc,
                      onTap: () {
                        Actions.invoke(context, const ExportIntent());
                      },
                    ),
                    ActionListItem(
                      backgroundColor: theme.error,
                      foregroundColor: theme.onError,
                      icon: const Icon(Icons.delete_outline),
                      title: l10n.l_delete_certificate,
                      subtitle: l10n.l_delete_certificate_desc,
                      onTap: () {
                        Actions.invoke(context, const DeleteIntent());
                      },
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
