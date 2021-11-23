import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/state.dart';
import '../../app/models.dart';

class OathAddAccountPage extends ConsumerWidget {
  final DeviceNode device;
  const OathAddAccountPage({required this.device, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // If current device changes, we need to pop back to the main Page.
    ref.listen<DeviceNode?>(currentDeviceProvider, (previous, next) {
      //TODO: This can probably be checked better to make sure it's the main page.
      Navigator.of(context).popUntil((route) => route.isFirst);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add account'),
      ),
      body: Column(
        children: [
          Text('Placeholder. Add account to ${device.name}'),
        ],
      ),
    );
  }
}
