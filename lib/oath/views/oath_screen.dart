import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/message.dart';
import '../../app/models.dart';
import '../../app/views/app_failure_screen.dart';
import '../../app/views/app_loading_screen.dart';
import '../../app/views/app_page.dart';
import '../models.dart';
import '../state.dart';
import 'account_list.dart';
import 'add_account_page.dart';
import 'manage_password_dialog.dart';
import 'reset_dialog.dart';

class OathScreen extends ConsumerWidget {
  final YubiKeyData deviceData;
  const OathScreen(this.deviceData, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(oathStateProvider(deviceData.node.path)).when(
          loading: () => AppPage(child: const AppLoadingScreen()),
          error: (error, _) => AppPage(child: AppFailureScreen('$error')),
          data: (oathState) => oathState.locked
              ? _LockedView(deviceData.node.path, oathState)
              : _UnlockedView(deviceData.node.path, oathState),
        );
  }
}

class _LockedView extends ConsumerWidget {
  final DevicePath devicePath;
  final OathState oathState;

  const _LockedView(this.devicePath, this.oathState, {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) => AppPage(
          child: ListView(
        children: [
          const ListTile(
            title: Text(
              'Unlock',
            ),
          ),
          _UnlockForm(
            keystore: oathState.keystore,
            onSubmit: (password, remember) async {
              final result = await ref
                  .read(oathStateProvider(devicePath).notifier)
                  .unlock(password, remember: remember);
              if (!result.first) {
                showMessage(context, 'Wrong password');
              } else if (remember && !result.second) {
                showMessage(context, 'Failed to remember password');
              }
            },
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Wrap(
              spacing: 4.0,
              runSpacing: 4.0,
              children: [
                OutlinedButton.icon(
                    icon: const Icon(Icons.password),
                    label: Text(
                        oathState.hasKey ? 'Change password' : 'Set password'),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) =>
                            ManagePasswordDialog(devicePath, oathState),
                      );
                    }),
                OutlinedButton.icon(
                  icon: const Icon(Icons.delete_forever),
                  label: const Text('Reset'),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => ResetDialog(devicePath),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ));
}

class _UnlockedView extends ConsumerWidget {
  final DevicePath devicePath;
  final OathState oathState;

  const _UnlockedView(this.devicePath, this.oathState, {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) => AppPage(
        title: Focus(
          canRequestFocus: false,
          onKeyEvent: (node, event) {
            if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              node.focusInDirection(TraversalDirection.down);
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: Builder(builder: (context) {
            return TextFormField(
              initialValue: ref.read(searchProvider),
              decoration: const InputDecoration(
                hintText: 'Search accounts...',
                border: InputBorder.none,
              ),
              onChanged: (value) {
                ref.read(searchProvider.notifier).setFilter(value);
              },
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (value) {
                Focus.of(context).focusInDirection(TraversalDirection.down);
              },
            );
          }),
        ),
        child: AccountList(devicePath, oathState),
        floatingActionButton: FloatingActionButton.extended(
          icon: const Icon(Icons.add),
          label: const Text('Setup'),
          backgroundColor: Theme.of(context).colorScheme.secondary,
          foregroundColor: Theme.of(context).colorScheme.onSecondary,
          onPressed: () {
            showModalBottomSheet(
              context: context,
              constraints: MediaQuery.of(context).size.width > 540
                  ? const BoxConstraints(maxWidth: 380)
                  : null,
              builder: (context) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.add),
                    title: const Text('Add account'),
                    onTap: () {
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (context) => OathAddAccountPage(devicePath),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.password),
                    title: Text(
                        oathState.hasKey ? 'Change password' : 'Set password'),
                    onTap: () {
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (context) =>
                            ManagePasswordDialog(devicePath, oathState),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete_forever),
                    title: const Text('Delete all data'),
                    onTap: () {
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (context) => ResetDialog(devicePath),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      );
}

class _UnlockForm extends StatefulWidget {
  final KeystoreState keystore;
  final Function(String, bool) onSubmit;
  const _UnlockForm({Key? key, required this.keystore, required this.onSubmit})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _UnlockFormState();
}

class _UnlockFormState extends State<_UnlockForm> {
  // TODO: Use a TextEditingController so we can clear it on wrong entry
  String _password = '';
  bool _remember = false;

  @override
  Widget build(BuildContext context) {
    final keystoreFailed = widget.keystore == KeystoreState.failed;
    return Column(
      //mainAxisAlignment: MainAxisAlignment.center,
      //crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter the password for your YubiKey. If you don\'t know your password, you\'ll need to reset the YubiKey.',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: TextField(
                  autofocus: true,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _password = value;
                    });
                  },
                  onSubmitted: (value) {
                    widget.onSubmit(value, _remember);
                  },
                ),
              ),
            ],
          ),
        ),
        CheckboxListTile(
          title: const Text('Remember password'),
          subtitle: Text(keystoreFailed
              ? 'The OS keychain is not available.'
              : 'Uses the OS keychain to protect access to this YubiKey.'),
          controlAffinity: ListTileControlAffinity.leading,
          value: _remember,
          onChanged: keystoreFailed
              ? null
              : (value) {
                  setState(() {
                    _remember = value ?? false;
                  });
                },
        ),
        Container(
          padding: const EdgeInsets.all(16.0),
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            child: const Text('Unlock'),
            onPressed: () {
              widget.onSubmit(_password, _remember);
            },
          ),
        ),
      ],
    );
  }
}
