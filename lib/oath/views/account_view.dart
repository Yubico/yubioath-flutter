import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/circle_timer.dart';
import '../../app/models.dart';
import '../models.dart';
import '../state.dart';
import 'delete_account_dialog.dart';
import 'rename_account_dialog.dart';

final _expireProvider =
    StateNotifierProvider.autoDispose.family<_ExpireNotifier, bool, int>(
  (ref, expiry) =>
      _ExpireNotifier(DateTime.now().millisecondsSinceEpoch, expiry * 1000),
);

class _ExpireNotifier extends StateNotifier<bool> {
  Timer? _timer;
  _ExpireNotifier(int now, int expiry) : super(expiry <= now) {
    if (expiry > now) {
      _timer = Timer(Duration(milliseconds: expiry - now), () {
        if (mounted) {
          state = true;
        }
      });
    }
  }

  @override
  dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

// TODO: Replace this with something cleaner
final _busyCalculatingProvider = StateProvider<bool>((ref) => false);

class AccountView extends ConsumerWidget {
  final YubiKeyData deviceData;
  final OathCredential credential;
  final OathCode? code;
  final FocusNode? focusNode;
  const AccountView(this.deviceData, this.credential, this.code,
      {Key? key, this.focusNode})
      : super(key: key);

  String formatCode() {
    var value = code?.value;
    if (value == null) {
      return '••• •••';
    } else if (value.length < 6) {
      return value;
    } else {
      var i = value.length ~/ 2;
      return value.substring(0, i) + ' ' + value.substring(i);
    }
  }

  List<PopupMenuEntry> _buildPopupMenu(
          BuildContext context, WidgetRef ref, bool trigger) =>
      [
        PopupMenuItem(
          child: const ListTile(
            leading: Icon(Icons.copy),
            title: Text('Copy to clipboard'),
          ),
          onTap: () {
            _copyToClipboard(context, ref, trigger);
          },
        ),
        PopupMenuItem(
          child: const ListTile(
            leading: Icon(Icons.star),
            title: Text('Toggle favorite'),
          ),
          onTap: () {
            ref.read(favoritesProvider.notifier).toggleFavorite(credential.id);
          },
        ),
        if (deviceData.info.version.major >= 5 &&
            deviceData.info.version.minor >= 3)
          PopupMenuItem(
            child: const ListTile(
              leading: Icon(Icons.edit),
              title: Text('Rename account'),
            ),
            onTap: () {
              // This ensures the onTap handler finishes before the dialog is shown, otherwise the dialog is immediately closed instead of the popup.
              Future.delayed(Duration.zero, () {
                showDialog(
                  context: context,
                  builder: (context) =>
                      RenameAccountDialog(deviceData.node, credential),
                );
              });
            },
          ),
        const PopupMenuDivider(),
        PopupMenuItem(
          child: const ListTile(
            leading: Icon(Icons.delete_forever),
            title: Text('Delete account'),
          ),
          onTap: () {
            // This ensures the onTap handler finishes before the dialog is shown, otherwise the dialog is immediately closed instead of the popup.
            Future.delayed(Duration.zero, () {
              showDialog(
                context: context,
                builder: (context) =>
                    DeleteAccountDialog(deviceData.node, credential),
              );
            });
          },
        ),
      ];

  _copyToClipboard(BuildContext context, WidgetRef ref, bool trigger) async {
    final busy = ref.read(_busyCalculatingProvider.notifier);
    if (busy.state) return;

    try {
      busy.state = true;
      String value;
      if (trigger) {
        final updated = await _calculate(context, ref);
        value = updated.value;
      } else {
        value = code!.value;
      }
      await Clipboard.setData(ClipboardData(text: value));
      await ScaffoldMessenger.of(context)
          .showSnackBar(
            const SnackBar(
              content: Text('Code copied'),
              duration: Duration(seconds: 2),
            ),
          )
          .closed;
    } finally {
      busy.state = false;
    }
  }

  Future<OathCode> _calculate(BuildContext context, WidgetRef ref) async {
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
    }
    try {
      return await ref
          .read(credentialListProvider(deviceData.node.path).notifier)
          .calculate(credential);
    } finally {
      // Hide the touch prompt when done
      close?.call();
    }
  }

  Color _iconColor(String label, int shade) {
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final code = this.code;
    final label = credential.issuer != null
        ? '${credential.issuer} (${credential.name})'
        : credential.name;
    final expired = ref.watch(_expireProvider(code?.validTo ?? 0));
    final trigger = code == null ||
        expired &&
            (credential.touchRequired || credential.oathType == OathType.hotp);

    final darkMode = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      focusNode: focusNode,
      onTap: () {
        final focus = focusNode;
        if (focus != null && focus.hasFocus == false) {
          focus.requestFocus();
        } else {
          _copyToClipboard(context, ref, trigger);
        }
      },
      leading: CircleAvatar(
        foregroundColor: darkMode ? Colors.black : Colors.white,
        backgroundColor: _iconColor(label, darkMode ? 300 : 400),
        child: Text(
          (credential.issuer ?? credential.name).characters.first.toUpperCase(),
          style: const TextStyle(fontSize: 18),
        ),
      ),
      title: Text(
        formatCode(),
        style: expired
            ? Theme.of(context)
                .textTheme
                .headline5
                ?.copyWith(color: Colors.grey)
            : Theme.of(context).textTheme.headline5,
      ),
      subtitle: Text(label, style: Theme.of(context).textTheme.caption),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            children: [
              Align(
                alignment: AlignmentDirectional.topCenter,
                child: trigger
                    ? const Icon(
                        Icons.touch_app,
                        size: 18,
                      )
                    : SizedBox.square(
                        dimension: 16,
                        child: CircleTimer(
                          code.validFrom * 1000,
                          code.validTo * 1000,
                        ),
                      ),
              ),
              const Spacer(),
              PopupMenuButton(
                child: Icon(Icons.adaptive.more),
                itemBuilder: (context) =>
                    _buildPopupMenu(context, ref, trigger),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
