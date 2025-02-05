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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
import '../../management/models.dart';
import '../../widgets/product_image.dart';
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
    final l10n = AppLocalizations.of(context)!;

    final serial = widget.deviceData.info.serial;
    final keyCustomization = ref.watch(keyCustomizationManagerProvider)[serial];
    final enabledCapabilities = widget.deviceData.info.config
            .enabledCapabilities[widget.deviceData.node.transport] ??
        0;
    final primaryColor = ref.watch(primaryColorProvider);

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DeviceContent(widget.deviceData, keyCustomization),
              const SizedBox(height: 16.0),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    flex: 8,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                  ),
                  if (widget.deviceData.info.version != const Version(0, 0, 0))
                    Flexible(
                      flex: 6,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 200),
                        child: _HeroAvatar(
                          color: keyCustomization?.color ?? primaryColor,
                          child: ProductImage(
                            name: widget.deviceData.name,
                            formFactor: widget.deviceData.info.formFactor,
                            isNfc: widget.deviceData.info.supportedCapabilities
                                .containsKey(Transport.nfc),
                          ),
                        ),
                      ),
                    )
                ],
              )
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
    final l10n = AppLocalizations.of(context)!;
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
                  alignment: PlaceholderAlignment.middle,
                  child: Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(
                      Symbols.shield,
                      size: 12,
                      fill: 0.0,
                    ),
                  ),
                ),
                TextSpan(
                    text: l10n.l_fips_capable,
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          RichText(
            text: TextSpan(
              children: [
                const WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(
                      Symbols.shield,
                      size: 12,
                      fill: 1.0,
                    ),
                  ),
                ),
                TextSpan(
                    text: l10n.l_fips_approved,
                    style: Theme.of(context).textTheme.bodySmall),
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
    final l10n = AppLocalizations.of(context)!;

    final name = deviceData.name;
    final serial = deviceData.info.serial;
    final version = deviceData.info.version;

    final label = initialCustomization?.name;
    String displayName = label != null ? '$label ($name)' : name;

    final defaultColor = ref.watch(defaultColorProvider);
    final customColor = initialCustomization?.color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
                crossAxisAlignment: CrossAxisAlignment.start,
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
                      PopupMenuButton(
                        popUpAnimationStyle:
                            AnimationStyle(duration: Duration.zero),
                        menuPadding: EdgeInsets.zero,
                        tooltip: l10n.s_set_color,
                        itemBuilder: (context) {
                          return [
                            PopupMenuItem(
                              enabled: false,
                              child: Center(
                                child: Wrap(
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
                                          ref.read(androidSdkVersionProvider) >=
                                              31)
                                        Colors.lightGreen
                                    ].map((e) => _ColorButton(
                                          color: e,
                                          isSelected:
                                              customColor?.toInt32 == e.toInt32,
                                          onPressed: () {
                                            _updateColor(e, ref, serial);
                                            Navigator.of(context).pop();
                                          },
                                        )),

                                    // "use default color" button
                                    RawMaterialButton(
                                      onPressed: () {
                                        _updateColor(null, ref, serial);
                                        Navigator.of(context).pop();
                                      },
                                      constraints: const BoxConstraints(
                                          minWidth: 26.0, minHeight: 26.0),
                                      fillColor: defaultColor,
                                      hoverColor: Colors.black12,
                                      shape: const CircleBorder(),
                                      child: Icon(
                                          customColor == null
                                              ? Symbols.circle
                                              : Symbols.clear,
                                          fill: 1,
                                          size: 16,
                                          weight: 700,
                                          opticalSize: 20,
                                          color: defaultColor
                                                      .computeLuminance() >
                                                  0.7
                                              ? Colors.grey // for bright colors
                                              : Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          ];
                        },
                        icon: Icon(
                          Symbols.palette,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Container(
                        height: 3.0,
                        width: 24.0,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8.0),
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.9)),
                      )
                    ],
                  ),
                ],
              )
            ]
          ],
        ),
        const SizedBox(
          height: 12,
        ),
        if (serial != null)
          Text(
            l10n.l_serial_number(serial),
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.apply(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        if (version != const Version(0, 0, 0))
          Text(
            l10n.l_firmware_version(version),
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.apply(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        if (deviceData.info.pinComplexity)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: RichText(
              text: TextSpan(children: [
                WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(
                        Symbols.check,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    )),
                TextSpan(
                  text: l10n.l_pin_complexity,
                  style: Theme.of(context).textTheme.titleSmall?.apply(
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ]),
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
      KeyCustomization keyCustomization, BuildContext context) async {
    await showBlurDialog(
      context: context,
      builder: (context) => ManageLabelDialog(
        initialCustomization: keyCustomization,
      ),
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
      constraints: const BoxConstraints(minWidth: 26.0, minHeight: 26.0),
      fillColor: widget.color,
      hoverColor: Colors.black12,
      shape: const CircleBorder(),
      child: Icon(
        Symbols.circle,
        fill: 1,
        size: 16,
        color: widget.isSelected ? Colors.white : Colors.transparent,
      ),
    );
  }
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
            color.withValues(alpha: 0.6),
            color.withValues(alpha: 0.25),
            (DialogTheme.of(context).backgroundColor ??
                    theme.dialogBackgroundColor)
                .withValues(alpha: 0),
          ],
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: child,
    );
  }
}
