import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/models.dart';
import '../../app/state.dart';
import '../../core/models.dart';
import '../../core/state.dart';
import '../../widgets/dialog_frame.dart';
import '../models.dart';
import 'account_mixin.dart';

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

  Pair<Color?, Color?> _getColors(BuildContext context, MenuAction action) {
    final theme =
        ButtonTheme.of(context).colorScheme ?? Theme.of(context).colorScheme;
    return action.text.startsWith('Copy')
        ? Pair(theme.primary, theme.onPrimary)
        : (action.text.startsWith('Delete')
            ? Pair(theme.error, theme.onError)
            : Pair(theme.secondary, theme.onSecondary));
  }

  List<Widget> _buildActions(BuildContext context, WidgetRef ref) {
    return buildActions(context, ref).map((e) {
      final action = e.action;
      final colors = _getColors(context, e);
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: CircleAvatar(
          backgroundColor: colors.first,
          foregroundColor: colors.second,
          child: IconButton(
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
              decoration: BoxDecoration(
                shape: BoxShape.rectangle,
                color: CardTheme.of(context).color,
                borderRadius: const BorderRadius.all(Radius.circular(30.0)),
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
