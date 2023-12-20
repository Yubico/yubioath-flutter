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
import 'package:path/path.dart';
/*
const primaryGreen = Color(0xffE58B32);
const accentGreen = Color(0xffEDAE70);
const primaryBlue = Color(0xff325f74);
const primaryRed = Color(0xffea4335);
const darkRed = Color(0xffda4d41);
const amber = Color(0xffffca28);

// Theme colors
const themeBlue = Color(0xFF4276F9);
const themePurple = Color(0xFF9955A5);
const themePink = Color(0xFFE2609D);
const themeRed = Color(0xFFE9645C);
const themeOrange = Color(0xFFE58B32);
const themeYellow = Color(0xFFF3C938);
const themeGreen = Color(0xFF78B850);
const themeGrey = Color(0xFF8C8B8C);
*/

const primaryColor = Colors.blueAccent;
//const primaryColor = Colors.green;
//const primaryColor = Colors.deepPurple;

class AppTheme {
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: Brightness.light,
          background: const Color(0xfffefdf4),
          surface: const Color(0xfffefdf4),
        ),
        listTileTheme: const ListTileThemeData(
          // For alignment under menu button
          contentPadding: EdgeInsets.symmetric(horizontal: 18.0),
          visualDensity: VisualDensity.compact,
        ),
        fontFamily: 'Roboto',
        tooltipTheme: const TooltipThemeData(
          waitDuration: Duration(milliseconds: 500),
          textStyle: TextStyle(color: Color(0xff3c3c3c)),
          decoration: BoxDecoration(
            color: Color(0xffe2e2e6),
            borderRadius: BorderRadius.all(Radius.circular(8.0)),
          ),
        ),
      );

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: Brightness.dark,
          background: const Color(0xff282828),
          surface: const Color(0xff282828),
        ),
        listTileTheme: const ListTileThemeData(
          // For alignment under menu button
          contentPadding: EdgeInsets.symmetric(horizontal: 18.0),
          visualDensity: VisualDensity.compact,
        ),
        fontFamily: 'Roboto',
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
