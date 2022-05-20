import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/message.dart';
import '../../app/models.dart';
import '../../app/views/app_failure_screen.dart';
import '../../app/views/app_loading_screen.dart';
import '../../app/views/app_page.dart';
import '../../app/views/graphics.dart';
import '../../app/views/message_page.dart';
import '../../desktop/models.dart';
import '../../desktop/state.dart';
import '../../management/models.dart';
import '../../theme.dart';
import '../state.dart';
import 'locked_page.dart';
import 'unlocked_page.dart';

class FidoScreen extends ConsumerWidget {
  final YubiKeyData deviceData;
  const FidoScreen(this.deviceData, {super.key});

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
            if (Platform.isWindows && error is RpcError) {
              if (error.status == 'connection-error' &&
                  !ref.watch(
                      rpcStateProvider.select((state) => state.isAdmin))) {
                return MessagePage(
                  title: const Text('WebAuthn'),
                  graphic: noPermission,
                  message: 'WebAuthn management requires elevated privileges.',
                  actions: [
                    OutlinedButton.icon(
                        label: const Text('Unlock'),
                        icon: const Icon(Icons.lock_open),
                        style: AppTheme.primaryOutlinedButtonStyle(context),
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
                  ],
                );
              }
            }
            return AppPage(
              title: const Text('WebAuthn'),
              centered: true,
              child: AppFailureScreen(error),
            );
          },
          data: (fidoState) {
            return fidoState.unlocked
                ? FidoUnlockedPage(deviceData.node, fidoState)
                : FidoLockedPage(deviceData.node, fidoState);
          });
}
