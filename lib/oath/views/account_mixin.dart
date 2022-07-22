import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/message.dart';
import '../../app/models.dart';
import '../../app/state.dart';
import '../../cancellation_exception.dart';
import '../../widgets/circle_timer.dart';
import '../../widgets/custom_icons.dart';
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
  String get title => credential.issuer ?? credential.name;

  @protected
  String? get subtitle => credential.issuer != null ? credential.name : null;

  @protected
  OathCode? getCode(WidgetRef ref) => ref.watch(codeProvider(credential));

  @protected
  String formatCode(OathCode? code) {
    final value = code?.value;
    if (value == null) {
      return '';
    } else if (value.length < 6) {
      return value;
    } else {
      var i = value.length ~/ 2;
      return '${value.substring(0, i)} ${value.substring(i)}';
    }
  }

  @protected
  bool isExpired(OathCode? code, WidgetRef ref) {
    return code == null ||
        (credential.oathType == OathType.totp &&
            ref.watch(expiredProvider(code.validTo)));
  }

  @protected
  bool isPinned(WidgetRef ref) =>
      ref.watch(favoritesProvider).contains(credential.id);

  @protected
  Future<OathCode> calculateCode(BuildContext context, WidgetRef ref) async {
    final node = ref.read(currentDeviceProvider)!;
    return await ref
        .read(credentialListProvider(node.path).notifier)
        .calculate(credential);
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
    return await showBlurDialog(
      context: context,
      builder: (context) => RenameAccountDialog(node, credential),
    );
  }

  @protected
  Future<bool> deleteCredential(BuildContext context, WidgetRef ref) async {
    final node = ref.read(currentDeviceProvider)!;
    return await showBlurDialog(
          context: context,
          builder: (context) => DeleteAccountDialog(node, credential),
        ) ??
        false;
  }

  @protected
  List<MenuAction> buildActions(BuildContext context, WidgetRef ref) =>
      ref.watch(currentDeviceDataProvider).maybeWhen(
            data: (data) {
              final code = getCode(ref);
              final expired = isExpired(code, ref);
              final manual = credential.touchRequired ||
                  credential.oathType == OathType.hotp;
              final ready = expired || credential.oathType == OathType.hotp;
              final pinned = isPinned(ref);

              final shortcut = Platform.isMacOS ? '\u2318 C' : 'Ctrl+C';
              return [
                MenuAction(
                  text: 'Copy to clipboard ($shortcut)',
                  icon: const Icon(Icons.copy),
                  action: code == null || expired
                      ? null
                      : (context) {
                          Clipboard.setData(ClipboardData(text: code.value));
                          showMessage(context, 'Code copied to clipboard');
                        },
                ),
                if (manual)
                  MenuAction(
                    text: 'Calculate',
                    icon: const Icon(Icons.refresh),
                    action: ready
                        ? (context) async {
                          try {
                            await calculateCode(context, ref);
                          } on CancellationException catch (_) {
                            // ignored
                          }
                        }
                        : null,
                  ),
                MenuAction(
                  text: pinned ? 'Unpin account' : 'Pin account',
                  icon: pinned
                      ? pushPinStrokeIcon
                      : const Icon(Icons.push_pin_outlined),
                  action: (context) {
                    ref
                        .read(favoritesProvider.notifier)
                        .toggleFavorite(credential.id);
                  },
                ),
                if (data.info.version.isAtLeast(5, 3))
                  MenuAction(
                    icon: const Icon(Icons.edit_outlined),
                    text: 'Rename account',
                    action: (context) async {
                      await renameCredential(context, ref);
                    },
                  ),
                MenuAction(
                  text: 'Delete account',
                  icon: const Icon(Icons.delete_outline),
                  action: (context) async {
                    await deleteCredential(context, ref);
                  },
                ),
              ];
            },
            orElse: () => [],
          );

  @protected
  Widget buildCodeView(WidgetRef ref) {
    final code = getCode(ref);
    final expired = isExpired(code, ref);
    return AnimatedSize(
      alignment: Alignment.centerRight,
      duration: const Duration(milliseconds: 100),
      child: Builder(builder: (context) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: code == null
              ? [
                  Icon(
                    credential.oathType == OathType.hotp
                        ? Icons.refresh
                        : Icons.touch_app,
                  ),
                  const Text(''),
                ]
              : [
                  if (credential.oathType == OathType.totp) ...[
                    ...expired
                        ? [
                            if (credential.touchRequired) ...[
                              const Icon(Icons.touch_app),
                              const SizedBox(width: 8.0),
                            ]
                          ]
                        : [
                            SizedBox.square(
                              dimension:
                                  (IconTheme.of(context).size ?? 18) * 0.8,
                              child: CircleTimer(
                                code.validFrom * 1000,
                                code.validTo * 1000,
                              ),
                            ),
                            const SizedBox(width: 8.0),
                          ],
                  ],
                  Opacity(
                    opacity: expired ? 0.4 : 1.0,
                    child: Text(
                      formatCode(code),
                      style: const TextStyle(
                        fontFeatures: [FontFeature.tabularFigures()],
                        //fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
        );
      }),
    );
  }
}
