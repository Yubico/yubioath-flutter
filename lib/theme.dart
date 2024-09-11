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
import 'package:flutter/services.dart';

const defaultPrimaryColor = Colors.lightGreen;

class AppTheme {
  static ThemeData getTheme(Brightness brightness, Color primaryColor) =>
      switch (brightness) {
        Brightness.light => getLightTheme(primaryColor),
        Brightness.dark => getDarkTheme(primaryColor),
      };

  static ColorScheme _colorScheme(Brightness brightness, Color primaryColor) =>
      switch (brightness) {
        Brightness.dark => ColorScheme.fromSeed(
            seedColor: primaryColor,
            brightness: brightness,
            surface: const Color(0xff282828),
            onSurface: const Color(0xeeffffff),
            onSurfaceVariant: const Color(0xaaffffff),
          ),
        Brightness.light => ColorScheme.fromSeed(
            seedColor: primaryColor,
            brightness: brightness,
            onSurface: const Color(0xbb000000),
            onSurfaceVariant: const Color(0x99000000),
          )
      };

  static ThemeData getLightTheme(Color primaryColor) {
    final colorScheme = _colorScheme(Brightness.light, primaryColor);
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        color: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle(
            statusBarIconBrightness: Brightness.dark,
            statusBarColor: Colors.transparent),
      ),
      listTileTheme: const ListTileThemeData(
        // For alignment under menu button
        contentPadding: EdgeInsets.symmetric(horizontal: 18.0),
        visualDensity: VisualDensity.compact,
      ),
      tooltipTheme: const TooltipThemeData(
        waitDuration: Duration(milliseconds: 500),
        textStyle: TextStyle(color: Color(0xff3c3c3c)),
        decoration: BoxDecoration(
          color: Color(0xffe2e2e6),
          borderRadius: BorderRadius.all(Radius.circular(8.0)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        labelStyle:
            TextStyle(fontFamily: 'Roboto', color: colorScheme.onSurface),
      ),
    );
  }

  static ThemeData getDarkTheme(Color primaryColor) {
    final colorScheme = _colorScheme(Brightness.dark, primaryColor);
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: 'Roboto',
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: const AppBarTheme(
        color: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle(
            statusBarIconBrightness: Brightness.light,
            statusBarColor: Colors.transparent),
      ),
      listTileTheme: const ListTileThemeData(
        // For alignment under menu button
        contentPadding: EdgeInsets.symmetric(horizontal: 18.0),
        visualDensity: VisualDensity.compact,
      ),
      tooltipTheme: const TooltipThemeData(
        waitDuration: Duration(milliseconds: 500),
        textStyle: TextStyle(color: Color(0xffE2E2E6)),
        decoration: BoxDecoration(
          color: Color(0xff3c3c3c),
          borderRadius: BorderRadius.all(Radius.circular(8.0)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        labelStyle:
            TextStyle(fontFamily: 'Roboto', color: colorScheme.onSurface),
      ),
    );
  }
}
