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

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app/message.dart';
import '../../app/models.dart';
import '../../core/models.dart';
import '../../widgets/app_input_decoration.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/delayed_visibility.dart';
import '../../widgets/responsive_dialog.dart';
import '../models.dart';
import '../state.dart';
import 'keys.dart' as management_keys;

final _mapEquals = const DeepCollectionEquality().equals;
const _usbCcid = 0x04;

enum _CapabilityType { usb, nfc }

class _CapabilityForm extends StatelessWidget {
  final _CapabilityType type;
  final int capabilities;
  final int enabled;
  final Function(int) onChanged;
  const _CapabilityForm({
    required this.type,
    required this.capabilities,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final keyPrefix = (type == _CapabilityType.usb)
        ? management_keys.usbCapabilityKeyPrefix
        : management_keys.nfcCapabilityKeyPrefix;
    return Wrap(
      spacing: 4.0,
      runSpacing: 8.0,
      children: Capability.values
          .where((c) => capabilities & c.value != 0)
          .map((c) => FilterChip(
                label: Text(c.getDisplayName(l10n)),
                key: Key('$keyPrefix.${c.name}'),
                selected: enabled & c.value != 0,
                onSelected: (_) {
                  onChanged(enabled ^ c.value);
                },
              ))
          .toList(),
    );
  }
}

class _ModeForm extends StatelessWidget {
  final int interfaces;
  final Function(int) onChanged;
  const _ModeForm(this.interfaces, {required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ListTile(
        leading: const Icon(Symbols.usb),
        title: Text(l10n.s_usb),
        contentPadding: const EdgeInsets.only(bottom: 8),
      ),
      Align(
          alignment: Alignment.topLeft,
          child: Wrap(
              spacing: 4.0,
              runSpacing: 8.0,
              children: UsbInterface.values
                  .map((iface) => FilterChip(
                        label: Text(iface.name.toUpperCase()),
                        selected: iface.value & interfaces != 0,
                        onSelected: (_) {
                          onChanged(interfaces ^ iface.value);
                        },
                      ))
                  .toList())),
    ]);
  }
}

class _CapabilitiesForm extends StatelessWidget {
  final Map<Transport, int> supported;
  final Map<Transport, int> enabled;
  final Function(Map<Transport, int> enabled) onChanged;

  const _CapabilitiesForm({
    required this.onChanged,
    required this.supported,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final usbCapabilities = supported[Transport.usb] ?? 0;
    final nfcCapabilities = supported[Transport.nfc] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (usbCapabilities != 0) ...[
          ListTile(
            leading: const Icon(Symbols.usb),
            title: Text(l10n.s_usb),
            contentPadding: const EdgeInsets.only(bottom: 4),
          ),
          _CapabilityForm(
            type: _CapabilityType.usb,
            capabilities: usbCapabilities,
            enabled: enabled[Transport.usb] ?? 0,
            onChanged: (value) {
              onChanged({...enabled, Transport.usb: value});
            },
          ),
        ],
        if (nfcCapabilities != 0) ...[
          if (usbCapabilities != 0)
            const Padding(
              padding: EdgeInsets.only(top: 8, bottom: 8),
            ),
          ListTile(
            leading: const Icon(Symbols.contactless),
            title: Text(l10n.s_nfc),
            contentPadding: const EdgeInsets.only(bottom: 4),
          ),
          _CapabilityForm(
            type: _CapabilityType.nfc,
            capabilities: nfcCapabilities,
            enabled: enabled[Transport.nfc] ?? 0,
            onChanged: (value) {
              onChanged({...enabled, Transport.nfc: value});
            },
          ),
        ]
      ],
    );
  }
}

class ManagementScreen extends ConsumerStatefulWidget {
  final YubiKeyData deviceData;

  const ManagementScreen(this.deviceData)
      : super(key: management_keys.screenKey);

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _ManagementScreenState();
}

