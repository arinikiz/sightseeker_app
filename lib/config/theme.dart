import 'package:flutter/material.dart';

class AppTheme {
  // Colors
  static const Color primaryColor = Color(0xFFFF6B35);    // Energetic orange
  static const Color secondaryColor = Color(0xFF1A535C);   // Teal
  static const Color backgroundColor = Color(0xFFF7F7F7);  // Light gray
  static const Color accentColor = Color(0xFFFFE66D);      // Gold for points/badges
  static const Color surfaceColor = Colors.white;

  // Challenge type colors
  static const Color photoColor = Colors.blue;
  static const Color foodColor = Colors.orange;
  static const Color activityColor = Colors.green;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        background: backgroundColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceColor,
        foregroundColor: secondaryColor,
        elevation: 0,
      ),
      cardTheme: const CardThemeData(
        elevation: 2,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
