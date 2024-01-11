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

import '../../widgets/app_input_decoration.dart';
import '../../widgets/app_text_form_field.dart';
import '../../widgets/focus_utils.dart';
import '../../widgets/responsive_dialog.dart';
import '../key_customization.dart';
import '../logging.dart';
import '../models.dart';
import '../state.dart';

final _log = Logger('CustomizePage');

class CustomizePage extends ConsumerStatefulWidget {
  final KeyCustomization? initialCustomization;

  const CustomizePage({super.key, required this.initialCustomization});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _CustomizePageState();
}

class _CustomizePageState extends ConsumerState<CustomizePage> {
  String? _displayName;
  String? _displayColor;

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

  void updateColor(String? colorString) {
    setState(() {
      _displayColor = colorString;
      Color? color =
          colorString != null ? Color(int.parse(colorString, radix: 16)) : null;
      ref.watch(darkThemeProvider.notifier).setPrimaryColor(color);
      ref.watch(lightThemeProvider.notifier).setPrimaryColor(color);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return ResponsiveDialog(
      title: const Text('Customize key appearance'),
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

            await ref.read(withContextProvider)((context) async {
              FocusUtils.unfocus(context);
              final nav = Navigator.of(context);
              nav.pop();
            });
          },
          child: Text(l10n.s_save),
        ),
      ],
      child: Theme(
        // Make the headers use the primary color to pop a bit.
        // Once M3 is implemented this will probably not be needed.
        data: theme.copyWith(
          textTheme: theme.textTheme.copyWith(
              labelLarge: theme.textTheme.labelLarge
                  ?.copyWith(color: theme.colorScheme.primary)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextFormField(
                //controller: displayNameController,
                initialValue: _displayName,
                maxLength: 20,
                decoration: const AppInputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Nick name',
                  helperText: '', // Prevents dialog resizing when disabled
                  prefixIcon: Icon(Icons.key),
                ),
                textInputAction: TextInputAction.done,
                onChanged: (value) {
                  setState(() {
                    _displayName = value.trim();
                  });
                },
                onFieldSubmitted: (_) {},
              ),
              Row(
                children: [
                  const Text('Color: '),
                  const SizedBox(width: 16),
                  ColorButton(
                    color: Colors.yellow,
                    isSelected: _displayColor == 'FFFFEB3B',
                    onPressed: () {
                      updateColor('FFFFEB3B');
                    },
                  ),
                  ColorButton(
                    color: Colors.orange,
                    isSelected: _displayColor == 'FFFF9800',
                    onPressed: () {
                      updateColor('FFFF9800');
                    },
                  ),
                  ColorButton(
                    color: Colors.red,
                    isSelected: _displayColor == 'FFF44336',
                    onPressed: () {
                      updateColor('FFF44336');
                    },
                  ),
                  ColorButton(
                    color: Colors.deepPurple,
                    isSelected: _displayColor == 'FF673AB7',
                    onPressed: () {
                      updateColor('FF673AB7');
                    },
                  ),
                  ColorButton(
                    color: Colors.green,
                    isSelected: _displayColor == 'FF4CAF50',
                    onPressed: () {
                      updateColor('FF4CAF50');
                    },
                  ),
                  ColorButton(
                    color: Colors.teal,
                    isSelected: _displayColor == 'FF009688',
                    onPressed: () {
                      updateColor('FF009688');
                    },
                  ),
                  ColorButton(
                    color: Colors.cyan,
                    isSelected: _displayColor == 'FF00BCD4',
                    onPressed: () {
                      updateColor('FF00BCD4');
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel_rounded),
                    color: _displayColor == null
                        ? theme.colorScheme.surface
                        : theme.colorScheme.onSurface,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        style: BorderStyle.solid,
                        width: 0.4,
                      ),
                      backgroundColor: _displayColor == null
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.surface,
                    ),
                    onPressed: () {
                      updateColor(null);
                    },
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

class ColorButton extends StatefulWidget {
  final MaterialColor color;
  final bool isSelected;
  final Function()? onPressed;

  const ColorButton(
      {super.key,
      required this.color,
      required this.isSelected,
      required this.onPressed});

  @override
  State<ColorButton> createState() => _ColorButtonState();
}

class _ColorButtonState extends State<ColorButton> {
  @override
  Widget build(BuildContext context) {
    var style = OutlinedButton.styleFrom(
      side: BorderSide(
        color: widget.color,
        style: BorderStyle.solid,
        width: 0.4,
      ),
    );
    if (widget.isSelected) {
      style = style.copyWith(
          backgroundColor: MaterialStatePropertyAll(widget.color.shade900));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: IconButton(
        icon: const Icon(Icons.circle),
        color: widget.color,
        style: style,
        onPressed: widget.onPressed,
      ),
    );
  }
}
