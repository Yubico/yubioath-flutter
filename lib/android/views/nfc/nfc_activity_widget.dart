import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yubico_authenticator/android/state.dart';

class NfcActivityWidget extends ConsumerWidget {
  final double width;
  final double height;
  final Widget Function(NfcActivity)? iconFn;
  final Widget Function(NfcActivity)? backgroundFn;

  const NfcActivityWidget(
      {super.key,
      this.width = 32.0,
      this.height = 32.0,
      this.iconFn,
      this.backgroundFn});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final NfcActivity nfcActivityState = ref.watch(androidNfcActivityProvider);

    final background = backgroundFn?.call(nfcActivityState);
    final icon = iconFn?.call(nfcActivityState);

    return IgnorePointer(
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (background != null) background,
            if (icon != null) icon,
          ],
        ),
      ),
    );
  }
}
