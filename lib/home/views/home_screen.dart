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

import 'package:flutter/material.dart';
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
                    icon: const Icon(Symbols.edit),
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
                      _ColorPickerButton(
                        l10n: l10n,
                        serial: serial,
                        customColor: customColor,
                        defaultColor: defaultColor,
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

class _ColorPickerButton extends ConsumerStatefulWidget {
  final AppLocalizations l10n;
  final int serial;
  final Color? customColor;
  final Color defaultColor;

  const _ColorPickerButton({
    required this.l10n,
    required this.serial,
    required this.customColor,
    required this.defaultColor,
  });

  @override
  ConsumerState<_ColorPickerButton> createState() => _ColorPickerButtonState();
}

class _ColorPickerButtonState extends ConsumerState<_ColorPickerButton> {
  bool _announceCollapsed = false;

  void _updateColor(Color? color) async {
    final manager = ref.read(keyCustomizationManagerProvider.notifier);
    await manager.set(
      serial: widget.serial,
      name: ref.read(keyCustomizationManagerProvider)[widget.serial]?.name,
      color: color,
    );
  }

  void _announceCollapsedState() {
    if (mounted) {
      setState(() {
        _announceCollapsed = true;
      });
      // Reset after a short delay to allow the announcement
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _announceCollapsed = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final customColor = widget.customColor;
    final defaultColor = widget.defaultColor;

    final colors = {
      Colors.teal: l10n.s_color_teal,
      Colors.cyan: l10n.s_color_cyan,
      Colors.blueAccent: l10n.s_color_blue,
      Colors.deepPurple: l10n.s_color_purple,
      Colors.red: l10n.s_color_red,
      Colors.orange: l10n.s_color_orange,
      Colors.yellow: l10n.s_color_yellow,
      if (isAndroid && ref.read(androidSdkVersionProvider) >= 31)
        Colors.lightGreen: l10n.s_color_green,
    };

    return Semantics(
      liveRegion: _announceCollapsed,
      label: _announceCollapsed ? l10n.s_collapsed : null,
      child: PopupMenuButton(
        tooltip: l10n.s_set_color,
        onCanceled: _announceCollapsedState,
        itemBuilder: (context) {
          return [
            _ColorPickerMenuEntry(
              child: Semantics(
                liveRegion: true,
                label: l10n.s_expanded,
                child: Center(
                  child: Wrap(
                    runSpacing: 8,
                    spacing: 16,
                    children: [
                      ...colors.entries.map(
                        (e) => _ColorButton(
                          color: e.key,
                          colorName: e.value,
                          isSelected: customColor?.toInt32 == e.key.toInt32,
                          onPressed: () {
                            _updateColor(e.key);
                            Navigator.of(context).pop();
                            _announceCollapsedState();
                          },
                        ),
                      ),
                      _ColorButton(
                        isDefault: true,
                        color: defaultColor,
                        colorName: l10n.s_system_default,
                        isSelected: customColor == null,
                        onPressed: () {
                          _updateColor(null);
                          Navigator.of(context).pop();
                          _announceCollapsedState();
                        },
                        icon: Icon(
                          customColor == null ? Symbols.circle : Symbols.clear,
                          fill: 1,
                          size: 16,
                          weight: 700,
                          opticalSize: 20,
                          color: defaultColor.computeLuminance() > 0.7
                              ? Colors.grey
                              : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        icon: Icon(
          Symbols.palette,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _ColorPickerMenuEntry extends PopupMenuEntry<void> {
  final Widget child;

  const _ColorPickerMenuEntry({required this.child});

  @override
  double get height => kMinInteractiveDimension;

  @override
  bool represents(void value) => false;

  @override
  State<_ColorPickerMenuEntry> createState() => _ColorPickerMenuEntryState();
}

class _ColorPickerMenuEntryState extends State<_ColorPickerMenuEntry> {
  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.all(16), child: widget.child);
  }
}

class _ColorButton extends StatefulWidget {
  final Color color;
  final String colorName;
  final bool isSelected;
  final bool isDefault;
  final Function()? onPressed;
  final Widget? icon;

  const _ColorButton({
    required this.color,
    required this.colorName,
    required this.isSelected,
    required this.onPressed,
    this.icon,
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
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: widget.colorName,
      onTap: widget.onPressed,
      child: ExcludeSemantics(
        child: ListenableBuilder(
          listenable: _focusNode,
          builder: (context, child) => DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: _focusNode.hasFocus
                  ? Border.all(color: colorScheme.primary, width: 1)
                  : null,
            ),
            child: child!,
          ),
          child: RawMaterialButton(
            focusNode: _focusNode,
            onPressed: widget.onPressed,
            constraints: const BoxConstraints(minWidth: 26.0, minHeight: 26.0),
            fillColor: widget.color,
            hoverColor: Colors.black12,
            shape: const CircleBorder(),
            child: widget.isDefault
                ? Icon(
                    widget.isSelected ? Symbols.circle : Symbols.clear,
                    fill: 1,
                    size: 16,
                    weight: 700,
                    opticalSize: 20,
                    color: widget.color.computeLuminance() > 0.7
                        ? Colors.grey
                        : Colors.white,
                  )
                : Icon(
                    Symbols.circle,
                    fill: 1,
                    size: 16,
                    color: widget.isSelected
                        ? Colors.white
                        : Colors.transparent,
                  ),
          ),
        ),
      ),
    );
  }
}
