import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/models.dart';
import '../state.dart';
import 'account_list.dart';

class OathScreen extends ConsumerWidget {
  final YubiKeyData device;
  const OathScreen(this.device, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(oathStateProvider(device.node.path));

    if (state == null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (state.locked) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Password required'),
            TextField(
              autofocus: true,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
              onSubmitted: (value) async {
                final result = await ref
                    .read(oathStateProvider(device.node.path).notifier)
                    .unlock(value);
                if (!result) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Wrong password'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      );
    } else {
      final accounts = ref.watch(credentialListProvider(device.node.path));
      if (accounts == null) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Center(child: CircularProgressIndicator()),
          ],
        );
      }
      return AccountList(
        device,
        ref.watch(filteredCredentialsProvider(accounts)),
        ref.watch(favoritesProvider),
      );
    }
  }
}
