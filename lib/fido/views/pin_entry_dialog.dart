import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/models.dart';
import '../../app/state.dart';
import '../state.dart';

class PinEntryDialog extends ConsumerStatefulWidget {
  final DevicePath _devicePath;
  const PinEntryDialog(this._devicePath, {Key? key}) : super(key: key);

  @override
  ConsumerState<PinEntryDialog> createState() => _PinEntryDialogState();
}

class _PinEntryDialogState extends ConsumerState<PinEntryDialog> {
  final _pinController = TextEditingController();
  bool _blocked = false;
  int? _retries;

  void _submit() async {
    final result = await ref
        .read(fidoPinProvider(widget._devicePath).notifier)
        .unlock(_pinController.text);
    result.when(success: () {
      Navigator.pop(context, true);
    }, failed: (retries, authBlocked) {
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
    // If current device changes, we need to pop back to the main Page.
    ref.listen<DeviceNode?>(currentDeviceProvider, (previous, next) {
      Navigator.of(context).pop();
    });

    return AlertDialog(
      scrollable: true,
      title: const Text('Enter PIN'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enter the FIDO PIN for your YubiKey.',
          ),
          TextField(
            autofocus: true,
            obscureText: true,
            controller: _pinController,
            decoration: InputDecoration(
              labelText: 'PIN',
              errorText: _getErrorText(),
            ),
            onChanged: (_) => setState(() {}), // Update state on change
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: const Text('Continue'),
          onPressed:
              _pinController.text.isNotEmpty && !_blocked ? _submit : null,
        ),
      ],
    );
  }
}
