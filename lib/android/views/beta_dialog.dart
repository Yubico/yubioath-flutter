import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

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
        final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Image.asset(
                  isDarkTheme
                      ? 'assets/graphics/beta-dark.png'
                      : 'assets/graphics/beta-light.png',
                  alignment: Alignment.topCenter,
                  height: 124,
                  filterQuality: FilterQuality.medium,
                ),
                const SizedBox(height: 24),
                Text(
                  'Welcome to Yubico Authenticator Beta!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: isDarkTheme ? Colors.white : Colors.black),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                const Text(
                    '• Preview the latest beta: Try out the newest features. (Sometimes these may be a little rough around the edges.)'),
                const SizedBox(height: 8),
                const Text(
                    '• Give early feedback: Let us know what you think and help make Authenticator for Android a better experience. Go to “Send us feedback” under Help and about.'),
              ],
            ),
            actions: <Widget>[
              TextButton(
                style: TextButton.styleFrom(
                  textStyle: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                child: const Text('Learn more'),
                onPressed: () {
                  // FIXME: get correct Android Beta Blog URI
                  launchUrl(Uri.parse('https://forms.gle/2J81Kh8rnzBrtNc69'),
                      mode: LaunchMode.externalApplication);
                  onBetaDialogClosed(context, ref);
                },
              ),
              TextButton(
                style: TextButton.styleFrom(
                  textStyle: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
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
