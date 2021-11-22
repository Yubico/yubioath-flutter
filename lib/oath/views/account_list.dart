import 'package:flutter/material.dart';

import '../../app/models.dart';
import '../models.dart';
import 'account_view.dart';

class AccountList extends StatelessWidget {
  final DeviceNode device;
  final List<OathPair> credentials;
  const AccountList(this.device, this.credentials, {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (credentials.isEmpty) {
      return const Center(
        child: Text('No credentials'),
      );
    }

    return ListView(
      shrinkWrap: true,
      children: [
        ...credentials.map(
          (entry) => AccountView(device, entry.credential, entry.code),
        ),
      ],
    );
  }
}
