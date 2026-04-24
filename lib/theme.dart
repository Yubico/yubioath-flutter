/*
 * Copyright (C) 2021-2024 Yubico.
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

import 'core/state.dart';

const defaultPrimaryColor = Colors.lightGreen;

class AppTheme {
  static ThemeData getLightTheme(Color primaryColor) =>
      _themeData(.light, primaryColor);
  static ThemeData getDarkTheme(Color primaryColor) =>
      _themeData(.dark, primaryColor);

  static ProgressIndicatorThemeData _progressIndicatorThemeData() =>
      // ignore: deprecated_member_use
      ProgressIndicatorThemeData(year2023: false);

  static ColorScheme _colorScheme(Brightness brightness, Color primaryColor) {
    const darkSurface = Color(0xff1e1e1e);
    return switch (brightness) {
      .dark => ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: brightness,
        surface: darkSurface,
      ),
      .light => ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: brightness,
      ),
    };
  }

  /// Returns a [WidgetStateProperty] that provides a 1px border in
  /// [ColorScheme.primary] when focused, aiming to improve visibility
  /// and contrast.
  static WidgetStateProperty<BorderSide?> _focusBorderSide(
    ColorScheme colorScheme,
  ) => WidgetStateProperty.resolveWith<BorderSide?>((states) {
    if (states.contains(WidgetState.focused)) {
      return BorderSide(color: colorScheme.primary, width: 1);
    }
    return null;
  });

  static ThemeData _themeData(Brightness brightness, Color primaryColor) {
    final colorScheme = _colorScheme(brightness, primaryColor);
    final focusBorder = isAndroid ? null : _focusBorderSide(colorScheme);
    final focusButtonStyle = ButtonStyle(side: focusBorder);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: 'Roboto',
      textButtonTheme: TextButtonThemeData(style: focusButtonStyle),
      elevatedButtonTheme: ElevatedButtonThemeData(style: focusButtonStyle),
      outlinedButtonTheme: OutlinedButtonThemeData(style: focusButtonStyle),
      iconButtonTheme: IconButtonThemeData(style: focusButtonStyle),
      filledButtonTheme: FilledButtonThemeData(style: focusButtonStyle),
      menuButtonTheme: MenuButtonThemeData(style: focusButtonStyle),
      chipTheme: ChipThemeData(
        labelStyle: TextStyle(
          fontFamily: 'Roboto',
          color: colorScheme.onSurface,
        ),
        side: WidgetStateBorderSide.resolveWith((states) {
          if (!isAndroid && states.contains(WidgetState.focused)) {
            return BorderSide(color: colorScheme.primary);
          }
          if (states.contains(WidgetState.disabled)) {
            return BorderSide(
              color: colorScheme.onSurface.withValues(alpha: 0.12),
            );
          }
          if (states.contains(WidgetState.selected)) {
            return BorderSide(color: Colors.transparent);
          }
          return BorderSide(color: colorScheme.outline);
        }),
      ),
      listTileTheme: const ListTileThemeData(
        // For alignment under menu button
        contentPadding: EdgeInsets.symmetric(horizontal: 18.0),
        visualDensity: VisualDensity.compact,
      ),
      progressIndicatorTheme: _progressIndicatorThemeData(),
    );
  }
}
