import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app/models.dart';
import '../../exception/cancellation_exception.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../widgets/app_input_decoration.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/responsive_dialog.dart';
import '../models.dart';
import '../state.dart';

class FidoPinDialog2 extends ConsumerStatefulWidget {
  final DevicePath devicePath;
  final FidoState state;

  const FidoPinDialog2({
    super.key,
    required this.devicePath,
    required this.state,
  });

  @override
  ConsumerState<FidoPinDialog2> createState() => _FidoPinDialog2State();
}

class _FidoPinDialog2State extends ConsumerState<FidoPinDialog2> {
  final _pinController = TextEditingController();
  final _pinFocus = FocusNode();
  bool _blocked = false;
  int? _retries;
  bool _pinIsWrong = false;
  bool _isObscure = true;

  @override
  void initState() {
    super.initState();
    _pinFocus.requestFocus();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _pinFocus.dispose();
    super.dispose();
  }

  void _submit() async {
    final navigator = Navigator.of(context);
    _pinFocus.unfocus();

    setState(() {
      _pinIsWrong = false;
      _isObscure = true;
    });
    try {
      final result = await ref
          .read(fidoStateProvider(widget.devicePath).notifier)
          .unlock(_pinController.text);
      switch (result) {
        case PinResultFailure(:final reason):
          {
            switch (reason) {
              case FidoInvalidPin(:final retries, :final authBlocked):
                {
                  _pinController.selection = TextSelection(
                    baseOffset: 0,
                    extentOffset: _pinController.text.length,
                  );
                  _pinFocus.requestFocus();
                  setState(() {
                    _pinIsWrong = true;
                    _retries = retries;
                    _blocked = authBlocked;
                  });
                }
              default:
              // nothing
            }
          }
        case PinResultSuccess():
          {
            navigator.pop(true);
          }
      }
    } on CancellationException catch (_) {
      navigator.pop(false);
    }
  }

  String? _getErrorText() {
    final l10n = AppLocalizations.of(context);
    if (_blocked) {
      return l10n.l_pin_soft_locked;
    }
    if (_retries != null) {
      return l10n.l_wrong_pin_attempts_remaining(_retries!);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authBlocked = widget.state.pinBlocked;
    final pinRetries = widget.state.pinRetries;

    return ResponsiveDialog(
      title: Text(l10n.s_pin_required),
      actions: [
        TextButton(
          onPressed:
              !_pinIsWrong &&
                  _pinController.text.length >= widget.state.minPinLength &&
                  !_blocked
              ? _submit
              : null,
          child: Text(l10n.s_unlock),
        ),
      ],
      builder: (context, fullScreen) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:
              [
                    Text(l10n.p_fido2_pin_required),
                    AppTextField(
                      autofocus: true,
                      obscureText: _isObscure,
                      autofillHints: const [AutofillHints.password],
                      controller: _pinController,
                      focusNode: _pinFocus,
                      enabled: !authBlocked && !_blocked && (_retries ?? 1) > 0,
                      decoration: AppInputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: l10n.s_pin,
                        helperText: pinRetries != null && pinRetries <= 3
                            ? l10n.l_attempts_remaining(pinRetries)
                            : '',
                        // Prevents dialog resizing
                        errorText:
                            (_pinIsWrong || authBlocked) &&
                                !(authBlocked || _retries == 0)
                            ? _getErrorText()
                            : null,
                        errorMaxLines: 3,
                        icon: const Icon(Symbols.pin),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isObscure
                                ? Symbols.visibility
                                : Symbols.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _isObscure = !_isObscure;
                            });
                          },
                          tooltip: _isObscure
                              ? l10n.s_show_pin
                              : l10n.s_hide_pin,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _pinIsWrong = false;
                        });
                      },
                      // Update state on change
                      onSubmitted: (_) {
                        if (_pinController.text.length >=
                            widget.state.minPinLength) {
                          _submit();
                        } else {
                          _pinFocus.requestFocus();
                        }
                      },
                    ).init(),
                  ]
                  .map(
                    (e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: e,
                    ),
                  )
                  .toList(),
        ),
      ),
    );
  }
}
