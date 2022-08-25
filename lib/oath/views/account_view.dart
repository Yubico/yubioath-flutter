import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yubico_authenticator/app/state.dart';
import 'package:yubico_authenticator/cancellation_exception.dart';

import '../../app/message.dart';
import '../../app/shortcuts.dart';
import '../../app/state.dart';
import '../../widgets/menu_list_tile.dart';
import '../models.dart';
import '../state.dart';
import 'account_dialog.dart';
import 'account_mixin.dart';

class AccountView extends ConsumerWidget with AccountMixin {
  @override
  final OathCredential credential;

  AccountView(this.credential, {super.key});

  Color _iconColor(int shade) {
    final colors = [
      Colors.red[shade],
      Colors.pink[shade],
      Colors.purple[shade],
      Colors.deepPurple[shade],
      Colors.indigo[shade],
      Colors.blue[shade],
      Colors.lightBlue[shade],
      Colors.cyan[shade],
      Colors.teal[shade],
      Colors.green[shade],
      Colors.lightGreen[shade],
      Colors.lime[shade],
      Colors.yellow[shade],
      Colors.amber[shade],
      Colors.orange[shade],
      Colors.deepOrange[shade],
      Colors.brown[shade],
      Colors.grey[shade],
      Colors.blueGrey[shade],
    ];
    return colors[label.hashCode % colors.length]!;
  }

  List<PopupMenuItem> _buildPopupMenu(BuildContext context, WidgetRef ref) {
    return buildActions(context, ref).map((e) {
      final action = e.action;
      return buildMenuItem(
        leading: e.icon,
        title: Text(e.text),
        action: action != null
            ? () {
                ref.read(withContextProvider)((context) async {
                  action.call(context);
                });
              }
            : null,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final code = getCode(ref);
    final expired = code == null ||
        (credential.oathType == OathType.totp &&
            ref.watch(expiredProvider(code.validTo)));
    final calculateReady = code == null ||
        credential.oathType == OathType.hotp ||
        (credential.touchRequired && expired);

    Future<void> triggerCopy() async {
      try {
        final withContext = ref.read(withContextProvider);
        await withContext(
          (context) async {
            OathCode? code = calculateReady
                ? await calculateCode(
                    context,
                    ref,
                  )
                : getCode(ref);
            await withContext((context) async => copyToClipboard(context, code));
          },
        );
      } on CancellationException catch (_) {
        // ignored
      }
    }

    final darkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onSecondaryTapDown: (details) {
        showMenu(
          context: context,
          position: RelativeRect.fromLTRB(
            details.globalPosition.dx,
            details.globalPosition.dy,
            details.globalPosition.dx,
            0,
          ),
          items: _buildPopupMenu(context, ref),
        );
      },
      child: Actions(
        actions: {
          CopyIntent: CallbackAction(onInvoke: (_) async {
            await triggerCopy();
            return null;
          }),
        },
        child: LayoutBuilder(builder: (context, constraints) {
          final showAvatar = constraints.maxWidth >= 315;
          return ListTile(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            onTap: () {
              showBlurDialog(
                context: context,
                builder: (context) => AccountDialog(credential),
              );
            },
            onLongPress: triggerCopy,
            leading: showAvatar
                ? CircleAvatar(
                    foregroundColor: darkMode ? Colors.black : Colors.white,
                    backgroundColor: _iconColor(darkMode ? 300 : 400),
                    child: Text(
                      (credential.issuer ?? credential.name)
                          .characters
                          .first
                          .toUpperCase(),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w300),
                    ),
                  )
                : null,
            title: Text(
              title,
              overflow: TextOverflow.fade,
              maxLines: 1,
              softWrap: false,
            ),
            subtitle: subtitle != null
                ? Text(
                    subtitle!,
                    overflow: TextOverflow.fade,
                    maxLines: 1,
                    softWrap: false,
                  )
                : null,
            trailing: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.rectangle,
                color: CardTheme.of(context).color,
                borderRadius: const BorderRadius.all(Radius.circular(30.0)),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10.0, vertical: 2.0),
                child: DefaultTextStyle.merge(
                  style: Theme.of(context).textTheme.bodyLarge,
                  child: buildCodeView(ref),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
