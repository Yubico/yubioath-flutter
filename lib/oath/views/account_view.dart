import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/circle_timer.dart';
import '../../app/models.dart';
import '../models.dart';
import '../state.dart';

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
  final DeviceNode device;
  final OathCredential credential;
  final OathCode? code;
  const AccountView(this.device, this.credential, this.code, {Key? key})
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
            Clipboard.setData(ClipboardData(text: code!.value));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Code copied'),
                duration: Duration(seconds: 2),
              ),
            );
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
        if (device.info.version.major >= 5 && device.info.version.minor >= 3)
          PopupMenuItem(
            child: const ListTile(
              leading: Icon(Icons.edit),
              title: Text('Rename account'),
            ),
            onTap: () {
              log.info('TODO');
            },
          ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          child: ListTile(
            leading: Icon(Icons.delete_forever),
            title: Text('Delete account'),
          ),
        ),
      ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final code = this.code;
    final expired = ref.watch(_expireProvider(code?.validTo ?? 0));
    final label = credential.issuer != null
        ? '${credential.issuer} (${credential.name})'
        : credential.name;

    return ListTile(
      onTap: () {},
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
          if (code == null ||
              expired &&
                  (credential.touchRequired ||
                      credential.oathType == OathType.hotp))
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () async {
                VoidCallback? close;
                if (credential.touchRequired) {
                  final sbc = ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Touch your YubiKey'),
                      duration: Duration(seconds: 30),
                    ),
                  )..closed.then((_) {
                      close = null;
                    });
                  close = sbc.close;
                }
                await ref
                    .read(credentialListProvider(device.path).notifier)
                    .calculate(credential);
                close?.call();
              },
            ),
          Stack(
            alignment: AlignmentDirectional.bottomCenter,
            children: [
              if (code != null && code.validTo - code.validFrom < 600)
                Align(
                  alignment: AlignmentDirectional.topCenter,
                  child: SizedBox.square(
                    dimension: 16,
                    child:
                        CircleTimer(code.validFrom * 1000, code.validTo * 1000),
                  ),
                ),
              Transform.scale(
                scale: 0.8,
                child: PopupMenuButton(
                  itemBuilder: (context) => _buildPopupMenu(context, ref),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}
