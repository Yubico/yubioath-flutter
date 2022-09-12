import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _ManagePasswordDialogState();
}

class _ManagePasswordDialogState extends ConsumerState<ManagePasswordDialog> {
  String _currentPassword = '';
  String _newPassword = '';
  String _confirmPassword = '';
  bool _currentIsWrong = false;

  _submit() async {
    final result = await ref
        .read(oathStateProvider(widget.path).notifier)
        .setPassword(_currentPassword, _newPassword);
    if (result) {
      if (!mounted) return;
      Navigator.of(context).pop();
      showMessage(context, AppLocalizations.of(context)!.oath_password_set);
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
      title: Text(AppLocalizations.of(context)!.oath_manage_password),
      actions: [
        TextButton(
          onPressed: isValid ? _submit : null,
          key: const Key('save oath password changes'),
          child: Text(AppLocalizations.of(context)!.oath_save),
        )
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.state.hasKey) ...[
              Text(AppLocalizations.of(context)!.oath_enter_current_password),
              TextField(
                autofocus: true,
                obscureText: true,
                key: const Key('current oath password'),
                decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText:
                        AppLocalizations.of(context)!.oath_current_password,
                    prefixIcon: const Icon(Icons.password_outlined),
                    errorText: _currentIsWrong
                        ? AppLocalizations.of(context)!.oath_wrong_password
                        : null,
                    errorMaxLines: 3),
                textInputAction: TextInputAction.next,
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
                    key: const Key('remove oath password btn'),
                    onPressed: _currentPassword.isNotEmpty
                        ? () async {
                            final result = await ref
                                .read(oathStateProvider(widget.path).notifier)
                                .unsetPassword(_currentPassword);
                            if (result) {
                              if (!mounted) return;
                              Navigator.of(context).pop();
                              showMessage(
                                  context,
                                  AppLocalizations.of(context)!
                                      .oath_password_removed);
                            } else {
                              setState(() {
                                _currentIsWrong = true;
                              });
                            }
                          }
                        : null,
                    child: Text(
                        AppLocalizations.of(context)!.oath_remove_password),
                  ),
                  if (widget.state.remembered)
                    OutlinedButton(
                      child: Text(AppLocalizations.of(context)!
                          .oath_clear_saved_password),
                      onPressed: () async {
                        await ref
                            .read(oathStateProvider(widget.path).notifier)
                            .forgetPassword();
                        if (!mounted) return;
                        Navigator.of(context).pop();
                        showMessage(
                            context,
                            AppLocalizations.of(context)!
                                .oath_password_forgotten);
                      },
                    ),
                ],
              ),
            ],
            Text(AppLocalizations.of(context)!.oath_enter_new_password),
            TextField(
              key: const Key('new oath password'),
              autofocus: !widget.state.hasKey,
              obscureText: true,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: AppLocalizations.of(context)!.oath_new_password,
                prefixIcon: const Icon(Icons.password_outlined),
                enabled: !widget.state.hasKey || _currentPassword.isNotEmpty,
              ),
              textInputAction: TextInputAction.next,
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
                labelText: AppLocalizations.of(context)!.oath_confirm_password,
                prefixIcon: const Icon(Icons.password_outlined),
                enabled:
                    (!widget.state.hasKey || _currentPassword.isNotEmpty) &&
                        _newPassword.isNotEmpty,
              ),
              textInputAction: TextInputAction.done,
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
      ),
    );
  }
}
