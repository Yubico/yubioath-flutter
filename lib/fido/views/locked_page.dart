import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/message.dart';
import '../../app/models.dart';
import '../../app/views/app_page.dart';
import '../models.dart';
import '../state.dart';
import 'pin_dialog.dart';
import 'reset_dialog.dart';

class FidoLockedPage extends ConsumerWidget {
  final DeviceNode node;
  final FidoState state;

  const FidoLockedPage(this.node, this.state, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppPage(
      title: const Text('WebAuthn'),
      child: Column(
        children: [
          if (state.bioEnroll == false) ...[
            const ListTile(
              title: Text('Fingerprints'),
              subtitle: Text('No fingerprints have been added'),
            ),
          ],
          ...state.hasPin
              ? [
                  const ListTile(title: Text('Unlock')),
                  _PinEntryForm(node.path),
                ]
              : [
                  const ListTile(
                    title: Text('PIN'),
                    subtitle: Text('No PIN has been set'),
                  ),
                ],
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.pin),
        label: const Text('Setup'),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        foregroundColor: Theme.of(context).colorScheme.onSecondary,
        onPressed: () {
          showBottomMenu(context, [
            MenuAction(
              text: state.hasPin ? 'Change PIN' : 'Set PIN',
              icon: const Icon(Icons.pin_outlined),
              action: (context) {
                showDialog(
                  context: context,
                  builder: (context) => FidoPinDialog(node.path, state),
                );
              },
            ),
            MenuAction(
              text: 'Delete all data',
              icon: const Icon(Icons.delete_outline),
              action: (context) {
                showDialog(
                  context: context,
                  builder: (context) => ResetDialog(node),
                );
              },
            ),
          ]);
        },
      ),
    );
  }
}

class _PinEntryForm extends ConsumerStatefulWidget {
  final DevicePath _devicePath;
  const _PinEntryForm(this._devicePath, {Key? key}) : super(key: key);

  @override
  ConsumerState<_PinEntryForm> createState() => _PinEntryFormState();
}

class _PinEntryFormState extends ConsumerState<_PinEntryForm> {
  final _pinController = TextEditingController();
  bool _blocked = false;
  int? _retries;

  void _submit() async {
    final result = await ref
        .read(fidoStateProvider(widget._devicePath).notifier)
        .unlock(_pinController.text);
    result.whenOrNull(failed: (retries, authBlocked) {
      setState(() {
        _pinController.clear();
        _retries = retries;
        _blocked = authBlocked;
      });
    });
  }

  String? _getErrorText() {
    if (_retries == 0) {
      return 'PIN is blocked. Factory reset the FIDO application.';
    }
    if (_blocked) {
      return 'PIN temporarily blocked, remove and reinsert your YubiKey.';
    }
    if (_retries != null) {
      return 'Wrong PIN. $_retries attempts remaining.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Enter the FIDO PIN for your YubiKey.'),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: TextField(
              autofocus: true,
              obscureText: true,
              controller: _pinController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'PIN',
                errorText: _getErrorText(),
              ),
              onChanged: (_) => setState(() {}), // Update state on change
              onSubmitted: (_) => _submit(),
            ),
          ),
          Container(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              child: const Text('Unlock'),
              onPressed:
                  _pinController.text.isNotEmpty && !_blocked ? _submit : null,
            ),
          ),
        ],
      ),
    );
  }
}
