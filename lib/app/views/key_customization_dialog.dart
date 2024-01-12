/*
 * Copyright (C) 2024 Yubico.
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

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../core/state.dart';
import '../../management/models.dart';
import '../../widgets/app_input_decoration.dart';
import '../../widgets/app_text_form_field.dart';
import '../../widgets/focus_utils.dart';
import '../../widgets/responsive_dialog.dart';
import '../key_customization.dart';
import '../logging.dart';
import '../models.dart';
import '../state.dart';
import 'device_avatar.dart';
import 'keys.dart';

final _log = Logger('KeyCustomizationDialog');

class KeyCustomizationDialog extends ConsumerStatefulWidget {
  final KeyCustomization? initialCustomization;

  const KeyCustomizationDialog({super.key, required this.initialCustomization});

  @override
  ConsumerState<KeyCustomizationDialog> createState() =>
      _KeyCustomizationDialogState();
}

class _KeyCustomizationDialogState
    extends ConsumerState<KeyCustomizationDialog> {
  String? _displayName;
  String? _displayColor;
  Color? _previewColor;

  @override
  void initState() {
    super.initState();

    _displayColor = widget.initialCustomization != null
        ? widget.initialCustomization?.properties['display_color']
        : null;
    _displayName = widget.initialCustomization != null
        ? widget.initialCustomization?.properties['display_name']
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentNode = ref.watch(currentDeviceProvider);
    final theme = Theme.of(context);

    final Widget hero;
    if (currentNode != null) {
      hero = _CurrentDeviceAvatar(currentNode,
          ref.watch(currentDeviceDataProvider), _previewColor ?? Colors.white);
    } else {
      hero = Column(
        children: [
          _HeroAvatar(
            color: _previewColor ?? Colors.white,
            child: DeviceAvatar(
              radius: 64,
              child: Icon(isAndroid ? Icons.no_cell : Icons.usb),
            ),
          ),
          ListTile(
            title: Center(child: Text(l10n.l_no_yk_present)),
            subtitle: Center(
                child: Text(isAndroid ? l10n.l_insert_or_tap_yk : l10n.s_usb)),
          ),
        ],
      );
    }

    final primaryColor = ref.read(primaryColorProvider);

    return Theme(
      data: theme.copyWith(
        colorScheme: ColorScheme.fromSeed(
            brightness: theme.brightness,
            seedColor:
                _previewColor ?? primaryColor ?? theme.colorScheme.primary),
      ),
      child: ResponsiveDialog(
        actions: [
          TextButton(
            onPressed: () async {
              KeyCustomization newValue = KeyCustomization(
                  widget.initialCustomization!.serialNumber, <String, dynamic>{
                'display_color': _displayColor,
                'display_name': _displayName
              });

              _log.debug('Saving customization for '
                  '${widget.initialCustomization!.serialNumber}: '
                  '$_displayName/$_displayColor');

              final manager = ref.read(keyCustomizationManagerProvider);
              manager.set(newValue);
              await manager.write();

              ref.invalidate(lightThemeProvider);
              ref.invalidate(darkThemeProvider);

              await ref.read(withContextProvider)((context) async {
                FocusUtils.unfocus(context);
                final nav = Navigator.of(context);
                nav.pop();
              });
            },
            child: Text(l10n.s_save),
          ),
        ],
        child: Column(
          children: [
            hero,
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AppTextFormField(
                    //controller: displayNameController,
                    initialValue: _displayName,
                    maxLength: 20,
                    decoration: AppInputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: l10n.s_custom_key_name,
                      helperText: '', // Prevents dialog resizing when disabled
                      prefixIcon: const Icon(Icons.key),
                    ),
                    textInputAction: TextInputAction.done,
                    onChanged: (value) {
                      setState(() {
                        _displayName = value.trim();
                      });
                    },
                    onFieldSubmitted: (_) {},
                  ),
                  Text(l10n.s_custom_key_color),
                  Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      ...[
                        [Colors.yellow, 'FFFFEB3B'],
                        [Colors.orange, 'FFFF9800'],
                        [Colors.red, 'FFF44336'],
                        [Colors.deepPurple, 'FF673AB7'],
                        [Colors.green, 'FF4CAF50'],
                        [Colors.teal, 'FF009688'],
                        [Colors.cyan, 'FF00BCD4']
                      ].map((e) => _ColorButton(
                            color: e[0] as MaterialColor,
                            isSelected: _displayColor == e[1],
                            onPressed: () {
                              _updateColor(e[1] as String?);
                            },
                          )),

                      // remove color button
                      RawMaterialButton(
                        onPressed: () => _updateColor(null),
                        constraints: const BoxConstraints(
                            minWidth: 32.0, minHeight: 32.0),
                        fillColor: _displayColor == null
                            ? theme.colorScheme.surface
                            : theme.colorScheme.onSurface,
                        shape: const CircleBorder(),
                        child: Icon(
                          Icons.cancel_rounded,
                          size: 16,
                          color: _displayColor == null
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.surface,
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateColor(String? colorString) {
    setState(() {
      _displayColor = colorString;
      _previewColor =
          colorString != null ? Color(int.parse(colorString, radix: 16)) : null;
    });
  }
}

String _getDeviceInfoString(BuildContext context, DeviceInfo info) {
  final l10n = AppLocalizations.of(context)!;
  final serial = info.serial;
  return [
    if (serial != null) l10n.s_sn_serial(serial),
    if (info.version.isAtLeast(1))
      l10n.s_fw_version(info.version)
    else
      l10n.s_unknown_type,
  ].join(' ');
}

List<String> _getDeviceStrings(
    BuildContext context, DeviceNode node, AsyncValue<YubiKeyData> data) {
  final l10n = AppLocalizations.of(context)!;
  final messages = data.whenOrNull(
        data: (data) => [data.name, _getDeviceInfoString(context, data.info)],
        error: (error, _) {
          switch (error) {
            case 'device-inaccessible':
              return [node.name, l10n.s_yk_inaccessible];
            case 'unknown-device':
              return [l10n.s_unknown_device];
          }
          return null;
        },
      ) ??
      [l10n.l_no_yk_present];

  // Add the NFC reader name, unless it's already included (as device name, like on Android)
  if (node is NfcReaderNode && !messages.contains(node.name)) {
    messages.add(node.name);
  }

  return messages;
}

class _HeroAvatar extends StatelessWidget {
  final Widget child;
  final Color color;

  const _HeroAvatar({required this.color, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withOpacity(0.6),
            color.withOpacity(0.25),
            (DialogTheme.of(context).backgroundColor ??
                    theme.dialogBackgroundColor)
                .withOpacity(0),
          ],
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Theme(
        // Give the avatar a transparent background
        data: theme.copyWith(
            colorScheme:
                theme.colorScheme.copyWith(surfaceVariant: Colors.transparent)),
        child: child,
      ),
    );
  }
}

class _CurrentDeviceAvatar extends ConsumerWidget {
  final DeviceNode node;
  final AsyncValue<YubiKeyData> data;
  final Color color;

  const _CurrentDeviceAvatar(this.node, this.data, this.color);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hero = data.maybeWhen(
      data: (data) => DeviceAvatar.yubiKeyData(data, ref, radius: 64),
      orElse: () => DeviceAvatar.deviceNode(node, ref, radius: 64),
    );
    final messages = _getDeviceStrings(context, node, data);

    return Column(
      children: [
        _HeroAvatar(color: color, child: hero),
        ListTile(
          key: deviceInfoListTile,
          title: Text(messages.removeAt(0), textAlign: TextAlign.center),
          isThreeLine: messages.length > 1,
          subtitle: Text(messages.join('\n'), textAlign: TextAlign.center),
        )
      ],
    );
  }
}

class _ColorButton extends StatefulWidget {
  final MaterialColor color;
  final bool isSelected;
  final Function()? onPressed;

  const _ColorButton({
    required this.color,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  State<_ColorButton> createState() => _ColorButtonState();
}

class _ColorButtonState extends State<_ColorButton> {
  @override
  Widget build(BuildContext context) {
    return RawMaterialButton(
      onPressed: widget.onPressed,
      constraints: const BoxConstraints(minWidth: 32.0, minHeight: 32.0),
      fillColor: widget.color,
      shape: const CircleBorder(),
      child: Icon(
        Icons.circle,
        size: 16,
        color: widget.isSelected ? Colors.white : Colors.transparent,
      ),
    );
  }
}
