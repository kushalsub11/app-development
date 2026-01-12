import 'package:flutter/material.dart';

class AppTheme {
  // Primary Colors
  static const Color primaryPurple = Color(0xFF5C2DB2);
  static const Color primaryDark = Color(0xFF3B1C78);
  static const Color accentPurple = Color(0xFFB028C9);
  static const Color lightPurple = Color(0xFF7B4FD4);

  // Accent Colors
  static const Color gold = Color(0xFFFFE45C);
  static const Color goldDark = Color(0xFFFFD700);

  // Neutral Colors
  static const Color white = Colors.white;
  static const Color cardBg = Color(0xFFF8F6FF);
  static const Color darkText = Color(0xFF22202A);
  static const Color greyText = Color(0xFF747180);
  static const Color inputBorder = Color(0xFF9A96A8);
  static const Color inputBg = Color(0xFFFCFCFF);

  // Status Colors
  static const Color success = Color(0xFF34C759);
  static const Color warning = Color(0xFFFF9500);
  static const Color error = Color(0xFFFF3B30);
  static const Color info = Color(0xFF007AFF);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primaryPurple, primaryDark],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6B3FA0), Color(0xFF4A2080)],
  );

  // Theme Data
  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: primaryPurple,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryPurple,
          primary: primaryPurple,
          secondary: accentPurple,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryPurple,
          foregroundColor: white,
          elevation: 0,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accentPurple,
            foregroundColor: white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: inputBg,
          hintStyle: const TextStyle(color: greyText, fontSize: 16),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: inputBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: accentPurple, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: error, width: 1.5),
          ),
        ),
        cardTheme: CardThemeData(
          color: white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      );
}
