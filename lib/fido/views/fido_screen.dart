import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/models.dart';
import '../../app/state.dart';
import '../../app/views/app_failure_screen.dart';
import '../../app/views/app_loading_screen.dart';
import '../../desktop/state.dart';
import '../../management/models.dart';
import '../models.dart';
import '../state.dart';
import 'credential_page.dart';
import 'fingerprint_page.dart';
import 'main_page.dart';

final _subPageProvider = StateProvider<SubPage>((ref) {
  // Reset whenever the device changes.
  ref.watch(currentDeviceProvider);
  return SubPage.main;
});

class FidoScreen extends ConsumerWidget {
  final YubiKeyData deviceData;
  const FidoScreen(this.deviceData, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      ref.watch(fidoStateProvider(deviceData.node.path)).when(
          loading: () => const AppLoadingScreen(),
          error: (error, _) {
            final supported = deviceData
                .info.supportedCapabilities[deviceData.node.transport]!;
            if (Capability.fido2.value & supported == 0) {
              return const AppFailureScreen(
                  'WebAuthn is supported by this device, but there are no management options available.');
            }
            if (Platform.isWindows) {
              if (!ref
                  .watch(rpcStateProvider.select((state) => state.isAdmin))) {
                return const AppFailureScreen(
                    'WebAuthn management requires elevated privileges.\nRestart this app as administrator.');
              }
            }
            return AppFailureScreen('$error');
          },
          data: (state) {
            setSubPage(value) {
              ref.read(_subPageProvider.notifier).state = value;
            }

            switch (ref.watch(_subPageProvider)) {
              case SubPage.fingerprints:
                return WithBackButton(
                  goBack: () {
                    setSubPage(SubPage.main);
                  },
                  child: FingerprintPage(deviceData.node, state),
                );
              case SubPage.credentials:
                return WithBackButton(
                  goBack: () {
                    setSubPage(SubPage.main);
                  },
                  child: CredentialPage(deviceData.node, state),
                );
              default:
                return FidoMainPage(
                  deviceData.node,
                  state,
                  setSubPage: setSubPage,
                );
            }
          });
}

// TODO: Replace this with the AppBar back button
class WithBackButton extends StatelessWidget {
  final Function() goBack;
  final Widget child;
  const WithBackButton({Key? key, required this.goBack, required this.child})
      : super(key: key);

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          TextButton(onPressed: goBack, child: const Text('Back')),
          Expanded(child: child),
        ],
      );
}
