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
import 'package:material_symbols_icons/symbols.dart';

import '../../../android/state.dart';
import '../../../core/state.dart';
import '../../../management/models.dart';
import '../../../theme.dart';
import '../../../widgets/app_input_decoration.dart';
import '../../../widgets/app_text_form_field.dart';
import '../../../widgets/focus_utils.dart';
import '../../../widgets/responsive_dialog.dart';
import '../../models.dart';
import '../../state.dart';
import '../../views/device_avatar.dart';
import '../../views/keys.dart';
import '../models.dart';
import '../state.dart';

class KeyCustomizationDialog extends ConsumerStatefulWidget {
  final KeyCustomization initialCustomization;
  final DeviceNode? node;

  const KeyCustomizationDialog(
      {super.key, required this.node, required this.initialCustomization});

  @override
  ConsumerState<KeyCustomizationDialog> createState() =>
      _KeyCustomizationDialogState();
}

class _KeyCustomizationDialogState
    extends ConsumerState<KeyCustomizationDialog> {
  String? _customName;
  Color? _customColor;

  @override
  void initState() {
    super.initState();
    _customName = widget.initialCustomization.name;
    _customColor = widget.initialCustomization.color;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentNode = widget.node;
    final theme = Theme.of(context);
    final primaryColor = ref.watch(defaultColorProvider);

    final Widget hero;
    if (currentNode != null) {
      hero = _CurrentDeviceAvatar(currentNode, _customColor ?? primaryColor);
    } else {
      hero = Column(
        children: [
          _HeroAvatar(
            color: _customColor ?? primaryColor,
            child: DeviceAvatar(
              radius: 64,
              child: Icon(isAndroid ? Symbols.contactless_off : Symbols.usb),
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

    final didChange = widget.initialCustomization.name != _customName ||
        widget.initialCustomization.color != _customColor;

    return Theme(
      data: AppTheme.getTheme(theme.brightness, _customColor ?? primaryColor),
      child: ResponsiveDialog(
        actions: [
          TextButton(
            onPressed: didChange ? _submit : null,
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
                  Container(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: AppTextFormField(
                      initialValue: _customName,
                      maxLength: 20,
                      decoration: AppInputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: l10n.s_label,
                        helperText:
                            '', // Prevents dialog resizing when disabled
                        prefixIcon: const Icon(Symbols.key),
                      ),
                      textInputAction: TextInputAction.done,
                      onChanged: (value) {
                        setState(() {
                          final trimmed = value.trim();
                          _customName = trimmed.isEmpty ? null : trimmed;
                        });
                      },
                      onFieldSubmitted: (_) {
                        _submit();
                      },
                    ),
                  ),
                  Text(l10n.s_theme_color),
                  const SizedBox(height: 16),
                  Container(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      runSpacing: 8,
                      spacing: 16,
                      children: [
                        ...[
                          Colors.teal,
                          Colors.cyan,
                          Colors.blueAccent,
                          Colors.deepPurple,
                          Colors.red,
                          Colors.orange,
                          Colors.yellow,
                          // add nice color to devices with dynamic color
                          if (isAndroid &&
                              ref.read(androidSdkVersionProvider) >= 31)
                            Colors.lightGreen
                        ].map((e) => _ColorButton(
                              color: e,
                              isSelected: _customColor == e,
                              onPressed: () {
                                _updateColor(e);
                              },
                            )),

                        // remove color button
                        RawMaterialButton(
                          onPressed: () => _updateColor(null),
                          constraints: const BoxConstraints(
                              minWidth: 32.0, minHeight: 32.0),
                          fillColor: (isAndroid &&
                                  ref.read(androidSdkVersionProvider) >= 31)
                              ? theme.colorScheme.onSurface
                              : primaryColor,
                          shape: const CircleBorder(),
                          child: Icon(
                            Symbols.cancel_rounded,
                            size: 16,
                            color: _customColor == null
                                ? theme.colorScheme.onSurface
                                : theme.colorScheme.surface.withOpacity(0.2),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() async {
    final manager = ref.read(keyCustomizationManagerProvider.notifier);
    await manager.set(
        serial: widget.initialCustomization.serial,
        name: _customName,
        color: _customColor);

    await ref.read(withContextProvider)((context) async {
      FocusUtils.unfocus(context);
      final nav = Navigator.of(context);
      nav.pop();
    });
  }

  void _updateColor(Color? color) {
    setState(() {
      _customColor = color;
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
    BuildContext context, WidgetRef ref, DeviceNode node) {
  final data = ref.watch(currentDeviceDataProvider);

  final messages = node is UsbYubiKeyNode
      ? node.info != null
          ? [node.name, _getDeviceInfoString(context, node.info!)]
          : <String>[]
      : data.hasValue
          ? data.value?.node.path == node.path
              ? [
                  data.value!.name,
                  _getDeviceInfoString(context, data.value!.info)
                ]
              : <String>[]
          : <String>[];
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
  final Color color;

  const _CurrentDeviceAvatar(this.node, this.color);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hero = DeviceAvatar.deviceNode(node, radius: 64);
    final messages = _getDeviceStrings(context, ref, node);

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
  final Color? color;
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
        Symbols.circle,
        size: 16,
        color: widget.isSelected ? Colors.white : Colors.transparent,
      ),
    );
  }
}
