import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/message.dart';
import '../../app/models.dart';
import '../../app/views/app_failure_screen.dart';
import '../../app/views/app_loading_screen.dart';
import '../../app/views/app_page.dart';
import '../../app/views/device_avatar.dart';
import '../../app/views/message_page.dart';
import '../../desktop/state.dart';
import '../../management/models.dart';
import '../state.dart';
import 'locked_page.dart';
import 'unlocked_page.dart';

class FidoScreen extends ConsumerWidget {
  final YubiKeyData deviceData;
  const FidoScreen(this.deviceData, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      ref.watch(fidoStateProvider(deviceData.node.path)).when(
          loading: () => AppPage(
                title: const Text('WebAuthn'),
                centered: true,
                child: const AppLoadingScreen(),
              ),
          error: (error, _) {
            final supported = deviceData
                    .info.supportedCapabilities[deviceData.node.transport] ??
                0;
            if (Capability.fido2.value & supported == 0) {
              return const MessagePage(
                title: Text('WebAuthn'),
                header: 'No management options',
                message:
                    'WebAuthn is supported by this device, but there are no management options available.',
              );
            }
            final enabled = deviceData.info.config
                    .enabledCapabilities[deviceData.node.transport] ??
                0;
            if (Capability.fido2.value & enabled == 0) {
              return const MessagePage(
                title: Text('WebAuthn'),
                header: 'FIDO2 disabled',
                message:
                    'WebAuthn requires the FIDO2 application to be enabled on your YubiKey',
              );
            }
            if (Platform.isWindows) {
              if (!ref
                  .watch(rpcStateProvider.select((state) => state.isAdmin))) {
                return AppPage(
                    title: const Text('WebAuthn'),
                    centered: true,
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
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                child: e,
                              ))
                          .toList(),
                    ));
              }
            }
            return AppPage(
              title: const Text('WebAuthn'),
              centered: true,
              child: AppFailureScreen('$error'),
            );
          },
          data: (fidoState) {
            return fidoState.unlocked
                ? FidoUnlockedPage(deviceData.node, fidoState)
                : FidoLockedPage(deviceData.node, fidoState);
          });
}
