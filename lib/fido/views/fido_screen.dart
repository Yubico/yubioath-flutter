import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/models.dart';
import '../../app/views/app_failure_screen.dart';
import '../../app/views/app_loading_screen.dart';
import '../../desktop/state.dart';
import '../../management/models.dart';
import '../state.dart';
import 'pin_dialog.dart';
import 'reset_dialog.dart';

class FidoScreen extends ConsumerWidget {
  final YubiKeyData deviceData;
  const FidoScreen(this.deviceData, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      ref.watch(fidoStateProvider(deviceData.node.path)).when(
          none: () => const AppLoadingScreen(),
          failure: (reason) {
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
            return AppFailureScreen(reason);
          },
          success: (state) => ListView(
                children: [
                  ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.pin),
                    ),
                    title: const Text('PIN'),
                    subtitle:
                        Text(state.hasPin ? 'Change your PIN' : 'Set a PIN'),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) =>
                            FidoPinDialog(deviceData.node.path, state),
                      );
                    },
                  ),
                  if (state.bioEnroll != null)
                    ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.fingerprint),
                      ),
                      title: const Text('Fingerprints'),
                      subtitle: Text(state.bioEnroll == true
                          ? 'Fingerprints have been registered'
                          : 'No fingerprints registered'),
                    ),
                  if (state.credMgmt)
                    const ListTile(
                      leading: CircleAvatar(
                        child: Icon(Icons.account_box),
                      ),
                      title: Text('Credentials'),
                      subtitle: Text('Manage stored credentials on key'),
                    ),
                  ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.delete_forever),
                    ),
                    title: const Text('Factory reset'),
                    subtitle: const Text('Delete all data and remove PIN'),
                    onTap: () async {
                      await showDialog(
                        context: context,
                        builder: (context) => ResetDialog(deviceData.node),
                      );
                    },
                  ),
                ],
              ));
}
