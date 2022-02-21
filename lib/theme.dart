import 'package:flutter/material.dart';

const primaryGreen = Color(0xffa8c86c);

class AppTheme {
  static ThemeData get lightTheme => ThemeData(
        brightness: Brightness.light,
      );

  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        colorScheme:
            ColorScheme.fromSwatch(brightness: Brightness.dark).copyWith(
          primary: primaryGreen,
          secondary: primaryGreen,
        ),
        toggleableActiveColor: primaryGreen,
        textTheme: TextTheme(
          bodyText1: TextStyle(
            color: Colors.grey.shade400,
          ),
          bodyText2: TextStyle(
            color: Colors.grey.shade500,
          ),
        ),
      );
}
