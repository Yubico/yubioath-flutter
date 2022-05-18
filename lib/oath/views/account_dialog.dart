import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/models.dart';
import '../../app/state.dart';
import '../../core/state.dart';
import '../../theme.dart';
import '../../widgets/dialog_frame.dart';
import '../models.dart';
import 'account_mixin.dart';

extension on MenuAction {
  Color? get iconColor => text.startsWith('Copy') ? Colors.black : Colors.white;

  Color get backgroundColor => text.startsWith('Copy')
      ? primaryGreen
      : (text.startsWith('Delete')
          ? const Color(0xffea4335)
          : const Color(0xff3d3d3d));
}

class AccountDialog extends ConsumerWidget with AccountMixin {
  @override
  final OathCredential credential;
  const AccountDialog(this.credential, {super.key});

  @override
  Future<OathCredential?> renameCredential(
      BuildContext context, WidgetRef ref) async {
    final renamed = await super.renameCredential(context, ref);
    if (renamed != null) {
      // Replace this dialog with a new one, for the renamed credential.
      await ref.read(withContextProvider)((context) async {
        Navigator.of(context).pop();
        await showDialog(
          context: context,
          builder: (context) {
            return AccountDialog(renamed);
          },
        );
      });
    }
    return renamed;
  }

  @override
  Future<bool> deleteCredential(BuildContext context, WidgetRef ref) async {
    final deleted = await super.deleteCredential(context, ref);
    if (deleted) {
      await ref.read(withContextProvider)((context) async {
        Navigator.of(context).pop();
      });
    }
    return deleted;
  }

  List<Widget> _buildActions(BuildContext context, WidgetRef ref) {
    return buildActions(context, ref).map((e) {
      final action = e.action;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: CircleAvatar(
          backgroundColor: e.backgroundColor,
          child: IconButton(
            color: e.iconColor,
            icon: e.icon,
            tooltip: e.text,
            onPressed: action != null
                ? () {
                    action(context);
                  }
                : null,
          ),
        ),
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
        actions: [
          Center(
            child: FittedBox(
              alignment: Alignment.center,
              child: Row(children: _buildActions(context, ref)),
            ),
          )
        ],
      ),
    );
  }
}
