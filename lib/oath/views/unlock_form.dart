import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/message.dart';
import '../../app/models.dart';
import '../models.dart';
import '../keys.dart' as keys;
import '../state.dart';

class UnlockForm extends ConsumerStatefulWidget {
  final DevicePath _devicePath;
  final KeystoreState keystore;
  const UnlockForm(this._devicePath, {required this.keystore, super.key});

  @override
  ConsumerState<UnlockForm> createState() => _UnlockFormState();
}

class _UnlockFormState extends ConsumerState<UnlockForm> {
  final _passwordController = TextEditingController();
  bool _remember = false;
  bool _passwordIsWrong = false;
  bool _isObscure = true;

  void _submit() async {
    setState(() {
      _passwordIsWrong = false;
    });
    final result = await ref
        .read(oathStateProvider(widget._devicePath).notifier)
        .unlock(_passwordController.text, remember: _remember);
    if (!mounted) return;
    if (!result.first) {
      setState(() {
        _passwordIsWrong = true;
        _passwordController.clear();
      });
    } else if (_remember && !result.second) {
      showMessage(
          context, AppLocalizations.of(context)!.oath_failed_remember_pw);
    }
  }

  @override
  Widget build(BuildContext context) {
    final keystoreFailed = widget.keystore == KeystoreState.failed;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.oath_enter_oath_pw,
              ),
              const SizedBox(height: 16.0),
              TextField(
                key: keys.passwordField,
                controller: _passwordController,
                autofocus: true,
                obscureText: _isObscure,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: AppLocalizations.of(context)!.oath_password,
                  errorText: _passwordIsWrong
                      ? AppLocalizations.of(context)!.oath_wrong_password
                      : null,
                  helperText: '', // Prevents resizing when errorText shown
                  prefixIcon: const Icon(Icons.password_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isObscure ? Icons.visibility : Icons.visibility_off,
                      color: IconTheme.of(context).color,
                    ),
                    onPressed: () {
                      setState(() {
                        _isObscure = !_isObscure;
                      });
                    },
                  ),
                ),
                onChanged: (_) => setState(() {
                  _passwordIsWrong = false;
                }), // Update state on change
                onSubmitted: (_) => _submit(),
              ),
            ],
          ),
        ),
        keystoreFailed
            ? ListTile(
                leading: const Icon(Icons.warning_amber_rounded),
                title: Text(
                    AppLocalizations.of(context)!.oath_keystore_unavailable),
                dense: true,
                minLeadingWidth: 0,
              )
            : CheckboxListTile(
                title:
                    Text(AppLocalizations.of(context)!.oath_remember_password),
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
                value: _remember,
                onChanged: (value) {
                  setState(() {
                    _remember = value ?? false;
                  });
                },
              ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              key: keys.unlockButton,
              label: Text(AppLocalizations.of(context)!.oath_unlock),
              icon: const Icon(Icons.lock_open),
              onPressed: _passwordController.text.isNotEmpty ? _submit : null,
            ),
          ),
        ),
      ],
    );
  }
}
