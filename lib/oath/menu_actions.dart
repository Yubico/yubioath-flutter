import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/models.dart';
import '../app/state.dart';
import 'state.dart';
import 'views/add_account_page.dart';
import 'views/password_dialog.dart';
import 'views/reset_dialog.dart';

List<MenuAction> buildOathMenuActions(AutoDisposeProviderRef ref) {
  final device = ref.watch(currentDeviceProvider);
  if (device != null) {
    final state = ref.watch(oathStateProvider(device.path));
    return state.whenOrNull(
            data: (oathState) => [
                  if (!oathState.locked) ...[
                    MenuAction(
                      text: 'Add credential',
                      icon: const Icon(Icons.add),
                      action: (context) {
                        showDialog(
                          context: context,
                          builder: (context) =>
                              OathAddAccountPage(device: device),
                        );
                      },
                    ),
                    MenuAction(
                      text: 'Manage password',
                      icon: const Icon(Icons.password),
                      action: (context) {
                        showDialog(
                          context: context,
                          builder: (context) => ManagePasswordDialog(device),
                        );
                      },
                    ),
                  ],
                  MenuAction(
                    text: 'Factory reset',
                    icon: const Icon(Icons.delete_forever),
                    action: (context) {
                      showDialog(
                        context: context,
                        builder: (context) => ResetDialog(device),
                      );
                    },
                  ),
                ]) ??
        [];
  }
  return [];
}
