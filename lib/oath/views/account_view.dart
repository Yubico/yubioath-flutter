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

class AccountView extends ConsumerWidget {
  final YubiKeyData deviceData;
  final OathCredential credential;
  final OathCode? code;
  const AccountView(this.deviceData, this.credential, this.code, {Key? key})
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

  List<PopupMenuEntry> _buildPopupMenu(BuildContext context, WidgetRef ref) => [
        PopupMenuItem(
          child: const ListTile(
            leading: Icon(Icons.copy),
            title: Text('Copy to clipboard'),
          ),
          enabled: code != null,
          onTap: () {
            _copyToClipboard(context);
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

  _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: code!.value));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Code copied'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  _calculate(BuildContext context, WidgetRef ref) async {
    VoidCallback? close;
    if (credential.touchRequired) {
      final sbc = ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Touch your YubiKey'),
          duration: Duration(seconds: 30),
        ),
      );
      unawaited(sbc.closed.then((_) {
        close = null;
      }));
      close = sbc.close;
    }
    try {
      await ref
          .read(credentialListProvider(deviceData.node.path).notifier)
          .calculate(credential);
    } finally {
      close?.call();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final code = this.code;
    final expired = ref.watch(_expireProvider(code?.validTo ?? 0));
    final label = credential.issuer != null
        ? '${credential.issuer} (${credential.name})'
        : credential.name;
    final trigger = code == null ||
        expired &&
            (credential.touchRequired || credential.oathType == OathType.hotp);

    return ListTile(
      onTap: () {
        if (trigger) {
          _calculate(context, ref);
        } else {
          _copyToClipboard(context);
        }
      },
      leading: CircleAvatar(
        backgroundColor: Colors.primaries
            .elementAt(label.hashCode % Colors.primaries.length),
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
                itemBuilder: (context) => _buildPopupMenu(context, ref),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
