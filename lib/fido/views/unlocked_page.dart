import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/message.dart';
import '../../app/models.dart';
import '../../app/views/app_page.dart';
import '../../app/views/graphics.dart';
import '../../app/views/message_page.dart';
import '../../widgets/list_title.dart';
import '../../widgets/menu_list_tile.dart';
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
                        showBlurDialog(
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
                        showBlurDialog(
                          context: context,
                          builder: (context) =>
                              RenameFingerprintDialog(node.path, fp),
                        );
                      },
                      icon: const Icon(Icons.edit_outlined)),
                  IconButton(
                      onPressed: () {
                        showBlurDialog(
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
        keyActions: _buildKeyActions(context),
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
        keyActions: _buildKeyActions(context),
      );
    }

    return MessagePage(
      title: const Text('WebAuthn'),
      graphic: manageAccounts,
      header: 'No discoverable accounts',
      message: 'Register as a Security Key on websites',
      keyActions: _buildKeyActions(context),
    );
  }

  Widget _buildLoadingPage() => AppPage(
        title: const Text('WebAuthn'),
        centered: true,
        child: const CircularProgressIndicator(),
      );

  List<PopupMenuEntry> _buildKeyActions(BuildContext context) => [
        if (state.bioEnroll != null)
          buildMenuItem(
            title: const Text('Add fingerprint'),
            leading: const Icon(Icons.fingerprint),
            action: () {
              showBlurDialog(
                context: context,
                builder: (context) => AddFingerprintDialog(node.path),
              );
            },
          ),
        buildMenuItem(
          title: const Text('Change PIN'),
          leading: const Icon(Icons.pin),
          action: () {
            showBlurDialog(
              context: context,
              builder: (context) => FidoPinDialog(node.path, state),
            );
          },
        ),
        buildMenuItem(
          title: const Text('Reset FIDO'),
          leading: const Icon(Icons.delete),
          action: () {
            showBlurDialog(
              context: context,
              builder: (context) => ResetDialog(node),
            );
          },
        ),
      ];
}
