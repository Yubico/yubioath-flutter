import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/models.dart';
import '../../app/views/app_failure_screen.dart';
import '../models.dart';
import '../state.dart';
import 'add_fingerprint_dialog.dart';
import 'delete_fingerprint_dialog.dart';
import 'rename_fingerprint_dialog.dart';

class FingerprintPage extends ConsumerWidget {
  final DevicePath devicePath;
  final FidoState state;

  const FingerprintPage(this.devicePath, this.state, {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(fingerprintProvider(devicePath)).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => AppFailureScreen('$error'),
          data: (fingerprints) => ListView(
            children: [
              ListTile(
                title: Text(
                  'FINGERPRINTS',
                  style: Theme.of(context).textTheme.bodyText2,
                ),
              ),
              ...fingerprints.map((fp) => ListTile(
                    title: Text(fp.label),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) =>
                                    RenameFingerprintDialog(devicePath, fp),
                              );
                            },
                            icon: const Icon(Icons.edit)),
                        IconButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) =>
                                    DeleteFingerprintDialog(devicePath, fp),
                              );
                            },
                            icon: const Icon(Icons.delete)),
                      ],
                    ),
                  )),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Wrap(
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.fingerprint),
                      label: const Text('Add fingerprint'),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) =>
                              AddFingerprintDialog(devicePath),
                        );
                      },
                    )
                  ],
                ),
              ),
            ],
          ),
        );
  }
}
