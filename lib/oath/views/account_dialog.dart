import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/circle_timer.dart';
import '../../widgets/dialog_frame.dart';
import '../models.dart';
import 'account_mixin.dart';

class AccountDialog extends ConsumerWidget with AccountMixin {
  @override
  final OathCredential credential;
  const AccountDialog(this.credential, {Key? key}) : super(key: key);

  @override
  Future<OathCredential?> renameCredential(
      BuildContext context, WidgetRef ref) async {
    final renamed = await super.renameCredential(context, ref);
    if (renamed != null) {
      // Replace this dialog with a new one, for the renamed credential.
      Navigator.of(context).pop();
      await showDialog(
        context: context,
        builder: (context) {
          return AccountDialog(renamed);
        },
      );
    }
    return renamed;
  }

  @override
  Future<bool> deleteCredential(BuildContext context, WidgetRef ref) async {
    final deleted = await super.deleteCredential(context, ref);
    if (deleted) {
      Navigator.of(context).pop();
    }
    return deleted;
  }

  List<Widget> _buildActions(BuildContext context, WidgetRef ref) {
    return buildActions(context, ref).map((e) {
      final action = e.action;
      return IconButton(
        icon: e.icon,
        tooltip: e.text,
        onPressed: action != null
            ? () {
                action(context);
              }
            : null,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final code = getCode(ref);
    final expired = isExpired(code, ref);
    final calculateReady = code == null ||
        credential.oathType == OathType.hotp ||
        (credential.touchRequired && expired);
    return DialogFrame(
      child: AlertDialog(
        title: Text(title),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24.0),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: EdgeInsets.zero,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(subtitle ?? ''),
            const SizedBox(height: 8.0),
            Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  borderRadius: const BorderRadius.all(Radius.circular(30.0)),
                  border: Border.all(width: 1.0, color: Colors.grey.shade500),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      calculateReady
                          ? Icon(
                              credential.touchRequired
                                  ? Icons.touch_app
                                  : Icons.refresh,
                              size: 36,
                            )
                          : SizedBox.square(
                              dimension: 32,
                              child: CircleTimer(
                                code.validFrom * 1000,
                                code.validTo * 1000,
                              ),
                            ),
                      if (code != null) ...[
                        const SizedBox(width: 8.0),
                        Opacity(
                          opacity: expired ? 0.4 : 1.0,
                          child: Text(
                            formatCode(code),
                            style: const TextStyle(
                                fontSize: 32.0,
                                fontFeatures: [FontFeature.tabularFigures()]),
                          ),
                        )
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: _buildActions(context, ref),
      ),
    );
  }
}
