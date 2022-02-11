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
    final qrScanner = ref.watch(qrScannerProvider);
    if (state != null) {
      return [
        if (!state.locked && qrScanner != null)
          MenuAction(
              text: 'Scan for QR code',
              icon: const Icon(Icons.qr_code),
              action: (context) async {
                var messenger = ScaffoldMessenger.of(context);
                // TODO: Go to add credential page.
                String message;
                try {
                  final otpauth = await qrScanner.scanQr();
                  message = 'Captured: $otpauth';
                } catch (e) {
                  message = 'Unable to capture QR code';
                }
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(message),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }),
        if (!state.locked)
          MenuAction(
            text: 'Add credential',
            icon: const Icon(Icons.add),
            action: (context) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => OathAddAccountPage(device: device),
                ),
              );
            },
          ),
        if (!state.locked)
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
      ];
    }
  }
  return [];
}
