import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/state.dart';
import '../../app/views/fs_dialog.dart';
import '../../app/views/action_list.dart';
import '../models.dart';
import '../state.dart';
import 'actions.dart';

class SlotDialog extends ConsumerWidget {
  final SlotId pivSlot;
  const SlotDialog(this.pivSlot, {super.key});

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
    // This is what ListTile uses for subtitle
    final subtitleStyle = textTheme.bodyMedium!.copyWith(
      color: textTheme.bodySmall!.color,
    );

    final pivState = ref.watch(pivStateProvider(node.path)).valueOrNull;
    final slotData = ref.watch(pivSlotsProvider(node.path).select((value) =>
        value.whenOrNull(
            data: (data) =>
                data.firstWhere((element) => element.slot == pivSlot))));

    if (pivState == null || slotData == null) {
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
                        style: subtitleStyle,
                      ),
                      Text(
                        l10n.l_serial(certInfo.serial),
                        softWrap: true,
                        textAlign: TextAlign.center,
                        style: subtitleStyle,
                      ),
                      Text(
                        l10n.l_certificate_fingerprint(certInfo.fingerprint),
                        softWrap: true,
                        textAlign: TextAlign.center,
                        style: subtitleStyle,
                      ),
                      Text(
                        l10n.l_valid(
                            certInfo.notValidBefore, certInfo.notValidAfter),
                        softWrap: true,
                        textAlign: TextAlign.center,
                        style: subtitleStyle,
                      ),
                    ] else ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Text(
                          l10n.l_no_certificate,
                          softWrap: true,
                          textAlign: TextAlign.center,
                          style: subtitleStyle,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              ActionListSection.fromMenuActions(
                l10n.s_actions,
                actions: buildSlotActions(certInfo != null, l10n),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
