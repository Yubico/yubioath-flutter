import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/message.dart';
import '../../core/state.dart';

class BetaDialog {
  final BuildContext context;
  final WidgetRef ref;

  const BetaDialog(this.context, this.ref);

  void request() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(prefProvider).reload();
      var dialogShouldBeShown =
          ref.read(prefProvider).getBool(prefBetaDialogShouldBeShown) ?? true;
      if (dialogShouldBeShown) {
        Future.delayed(Duration.zero, () async {
          await showBetaDialog();
        });
      }
    });
  }

  Future<void> showBetaDialog() async {
    await showBlurDialog(
      context: context,
      builder: (context) {
        final color =
            Theme.of(context).brightness == Brightness.dark ? 'white' : 'green';
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Image.asset(
                  'assets/graphics/yubico-$color.png',
                  alignment: Alignment.centerLeft,
                  height: 78,
                  filterQuality: FilterQuality.medium,
                ),
                const SizedBox(height: 16),
                Text('Beta Release',
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                const Text(
                    'Preview the latest beta: Try out the newest features. (Sometimes these may be a little rough around the edges.)'),
                const SizedBox(height: 8),
                const Text(
                    'Give early feedback: Let us know what you think and help make Authenticator for Android a better experience. Go to “Send us feedback” under Help and about.'),
              ],
            ),
            actions: <Widget>[
              TextButton(
                style: TextButton.styleFrom(
                  textStyle: Theme.of(context).textTheme.labelLarge,
                ),
                child: const Text('Learn more'),
                onPressed: () => onBetaDialogClosed(context, ref),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  textStyle: Theme.of(context).textTheme.labelLarge,
                ),
                child: const Text('Got it'),
                onPressed: () => onBetaDialogClosed(context, ref),
              ),
            ],
          ),
        );
      },
    );
  }

  final String prefBetaDialogShouldBeShown = 'prefBetaDialogShouldBeShown';

  void onBetaDialogClosed(BuildContext context, WidgetRef ref) async {
    Navigator.of(context).pop(true);
    await ref.read(prefProvider).setBool(prefBetaDialogShouldBeShown, false);
  }
}
