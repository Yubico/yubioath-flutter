import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/message.dart';
import '../../app/models.dart';
import '../../app/state.dart';
import '../../widgets/responsive_dialog.dart';
import '../models.dart';
import '../state.dart';

class FidoPinDialog extends ConsumerStatefulWidget {
  final DevicePath devicePath;
  final FidoState state;
  const FidoPinDialog(this.devicePath, this.state, {super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _FidoPinDialogState();
}

class _FidoPinDialogState extends ConsumerState<FidoPinDialog> {
  String _currentPin = '';
  String _newPin = '';
  String _confirmPin = '';
  String? _currentPinError;
  String? _newPinError;
  bool _currentIsWrong = false;
  bool _newIsWrong = false;

  @override
  Widget build(BuildContext context) {
    // If current device changes, we need to pop back to the main Page.
    ref.listen<DeviceNode?>(currentDeviceProvider, (previous, next) {
      Navigator.of(context).pop();
    });

    final hasPin = widget.state.hasPin;
    final isValid = _newPin.isNotEmpty &&
        _newPin == _confirmPin &&
        (!hasPin || _currentPin.isNotEmpty);

    return ResponsiveDialog(
      title: Text(hasPin ? 'Change PIN' : 'Set PIN'),
      actions: [
        TextButton(
          onPressed: isValid ? _submit : null,
          child: const Text('Save'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasPin) ...[
            const Text(
                "Enter your current PIN. If you don't know your PIN, you'll need to reset the YubiKey."),
            TextFormField(
              initialValue: _currentPin,
              autofocus: true,
              obscureText: true,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'Current PIN',
                errorText: _currentIsWrong ? _currentPinError : null,
                errorMaxLines: 3,
              ),
              onChanged: (value) {
                setState(() {
                  _currentIsWrong = false;
                  _currentPin = value;
                });
              },
            ),
          ],
          const Text(
              'Enter your new PIN. A PIN must be at least 4 characters long and may contain letters, numbers and special characters.'),
          TextFormField(
            initialValue: _newPin,
            autofocus: !hasPin,
            obscureText: true,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: 'New PIN',
              enabled: !hasPin || _currentPin.isNotEmpty,
              errorText: _newIsWrong ? _newPinError : null,
              errorMaxLines: 3,
            ),
            onChanged: (value) {
              setState(() {
                _newIsWrong = false;
                _newPin = value;
              });
            },
          ),
          TextFormField(
            initialValue: _confirmPin,
            obscureText: true,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: 'Confirm PIN',
              enabled:
                  (!hasPin || _currentPin.isNotEmpty) && _newPin.isNotEmpty,
            ),
            onChanged: (value) {
              setState(() {
                _confirmPin = value;
              });
            },
            onFieldSubmitted: (_) {
              if (isValid) {
                _submit();
              }
            },
          ),
        ]
            .map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: e,
                ))
            .toList(),
      ),
    );
  }

  void _submit() async {
    final minPinLength = widget.state.minPinLength;
    final oldPin = _currentPin.isNotEmpty ? _currentPin : null;
    if (_newPin.length < minPinLength) {
      setState(() {
        _newPinError = 'New PIN must be at least $minPinLength characters';
        _newIsWrong = true;
      });
      return;
    }
    final result = await ref
        .read(fidoStateProvider(widget.devicePath).notifier)
        .setPin(_newPin, oldPin: oldPin);
    result.when(success: () {
      Navigator.of(context).pop(true);
      showMessage(context, 'PIN set');
    }, failed: (retries, authBlocked) {
      setState(() {
        if (authBlocked) {
          _currentPinError =
              'PIN has been blocked until the YubiKey is removed and reinserted';
          _currentIsWrong = true;
        } else {
          _currentPinError = 'Wrong PIN ($retries tries remaining)';
          _currentIsWrong = true;
        }
      });
    });
  }
}
