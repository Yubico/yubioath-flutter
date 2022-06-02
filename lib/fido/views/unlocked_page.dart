import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/message.dart';
import '../../app/models.dart';
import '../../app/views/app_page.dart';
import '../../app/views/graphics.dart';
import '../../app/views/message_page.dart';
import '../../theme.dart';
import '../../widgets/list_title.dart';
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
    List<Widget> children = [];
    if (state.credMgmt) {
      final data = ref.watch(credentialProvider(node.path)).asData;
      if (data == null) {
        return _buildLoadingPage();
      }
      final creds = data.value;
      if (creds.isNotEmpty) {
        children.add(const ListTitle('Credentials'));
        children.addAll(
          creds.map(
            (cred) => ListTile(
              leading: CircleAvatar(
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: const Icon(Icons.person),
              ),
              title: Text(
                cred.userName,
                softWrap: false,
                overflow: TextOverflow.fade,
              ),
              subtitle: Text(
                cred.rpId,
                softWrap: false,
                overflow: TextOverflow.fade,
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) =>
                              DeleteCredentialDialog(node.path, cred),
                        );
                      },
                      icon: const Icon(Icons.delete_outline)),
                ],
              ),
            ),
          ),
        );
      }
    }

    if (state.bioEnroll != null) {
      final data = ref.watch(fingerprintProvider(node.path)).asData;
      if (data == null) {
        return _buildLoadingPage();
      }
      final fingerprints = data.value;
      if (fingerprints.isNotEmpty) {
        children.add(const ListTitle('Fingerprints'));
        children.addAll(fingerprints.map((fp) => ListTile(
              leading: CircleAvatar(
                foregroundColor: Theme.of(context).colorScheme.onSecondary,
                backgroundColor: Theme.of(context).colorScheme.secondary,
                child: const Icon(Icons.fingerprint),
              ),
              title: Text(
                fp.label,
                softWrap: false,
                overflow: TextOverflow.fade,
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) =>
                              RenameFingerprintDialog(node.path, fp),
                        );
                      },
                      icon: const Icon(Icons.edit_outlined)),
                  IconButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) =>
                              DeleteFingerprintDialog(node.path, fp),
                        );
                      },
                      icon: const Icon(Icons.delete_outline)),
                ],
              ),
            )));
      }
    }

    if (children.isNotEmpty) {
      return AppPage(
        title: const Text('WebAuthn'),
        actions: _buildActions(context),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: children),
      );
    }

    if (state.bioEnroll != null) {
      return MessagePage(
        title: const Text('WebAuthn'),
        graphic: noFingerprints,
        header: 'No fingerprints',
        message: 'Add one or more (up to five) fingerprints',
        actions: _buildActions(context, fingerprintPrimary: true),
      );
    }

    return MessagePage(
      title: const Text('WebAuthn'),
      graphic: noDiscoverable,
      header: 'No discoverable accounts',
      message: 'Register as a Security Key on websites',
      actions: _buildActions(context),
    );
  }

  Widget _buildLoadingPage() => AppPage(
        title: const Text('WebAuthn'),
        centered: true,
        child: const CircularProgressIndicator(),
      );

  List<Widget> _buildActions(BuildContext context,
          {bool fingerprintPrimary = false}) =>
      [
        if (state.bioEnroll != null)
          OutlinedButton.icon(
            style: fingerprintPrimary
                ? AppTheme.primaryOutlinedButtonStyle(context)
                : null,
            label: const Text('Add fingerprint'),
            icon: const Icon(Icons.fingerprint),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AddFingerprintDialog(node.path),
              );
            },
          ),
        OutlinedButton.icon(
          label: const Text('Options'),
          icon: const Icon(Icons.tune),
          onPressed: () {
            showBottomMenu(context, [
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
                text: 'Reset FIDO',
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
        ),
      ];
}
