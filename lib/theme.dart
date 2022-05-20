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
          backgroundColor: Colors.white,
          foregroundColor: Colors.grey.shade800,
        ),
        // Mainly used for the OATH dialog view at the moment
        buttonTheme: ButtonThemeData(
          colorScheme: ColorScheme.light(
            secondary: Colors.grey.shade300,
            onSecondary: Colors.black,
            primary: primaryGreen,
            onPrimary: Colors.black,
            error: const Color(0xffea4335),
            onError: Colors.white,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
          primary: Colors.grey.shade800,
          side: BorderSide(width: 1, color: Colors.grey.shade400),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        )),
        cardTheme: CardTheme(
          color: Colors.grey.shade300,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: Colors.transparent,
          selectedColor: const Color(0xffc2e7ff),
          side: BorderSide(width: 1, color: Colors.grey.shade400),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
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
        ),
        // Mainly used for the OATH dialog view at the moment
        buttonTheme: ButtonThemeData(
          colorScheme: ColorScheme.dark(
            secondary: Colors.grey.shade800,
            onSecondary: Colors.white70,
            primary: primaryGreen,
            onPrimary: Colors.black,
            error: const Color(0xffea4335),
            onError: Colors.white,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
          primary: Colors.white,
          side: const BorderSide(width: 1, color: Colors.white12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        )),
        cardTheme: CardTheme(
          color: Colors.grey.shade800,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: Colors.transparent,
          selectedColor: Colors.white12,
          side: const BorderSide(width: 1, color: Colors.white12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
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
