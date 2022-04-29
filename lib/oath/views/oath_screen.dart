import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/message.dart';
import '../../app/models.dart';
import '../../app/views/app_failure_screen.dart';
import '../../app/views/app_loading_screen.dart';
import '../../app/views/app_page.dart';
import '../../app/views/message_page.dart';
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
              oathState,
              keystore: oathState.keystore,
            ),
          ],
        ),
      );
}

class _UnlockedView extends ConsumerWidget {
  final DevicePath devicePath;
  final OathState oathState;

  const _UnlockedView(this.devicePath, this.oathState, {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEmpty = ref.watch(credentialListProvider(devicePath)
        .select((value) => value?.isEmpty == true));
    if (isEmpty) {
      return MessagePage(
        title: const Text('Authenticator'),
        header: 'No accounts',
        message: 'Follow the instructions on a website to add an account',
        floatingActionButton: _buildFab(context),
      );
    }

    return AppPage(
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
            key: const Key('search_accounts'),
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
      floatingActionButton: _buildFab(context),
    );
  }

  FloatingActionButton _buildFab(BuildContext context) {
    final fab = FloatingActionButton.extended(
      icon: const Icon(Icons.person_add_alt_1),
      label: const Text('Setup'),
      onPressed: () {
        showBottomMenu(context, [
          MenuAction(
            text: 'Add account',
            icon: const Icon(Icons.person_add_alt),
            action: (context) {
              showDialog(
                context: context,
                builder: (context) => OathAddAccountPage(
                  devicePath,
                  openQrScanner: Platform.isAndroid,
                ),
              );
            },
          ),
          MenuAction(
            text: oathState.hasKey ? 'Manage password' : 'Set password',
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
            text: 'Reset OATH',
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
    );
    return fab;
  }
}

class _UnlockForm extends ConsumerStatefulWidget {
  final DevicePath _devicePath;
  final OathState _oathState;
  final KeystoreState keystore;
  const _UnlockForm(this._devicePath, this._oathState,
      {Key? key, required this.keystore})
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter the OATH password for your YubiKey',
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
              Wrap(
                spacing: 4.0,
                runSpacing: 8.0,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.password),
                    label: const Text('Manage password'),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => ManagePasswordDialog(
                            widget._devicePath, widget._oathState),
                      );
                    },
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.delete_outlined),
                    label: const Text('Reset OATH'),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => ResetDialog(widget._devicePath),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16.0),
        Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            Expanded(
              child: keystoreFailed
                  ? const ListTile(
                      leading: Icon(Icons.warning_amber_rounded),
                      title: Text('OS Keystore unavailable'),
                      dense: true,
                      minLeadingWidth: 0,
                    )
                  : CheckboxListTile(
                      title: const Text('Remember password'),
                      dense: true,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: _remember,
                      onChanged: (value) {
                        setState(() {
                          _remember = value ?? false;
                        });
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ElevatedButton(
                child: const Text('Unlock'),
                onPressed: _passwordController.text.isNotEmpty ? _submit : null,
              ),
            )
          ],
        ),
      ],
    );
  }
}
