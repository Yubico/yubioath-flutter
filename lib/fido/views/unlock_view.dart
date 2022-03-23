import 'package:flutter/material.dart';

import '../models.dart';

class UnlockView extends StatelessWidget {
  final Future<PinResult> Function(String pin) onUnlock;

  const UnlockView({required this.onUnlock, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                  // TODO: Handle wrong PIN
                  await onUnlock(pin);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
