import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/models.dart';
import '../models.dart';
import '../state.dart';
import 'account_list.dart';
import 'account_view.dart';
import 'add_account_page.dart';

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
            Text('YubiKey: ${device.name}'),
            Text('OATH ID: ${state.deviceId}'),
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
      return Column(
        children: [
          TextField(
            onChanged: (value) {
              ref.read(searchFilterProvider.notifier).setFilter(value);
            },
            decoration: const InputDecoration(labelText: 'Search'),
          ),
          AccountList(device, ref.watch(filteredCredentialsProvider(accounts))),
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (context) => OathAddAccountPage(device: device)),
              );
            },
            child: const Text('Add'),
          ),
        ],
      );
    }
  }
}
