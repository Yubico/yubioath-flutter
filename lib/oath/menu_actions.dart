import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/models.dart';
import '../app/state.dart';
import 'state.dart';
import 'views/add_account_page.dart';

List<MenuAction> buildOathMenuActions(
    BuildContext context, AutoDisposeProviderRef ref) {
  final device = ref.watch(currentDeviceProvider);
  if (device != null) {
    final state = ref.watch(oathStateProvider(device.path));
    if (state != null) {
      return [
        if (!state.locked)
          MenuAction(
            text: 'Add credential',
            icon: const Icon(Icons.add),
            action: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => OathAddAccountPage(device: device),
                ),
              );
            },
          ),
        MenuAction(
          text: 'Factory reset',
          icon: const Icon(Icons.delete_forever),
          action: () {
            ScaffoldMessenger.of(context)
              ..clearSnackBars()
              ..showSnackBar(
                const SnackBar(
                  content: Text('Not implemented'),
                  duration: Duration(seconds: 2),
                ),
              );
          },
        ),
      ];
    }
  }
  return [];
}
