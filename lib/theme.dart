import 'package:flutter/material.dart';

const primaryGreen = Color(0xffAED581);
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
        backgroundColor: Colors.white,
        toggleableActiveColor: accentGreen,
        appBarTheme: AppBarTheme(
          elevation: 0.5,
          backgroundColor: Colors.white,
          foregroundColor: Colors.grey.shade800,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: primaryBlue,
        ),
        fontFamily: 'Roboto',
        textTheme: TextTheme(
          bodyText1: TextStyle(
            color: Colors.grey.shade600,
          ),
          bodyText2: TextStyle(
            color: Colors.grey.shade800,
          ),
          headline2: TextStyle(
            color: Colors.grey.shade800,
          ),
        ),
      );

  static ThemeData get darkTheme => ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSwatch(brightness: Brightness.dark).copyWith(
        primary: primaryGreen,
        secondary: primaryGreen,
      ),
      toggleableActiveColor: primaryGreen,
      appBarTheme: AppBarTheme(
        elevation: 0,
        toolbarHeight: 48,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.grey.shade400,
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
        /*bodyText1: TextStyle(
              color: Colors.grey.shade400,
            ),
            bodyText2: TextStyle(
              color: Colors.grey.shade500,
            ),
            headline2: TextStyle(
              color: Colors.grey.shade100,
            )*/
        bodySmall: TextStyle(color: Colors.grey.shade500),
        bodyLarge: TextStyle(color: Colors.blue.shade900),
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
      ));
}
