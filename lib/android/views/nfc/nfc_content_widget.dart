import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NfcContentWidget extends ConsumerWidget {
  final String title;
  final String subtitle;
  final Widget icon;

  const NfcContentWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          Text(title, textAlign: TextAlign.center, style: textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: textTheme.titleMedium!.copyWith(
                color: colorScheme.onSurfaceVariant,
              )),
          const SizedBox(height: 32),
          icon,
          const SizedBox(height: 24)
        ],
      ),
    );
  }
}
