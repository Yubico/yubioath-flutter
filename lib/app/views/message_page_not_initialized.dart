import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../android/app_methods.dart';
import '../../android/state.dart';
import '../../core/state.dart';
import 'message_page.dart';

class MessagePageNotInitialized extends ConsumerWidget {
  final String title;
  const MessagePageNotInitialized({super.key, required this.title});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final noKeyImage = Image.asset(
      'assets/graphics/no-key.png',
      filterQuality: FilterQuality.medium,
      scale: 2,
      color: Theme.of(context).colorScheme.primary,
    );

    if (isAndroid) {
      var hasNfcSupport = ref.watch(androidNfcSupportProvider);
      var isNfcEnabled = ref.watch(androidNfcStateProvider);
      return MessagePage(
        title: title,
        centered: true,
        graphic: noKeyImage,
        header: hasNfcSupport && isNfcEnabled
            ? l10n.l_insert_or_tap_yk
            : l10n.l_insert_yk,
        actionsBuilder: (context, expanded) => [
          if (hasNfcSupport && !isNfcEnabled)
            ElevatedButton.icon(
                label: Text(l10n.s_enable_nfc),
                icon: const Icon(Symbols.contactless),
                onPressed: () async {
                  await openNfcSettings();
                })
        ],
      );
    } else {
      return MessagePage(
        title: title,
        centered: true,
        delayedContent: false,
        graphic: noKeyImage,
        header: l10n.l_insert_yk,
      );
    }
  }
}
