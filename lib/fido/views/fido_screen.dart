import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/message.dart';
import '../../app/models.dart';
import '../../app/state.dart';
import '../../app/views/app_failure_screen.dart';
import '../../app/views/app_loading_screen.dart';
import '../../app/views/app_page.dart';
import '../../app/views/device_avatar.dart';
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
  Widget build(BuildContext context, WidgetRef ref) {
    final subPage = ref.watch(_subPageProvider);
    return AppPage(
      onBack: subPage != SubPage.main
          ? () {
              ref.read(_subPageProvider.notifier).state = SubPage.main;
            }
          : null,
      title: const Text('WebAuthn'),
      child: ref.watch(fidoStateProvider(deviceData.node.path)).when(
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
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const DeviceAvatar(child: Icon(Icons.lock)),
                      const Text(
                        'WebAuthn management requires elevated privileges.',
                        textAlign: TextAlign.center,
                      ),
                      OutlinedButton.icon(
                          icon: const Icon(Icons.lock_open),
                          label: const Text('Unlock'),
                          onPressed: () async {
                            final controller = showMessage(
                                context, 'Elevating permissions...',
                                duration: const Duration(seconds: 30));
                            try {
                              if (await ref.read(rpcProvider).elevate()) {
                                ref.refresh(rpcProvider);
                              } else {
                                showMessage(context, 'Permission denied');
                              }
                            } finally {
                              controller.close();
                            }
                          }),
                    ]
                        .map((e) => Padding(
                              child: e,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                            ))
                        .toList(),
                  ),
                );
              }
            }
            return AppFailureScreen('$error');
          },
          data: (state) {
            switch (subPage) {
              case SubPage.fingerprints:
                return FingerprintPage(deviceData.node.path, state);
              case SubPage.credentials:
                return CredentialPage(deviceData.node.path, state);
              default:
                return FidoMainPage(
                  deviceData.node,
                  state,
                  setSubPage: (page) {
                    ref.read(_subPageProvider.notifier).state = page;
                  },
                );
            }
          }),
    );
  }
}
