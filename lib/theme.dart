import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const primaryGreen = Color(0xffaed581);
const accentGreen = Color(0xff9aca3c);
const primaryBlue = Color(0xff325f74);
const primaryRed = Color(0xffea4335);

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
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.grey.shade800,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
          )
        ),
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
          onPrimary: Colors.white,
          primary: primaryBlue,
        )),
        outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
          side: BorderSide(width: 1, color: Colors.grey.shade400),
        )),
        cardTheme: CardTheme(
          color: Colors.grey.shade300,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: Colors.transparent, // Remove 3.3
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8)), // Remove 3.3
          selectedColor: const Color(0xffd2dbdf),
          side: _ChipBorder(color: Colors.grey.shade400),
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
          titleMedium: TextStyle(
              fontWeight: FontWeight.w300,
              fontSize: 16),
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
          onPrimary: Colors.black,
          secondary: const Color(0xff5d7d90),
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
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
          )
        ),
        // Mainly used for the OATH dialog view at the moment
        buttonTheme: ButtonThemeData(
          colorScheme: ColorScheme.dark(
            secondary: Colors.grey.shade800,
            onSecondary: Colors.white,
            primary: primaryGreen,
            onPrimary: Colors.grey.shade900,
            error: primaryRed,
            onError: Colors.grey.shade100,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
          onPrimary: Colors.black,
          primary: primaryGreen,
        )),
        outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
          side: BorderSide(width: 1, color: Colors.grey.shade400),
        )),
        cardTheme: CardTheme(
          color: Colors.grey.shade800,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: Colors.transparent, // Remove 3.3
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8)), // Remove 3.3
          selectedColor: Colors.white12,
          side: const _ChipBorder(color: Colors.white12),
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
          labelLarge: TextStyle(color: Colors.cyan.shade500),
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
}

/// This fixes the issue with FilterChip resizing vertically on toggle.
class _ChipBorder extends BorderSide implements MaterialStateBorderSide {
  const _ChipBorder({super.color});

  @override
  BorderSide? resolve(Set<MaterialState> states) {
    if (states.contains(MaterialState.selected)) {
      return const BorderSide(width: 1, color: Colors.transparent);
    }
    return BorderSide(width: 1, color: color);
  }
}
