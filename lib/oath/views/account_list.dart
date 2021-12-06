import 'package:flutter/material.dart';

import '../../app/models.dart';
import '../models.dart';
import 'account_view.dart';

class AccountList extends StatelessWidget {
  final DeviceNode device;
  final List<OathPair> credentials;
  final List<String> favorites;
  const AccountList(this.device, this.credentials, this.favorites, {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (credentials.isEmpty) {
      return const Center(
        child: Text('No credentials'),
      );
    }

    final favCreds =
        credentials.where((entry) => favorites.contains(entry.credential.id));
    final creds =
        credentials.where((entry) => !favorites.contains(entry.credential.id));

    return ListView(
      children: [
        if (favCreds.isNotEmpty)
          ListTile(
            title: Text(
              'FAVORITES',
              style: Theme.of(context).textTheme.bodyText2,
            ),
          ),
        ...favCreds.map(
          (entry) => AccountView(device, entry.credential, entry.code),
        ),
        if (creds.isNotEmpty)
          ListTile(
            title: Text(
              'ACCOUNTS',
              style: Theme.of(context).textTheme.bodyText2,
            ),
          ),
        ...creds.map(
          (entry) => AccountView(device, entry.credential, entry.code),
        ),
      ],
    );
  }
}
