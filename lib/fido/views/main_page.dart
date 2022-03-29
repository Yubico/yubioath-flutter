import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/models.dart';
import '../models.dart';
import '../state.dart';
import 'pin_dialog.dart';
import 'pin_entry_dialog.dart';
import 'reset_dialog.dart';

class FidoMainPage extends ConsumerWidget {
  final DeviceNode node;
  final FidoState state;
  final Function(SubPage page) setSubPage;

  const FidoMainPage(this.node, this.state,
      {required this.setSubPage, Key? key})
      : super(key: key);

  _openLockedPage(BuildContext context, WidgetRef ref, SubPage subPage) async {
    final unlocked = ref.read(fidoPinProvider(node.path));
    if (unlocked) {
      setSubPage(subPage);
    } else {
      final result = await showDialog(
          context: context, builder: (context) => PinEntryDialog(node.path));
      if (result == true) {
        setSubPage(subPage);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      children: [
        ListTile(
          leading: const CircleAvatar(
            child: Icon(Icons.pin),
          ),
          title: const Text('PIN'),
          subtitle: Text(state.hasPin ? 'Change your PIN' : 'Set a PIN'),
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => FidoPinDialog(node.path, state),
            );
          },
        ),
        if (state.bioEnroll != null)
          ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.fingerprint),
            ),
            title: const Text('Fingerprints'),
            subtitle: Text(state.bioEnroll == true
                ? 'Fingerprints have been registered'
                : 'No fingerprints registered'),
            onTap: () {
              _openLockedPage(context, ref, SubPage.fingerprints);
            },
          ),
        if (state.credMgmt)
          ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.account_box),
            ),
            title: const Text('Credentials'),
            enabled: state.hasPin,
            subtitle: Text(state.hasPin
                ? 'Manage stored credentials on key'
                : 'Set a PIN to manage credentials'),
            onTap: () {
              _openLockedPage(context, ref, SubPage.credentials);
            },
          ),
        ListTile(
          leading: const CircleAvatar(
            child: Icon(Icons.delete_forever),
          ),
          title: const Text('Factory reset'),
          subtitle: const Text('Delete all data and remove PIN'),
          onTap: () async {
            await showDialog(
              context: context,
              builder: (context) => ResetDialog(node),
            );
          },
        ),
      ],
    );
  }
}
