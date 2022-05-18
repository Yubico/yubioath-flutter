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
        title: Center(
          child: Text(
            title,
            overflow: TextOverflow.fade,
            style: Theme.of(context).textTheme.headlineSmall,
            maxLines: 1,
            softWrap: false,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12.0),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (subtitle != null)
              Text(
                subtitle!,
                overflow: TextOverflow.fade,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 1,
                softWrap: false,
              ),
            const SizedBox(height: 12.0),
            DecoratedBox(
              decoration: const BoxDecoration(
                shape: BoxShape.rectangle,
                color: Color(0xff3d3d3d),
                borderRadius: BorderRadius.all(Radius.circular(30.0)),
              ),
              child: Center(
                child: FittedBox(child: buildCodeView(ref, big: true)),
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.only(top: 10.0, right: -16.0),
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
