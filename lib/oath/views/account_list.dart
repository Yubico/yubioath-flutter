import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/models.dart';
import '../models.dart';
import 'account_view.dart';

class AccountList extends StatefulWidget {
  final YubiKeyData deviceData;
  final List<OathPair> credentials;
  final List<String> favorites;
  const AccountList(this.deviceData, this.credentials, this.favorites,
      {Key? key})
      : super(key: key);

  @override
  State<AccountList> createState() => _AccountListState();
}

class _AccountListState extends State<AccountList> {
  List<OathCredential> _credentials = [];
  Map<OathCredential, FocusNode> _focusNodes = {};

  @override
  void dispose() {
    super.dispose();
    for (var e in _focusNodes.values) {
      e.dispose();
    }
    _focusNodes.clear();
  }

  void _updateFocusNodes() {
    _focusNodes = {
      for (var cred in _credentials)
        cred: _focusNodes[cred] ??
            FocusNode(
              debugLabel: cred.id,
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent) {
                  int index = -1;
                  ScrollPositionAlignmentPolicy policy =
                      ScrollPositionAlignmentPolicy.explicit;
                  if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                    index = _credentials.indexOf(cred) + 1;
                    policy = ScrollPositionAlignmentPolicy.keepVisibleAtEnd;
                  } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                    index = _credentials.indexOf(cred) - 1;
                    policy = ScrollPositionAlignmentPolicy.keepVisibleAtStart;
                  }
                  if (index >= 0 && index < _credentials.length) {
                    final targetNode = _focusNodes[_credentials[index]]!;
                    targetNode.requestFocus();
                    Scrollable.ensureVisible(
                      targetNode.context!,
                      alignmentPolicy: policy,
                    );
                    return KeyEventResult.handled;
                  }
                }
                return KeyEventResult.ignored;
              },
            )
    };
    _focusNodes.removeWhere((cred, _) => !_credentials.contains(cred));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.credentials.isEmpty) {
      return const Center(
        child: Text('No credentials'),
      );
    }

    final favCreds = widget.credentials
        .where((entry) => widget.favorites.contains(entry.credential.id));
    final creds = widget.credentials
        .where((entry) => !widget.favorites.contains(entry.credential.id));

    _credentials = favCreds.followedBy(creds).map((e) => e.credential).toList();
    _updateFocusNodes();

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
          (entry) => AccountView(
            widget.deviceData,
            entry.credential,
            entry.code,
            focusNode: _focusNodes[entry.credential],
          ),
        ),
        if (creds.isNotEmpty)
          ListTile(
            title: Text(
              'ACCOUNTS',
              style: Theme.of(context).textTheme.bodyText2,
            ),
          ),
        ...creds.map(
          (entry) => AccountView(
            widget.deviceData,
            entry.credential,
            entry.code,
            focusNode: _focusNodes[entry.credential],
          ),
        ),
      ],
    );
  }
}
