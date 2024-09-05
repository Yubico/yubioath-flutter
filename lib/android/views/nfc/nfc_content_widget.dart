import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/state.dart';
import 'nfc_progress_bar.dart';

class NfcContentWidget extends ConsumerWidget {
  final String? title;
  final String? subtitle;
  final Widget? icon;

  const NfcContentWidget({super.key, this.title, this.subtitle, this.icon});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(l10nProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          Text(title ?? l10n.s_nfc_ready_to_scan,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(subtitle ?? '',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 32),
          icon ?? const NfcIconProgressBar(false),
          const SizedBox(height: 24)
        ],
      ),
    );
  }
}
