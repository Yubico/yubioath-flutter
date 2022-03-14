import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import 'package:yubico_authenticator/app/views/app_loading_screen.dart';

import '../../app/models.dart';
import '../../app/views/app_failure_screen.dart';
import '../models.dart';
import '../state.dart';

final _mapEquals = const DeepCollectionEquality().equals;

class _CapabilityForm extends StatelessWidget {
  final int capabilities;
  final int enabled;
  final Function(int) onChanged;
  const _CapabilityForm(
      {required this.capabilities,
      required this.enabled,
      required this.onChanged,
      Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6.0,
      runSpacing: 6.0,
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

class _ModeForm extends StatefulWidget {
  final int initialInterfaces;
  final Function(int) onSubmit;
  const _ModeForm(this.initialInterfaces, {required this.onSubmit, Key? key})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _ModeFormState();
}

class _ModeFormState extends State<_ModeForm> {
  int _enabledInterfaces = 0;

  @override
  void initState() {
    super.initState();
    _enabledInterfaces = widget.initialInterfaces;
  }

  @override
  Widget build(BuildContext context) {
    final valid = _enabledInterfaces != 0 &&
        _enabledInterfaces != widget.initialInterfaces;
    return Column(children: [
      ...UsbInterface.values.map(
        (iface) => CheckboxListTile(
          title: Text(iface.name.toUpperCase()),
          value: iface.value & _enabledInterfaces != 0,
          onChanged: (_) {
            setState(() {
              _enabledInterfaces ^= iface.value;
            });
          },
        ),
      ),
      Container(
        padding: const EdgeInsets.all(16.0),
        alignment: Alignment.centerRight,
        child: ElevatedButton(
          onPressed: valid
              ? () {
                  widget.onSubmit(_enabledInterfaces);
                }
              : null,
          child: const Text('Apply changes'),
        ),
      )
    ]);
  }
}

class _CapabilitiesForm extends StatefulWidget {
  final DeviceInfo info;
  final Function(Map<Transport, int>) onSubmit;

  const _CapabilitiesForm(this.info, {required this.onSubmit, Key? key})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _CapabilitiesFormState();
}

class _CapabilitiesFormState extends State<_CapabilitiesForm> {
  late Map<Transport, int> _enabled;

  @override
  void initState() {
    super.initState();
    // Make sure to copy enabledCapabilites, not mutate the original.
    _enabled = {...widget.info.config.enabledCapabilities};
  }

  @override
  Widget build(BuildContext context) {
    final usbCapabilities =
        widget.info.supportedCapabilities[Transport.usb] ?? 0;
    final nfcCapabilities =
        widget.info.supportedCapabilities[Transport.nfc] ?? 0;

    final changed =
        !_mapEquals(widget.info.config.enabledCapabilities, _enabled);
    final valid = changed && (_enabled[Transport.usb] ?? 0) > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (usbCapabilities != 0)
          const ListTile(
            leading: Icon(Icons.usb),
            title: Text('USB applications'),
          ),
        _CapabilityForm(
          capabilities: usbCapabilities,
          enabled: _enabled[Transport.usb] ?? 0,
          onChanged: (enabled) {
            setState(() {
              _enabled[Transport.usb] = enabled;
            });
          },
        ),
        if (nfcCapabilities != 0)
          const ListTile(
            leading: Icon(Icons.wifi),
            title: Text('NFC applications'),
          ),
        _CapabilityForm(
          capabilities: nfcCapabilities,
          enabled: _enabled[Transport.nfc] ?? 0,
          onChanged: (enabled) {
            setState(() {
              _enabled[Transport.nfc] = enabled;
            });
          },
        ),
        Container(
          padding: const EdgeInsets.all(16.0),
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            onPressed: valid
                ? () {
                    widget.onSubmit(_enabled);
                  }
                : null,
            child: const Text('Apply changes'),
          ),
        )
      ],
    );
  }
}

class ManagementScreen extends ConsumerWidget {
  final YubiKeyData deviceData;
  const ManagementScreen(this.deviceData, {Key? key}) : super(key: key);

  Widget _buildCapabilitiesForm(
          BuildContext context, WidgetRef ref, DeviceInfo info) =>
      _CapabilitiesForm(info, onSubmit: (enabled) async {
        final bool reboot;
        if (deviceData.node is UsbYubiKeyNode) {
          // Reboot if USB device descriptor is changed.
          final oldInterfaces = UsbInterfaces.forCapabilites(
              info.config.enabledCapabilities[Transport.usb] ?? 0);
          final newInterfaces =
              UsbInterfaces.forCapabilites(enabled[Transport.usb] ?? 0);
          reboot = oldInterfaces != newInterfaces;
        } else {
          reboot = false;
        }

        Function()? close;
        try {
          if (reboot) {
            // This will take longer, show a message
            close = ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(
                  content: Text('Reconfiguring YubiKey...'),
                  duration: Duration(seconds: 8),
                ))
                .close;
          }
          await ref
              .read(managementStateProvider(deviceData.node.path).notifier)
              .writeConfig(
                info.config.copyWith(enabledCapabilities: enabled),
                reboot: reboot,
              );
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Configuration updated'),
            duration: Duration(seconds: 2),
          ));
        } finally {
          close?.call();
        }
      });

  Widget _buildModeForm(BuildContext context, WidgetRef ref, DeviceInfo info) =>
      _ModeForm(
          UsbInterfaces.forCapabilites(
              info.config.enabledCapabilities[Transport.usb] ?? 0),
          onSubmit: (enabledInterfaces) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Not yet implemented!'),
          duration: Duration(seconds: 1),
        ));
      });

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      ref.watch(managementStateProvider(deviceData.node.path)).when(
          none: () => const AppLoadingScreen(),
          failure: (reason) => AppFailureScreen(reason),
          success: (info) => ListView(
                children: [
                  info.version.major > 4
                      ? _buildCapabilitiesForm(context, ref, info)
                      : _buildModeForm(context, ref, info),
                ],
              ));
}
