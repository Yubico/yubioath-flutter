import 'package:flutter/material.dart';

import '../../app/models.dart';
import '../models.dart';
import 'pin_dialog.dart';
import 'reset_dialog.dart';

class FidoMainPage extends StatelessWidget {
  final DeviceNode node;
  final FidoState state;
  final Function(SubPage page) setSubPage;

  const FidoMainPage(this.node, this.state,
      {required this.setSubPage, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
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
              setSubPage(SubPage.fingerprints);
            },
          ),
        if (state.credMgmt)
          ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.account_box),
            ),
            title: const Text('Credentials'),
            subtitle: const Text('Manage stored credentials on key'),
            onTap: () {
              setSubPage(SubPage.credentials);
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
