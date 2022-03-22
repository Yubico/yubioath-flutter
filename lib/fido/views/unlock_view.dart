import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/models.dart';
import '../state.dart';

class UnlockView extends ConsumerWidget {
  final DeviceNode node;

  const UnlockView(this.node, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Text(
                  'Enter PIN',
                  style: Theme.of(context).textTheme.headline5,
                ),
              ),
              const Text(
                'Enter the FIDO PIN for your YubiKey. If you don\'t know your PIN, you\'ll need to reset the YubiKey.',
              ),
              TextField(
                autofocus: true,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'PIN'),
                onSubmitted: (pin) async {
                  await ref
                      .read(fidoStateProvider(node.path).notifier)
                      .unlock(pin);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
