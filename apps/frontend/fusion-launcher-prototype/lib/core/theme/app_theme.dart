import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      // Primary color scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.grey.shade800,
        brightness: Brightness.light,
      ),

      fontFamily: GoogleFonts.montserrat().fontFamily,

      // ElevatedButton theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey.shade800,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          elevation: 0,
          textStyle: TextStyle(
            fontSize: 11,
            fontFamily: GoogleFonts.montserrat().fontFamily,
          ),
        ),
      ),

      // Optional: Other button themes to match
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.grey.shade800,
          side: BorderSide(color: Colors.grey.shade800),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Colors.grey.shade800,
          textStyle: TextStyle(
            fontSize: 11,
            fontFamily: GoogleFonts.montserrat().fontFamily,
          ),
        ),
      ),

      tabBarTheme: TabBarThemeData(
        labelStyle: TextStyle(
          fontFamily: GoogleFonts.montserrat().fontFamily,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: GoogleFonts.montserrat().fontFamily,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return lightTheme;
  }
}

extension ColorExtends on ColorScheme {
  static const Color _primaryColorL = Color(0xFF146C94);
  static const Color _primaryColorD = Color(0xFF80C7FF);
  static const Color launcherBgColorLight1 = Color(0xFFF8F8F8);
  static const Color launcherBgColorLight2 = Color(0xFFDADADA);
  static const Color launcherBgColorDark1 = Color(0xFF1A1A2E);
  static const Color launcherBgColorDark2 = Color(0xFF0F0F1E);
  static const Color _greyDarkL = Color(0xFF464545);
  static const Color _greyDarkD = Color(0xFFD0CECE);
  static const Color _softGreyL = Color(0xFFF6F6F6);
  static const Color _softGreyD = Color(0xFF424242);
  static const Color _greyL = Color(0xFFD9D9D9);
  static const Color _greyD = Color(0xFF606060);
  static const Color _greyLightL = Color(0xFFF5F5F5);
  static const Color _greyLightD = Color(0xFF121212);
  static const Color _whiteL = Color(0xFFFFFFFF);
  static const Color _whiteD = Color(0xFF000000);
  static const Color _blackL = Color(0xFF000000);
  static const Color _blackD = Color(0xFFFFFFFF);
  static const Color _blackTransparentL = Color(0x4D000000);

  static const Color _borderColorL = Color(0xFFE5E5E5);

  bool get isDarkMode => brightness == Brightness.dark;
  Color get primaryColor => isDarkMode ? _primaryColorD : _primaryColorL;

  /// onboard screen colors
  Color get grey => isDarkMode ? _greyD : _greyL;
  Color get blackTransparentL => _blackTransparentL;
  Color get borderColorL => _borderColorL;

  Color get greyLight => isDarkMode ? _greyLightD : _greyLightL;

  Color get white => isDarkMode ? _whiteD : _whiteL;

  Color get black => isDarkMode ? _blackD : _blackL;

  /// app launcher background colors
  Color get launcherBgColor1 => isDarkMode ? launcherBgColorDark1 : launcherBgColorLight1;
  Color get launcherBgColor2 => isDarkMode ? launcherBgColorDark2 : launcherBgColorLight2;

  /// app text field colors
  Color get greyDark => isDarkMode ? _greyDarkD : _greyDarkL;
  Color get softGrey => isDarkMode ? _softGreyD : _softGreyL;
}
