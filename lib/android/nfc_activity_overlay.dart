import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yubico_authenticator/android/state.dart';
import 'package:yubico_authenticator/core/state.dart';

class NfcActivityOverlay extends ConsumerWidget {
  final Widget child;

  const NfcActivityOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isDesktop) {
      return child;
    }

    const widgetColor = Colors.amber;
    final nfcActivity = ref.watch(androidNfcActivityProvider);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(children: [
        child,
        Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              verticalDirection: VerticalDirection.down,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    border: Border.all(width: 3, color: widgetColor),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'NFC: ${nfcActivity.name}',
                      style: const TextStyle(
                        fontSize: 15,
                        decoration: TextDecoration.none,
                        color: widgetColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 56,
                )
              ],
            ),
            const SizedBox(
              width: 16,
            )
          ],
        )
      ]),
    );
  }
}
