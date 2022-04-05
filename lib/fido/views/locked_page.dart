import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/message.dart';
import '../../app/models.dart';
import '../../app/views/app_page.dart';
import '../../app/views/message_page.dart';
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
    if (!state.hasPin) {
      if (state.bioEnroll != null) {
        return MessagePage(
          title: const Text('WebAuthn'),
          header: 'No fingerprints',
          message: 'Set a PIN to register fingerprints',
          floatingActionButton: _buildFab(context),
        );
      } else {
        return MessagePage(
          title: const Text('WebAuthn'),
          header: 'No discoverable accounts',
          message:
              'Optionally set a PIN to protect access to your YubiKey\nRegister as a Security Key on websites',
          floatingActionButton: _buildFab(context),
        );
      }
    }

    return AppPage(
      title: const Text('WebAuthn'),
      child: Column(
        children: [
          const ListTile(title: Text('Unlock')),
          _PinEntryForm(state, node),
        ],
      ),
    );
  }

  FloatingActionButton _buildFab(BuildContext context) {
    return FloatingActionButton.extended(
      icon: Icon(
          state.bioEnroll != null ? Icons.fingerprint : Icons.pin_outlined),
      label: const Text('Setup'),
      backgroundColor: Theme.of(context).colorScheme.secondary,
      foregroundColor: Theme.of(context).colorScheme.onSecondary,
      onPressed: () {
        showBottomMenu(context, [
          if (state.bioEnroll != null)
            MenuAction(
              text: 'Add fingerprint',
              icon: const Icon(Icons.fingerprint),
            ),
          MenuAction(
            text: 'Set PIN',
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
    );
  }
}

class _PinEntryForm extends ConsumerStatefulWidget {
  final FidoState _state;
  final DeviceNode _deviceNode;
  const _PinEntryForm(this._state, this._deviceNode, {Key? key})
      : super(key: key);

  @override
  ConsumerState<_PinEntryForm> createState() => _PinEntryFormState();
}

class _PinEntryFormState extends ConsumerState<_PinEntryForm> {
  final _pinController = TextEditingController();
  bool _blocked = false;
  int? _retries;

  void _submit() async {
    final result = await ref
        .read(fidoStateProvider(widget._deviceNode.path).notifier)
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
    final noFingerprints = widget._state.bioEnroll == false;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Enter the FIDO2 PIN for your YubiKey'),
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
          Wrap(
            spacing: 4.0,
            runSpacing: 8.0,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.pin_outlined),
                label: const Text('Change PIN'),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) =>
                        FidoPinDialog(widget._deviceNode.path, widget._state),
                  );
                },
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.delete_outlined),
                label: const Text('Reset FIDO'),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => ResetDialog(widget._deviceNode),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          ListTile(
            leading:
                noFingerprints ? const Icon(Icons.warning_amber_rounded) : null,
            title: noFingerprints
                ? const Text(
                    'No fingerprints have been added',
                    overflow: TextOverflow.fade,
                  )
                : null,
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 0),
            minLeadingWidth: 0,
            trailing: ElevatedButton(
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