class _ManagementScreenState extends ConsumerState<ManagementScreen> {
  late Map<Transport, int> _enabled;
  late int _interfaces;
  final _lockCodeController = TextEditingController();
  final _lockCodeFocus = FocusNode();
  bool _lockCodeIsWrong = false;
  String _lockCodeError = '';
  bool _isObscure = true;
  final lockCodeLength = 32;
  bool _configuring = false;

  @override
  void initState() {
    super.initState();
    _enabled = widget.deviceData.info.config.enabledCapabilities;
    _interfaces = UsbInterface.forCapabilities(
        widget.deviceData.info.config.enabledCapabilities[Transport.usb] ?? 0);
  }

  @override
  void dispose() {
    _lockCodeController.dispose();
    _lockCodeFocus.dispose();
    super.dispose();
  }

  Widget _buildLockCodeForm(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.p_lock_code_required_desc),
        AppTextField(
          obscureText: _isObscure,
          maxLength: lockCodeLength,
          autofillHints: const [AutofillHints.password],
          controller: _lockCodeController,
          focusNode: _lockCodeFocus,
          decoration: AppInputDecoration(
            border: const OutlineInputBorder(),
            labelText: l10n.s_lock_code,
            errorText: _lockCodeIsWrong ? _lockCodeError : null,
            errorMaxLines: 3,
            prefixIcon: const Icon(Symbols.pin),
            suffixIcon: IconButton(
              icon: Icon(
                  _isObscure ? Symbols.visibility : Symbols.visibility_off),
              onPressed: () {
                setState(() {
                  _isObscure = !_isObscure;
                });
              },
              tooltip:
                  _isObscure ? l10n.s_show_lock_code : l10n.s_hide_lock_code,
            ),
          ),
          textInputAction: TextInputAction.next,
          onChanged: (value) {
            setState(() {
              _lockCodeIsWrong = false;
            });
          },
          onSubmitted: (_) => _submitForm,
        ).init()
      ]
          .map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: e,
              ))
          .toList(),
    );
  }

  Widget _buildCapabilitiesForm(
      BuildContext context, WidgetRef ref, DeviceInfo info) {
    return _CapabilitiesForm(
      supported: widget.deviceData.info.supportedCapabilities,
      enabled: _enabled,
      onChanged: (enabled) {
        setState(() {
          _enabled = enabled;
        });
      },
    );
  }

  void _submitCapabilitiesForm() async {
    final l10n = AppLocalizations.of(context)!;
    final isLocked = widget.deviceData.info.isLocked;

    if (isLocked && !Format.hex.isValid(_lockCodeController.text)) {
      _lockCodeController.selection = TextSelection(
          baseOffset: 0, extentOffset: _lockCodeController.text.length);
      _lockCodeFocus.requestFocus();
      setState(() {
        _lockCodeError =
            l10n.l_invalid_format_allowed_chars(Format.hex.allowedCharacters);
        _lockCodeIsWrong = true;
      });
      return;
    }

    final bool reboot;
    if (widget.deviceData.node is UsbYubiKeyNode) {
      // Reboot if USB device descriptor is changed.
      final oldInterfaces = UsbInterface.forCapabilities(
          widget.deviceData.info.config.enabledCapabilities[Transport.usb] ??
              0);
      final newInterfaces =
          UsbInterface.forCapabilities(_enabled[Transport.usb] ?? 0);
      reboot = oldInterfaces != newInterfaces;
    } else {
      reboot = false;
    }

    Function()? close;
    try {
      setState(() {
        _configuring = true;
      });
      if (reboot) {
        // This will take longer, show a message
        close = showMessage(
          context,
          l10n.s_reconfiguring_yk,
          duration: const Duration(seconds: 8),
        );
      }
      await ref
          .read(managementStateProvider(widget.deviceData.node.path).notifier)
          .writeConfig(
              widget.deviceData.info.config
                  .copyWith(enabledCapabilities: _enabled),
              reboot: reboot,
              currentLockCode: _lockCodeController.text);
      if (!mounted) return;
      Navigator.pop(context);
      showMessage(context, l10n.s_config_updated);
    } catch (_) {
      if (isLocked) {
        _lockCodeController.selection = TextSelection(
            baseOffset: 0, extentOffset: _lockCodeController.text.length);
        _lockCodeFocus.requestFocus();
        setState(() {
          _lockCodeIsWrong = true;
          _configuring = false;
          _lockCodeError = l10n.l_wrong_lock_code;
        });
      }
    } finally {
      close?.call();
    }
  }

  Widget _buildModeForm(BuildContext context, WidgetRef ref, DeviceInfo info) =>
      _ModeForm(
        _interfaces,
        onChanged: (interfaces) {
          setState(() {
            _interfaces = interfaces;
          });
        },
      );

  void _submitModeForm() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _configuring = true;
    });
    await ref
        .read(managementStateProvider(widget.deviceData.node.path).notifier)
        .setMode(interfaces: _interfaces);
    if (!mounted) return;
    showMessage(
        context,
        widget.deviceData.node.maybeMap(
            nfcReader: (_) => l10n.s_config_updated,
            orElse: () => l10n.l_config_updated_reinsert));
    Navigator.pop(context);
  }

  void _submitForm() {
    if (widget.deviceData.info.version.major > 4) {
      _submitCapabilitiesForm();
    } else {
      _submitModeForm();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    var canSave = false;
    bool hasConfig = false;
    final child = ref
        .watch(managementStateProvider(widget.deviceData.node.path))
        .when(
          loading: () => const Center(
              child: DelayedVisibility(
            delay: Duration(milliseconds: 200),
            child: CircularProgressIndicator(),
          )),
          error: (error, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          data: (info) {
            hasConfig = info.version.major > 4;
            int usbEnabled = _enabled[Transport.usb] ?? 0;
            if (hasConfig) {
              // Ignore the _usbCcid bit:
              canSave = (usbEnabled & ~_usbCcid) != 0 &&
                  !_mapEquals(
                    _enabled,
                    info.config.enabledCapabilities,
                  );
            } else {
              canSave = _interfaces != 0 &&
                  _interfaces !=
                      UsbInterface.forCapabilities(widget.deviceData.info.config
                              .enabledCapabilities[Transport.usb] ??
                          0);
            }
            if (info.isLocked) {
              final lockCode = _lockCodeController.text.replaceAll(' ', '');
              canSave = canSave &&
                  lockCode.length == lockCodeLength &&
                  !_lockCodeIsWrong;
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8),
                  child: Text(hasConfig
                      ? l10n.p_toggle_applications_desc
                      : l10n.p_toggle_interfaces_desc),
                ),
                hasConfig
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18.0),
                        child: _buildCapabilitiesForm(context, ref, info),
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18.0),
                        child: _buildModeForm(context, ref, info),
                      ),
                if (info.isLocked)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18.0)
                        .copyWith(top: 20),
                    child: _buildLockCodeForm(context),
                  ),
                Padding(
                  padding: EdgeInsets.only(
                      top: info.isLocked ? 4.0 : 24.0,
                      bottom: 4,
                      left: 18.0,
                      right: 18.0),
                  child: Visibility(
                    visible: _configuring,
                    maintainSize: true,
                    maintainAnimation: true,
                    maintainState: true,
                    child: const LinearProgressIndicator(),
                  ),
                ),
              ],
            );
          },
        );

    return ResponsiveDialog(
      title: hasConfig
          ? Text(l10n.s_toggle_applications)
          : Text(l10n.s_toggle_interfaces),
      actions: [
        TextButton(
          onPressed: canSave ? _submitForm : null,
          key: management_keys.saveButtonKey,
          child: Text(l10n.s_save),
        ),
      ],
      child: child,
    );
  }
}
