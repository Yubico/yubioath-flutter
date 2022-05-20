import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/message.dart';
import '../../app/models.dart';
import '../../app/views/app_page.dart';
import '../../app/views/graphics.dart';
import '../../app/views/message_page.dart';
import '../models.dart';
import '../state.dart';
import 'add_fingerprint_dialog.dart';
import 'delete_credential_dialog.dart';
import 'delete_fingerprint_dialog.dart';
import 'pin_dialog.dart';
import 'rename_fingerprint_dialog.dart';
import 'reset_dialog.dart';

class FidoUnlockedPage extends ConsumerWidget {
  final DeviceNode node;
  final FidoState state;

  const FidoUnlockedPage(this.node, this.state, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    List<Widget> children = [
      if (state.credMgmt)
        ...ref.watch(credentialProvider(node.path)).maybeWhen(
              data: (creds) => creds.isNotEmpty
                  ? [
                      const ListTile(title: Text('Credentials')),
                      ...creds.map((cred) => ListTile(
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
                    ]
                  : [],
              orElse: () => [],
            ),
      if (state.bioEnroll != null)
        ...ref.watch(fingerprintProvider(node.path)).maybeWhen(
              data: (fingerprints) => fingerprints.isNotEmpty
                  ? [
                      const ListTile(title: Text('Fingerprints')),
                      ...fingerprints.map((fp) => ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.fingerprint),
                            ),
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
                          ))
                    ]
                  : [],
              orElse: () => [],
            ),
    ];

    if (children.isNotEmpty) {
      return AppPage(
        title: const Text('WebAuthn'),
        floatingActionButton: _buildFab(context),
        child: Column(
          children: children,
        ),
      );
    }

    if (state.bioEnroll == false) {
      return MessagePage(
        title: const Text('WebAuthn'),
        graphics: noFingerprints,
        header: 'No fingerprints',
        message: 'Add one or more (up to five) fingerprints',
        floatingActionButton: _buildFab(context),
      );
    }

    return MessagePage(
      title: const Text('WebAuthn'),
      graphics: noDiscoverable,
      header: 'No discoverable accounts',
      message: 'Register as a Security Key on websites',
      floatingActionButton: _buildFab(context),
    );
  }

  FloatingActionButton _buildFab(BuildContext context) {
    return FloatingActionButton.extended(
      icon: Icon(state.bioEnroll != null ? Icons.fingerprint : Icons.pin),
      label: const Text('Manage'),
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
            icon: const Icon(Icons.pin),
            action: (context) {
              showDialog(
                context: context,
                builder: (context) => FidoPinDialog(node.path, state),
              );
            },
          ),
          MenuAction(
            text: 'Delete all data',
            icon: const Icon(Icons.delete),
            action: (context) {
              showDialog(
                context: context,
                builder: (context) => ResetDialog(node),
              );
            },
          ),
        ]);
      },
    );
  }
}
