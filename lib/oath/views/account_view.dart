import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yubico_authenticator/oath/views/account_dialog.dart';

import '../../widgets/circle_timer.dart';
import '../../app/models.dart';
import '../models.dart';
import '../state.dart';
import 'utils.dart';

class AccountView extends ConsumerWidget {
  final YubiKeyData deviceData;
  final OathCredential credential;
  final OathCode? code;
  final FocusNode? focusNode;
  const AccountView(this.deviceData, this.credential, this.code,
      {Key? key, this.focusNode})
      : super(key: key);

  _copyToClipboard(BuildContext context, WidgetRef ref, bool trigger) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    String value;
    if (trigger) {
      final updated = await calculateCode(
        context,
        credential,
        ref.read(credentialListProvider(deviceData.node.path).notifier),
      );
      value = updated.value;
    } else {
      value = code!.value;
    }
    await Clipboard.setData(ClipboardData(text: value));
    await scaffoldMessenger
        .showSnackBar(
          const SnackBar(
            content: Text('Code copied to clipboard'),
            duration: Duration(seconds: 2),
          ),
        )
        .closed;
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
    final expired = code == null ||
        (credential.oathType == OathType.totp &&
            ref.watch(expiredProvider(code.validTo)));
    final trigger = code == null ||
        credential.oathType == OathType.hotp ||
        (credential.touchRequired && expired);

    final darkMode = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      focusNode: focusNode,
      onTap: () {
        showDialog(
          context: context,
          builder: (context) {
            return AccountDialog(deviceData.node, credential);
          },
        );
      },
      onLongPress: () {
        _copyToClipboard(context, ref, trigger);
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
        formatOathCode(code),
        style: expired
            ? Theme.of(context)
                .textTheme
                .headline5
                ?.copyWith(color: Colors.grey)
            : Theme.of(context).textTheme.headline5,
      ),
      subtitle: Text(
        label,
        style: Theme.of(context).textTheme.caption,
        overflow: TextOverflow.fade,
        maxLines: 1,
        softWrap: false,
      ),
      trailing: trigger
          ? Icon(
              credential.touchRequired ? Icons.touch_app : Icons.refresh,
              size: 18,
            )
          : SizedBox.square(
              dimension: 16,
              child: CircleTimer(
                code.validFrom * 1000,
                code.validTo * 1000,
              ),
            ),
    );
  }
}
