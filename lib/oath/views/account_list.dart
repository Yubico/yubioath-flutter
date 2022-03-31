import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/models.dart';
import '../models.dart';
import '../state.dart';
import 'account_view.dart';

class AccountList extends ConsumerStatefulWidget {
  final DevicePath devicePath;
  final OathState oathState;
  const AccountList(this.devicePath, this.oathState, {Key? key})
      : super(key: key);

  @override
  ConsumerState<AccountList> createState() => _AccountListState();
}

class _AccountListState extends ConsumerState<AccountList> {
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
    final accounts = ref.watch(credentialListProvider(widget.devicePath));
    if (accounts == null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Center(child: CircularProgressIndicator()),
        ],
      );
    }
    final credentials = ref.watch(filteredCredentialsProvider(accounts));
    final favorites = ref.watch(favoritesProvider);
    if (credentials.isEmpty) {
      return const Center(
        child: Text('No credentials'),
      );
    }

    final pinnedCreds =
        credentials.where((entry) => favorites.contains(entry.credential.id));
    final creds =
        credentials.where((entry) => !favorites.contains(entry.credential.id));

    _credentials =
        pinnedCreds.followedBy(creds).map((e) => e.credential).toList();
    _updateFocusNodes();

    return ListView(
      children: [
        if (pinnedCreds.isNotEmpty)
          const ListTile(
            title: Text(
              'Pinned',
            ),
          ),
        ...pinnedCreds.map(
          (entry) => AccountView(
            entry.credential,
            focusNode: _focusNodes[entry.credential],
          ),
        ),
        if (creds.isNotEmpty)
          const ListTile(
            title: Text(
              'Accounts',
            ),
          ),
        ...creds.map(
          (entry) => AccountView(
            entry.credential,
            focusNode: _focusNodes[entry.credential],
          ),
        ),
        // Make sure FAB doesn't block content
        const SizedBox(height: 72.0),
      ],
    );
  }
}
