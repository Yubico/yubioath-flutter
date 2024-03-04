/*
 * Copyright (C) 2022 Yubico.
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
  static ThemeData getTheme(Brightness brightness, Color primaryColor) =>
      switch (brightness) {
        Brightness.light => getLightTheme(primaryColor),
        Brightness.dark => getDarkTheme(primaryColor),
      };

  static ThemeData getLightTheme(Color primaryColor) => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.light,
          seedColor: primaryColor,
          onSurface: const Color(0xbb000000),
          onSurfaceVariant: const Color(0x99000000),
        ),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          color: Colors.transparent,
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
      );

  static ThemeData getDarkTheme(Color primaryColor) => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: primaryColor,
          background: const Color(0xff282828),
          onSurface: const Color(0xeeffffff),
          onSurfaceVariant: const Color(0xaaffffff),
        ),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          color: Colors.transparent,
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
      );
}

/* TODO: Remove this. It is left here as a reference as we adjust styles to work with Flutter 3.7.
/// This fixes the issue with FilterChip resizing vertically on toggle.
BorderSide? _chipBorder(Color color) =>
    MaterialStateBorderSide.resolveWith((states) => BorderSide(
        width: 1,
        color: states.contains(MaterialState.selected)
            ? Colors.transparent
            : color));
*/
