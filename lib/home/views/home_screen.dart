/*
 * Copyright (C) 2024-2025 Yubico.
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

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../android/state.dart';
import '../../app/color_extension.dart';
import '../../app/message.dart';
import '../../app/models.dart';
import '../../app/state.dart';
import '../../app/views/app_page.dart';
import '../../core/models.dart';
import '../../core/state.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../management/models.dart';
import '../../widgets/focus_border.dart';
import 'key_actions.dart';
import 'manage_label_dialog.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final YubiKeyData deviceData;

  const HomeScreen(this.deviceData, {super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool hide = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final serial = widget.deviceData.info.serial;
    final keyCustomization = ref.watch(keyCustomizationManagerProvider)[serial];
    final enabledCapabilities =
        widget.deviceData.info.config.enabledCapabilities[widget
            .deviceData
            .node
            .transport] ??
        0;

    // We need this to avoid unwanted app switch animation
    if (hide) {
      Timer.run(() {
        setState(() {
          hide = false;
        });
      });
    }

    return AppPage(
      title: hide ? null : l10n.s_home,
      delayedContent: hide,
      keyActionsBuilder: (context) =>
          homeBuildActions(context, widget.deviceData, ref),
      builder: (context, expanded) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0),
          child: Column(
            crossAxisAlignment: .start,
            children: [
              _DeviceContent(widget.deviceData, keyCustomization),
              const SizedBox(height: 16.0),
              Column(
                crossAxisAlignment: .start,
                children: [
                  Wrap(
                    spacing: 4,
                    runSpacing: 8,
                    children: Capability.values
                        .where((c) => enabledCapabilities & c.value != 0)
                        .map((c) => CapabilityBadge(c, noTooltip: true))
                        .toList(),
                  ),
                  if (widget.deviceData.info.fipsCapable != 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 38),
                      child: _FipsLegend(),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FipsLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Opacity(
      opacity: 0.6,
      child: Wrap(
        runSpacing: 0,
        spacing: 16,
        children: [
          RichText(
            text: TextSpan(
              children: [
                const WidgetSpan(
                  alignment: .middle,
                  child: Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(Symbols.shield, size: 12, fill: 0.0),
                  ),
                ),
                TextSpan(
                  text: l10n.l_fips_capable,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          RichText(
            text: TextSpan(
              children: [
                const WidgetSpan(
                  alignment: .middle,
                  child: Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(Symbols.shield, size: 12, fill: 1.0),
                  ),
                ),
                TextSpan(
                  text: l10n.l_fips_approved,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceContent extends ConsumerWidget {
  final YubiKeyData deviceData;
  final KeyCustomization? initialCustomization;

  const _DeviceContent(this.deviceData, this.initialCustomization);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    final name = deviceData.name;
    final serial = deviceData.info.serial;
    final version = deviceData.info.version;

    final label = initialCustomization?.name;
    String displayName = label != null ? '$label ($name)' : name;

    final defaultColor = ref.watch(defaultColorProvider);
    final customColor = initialCustomization?.color;

    return Column(
      crossAxisAlignment: .start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                displayName,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            if (serial != null) ...[
              const SizedBox(width: 8),
              Row(
                crossAxisAlignment: .start,
                children: [
                  IconButton(
                    icon: Icon(Symbols.edit, semanticLabel: l10n.s_set_label),
                    tooltip: l10n.s_set_label,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    onPressed: () async {
                      await ref.read(withContextProvider)((context) async {
                        await _showManageLabelDialog(
                          initialCustomization ??
                              KeyCustomization(serial: serial),
                          context,
                        );
                      });
                    },
                  ),
                  Column(
                    children: [
                      Builder(
                        builder: (context) {
                          return IconButton(
                            tooltip: l10n.s_set_color,
                            icon: Icon(
                              Symbols.palette,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                              semanticLabel: l10n.s_set_color,
                            ),
                            onPressed: () {
                              final button =
                                  context.findRenderObject() as RenderBox;
                              final buttonRect =
                                  button.localToGlobal(Offset.zero) &
                                  button.size;
                              final colors = {
                                Colors.teal: l10n.s_color_teal,
                                Colors.cyan: l10n.s_color_cyan,
                                Colors.blueAccent: l10n.s_color_blue,
                                Colors.deepPurple: l10n.s_color_purple,
                                Colors.red: l10n.s_color_red,
                                Colors.orange: l10n.s_color_orange,
                                Colors.yellow: l10n.s_color_yellow,
                                if (isAndroid &&
                                    ref.read(androidSdkVersionProvider) >= 31)
                                  Colors.lightGreen: l10n.s_color_green,
                              };
                              final collapsedMessage = l10n.s_collapsed;
                              final view = View.of(context);
                              SemanticsService.sendAnnouncement(
                                view,
                                l10n.s_expanded,
                                TextDirection.ltr,
                              );
                              showDialog(
                                context: context,
                                barrierColor: Colors.transparent,
                                builder: (context) => CustomSingleChildLayout(
                                  delegate: _ColorPickerLayoutDelegate(
                                    buttonRect: buttonRect,
                                  ),
                                  child: Material(
                                    elevation: 8,
                                    borderRadius: BorderRadius.circular(12),
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainer,
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: SizedBox(
                                        width: 240,
                                        child: Wrap(
                                          runSpacing: 8,
                                          spacing: 16,
                                          children: [
                                            ...colors.entries.map(
                                              (e) => _ColorButton(
                                                color: e.key,
                                                colorName: e.value,
                                                isSelected:
                                                    customColor?.toInt32 ==
                                                    e.key.toInt32,
                                                onPressed: () {
                                                  _updateColor(
                                                    e.key,
                                                    ref,
                                                    serial,
                                                  );
                                                  Navigator.of(context).pop();
                                                },
                                              ),
                                            ),

                                            // "System default color" button
                                            _ColorButton(
                                              isDefault: true,
                                              color: defaultColor,
                                              colorName: l10n.s_system_default,
                                              isSelected: customColor == null,
                                              onPressed: () {
                                                _updateColor(null, ref, serial);
                                                Navigator.of(context).pop();
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ).then((_) {
                                SemanticsService.sendAnnouncement(
                                  view,
                                  collapsedMessage,
                                  TextDirection.ltr,
                                );
                              });
                            },
                          );
                        },
                      ),
                      Container(
                        height: 3.0,
                        width: 24.0,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8.0),
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        if (serial != null)
          Text(
            l10n.l_serial_number(serial),
            style: Theme.of(context).textTheme.titleSmall?.apply(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        if (version != const Version(0, 0, 0))
          Text(
            l10n.l_firmware_version(deviceData.info.getVersionName()),
            style: Theme.of(context).textTheme.titleSmall?.apply(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        if (deviceData.info.pinComplexity)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: RichText(
              text: TextSpan(
                children: [
                  WidgetSpan(
                    alignment: .middle,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(
                        Symbols.check,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  TextSpan(
                    text: l10n.l_pin_complexity,
                    style: Theme.of(context).textTheme.titleSmall?.apply(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _updateColor(Color? color, WidgetRef ref, int serial) async {
    final manager = ref.read(keyCustomizationManagerProvider.notifier);
    await manager.set(
      serial: serial,
      name: initialCustomization?.name,
      color: color,
    );
  }

  Future<void> _showManageLabelDialog(
    KeyCustomization keyCustomization,
    BuildContext context,
  ) async {
    await showBlurDialog(
      context: context,
      builder: (context) =>
          ManageLabelDialog(initialCustomization: keyCustomization),
    );
  }
}

class _ColorButton extends StatefulWidget {
  final Color color;
  final String colorName;
  final bool isSelected;
  final bool isDefault;
  final Function()? onPressed;

  const _ColorButton({
    required this.color,
    required this.colorName,
    required this.isSelected,
    required this.onPressed,
    this.isDefault = false,
  });

  @override
  State<_ColorButton> createState() => _ColorButtonState();
}

class _ColorButtonState extends State<_ColorButton> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iconColor =
        ThemeData.estimateBrightnessForColor(widget.color) == Brightness.light
        ? Colors.black.withValues(alpha: 0.6)
        : Colors.white.withValues(alpha: 0.9);
    return Semantics(
      button: true,
      label: widget.colorName,
      onTap: widget.onPressed,
      selected: widget.isSelected,
      child: FocusBorder(
        focusNode: _focusNode,
        shape: BoxShape.circle,
        child: ExcludeSemantics(
          excluding: isAndroid,
          child: RawMaterialButton(
            focusNode: _focusNode,
            onPressed: widget.onPressed,
            constraints: const BoxConstraints(minWidth: 26.0, minHeight: 26.0),
            fillColor: widget.color,
            hoverColor: Colors.black12,
            shape: const CircleBorder(),
            child: Icon(
              widget.isDefault && !widget.isSelected
                  ? Symbols.clear
                  : Symbols.circle,
              fill: 1,
              size: 16,
              weight: widget.isDefault ? 700 : null,
              opticalSize: widget.isDefault ? 20 : null,
              color: !widget.isDefault && !widget.isSelected
                  ? Colors.transparent
                  : iconColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _ColorPickerLayoutDelegate extends SingleChildLayoutDelegate {
  final Rect buttonRect;

  _ColorPickerLayoutDelegate({required this.buttonRect});

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return BoxConstraints.loose(constraints.biggest);
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    double x = buttonRect.right - childSize.width;
    double y = buttonRect.bottom;

    double maxX = math.max(8.0, size.width - childSize.width - 8.0);
    double maxY = math.max(8.0, size.height - childSize.height - 8.0);

    x = x.clamp(8.0, maxX);
    y = y.clamp(8.0, maxY);

    return Offset(x, y);
  }

  @override
  bool shouldRelayout(_ColorPickerLayoutDelegate oldDelegate) {
    return buttonRect != oldDelegate.buttonRect;
  }
}
