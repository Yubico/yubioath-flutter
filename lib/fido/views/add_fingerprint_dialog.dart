/*
 * Copyright (C) 2022 Yubico.
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
import 'package:yubico_authenticator/app/logging.dart';

import '../../app/message.dart';
import '../../desktop/models.dart';
import '../../widgets/responsive_dialog.dart';
import '../../widgets/utf8_utils.dart';
import '../state.dart';
import '../../fido/models.dart';
import '../../app/models.dart';

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
    super.dispose();
  }

  Animation<Color?> _animateColor(Color color,
      {Function? atPeak, bool reverse = true}) {
    final animation =
        ColorTween(begin: Colors.black, end: color).animate(_animator);
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
    _color =
        ColorTween(begin: Colors.black, end: Colors.black).animate(_animator);

    _subscription = ref
        .read(fingerprintProvider(widget.devicePath).notifier)
        .registerFingerprint()
        .listen((event) {
      setState(() {
        event.when(capture: (remaining) {
          _color = _animateColor(Colors.lightGreenAccent, atPeak: () {
            setState(() {
              _samples += 1;
              _remaining = remaining;
            });
          }, reverse: remaining > 0);
        }, complete: (fingerprint) {
          _remaining = 0;
          _fingerprint = fingerprint;
          // This needs a short delay to ensure the field is enabled first
          Timer(const Duration(milliseconds: 100), _nameFocus.requestFocus);
        }, error: (code) {
          _log.debug('Fingerprint capture error (code: $code)');
          _color = _animateColor(Colors.redAccent);
        });
      });
    }, onError: (error, stacktrace) {
      _log.error('Error adding fingerprint', error, stacktrace);
      Navigator.of(context).pop();
      final String errorMessage;
      // TODO: Make this cleaner than importing desktop specific RpcError.
      if (error is RpcError) {
        errorMessage = error.message;
      } else {
        errorMessage = error.toString();
      }
      showMessage(
        context,
        'Error adding fingerprint: $errorMessage',
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
      showMessage(context, l10n.l_fingerprint_added);
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
      title: Text(l10n.l_add_fingerprint),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.l_fp_step_1_capture),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(36.0),
                  child: AnimatedBuilder(
                    animation: _color,
                    builder: (context, _) {
                      return Icon(
                        _fingerprint == null ? Icons.fingerprint : Icons.check,
                        size: 128.0,
                        color: _color.value,
                      );
                    },
                  ),
                ),
                LinearProgressIndicator(value: progress),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(_getMessage()),
                ),
              ],
            ),
            Text(l10n.l_fp_step_2_name),
            TextFormField(
              focusNode: _nameFocus,
              maxLength: 15,
              inputFormatters: [limitBytesLength(15)],
              buildCounter: buildByteCounterFor(_label),
              autofocus: true,
              decoration: InputDecoration(
                enabled: _fingerprint != null,
                border: const OutlineInputBorder(),
                labelText: l10n.w_name,
                prefixIcon: const Icon(Icons.fingerprint_outlined),
              ),
              onChanged: (value) {
                setState(() {
                  _label = value.trim();
                });
              },
              onFieldSubmitted: (_) {
                _submit();
              },
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
        TextButton(
          onPressed: _fingerprint != null && _label.isNotEmpty ? _submit : null,
          child: Text(l10n.w_save),
        ),
      ],
    );
  }
}
