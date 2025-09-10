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

const defaultPrimaryColor = Colors.lightGreen;

class AppTheme {
  static ThemeData getLightTheme(Color primaryColor) =>
      _themeData(Brightness.light, primaryColor);
  static ThemeData getDarkTheme(Color primaryColor) =>
      _themeData(Brightness.dark, primaryColor);

  static ProgressIndicatorThemeData _progressIndicatorThemeData() =>
      // ignore: deprecated_member_use
      ProgressIndicatorThemeData(year2023: false);

  static ColorScheme _colorScheme(Brightness brightness, Color primaryColor) {
    const darkSurface = Color(0xff1e1e1e);
    return switch (brightness) {
      Brightness.dark => ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: brightness,
        surface: darkSurface,
      ),
      Brightness.light => ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: brightness,
      ),
    };
  }

  static ThemeData _themeData(Brightness brightness, Color primaryColor) {
    final colorScheme = _colorScheme(brightness, primaryColor);
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: 'Roboto',
      listTileTheme: const ListTileThemeData(
        // For alignment under menu button
        contentPadding: EdgeInsets.symmetric(horizontal: 18.0),
        visualDensity: VisualDensity.compact,
      ),
      chipTheme: ChipThemeData(
        labelStyle: TextStyle(
          fontFamily: 'Roboto',
          color: colorScheme.onSurface,
        ),
      ),
      progressIndicatorTheme: _progressIndicatorThemeData(),
    );
  }
}
