import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/message.dart';
import '../../app/state.dart';
import '../../core/state.dart';
import '../keys.dart' as keys;

void requestBetaDialog(WidgetRef ref) async {
  const String prefBetaDialogShouldBeShown = 'prefBetaDialogShouldBeShown';
  var sharedPrefs = ref.read(prefProvider);
  await sharedPrefs.reload();
  var dialogShouldBeShown =
      sharedPrefs.getBool(prefBetaDialogShouldBeShown) ?? true;
  if (dialogShouldBeShown) {
    final withContext = ref.read(withContextProvider);

    await withContext(
      (context) async {
        await showBlurDialog(
          context: context,
          builder: (context) => const _BetaDialog(),
          routeSettings: const RouteSettings(name: 'android_beta_dialog'),
        );
      },
    );

    await sharedPrefs.setBool(prefBetaDialogShouldBeShown, false);
  }
}

class _BetaDialog extends StatefulWidget {
  const _BetaDialog();

  @override
  State<StatefulWidget> createState() => _BetaDialogState();
}

class _BetaDialogState extends State<_BetaDialog> {
  late FocusScopeNode _focus;

  @override
  void initState() {
    super.initState();
    _focus = FocusScopeNode();
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // This keeps the focus in the dialog, even if the underlying page
    // changes as it does when a new device is selected.
    return FocusScope(
      node: _focus,
      autofocus: true,
      onFocusChange: (focused) {
        if (!focused) {
          _focus.requestFocus();
        }
      },
      child: const _BetaDialogContent(),
    );
  }
}

class _BetaDialogContent extends ConsumerWidget {
  const _BetaDialogContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(color: isDarkTheme ? Colors.white : Colors.black),
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
              onPressed: () => Navigator.of(context)
                  .pop(true) //{}, //onBetaDialogClosed(context, ref),
              ),
        ],
      ),
    );
  }
}
