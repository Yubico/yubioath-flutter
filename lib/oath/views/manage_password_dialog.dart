import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/message.dart';
import '../../app/models.dart';
import '../../app/state.dart';
import '../../widgets/responsive_dialog.dart';
import '../models.dart';
import '../state.dart';

class ManagePasswordDialog extends ConsumerStatefulWidget {
  final DevicePath path;
  final OathState state;
  const ManagePasswordDialog(this.path, this.state, {Key? key})
      : super(key: key);

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _ManagePasswordDialogState();
}

class _ManagePasswordDialogState extends ConsumerState<ManagePasswordDialog> {
  String _currentPassword = '';
  String _newPassword = '';
  String _confirmPassword = '';
  bool _currentIsWrong = false;

  @override
  Widget build(BuildContext context) {
    // If current device changes, we need to pop back to the main Page.
    ref.listen<DeviceNode?>(currentDeviceProvider, (previous, next) {
      Navigator.of(context).pop();
    });

    return ResponsiveDialog(
      title: const Text('Manage password'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.state.hasKey) ...[
            Text(
              'Current password',
              style: Theme.of(context).textTheme.headline6,
            ),
            TextField(
              autofocus: true,
              obscureText: true,
              decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: 'Current password',
                  errorText: _currentIsWrong ? 'Wrong password' : null),
              onChanged: (value) {
                setState(() {
                  _currentPassword = value;
                });
              },
            ),
            Wrap(
              spacing: 4.0,
              runSpacing: 8.0,
              children: [
                OutlinedButton(
                  child: const Text('Remove password'),
                  onPressed: _currentPassword.isNotEmpty
                      ? () async {
                          final result = await ref
                              .read(oathStateProvider(widget.path).notifier)
                              .unsetPassword(_currentPassword);
                          if (result) {
                            Navigator.of(context).pop();
                            showMessage(context, 'Password removed');
                          } else {
                            setState(() {
                              _currentIsWrong = true;
                            });
                          }
                        }
                      : null,
                ),
                if (widget.state.remembered)
                  OutlinedButton(
                    child: const Text('Clear saved password'),
                    onPressed: () async {
                      await ref
                          .read(oathStateProvider(widget.path).notifier)
                          .forgetPassword();
                      Navigator.of(context).pop();
                      showMessage(context, 'Password forgotten');
                    },
                  ),
              ],
            ),
            const Divider(),
          ],
          Text(
            'New password',
            style: Theme.of(context).textTheme.headline6,
          ),
          TextField(
            autofocus: !widget.state.hasKey,
            obscureText: true,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: 'New password',
              enabled: !widget.state.hasKey || _currentPassword.isNotEmpty,
            ),
            onChanged: (value) {
              setState(() {
                _newPassword = value;
              });
            },
          ),
          TextField(
            obscureText: true,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: 'Confirm password',
              enabled: _newPassword.isNotEmpty,
            ),
            onChanged: (value) {
              setState(() {
                _confirmPassword = value;
              });
            },
          ),
        ]
            .map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: e,
                ))
            .toList(),
      ),
      actions: [
        TextButton(
          onPressed: _newPassword.isNotEmpty &&
                  _newPassword == _confirmPassword &&
                  (!widget.state.hasKey || _currentPassword.isNotEmpty)
              ? () async {
                  final result = await ref
                      .read(oathStateProvider(widget.path).notifier)
                      .setPassword(_currentPassword, _newPassword);
                  if (result) {
                    Navigator.of(context).pop();
                    showMessage(context, 'Password set');
                  } else {
                    setState(() {
                      _currentIsWrong = true;
                    });
                  }
                }
              : null,
          child: const Text('Save'),
        )
      ],
    );
  }
}
