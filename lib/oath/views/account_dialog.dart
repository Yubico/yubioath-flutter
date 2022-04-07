import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/state.dart';
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
    if (code == null) {
      if (isDesktop) {
        Timer(Duration.zero, () => calculateCode(context, ref));
      }
    }
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
            Center(child: FittedBox(child: buildCodeView(ref, big: true))),
          ],
        ),
        actions: [FittedBox(child: Row(children: _buildActions(context, ref)))],
      ),
    );
  }
}
