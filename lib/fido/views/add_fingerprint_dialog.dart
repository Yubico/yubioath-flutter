/*
 * Copyright (C) 2022-2023 Yubico.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *       http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// ignore_for_file: sort_child_properties_last

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app/logging.dart';
import '../../app/message.dart';
import '../../app/models.dart';
import '../../desktop/models.dart';
import '../../fido/models.dart';
import '../../widgets/app_input_decoration.dart';
import '../../widgets/app_text_form_field.dart';
import '../../widgets/responsive_dialog.dart';
import '../../widgets/utf8_utils.dart';
import '../state.dart';

final _log = Logger('fido.views.add_fingerprint_dialog');

class AddFingerprintDialog extends ConsumerStatefulWidget {
  final DevicePath devicePath;
  const AddFingerprintDialog(this.devicePath, {super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _AddFingerprintDialogState();
}

class _AddFingerprintDialogState extends ConsumerState<AddFingerprintDialog>
    with SingleTickerProviderStateMixin {
  late FocusNode _nameFocus;

  late AnimationController _animator;
  late Animation<Color?> _color;
  late StreamSubscription<FingerprintEvent> _subscription;

  int _samples = 0;
  int _remaining = 5;
  Fingerprint? _fingerprint;
  String _label = '';

  @override
  void dispose() {
    _animator.dispose();
    _nameFocus.dispose();
    _subscription.cancel();
    super.dispose();
  }

  Animation<Color?> _animateColor(bool success,
      {Function? atPeak, bool reverse = true}) {
    final theme = Theme.of(context);
    final darkMode = theme.brightness == Brightness.dark;
    final beginColor = darkMode ? Colors.white : Colors.black;
    final endColor =
        success ? theme.colorScheme.primary : theme.colorScheme.error;
    final animation =
        ColorTween(begin: beginColor, end: endColor).animate(_animator);
    _animator.forward().then((_) {
      if (reverse) {
        atPeak?.call();
        _animator.reverse();
      }
    });
    return animation;
  }

  @override
  void initState() {
    super.initState();

    _nameFocus = FocusNode();
    _animator = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250));
    _color = ColorTween().animate(_animator);

    _subscription = ref
        .read(fingerprintProvider(widget.devicePath).notifier)
        .registerFingerprint()
        .listen((event) {
      setState(() {
        event.when(capture: (remaining) {
          _color = _animateColor(true, atPeak: () {
            setState(() {
              _samples += 1;
              _remaining = remaining;
            });
          }, reverse: remaining > 0);
        }, complete: (fingerprint) {
          _remaining = 0;
          // Add delay to show that progressbar is filled
          Timer(const Duration(milliseconds: 200), () {
            setState(() {
              _fingerprint = fingerprint;
            });
            // This needs a short delay to ensure the field is enabled first
            Timer(const Duration(milliseconds: 100), _nameFocus.requestFocus);
          });
        }, error: (code) {
          _log.debug('Fingerprint capture error (code: $code)');
          _color = _animateColor(false);
        });
      });
    }, onError: (error, stacktrace) {
      _log.error('Error adding fingerprint', error, stacktrace);

      if (!mounted) return;
      Navigator.of(context).pop();
      final l10n = AppLocalizations.of(context)!;
      final String errorMessage;
      // TODO: Make this cleaner than importing desktop specific RpcError.
      if (error is RpcError) {
        if (error.status == 'user-action-timeout') {
          errorMessage = l10n.l_user_action_timeout_error;
        } else if (error.status == 'connection-error') {
          errorMessage = l10n.l_failed_connecting_to_fido;
        } else {
          errorMessage = error.message;
        }
      } else {
        errorMessage = error.toString();
      }
      showMessage(
        context,
        l10n.l_adding_fingerprint_failed(errorMessage),
        duration: const Duration(seconds: 4),
      );
    });
  }

  String _getMessage() {
    final l10n = AppLocalizations.of(context)!;
    if (_samples == 0) {
      return l10n.p_press_fingerprint_begin;
    }
    if (_fingerprint == null) {
      return l10n.l_keep_touching_yk;
    } else {
      return l10n.l_fingerprint_captured;
    }
  }

  void _submit() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await ref
          .read(fingerprintProvider(widget.devicePath).notifier)
          .renameFingerprint(_fingerprint!, _label);
      if (!mounted) return;
      Navigator.of(context).pop(true);
      showMessage(context, l10n.s_fingerprint_added);
    } catch (e) {
      final String errorMessage;
      // TODO: Make this cleaner than importing desktop specific RpcError.
      if (e is RpcError) {
        errorMessage = e.message;
      } else {
        errorMessage = e.toString();
      }
      showMessage(
        context,
        l10n.l_setting_name_failed(errorMessage),
        duration: const Duration(seconds: 4),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final progress = _samples == 0 ? 0.0 : _samples / (_samples + _remaining);
    return ResponsiveDialog(
      title: Text(l10n.s_add_fingerprint),
      child: Padding(
        padding: const EdgeInsets.only(top: 38, bottom: 4, right: 18, left: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    _getMessage(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.normal),
                  ),
                ),
                Padding(
                  padding: _fingerprint == null
                      ? const EdgeInsets.all(34)
                      : const EdgeInsets.only(top: 4, bottom: 12),
                  child: AnimatedBuilder(
                    animation: _color,
                    builder: (context, _) {
                      return Icon(
                        _fingerprint == null
                            ? Symbols.fingerprint
                            : Symbols.check,
                        size: 128.0,
                        color: _color.value,
                      );
                    },
                  ),
                ),
                if (_fingerprint == null)
                  Container(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: LinearProgressIndicator(
                      value: progress,
                    ),
                  ),
                if (_fingerprint != null) ...[
                  Text(
                    l10n.l_name_fingerprint,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.normal),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: AppTextFormField(
                      focusNode: _nameFocus,
                      maxLength: 15,
                      inputFormatters: [limitBytesLength(15)],
                      buildCounter: buildByteCounterFor(_label),
                      autofocus: true,
                      decoration: AppInputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: l10n.s_name,
                        prefixIcon: const Icon(Symbols.fingerprint),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _label = value.trim();
                        });
                      },
                      onFieldSubmitted: (_) {
                        _submit();
                      },
                    ).init(),
                  )
                ]
              ],
            ),
          ]
              .map((e) => Padding(
                    child: e,
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                  ))
              .toList(),
        ),
      ),
      onCancel: () {
        _subscription.cancel();
      },
      actions: [
        if (_fingerprint != null)
          TextButton(
            onPressed: _label.isNotEmpty ? _submit : null,
            child: Text(l10n.s_save),
          )
      ],
    );
  }
}
