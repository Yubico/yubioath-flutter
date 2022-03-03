import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/models.dart';
import '../../app/state.dart';
import '../models.dart';
import '../state.dart';
import 'delete_account_dialog.dart';
import 'rename_account_dialog.dart';

mixin AccountMixin {
  OathCredential get credential;

  @protected
  String get label => credential.issuer != null
      ? '${credential.issuer} (${credential.name})'
      : credential.name;

  @protected
  OathCode? getCode(WidgetRef ref) => ref.watch(codeProvider(credential));

  @protected
  String formatCode(WidgetRef ref) {
    final value = getCode(ref)?.value;
    if (value == null) {
      return '••• •••';
    } else if (value.length < 6) {
      return value;
    } else {
      var i = value.length ~/ 2;
      return value.substring(0, i) + ' ' + value.substring(i);
    }
  }

  @protected
  bool isExpired(WidgetRef ref) {
    final code = getCode(ref);
    return code == null ||
        (credential.oathType == OathType.totp &&
            ref.watch(expiredProvider(code.validTo)));
  }

  @protected
  bool isFavorite(WidgetRef ref) =>
      ref.watch(favoritesProvider).contains(credential.id);

  @protected
  Future<OathCode> calculateCode(BuildContext context, WidgetRef ref) async {
    Function? close;
    if (credential.touchRequired) {
      close = ScaffoldMessenger.of(context)
          .showSnackBar(
            const SnackBar(
              content: Text('Touch your YubiKey'),
              duration: Duration(seconds: 30),
            ),
          )
          .close;
    } else if (credential.oathType == OathType.hotp) {
      final showPrompt = Timer(const Duration(milliseconds: 500), () {
        close = ScaffoldMessenger.of(context)
            .showSnackBar(
              const SnackBar(
                content: Text('Touch your YubiKey'),
                duration: Duration(seconds: 30),
              ),
            )
            .close;
      });
      close = showPrompt.cancel;
    }
    try {
      final node = ref.read(currentDeviceProvider)!;
      return await ref
          .read(credentialListProvider(node.path).notifier)
          .calculate(credential);
    } finally {
      // Hide the touch prompt when done
      close?.call();
    }
  }

  @protected
  void copyToClipboard(BuildContext context, WidgetRef ref) {
    final code = getCode(ref);
    if (code != null) {
      Clipboard.setData(ClipboardData(text: code.value));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Code copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @protected
  Future<OathCredential?> renameCredential(
      BuildContext context, WidgetRef ref) async {
    final node = ref.read(currentDeviceProvider)!;
    return await showDialog(
      context: context,
      builder: (context) => RenameAccountDialog(node, credential),
    );
  }

  @protected
  Future<bool> deleteCredential(BuildContext context, WidgetRef ref) async {
    final node = ref.read(currentDeviceProvider)!;
    return await showDialog(
      context: context,
      builder: (context) => DeleteAccountDialog(node, credential),
    );
  }

  @protected
  List<MenuAction> buildActions(WidgetRef ref) {
    final deviceData = ref.watch(currentDeviceDataProvider);
    if (deviceData == null) {
      return [];
    }
    final code = getCode(ref);
    final expired = isExpired(ref);
    final manual =
        credential.touchRequired || credential.oathType == OathType.hotp;
    final ready = expired || credential.oathType == OathType.hotp;
    final favorite = isFavorite(ref);

    return [
      if (manual)
        MenuAction(
          text: 'Calculate',
          icon: const Icon(Icons.refresh),
          action: ready
              ? (context) {
                  calculateCode(context, ref);
                }
              : null,
        ),
      MenuAction(
        text: 'Copy to clipboard',
        icon: const Icon(Icons.copy),
        action: code == null || expired
            ? null
            : (context) {
                Clipboard.setData(ClipboardData(text: code.value));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Code copied to clipboard'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
      ),
      MenuAction(
        text: favorite ? 'Remove from favorites' : 'Add to favorites',
        icon: Icon(favorite ? Icons.star : Icons.star_border),
        action: (context) {
          ref.read(favoritesProvider.notifier).toggleFavorite(credential.id);
        },
      ),
      if (deviceData.info.version.major >= 5 &&
          deviceData.info.version.minor >= 3)
        MenuAction(
          icon: const Icon(Icons.edit),
          text: 'Rename account',
          action: (context) async {
            await renameCredential(context, ref);
          },
        ),
      MenuAction(
        text: 'Delete account',
        icon: const Icon(Icons.delete_forever),
        action: (context) async {
          await deleteCredential(context, ref);
        },
      ),
    ];
  }
}
