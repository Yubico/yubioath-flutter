import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';

import '../../app/message.dart';
import '../../app/models.dart';
import '../../app/views/app_loading_screen.dart';
import '../../core/models.dart';
import '../../widgets/custom_icons.dart';
import '../../widgets/responsive_dialog.dart';
import '../models.dart';
import '../state.dart';

final _mapEquals = const DeepCollectionEquality().equals;

class _CapabilityForm extends StatelessWidget {
  final int capabilities;
  final int enabled;
  final Function(int) onChanged;
  const _CapabilityForm({
    required this.capabilities,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 16,
      children: Capability.values
          .where((c) => capabilities & c.value != 0)
          .map((c) => FilterChip(
                showCheckmark: true,
                selected: enabled & c.value != 0,
                label: Text(c.name),
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
      Text(interfaces == 0 ? 'At least one interface must be enabled' : ''),
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
    final usbCapabilities = supported[Transport.usb] ?? 0;
    final nfcCapabilities = supported[Transport.nfc] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (usbCapabilities != 0) ...[
          const ListTile(
            leading: Icon(Icons.usb),
            title: Text('USB'),
            contentPadding: EdgeInsets.only(bottom: 8),
            horizontalTitleGap: 0,
          ),
          _CapabilityForm(
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
            title: const Text('NFC'),
            contentPadding: const EdgeInsets.only(bottom: 8),
            horizontalTitleGap: 0,
          ),
          _CapabilityForm(
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
  const ManagementScreen(this.deviceData, {super.key});

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
    _interfaces = UsbInterface.forCapabilites(
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
    final bool reboot;
    if (widget.deviceData.node is UsbYubiKeyNode) {
      // Reboot if USB device descriptor is changed.
      final oldInterfaces = UsbInterface.forCapabilites(
          widget.deviceData.info.config.enabledCapabilities[Transport.usb] ??
              0);
      final newInterfaces =
          UsbInterface.forCapabilites(_enabled[Transport.usb] ?? 0);
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
          'Reconfiguring YubiKey...',
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
      showMessage(context, 'Configuration updated');
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
    await ref
        .read(managementStateProvider(widget.deviceData.node.path).notifier)
        .setMode(interfaces: _interfaces);
    if (!mounted) return;
    showMessage(
        context,
        widget.deviceData.node.maybeMap(
            nfcReader: (_) => 'Configuration updated',
            orElse: () =>
                'Configuration updated, remove and reinsert your YubiKey'));
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
    var canSave = false;
    final child =
        ref.watch(managementStateProvider(widget.deviceData.node.path)).when(
              loading: () => const AppLoadingScreen(),
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
                if (hasConfig) {
                  canSave = _enabled[Transport.usb] != 0 &&
                      !_mapEquals(
                        _enabled,
                        info.config.enabledCapabilities,
                      );
                } else {
                  canSave = _interfaces != 0 &&
                      _interfaces !=
                          UsbInterface.forCapabilites(widget.deviceData.info
                                  .config.enabledCapabilities[Transport.usb] ??
                              0);
                }
                return Column(
                  children: [
                    hasConfig
                        ? _buildCapabilitiesForm(context, ref, info)
                        : _buildModeForm(context, ref, info),
                  ],
                );
              },
            );

    return ResponsiveDialog(
      title: const Text('Toggle applications'),
      actions: [
        TextButton(
          onPressed: canSave ? _submitForm : null,
          child: const Text('Save'),
        ),
      ],
      child: child,
    );
  }
}
