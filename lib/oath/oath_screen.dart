import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/models.dart';
import 'state.dart';

class OathScreen extends ConsumerWidget {
  final DeviceNode device;
  const OathScreen(this.device, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(oathStateProvider(device.path));

    if (state == null) {
      return const CircularProgressIndicator();
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('YubiKey: ${device.name}'),
          Text('OATH ID: ${state.deviceId}'),
        ],
      ),
    );
  }
}
