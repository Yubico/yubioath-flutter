import 'package:flutter/material.dart';

const primaryGreen = Color(0xffaed581);
const accentGreen = Color(0xff9aca3c);
const primaryBlue = Color(0xff325f74);

class AppTheme {
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme:
            ColorScheme.fromSwatch(brightness: Brightness.light).copyWith(
          primary: primaryBlue,
          secondary: accentGreen,
          background: Colors.grey.shade200,
        ),
        //backgroundColor: Colors.white,
        toggleableActiveColor: accentGreen,
        appBarTheme: AppBarTheme(
          elevation: 0,
          toolbarHeight: 48,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          backgroundColor: Colors.white,
          foregroundColor: Colors.grey.shade800,
        ),
        // Mainly used for the OATH dialog view at the moment
        buttonTheme: ButtonThemeData(
          colorScheme: ColorScheme.light(
            background: Colors.grey.shade300,
            onBackground: Colors.black,
            primary: primaryGreen,
            onPrimary: Colors.black,
            secondary: const Color(0xffea4335),
            onSecondary: Colors.white,
          ),
        ),
        cardTheme: CardTheme(
          color: Colors.grey.shade300,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: primaryBlue,
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

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme:
            ColorScheme.fromSwatch(brightness: Brightness.dark).copyWith(
          primary: primaryGreen,
          secondary: primaryGreen,
        ),
        toggleableActiveColor: primaryGreen,
        appBarTheme: AppBarTheme(
          elevation: 0,
          toolbarHeight: 48,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.grey.shade400,
        ),
        buttonTheme: ButtonThemeData(
          colorScheme: ColorScheme.dark(
            background: Colors.grey.shade800,
            onBackground: Colors.white,
            primary: primaryGreen,
            onPrimary: Colors.black,
            secondary: const Color(0xffea4335),
            onSecondary: Colors.white,
          ),
        ),
        cardTheme: CardTheme(
          color: Colors.grey.shade800,
        ),
        dialogTheme: const DialogTheme(
          backgroundColor: Color(0xff323232),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          foregroundColor: Colors.grey.shade900,
          backgroundColor: primaryGreen,
        ),
        fontFamily: 'Roboto',
        textTheme: TextTheme(
          bodySmall: TextStyle(color: Colors.grey.shade500),
          bodyLarge: const TextStyle(color: Colors.white70),
          bodyMedium: TextStyle(color: Colors.grey.shade200),
          labelSmall: TextStyle(color: Colors.grey.shade500),
          labelMedium: TextStyle(color: Colors.cyan.shade200),
          labelLarge: TextStyle(color: Colors.cyan.shade500),
          titleSmall: TextStyle(color: Colors.grey.shade600),
          titleMedium: const TextStyle(),
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
}
