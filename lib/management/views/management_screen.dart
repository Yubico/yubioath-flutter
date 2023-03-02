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

import '../../app/message.dart';
import '../../app/models.dart';
import '../../core/models.dart';
import '../../widgets/custom_icons.dart';
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
    final keyPrefix = (type == _CapabilityType.usb)
        ? management_keys.usbCapabilityKeyPrefix
        : management_keys.nfcCapabilityKeyPrefix;
    return Wrap(
      spacing: 8,
      runSpacing: 16,
      children: Capability.values
          .where((c) => capabilities & c.value != 0)
          .map((c) => FilterChip(
                label: Text(c.name),
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
    return Column(children: [
      ...UsbInterface.values.map(
        (iface) => CheckboxListTile(
          title: Text(iface.name.toUpperCase()),
          value: iface.value & interfaces != 0,
          onChanged: (_) {
            onChanged(interfaces ^ iface.value);
          },
        ),
      ),
      Text(interfaces == 0
          ? AppLocalizations.of(context)!.l_min_one_interface
          : ''),
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
            leading: const Icon(Icons.usb),
            title: Text(l10n.s_usb),
            contentPadding: const EdgeInsets.only(bottom: 8),
            horizontalTitleGap: 0,
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
              padding: EdgeInsets.only(top: 24, bottom: 12),
              child: Divider(),
            ),
          ListTile(
            leading: nfcIcon,
            title: Text(l10n.s_nfc),
            contentPadding: const EdgeInsets.only(bottom: 8),
            horizontalTitleGap: 0,
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

  @override
  void initState() {
    super.initState();
    _enabled = widget.deviceData.info.config.enabledCapabilities;
    _interfaces = UsbInterface.forCapabilities(
        widget.deviceData.info.config.enabledCapabilities[Transport.usb] ?? 0);
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
          );
      if (!mounted) return;
      if (!reboot) Navigator.pop(context);
      showMessage(context, l10n.s_config_updated);
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
            bool hasConfig = info.version.major > 4;
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
            return Column(
              children: [
                hasConfig
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18.0),
                        child: _buildCapabilitiesForm(context, ref, info),
                      )
                    : _buildModeForm(context, ref, info),
              ],
            );
          },
        );

    return ResponsiveDialog(
      title: Text(l10n.s_toggle_applications),
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
