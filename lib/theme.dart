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

const primaryGreen = Color(0xffaed581);
const accentGreen = Color(0xff9aca3c);
const primaryBlue = Color(0xff325f74);
const primaryRed = Color(0xffea4335);
const darkRed = Color(0xffda4d41);

class AppTheme {
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.light,
          seedColor: const Color(0xff2196f3),
          //seedColor: primaryBlue,
        ).copyWith(
          primary: primaryBlue,
          //secondary: accentGreen,
        ),
        textTheme: TextTheme(
          bodySmall: TextStyle(color: Colors.grey.shade900),
        ),
        dialogTheme: const DialogTheme(
          surfaceTintColor: Colors.white70,
        ),
      );

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: const Color(0xff2196f3),
          //seedColor: const Color(0xff3f51b5),
        ).copyWith(
          primary: primaryGreen,
          //onPrimary: Colors.grey.shade900,
          //secondary: accentGreen,
          //secondary: const Color(0xff5d7d90),
          //onSecondary: Colors.grey.shade900,
          //primaryContainer: Colors.grey.shade800,
          //onPrimaryContainer: Colors.grey.shade100,
          error: darkRed,
          onError: Colors.white.withOpacity(0.9),
        ),
        textTheme: TextTheme(
          bodySmall: TextStyle(color: Colors.grey.shade500),
        ),
        dialogTheme: DialogTheme(
          surfaceTintColor: Colors.grey.shade700,
        ),
      );

  /* TODO: Remove this. It is left here as a reference as we adjust styles to work with Flutter 3.7.
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme:
            ColorScheme.fromSwatch(brightness: Brightness.light).copyWith(
          primary: primaryBlue,
          secondary: accentGreen,
          background: Colors.grey.shade200,
        ),
        iconTheme: IconThemeData(
          color: Colors.grey.shade400,
          size: 18.0,
        ),
        //backgroundColor: Colors.white,
        toggleableActiveColor: accentGreen,
        appBarTheme: AppBarTheme(
            elevation: 0,
            toolbarHeight: 48,
            //shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.grey.shade800,
            systemOverlayStyle: const SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.dark,
                systemNavigationBarIconBrightness: Brightness.dark)),
        // Mainly used for the OATH dialog view at the moment
        buttonTheme: ButtonThemeData(
          colorScheme: ColorScheme.light(
            secondary: Colors.grey.shade300,
            onSecondary: Colors.grey.shade900,
            primary: primaryGreen,
            onPrimary: Colors.grey.shade900,
            error: primaryRed,
            onError: Colors.grey.shade100,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: primaryBlue,
        )),
        outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
          side: BorderSide(width: 1, color: Colors.grey.shade400),
        )),
        cardTheme: CardTheme(
          color: Colors.grey.shade300,
        ),
        chipTheme: ChipThemeData(
          selectedColor: const Color(0xffd2dbdf),
          side: _chipBorder(Colors.grey.shade400),
          checkmarkColor: Colors.black,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: primaryBlue,
        ),
        listTileTheme: const ListTileThemeData(
          // For alignment under menu button
          contentPadding: EdgeInsets.symmetric(horizontal: 18.0),
          visualDensity: VisualDensity.compact,
        ),
        fontFamily: 'Roboto',
        textTheme: const TextTheme(
          //bodySmall: TextStyle(color: Colors.grey.shade500),
          //bodyLarge: const TextStyle(color: Colors.white70),
          //bodyMedium: TextStyle(color: Colors.grey.shade200),
          //labelSmall: TextStyle(color: Colors.grey.shade500),
          //labelMedium: TextStyle(color: Colors.cyan.shade200),
          //labelLarge: TextStyle(color: Colors.cyan.shade500),
          //titleSmall: TextStyle(color: Colors.grey.shade600),
          //titleMedium: const TextStyle(),
          titleMedium: TextStyle(fontWeight: FontWeight.w300, fontSize: 16),
          titleLarge: TextStyle(
              //color: Colors.grey.shade500,
              fontWeight: FontWeight.w400,
              fontSize: 18),
          headlineSmall: TextStyle(
              //color: Colors.grey.shade200,
              fontWeight: FontWeight.w300,
              fontSize: 16),
        ),
      );
  */

  /* TODO: Remove this. It is left here as a reference as we adjust styles to work with Flutter 3.7.
  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme:
            ColorScheme.fromSwatch(brightness: Brightness.dark).copyWith(
          primary: primaryGreen,
          onPrimary: Colors.black,
          secondary: const Color(0xff5d7d90),
        ),
        // Default for CircleAvatar background if foreground is light
        primaryColorDark: Colors.white38,
        errorColor: darkRed,
        iconTheme: const IconThemeData(
          color: Colors.white70,
          size: 18.0,
        ),
        toggleableActiveColor: primaryGreen,
        appBarTheme: AppBarTheme(
            elevation: 0,
            toolbarHeight: 48,
            //shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.grey.shade400,
            systemOverlayStyle: const SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.light,
                systemNavigationBarIconBrightness: Brightness.light)),
        // Mainly used for the OATH dialog view at the moment
        buttonTheme: ButtonThemeData(
          colorScheme: ColorScheme.dark(
            secondary: Colors.grey.shade800,
            onSecondary: Colors.white,
            primary: primaryGreen,
            onPrimary: Colors.grey.shade900,
            error: darkRed,
            onError: Colors.grey.shade100,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
          foregroundColor: Colors.black,
          backgroundColor: primaryGreen,
        )),
        outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
          side: BorderSide(width: 1, color: Colors.grey.shade400),
        )),
        cardTheme: CardTheme(
          color: Colors.grey.shade800,
        ),
        chipTheme: ChipThemeData(
          selectedColor: Colors.white12,
          side: _chipBorder(Colors.white12),
          labelStyle: TextStyle(
            color: Colors.grey.shade200,
          ),
          checkmarkColor: Colors.grey.shade200,
        ),
        dialogTheme: const DialogTheme(
          backgroundColor: Color(0xff323232),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          foregroundColor: Colors.grey.shade900,
          backgroundColor: primaryGreen,
        ),
        listTileTheme: const ListTileThemeData(
          // For alignment under menu button
          contentPadding: EdgeInsets.symmetric(horizontal: 18.0),
          visualDensity: VisualDensity.compact,
        ),
        fontFamily: 'Roboto',
        textTheme: TextTheme(
          bodySmall: TextStyle(color: Colors.grey.shade500),
          bodyLarge: const TextStyle(color: Colors.white70),
          bodyMedium: TextStyle(color: Colors.grey.shade200),
          labelSmall: TextStyle(color: Colors.grey.shade500),
          labelMedium: TextStyle(color: Colors.cyan.shade200),
          labelLarge: TextStyle(color: Colors.grey.shade400),
          titleSmall: TextStyle(color: Colors.grey.shade600),
          titleMedium: TextStyle(
              color: Colors.grey.shade200,
              fontWeight: FontWeight.w300,
              fontSize: 16),
          titleLarge: TextStyle(
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w400,
              fontSize: 18),
          headlineSmall: TextStyle(
              color: Colors.grey.shade200,
              fontWeight: FontWeight.w300,
              fontSize: 16),
        ),
      );
      */
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
