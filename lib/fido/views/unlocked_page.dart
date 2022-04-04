import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yubico_authenticator/fido/state.dart';

import '../../app/message.dart';
import '../../app/models.dart';
import '../../app/views/app_page.dart';
import '../models.dart';
import 'add_fingerprint_dialog.dart';
import 'delete_credential_dialog.dart';
import 'delete_fingerprint_dialog.dart';
import 'pin_dialog.dart';
import 'rename_fingerprint_dialog.dart';
import 'reset_dialog.dart';

class FidoUnlockedPage extends ConsumerWidget {
  final DeviceNode node;
  final FidoState state;

  const FidoUnlockedPage(this.node, this.state, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppPage(
      title: const Text('WebAuthn'),
      child: Column(
        children: [
          if (state.credMgmt) ...[
            const ListTile(title: Text('Credentials')),
            ...ref.watch(credentialProvider(node.path)).when(
                  data: (creds) => creds.isEmpty
                      ? [const Text('You have no stored credentials')]
                      : creds.map((cred) => ListTile(
                            leading:
                                const CircleAvatar(child: Icon(Icons.link)),
                            title: Text(cred.userName),
                            subtitle: Text(cred.rpId),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) =>
                                            DeleteCredentialDialog(
                                                node.path, cred),
                                      );
                                    },
                                    icon: const Icon(Icons.delete)),
                              ],
                            ),
                          )),
                  error: (err, trace) =>
                      [const Text('Failed reading credentials')],
                  loading: () =>
                      [const Center(child: CircularProgressIndicator())],
                ),
          ],
          if (state.bioEnroll != null) ...[
            const ListTile(title: Text('Fingerprints')),
            ...ref.watch(fingerprintProvider(node.path)).when(
                  data: (fingerprints) => fingerprints.isEmpty
                      ? [const Text('No fingerprints added')]
                      : fingerprints.map((fp) => ListTile(
                            leading: const CircleAvatar(
                                child: Icon(Icons.fingerprint)),
                            title: Text(fp.label),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) =>
                                            RenameFingerprintDialog(
                                                node.path, fp),
                                      );
                                    },
                                    icon: const Icon(Icons.edit)),
                                IconButton(
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) =>
                                            DeleteFingerprintDialog(
                                                node.path, fp),
                                      );
                                    },
                                    icon: const Icon(Icons.delete)),
                              ],
                            ),
                          )),
                  error: (err, trace) =>
                      [const Text('Failed reading fingerprints')],
                  loading: () =>
                      [const Center(child: CircularProgressIndicator())],
                ),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: Icon(state.bioEnroll != null ? Icons.fingerprint : Icons.pin),
        label: const Text('Setup'),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        foregroundColor: Theme.of(context).colorScheme.onSecondary,
        onPressed: () {
          showBottomMenu(context, [
            if (state.bioEnroll != null)
              MenuAction(
                text: 'Add fingerprint',
                icon: const Icon(Icons.fingerprint),
                action: (context) {
                  showDialog(
                    context: context,
                    builder: (context) => AddFingerprintDialog(node.path),
                  );
                },
              ),
            MenuAction(
              text: 'Change PIN',
              icon: const Icon(Icons.pin_outlined),
              action: (context) {
                showDialog(
                  context: context,
                  builder: (context) => FidoPinDialog(node.path, state),
                );
              },
            ),
            MenuAction(
              text: 'Delete all data',
              icon: const Icon(Icons.delete_outline),
              action: (context) {
                showDialog(
                  context: context,
                  builder: (context) => ResetDialog(node),
                );
              },
            ),
          ]);
        },
      ),
    );
  }
}
