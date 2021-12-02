import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme => ThemeData(
        brightness: Brightness.light,
      );

  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        colorScheme:
            ColorScheme.fromSwatch(brightness: Brightness.dark).copyWith(
          secondary: const Color(0xffa8c86c),
        ),
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
