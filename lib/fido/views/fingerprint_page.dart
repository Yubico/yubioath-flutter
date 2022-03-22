import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/models.dart';
import '../models.dart';
import '../state.dart';
import 'delete_fingerprint_dialog.dart';
import 'rename_fingerprint_dialog.dart';
import 'unlock_view.dart';

class FingerprintPage extends ConsumerWidget {
  final DeviceNode node;
  final FidoState state;

  const FingerprintPage(this.node, this.state, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.locked) {
      return UnlockView(node);
    }

    final fingerprints = ref.watch(fingerprintProvider(node.path));
    if (fingerprints == null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    return ListView(
      children: [
        ListTile(
          title: Text(
            'FINGERPRINTS',
            style: Theme.of(context).textTheme.bodyText2,
          ),
        ),
        ...fingerprints.map((fp) => ListTile(
              title: Text(fp.label ?? 'Unnamed (ID: ${fp.id})'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) =>
                              RenameFingerprintDialog(node, fp),
                        );
                      },
                      icon: const Icon(Icons.edit)),
                  IconButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) =>
                              DeleteFingerprintDialog(node, fp),
                        );
                      },
                      icon: const Icon(Icons.delete)),
                ],
              ),
            )),
      ],
    );
  }
}
