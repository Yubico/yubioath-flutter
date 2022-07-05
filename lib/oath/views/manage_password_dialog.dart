import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/message.dart';
import '../../app/models.dart';
import '../../widgets/responsive_dialog.dart';
import '../models.dart';
import '../state.dart';

class ManagePasswordDialog extends ConsumerStatefulWidget {
  final DevicePath path;
  final OathState state;
  const ManagePasswordDialog(this.path, this.state, {super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ManagePasswordDialogState();
}

class _ManagePasswordDialogState extends ConsumerState<ManagePasswordDialog> {
  String _currentPassword = '';
  String _newPassword = '';
  String _confirmPassword = '';
  bool _currentIsWrong = false;

  _submit() async {
    final result = await ref.read(oathStateProvider(widget.path).notifier).setPassword(_currentPassword, _newPassword);
    if (result) {
      if (!mounted) return;
      Navigator.of(context).pop();
      showMessage(context, 'Password set');
    } else {
      setState(() {
        _currentIsWrong = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isValid = _newPassword.isNotEmpty &&
        _newPassword == _confirmPassword &&
        (!widget.state.hasKey || _currentPassword.isNotEmpty);

    return ResponsiveDialog(
      title: const Text('Manage password'),
      actions: [
        TextButton(
          onPressed: isValid ? _submit : null,
          child: const Text('Save'),
        )
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.state.hasKey) ...[
            const Text(
                "Enter your current password. If you don't know your password, you'll need to reset the YubiKey."),
            TextField(
              key: const Key('current oath password'),
              autofocus: true,
              obscureText: true,
              decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: 'Current password',
                  prefixIcon: const Icon(Icons.password_outlined),
                  errorText: _currentIsWrong ? 'Wrong password' : null,
                  errorMaxLines: 3),
              onChanged: (value) {
                setState(() {
                  _currentIsWrong = false;
                  _currentPassword = value;
                });
              },
            ),
            Wrap(
              spacing: 4.0,
              runSpacing: 8.0,
              children: [
                OutlinedButton(
                  onPressed: _currentPassword.isNotEmpty
                      ? () async {
                          final result =
                              await ref.read(oathStateProvider(widget.path).notifier).unsetPassword(_currentPassword);
                          if (result) {
                            if (!mounted) return;
                            Navigator.of(context).pop();
                            showMessage(context, 'Password removed');
                          } else {
                            setState(() {
                              _currentIsWrong = true;
                            });
                          }
                        }
                      : null,
                  child: const Text('Remove password'),
                ),
                if (widget.state.remembered)
                  OutlinedButton(
                    child: const Text('Clear saved password'),
                    onPressed: () async {
                      await ref.read(oathStateProvider(widget.path).notifier).forgetPassword();
                      if (!mounted) return;
                      Navigator.of(context).pop();
                      showMessage(context, 'Password forgotten');
                    },
                  ),
              ],
            ),
          ],
          const Text('Enter your new password. A password may contain letters, numbers and special characters.'),
          TextField(
            key: const Key('new oath password'),
            autofocus: !widget.state.hasKey,
            obscureText: true,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: 'New password',
              prefixIcon: const Icon(Icons.password_outlined),
              enabled: !widget.state.hasKey || _currentPassword.isNotEmpty,
            ),
            onChanged: (value) {
              setState(() {
                _newPassword = value;
              });
            },
            onSubmitted: (_) {
              if (isValid) {
                _submit();
              }
            },
          ),
          TextField(
            key: const Key('confirm oath password'),
            obscureText: true,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: 'Confirm password',
              prefixIcon: const Icon(Icons.password_outlined),
              enabled: (!widget.state.hasKey || _currentPassword.isNotEmpty) && _newPassword.isNotEmpty,
            ),
            onChanged: (value) {
              setState(() {
                _confirmPassword = value;
              });
            },
            onSubmitted: (_) {
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
}
