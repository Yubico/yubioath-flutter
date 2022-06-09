import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/message.dart';
import '../../app/models.dart';
import '../../app/views/app_page.dart';
import '../../app/views/graphics.dart';
import '../../app/views/message_page.dart';
import '../../theme.dart';
import '../models.dart';
import '../state.dart';
import 'pin_dialog.dart';
import 'reset_dialog.dart';

class FidoLockedPage extends ConsumerWidget {
  final DeviceNode node;
  final FidoState state;

  const FidoLockedPage(this.node, this.state, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!state.hasPin) {
      if (state.bioEnroll != null) {
        return MessagePage(
          title: const Text('WebAuthn'),
          graphic: noFingerprints,
          header: 'No fingerprints',
          message: 'Set a PIN to register fingerprints.',
          actions: _buildActions(context),
        );
      } else {
        return MessagePage(
          title: const Text('WebAuthn'),
          graphic: noDiscoverable,
          header: 'No discoverable accounts',
          message:
              'Optionally set a PIN to protect access to your YubiKey\nRegister as a Security Key on websites',
          actions: _buildActions(context),
        );
      }
    }

    return AppPage(
      title: const Text('WebAuthn'),
      actions: _buildActions(context),
      child: Column(
        children: [
          _PinEntryForm(state, node),
        ],
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context) => [
        if (!state.hasPin)
          OutlinedButton.icon(
            style: AppTheme.primaryOutlinedButtonStyle(context),
            label: const Text('Set PIN'),
            icon: const Icon(Icons.pin),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => FidoPinDialog(node.path, state),
              );
            },
          ),
        OutlinedButton.icon(
          label: const Text('Options'),
          icon: const Icon(Icons.tune),
          onPressed: () {
            showBottomMenu(context, [
              if (state.hasPin)
                MenuAction(
                  text: 'Change PIN',
                  icon: const Icon(Icons.pin),
                  action: (context) {
                    showDialog(
                      context: context,
                      builder: (context) => FidoPinDialog(node.path, state),
                    );
                  },
                ),
              MenuAction(
                text: 'Reset FIDO',
                icon: const Icon(Icons.delete),
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
      ];
}

class _PinEntryForm extends ConsumerStatefulWidget {
  final FidoState _state;
  final DeviceNode _deviceNode;
  const _PinEntryForm(this._state, this._deviceNode);

  @override
  ConsumerState<_PinEntryForm> createState() => _PinEntryFormState();
}

class _PinEntryFormState extends ConsumerState<_PinEntryForm> {
  final _pinController = TextEditingController();
  bool _blocked = false;
  int? _retries;
  bool _pinIsWrong = false;
  bool _isObscure = true;

  void _submit() async {
    setState(() {
      _pinIsWrong = false;
      _isObscure = true;
    });
    final result = await ref
        .read(fidoStateProvider(widget._deviceNode.path).notifier)
        .unlock(_pinController.text);
    result.whenOrNull(failed: (retries, authBlocked) {
      setState(() {
        _pinController.clear();
        _pinIsWrong = true;
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
      padding: const EdgeInsets.only(left: 18.0, right: 18, top: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Enter the FIDO2 PIN for your YubiKey'),
          Padding(
            padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
            child: TextField(
              autofocus: true,
              obscureText: _isObscure,
              controller: _pinController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'PIN',
                helperText: '', // Prevents dialog resizing
                errorText: _pinIsWrong ? _getErrorText() : null,
                errorMaxLines: 3,
                prefixIcon: const Icon(Icons.pin_outlined),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isObscure ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _isObscure = !_isObscure;
                    });
                  },
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _pinIsWrong = false;
                });
              }, // Update state on change
              onSubmitted: (_) => _submit(),
            ),
          ),
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
              onPressed:
                  _pinController.text.isNotEmpty && !_blocked ? _submit : null,
              child: const Text('Unlock'),
            ),
          ),
        ],
      ),
    );
  }
}
