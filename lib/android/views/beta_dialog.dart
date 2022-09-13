import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/message.dart';
import '../../core/state.dart';
import '../keys.dart' as keys;

class BetaDialog {
  final BuildContext context;
  final WidgetRef ref;

  const BetaDialog(this.context, this.ref);

  void request() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      var sharedPrefs = ref.read(prefProvider);
      await sharedPrefs.reload();
      var dialogShouldBeShown =
          sharedPrefs.getBool(prefBetaDialogShouldBeShown) ?? true;
      if (dialogShouldBeShown) {
        Future.delayed(const Duration(milliseconds: 100), () async {
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
            key: keys.betaDialogView,
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
              // FIXME: enable and add correct uri
              // TextButton(
              //   style: TextButton.styleFrom(
              //     textStyle: Theme.of(context)
              //         .textTheme
              //         .labelLarge
              //         ?.copyWith(fontWeight: FontWeight.bold),
              //   ),
              //   child: const Text('Learn more'),
              //   onPressed: () {
              //     launchUrl(Uri.parse('https://learn more uri'),
              //         mode: LaunchMode.externalApplication);
              //     onBetaDialogClosed(context, ref);
              //   },
              // ),
              TextButton(
                key: keys.okButton,
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
