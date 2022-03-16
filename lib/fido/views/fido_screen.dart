import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yubico_authenticator/desktop/state.dart';

import '../../app/models.dart';
import '../../app/views/app_failure_screen.dart';
import '../../app/views/app_loading_screen.dart';
import '../state.dart';

class FidoScreen extends ConsumerWidget {
  final YubiKeyData deviceData;
  const FidoScreen(this.deviceData, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      ref.watch(fidoStateProvider(deviceData.node.path)).when(
          none: () => const AppLoadingScreen(),
          failure: (reason) {
            if (Platform.isWindows) {
              if (!ref
                  .watch(rpcStateProvider.select((state) => state.isAdmin))) {
                return const AppFailureScreen(
                    'WebAuthn management requires elevated privileges.\nRestart this app as administrator.');
              }
            }
            return AppFailureScreen(reason);
          },
          success: (state) => ListView(
                children: [
                  Text('${state.info}'),
                ],
              ));
}
