import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/message.dart';
import '../../app/models.dart';
import '../../app/state.dart';
import '../models.dart';
import '../state.dart';
import 'delete_account_dialog.dart';
import 'rename_account_dialog.dart';

class _StrikethroughClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path()
      ..moveTo(0, 2)
      ..lineTo(0, size.height)
      ..lineTo(size.width - 2, size.height)
      ..lineTo(0, 2)
      ..moveTo(2, 0)
      ..lineTo(size.width, size.height - 2)
      ..lineTo(size.width, 0)
      ..lineTo(2, 0)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return false;
  }
}

class _StrikethroughPainter extends CustomPainter {
  final Color color;
  _StrikethroughPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    paint.color = color;
    paint.strokeWidth = 1.3;
    canvas.drawLine(Offset(size.width * 0.15, size.height * 0.15),
        Offset(size.width * 0.8, size.height * 0.8), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

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
  bool isPinned(WidgetRef ref) =>
      ref.watch(favoritesProvider).contains(credential.id);

  @protected
  Future<OathCode> calculateCode(BuildContext context, WidgetRef ref) async {
    Function? close;
    if (credential.touchRequired) {
      close = showMessage(context, 'Touch your YubiKey',
              duration: const Duration(seconds: 30))
          .close;
    } else if (credential.oathType == OathType.hotp) {
      final showPrompt = Timer(const Duration(milliseconds: 500), () {
        close = showMessage(context, 'Touch your YubiKey',
                duration: const Duration(seconds: 30))
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
      showMessage(context, 'Code copied to clipboard');
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
        ) ??
        false;
  }

  @protected
  List<MenuAction> buildActions(BuildContext context, WidgetRef ref) {
    final deviceData = ref.watch(currentDeviceDataProvider);
    if (deviceData == null) {
      return [];
    }
    final code = getCode(ref);
    final expired = isExpired(ref);
    final manual =
        credential.touchRequired || credential.oathType == OathType.hotp;
    final ready = expired || credential.oathType == OathType.hotp;
    final pinned = isPinned(ref);

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
                showMessage(context, 'Code copied to clipboard');
              },
      ),
      MenuAction(
        text: pinned ? 'Unpin account' : 'Pin account',
        //TODO: Replace this with a custom icon.
        //Icon(pinned ? Icons.push_pin_remove : Icons.push_pin),
        icon: pinned
            ? CustomPaint(
                painter: _StrikethroughPainter(
                    Theme.of(context).iconTheme.color ?? Colors.black),
                child: ClipPath(
                    clipper: _StrikethroughClipper(),
                    child: const Icon(Icons.push_pin)),
              )
            : const Icon(Icons.push_pin),
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
        icon: const Icon(Icons.delete),
        action: (context) async {
          await deleteCredential(context, ref);
        },
      ),
    ];
  }
}
