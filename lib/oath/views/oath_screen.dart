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
  final DevicePath devicePath;
  const OathScreen(this.devicePath, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(oathStateProvider(devicePath)).when(
          loading: () => AppPage(
            title: const Text('Authenticator'),
            centered: true,
            child: const AppLoadingScreen(),
          ),
          error: (error, _) => AppPage(
            title: const Text('Authenticator'),
            centered: true,
            child: AppFailureScreen('$error'),
          ),
          data: (oathState) => oathState.locked
              ? _LockedView(devicePath, oathState)
              : _UnlockedView(devicePath, oathState),
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
        title: const Text('Authenticator'),
        child: Column(
          children: [
            const ListTile(title: Text('Unlock')),
            _UnlockForm(
              devicePath,
              keystore: oathState.keystore,
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          icon: const Icon(Icons.password),
          label: const Text('Setup'),
          backgroundColor: Theme.of(context).colorScheme.secondary,
          foregroundColor: Theme.of(context).colorScheme.onSecondary,
          onPressed: () {
            showBottomMenu(context, [
              MenuAction(
                text: 'Change password',
                icon: const Icon(Icons.password),
                action: (context) {
                  showDialog(
                    context: context,
                    builder: (context) =>
                        ManagePasswordDialog(devicePath, oathState),
                  );
                },
              ),
              MenuAction(
                text: 'Delete all data',
                icon: const Icon(Icons.delete_outline),
                action: (context) {
                  showDialog(
                    context: context,
                    builder: (context) => ResetDialog(devicePath),
                  );
                },
              ),
            ]);
          },
        ),
      );
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
                hintText: 'Search accounts',
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
          icon: const Icon(Icons.person_add_alt),
          label: const Text('Setup'),
          backgroundColor: Theme.of(context).colorScheme.secondary,
          foregroundColor: Theme.of(context).colorScheme.onSecondary,
          onPressed: () {
            showBottomMenu(context, [
              MenuAction(
                text: 'Add account',
                icon: const Icon(Icons.person_add_alt),
                action: (context) {
                  showDialog(
                    context: context,
                    builder: (context) => OathAddAccountPage(devicePath),
                  );
                },
              ),
              MenuAction(
                text: oathState.hasKey ? 'Change password' : 'Set password',
                icon: const Icon(Icons.password),
                action: (context) {
                  showDialog(
                    context: context,
                    builder: (context) =>
                        ManagePasswordDialog(devicePath, oathState),
                  );
                },
              ),
              MenuAction(
                text: 'Delete all data',
                icon: const Icon(Icons.delete_outline),
                action: (context) {
                  showDialog(
                    context: context,
                    builder: (context) => ResetDialog(devicePath),
                  );
                },
              ),
            ]);
          },
        ),
      );
}

class _UnlockForm extends ConsumerStatefulWidget {
  final DevicePath _devicePath;
  final KeystoreState keystore;
  const _UnlockForm(this._devicePath, {Key? key, required this.keystore})
      : super(key: key);

  @override
  ConsumerState<_UnlockForm> createState() => _UnlockFormState();
}

class _UnlockFormState extends ConsumerState<_UnlockForm> {
  final _passwordController = TextEditingController();
  bool _remember = false;
  bool _wrong = false;

  void _submit() async {
    setState(() {
      _wrong = false;
    });
    final result = await ref
        .read(oathStateProvider(widget._devicePath).notifier)
        .unlock(_passwordController.text, remember: _remember);
    if (!result.first) {
      setState(() {
        _wrong = true;
        _passwordController.clear();
      });
      showMessage(context, 'Wrong password');
    } else if (_remember && !result.second) {
      showMessage(context, 'Failed to remember password');
    }
  }

  @override
  Widget build(BuildContext context) {
    final keystoreFailed = widget.keystore == KeystoreState.failed;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              const Text(
                'Enter the password for your YubiKey. If you don\'t know your password, you\'ll need to reset the YubiKey.',
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: _passwordController,
                autofocus: true,
                obscureText: true,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: 'Password',
                  errorText: _wrong ? 'Wrong password' : null,
                  helperText: '', // Prevents resizing when errorText shown
                ),
                onChanged: (_) => setState(() {}), // Update state on change
                onSubmitted: (_) => _submit(),
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
            onPressed: _passwordController.text.isNotEmpty ? _submit : null,
          ),
        ),
      ],
    );
  }
}
