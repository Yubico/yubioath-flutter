import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/models.dart';
import '../state.dart';
import 'account_list.dart';

class OathScreen extends ConsumerWidget {
  final DeviceNode device;
  const OathScreen(this.device, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(oathStateProvider(device.path));

    if (state == null) {
      return const CircularProgressIndicator();
    }

    if (state.locked) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('YubiKey locked'),
            TextField(
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
              onSubmitted: (value) {
                ref.read(oathStateProvider(device.path).notifier).unlock(value);
              },
            ),
          ],
        ),
      );
    } else {
      final accounts = ref.watch(credentialListProvider(device.path));
      if (accounts == null) {
        return Column(
          children: const [
            Text('Reading...'),
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
