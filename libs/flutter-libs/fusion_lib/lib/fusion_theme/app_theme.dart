import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/color_scheme.dart';
import 'package:google_fonts/google_fonts.dart';

export 'color_scheme.dart';

/// Centralized theme configuration for the Fusion App,
/// providing both light and dark themes with comprehensive styling for typography, colors, and components.
class FusionAppTheme {
  /// Private constructor to prevent instantiation
  FusionAppTheme._();

  /// Creates a custom [TextTheme] with proper color assignments for the given [ColorScheme].
  ///
  /// This method ensures all text styles use appropriate colors from the [ColorExtends]
  /// extension, maintaining proper contrast and hierarchy across light and dark themes.
  ///
  /// Text color hierarchy:
  /// - Display/Headlines/Titles/Body: Uses [ColorExtends.black] (primary text)
  /// - Small titles/Body small: Uses [ColorExtends.elevation1] (secondary text)
  /// - Labels: Uses [ColorExtends.primaryColor] (accent text)
  ///
  /// [colorScheme] - The color scheme to apply colors from
  ///
  /// Returns a fully configured [TextTheme] with Montserrat font and custom colors
  static TextTheme _createTextTheme(ColorScheme colorScheme) {
    return TextTheme(
      /// Display styles - largest text on screen (typically for splash screens, hero sections)
      displayLarge: TextStyle(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
        color: colorScheme.textPrimary,
      ),
      displayMedium: TextStyle(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: colorScheme.textPrimary,
      ),
      displaySmall: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: colorScheme.textPrimary,
      ),

      /// Headline styles - high-emphasis text for short, important text or numerals
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: colorScheme.textPrimary,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: colorScheme.textPrimary,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: colorScheme.textPrimary,
      ),

      /// Title styles - medium-emphasis text for titles of medium length
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        color: colorScheme.textPrimary,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
        color: colorScheme.textPrimary,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: colorScheme.textPrimary,
      ),

      /// Label styles - small utility text (buttons, tabs, captions)
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: colorScheme.textPrimary,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: colorScheme.textPrimary,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: colorScheme.textPrimary,
      ),

      /// Body styles - regular text content
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        color: colorScheme.textPrimary,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        color: colorScheme.textPrimary,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        color: colorScheme.textPrimary,
      ),
    );
  }

  /// Gets the complete light theme configuration for the Fusion App.
  ///
  /// This theme uses a light color palette with:
  /// - Primary color: Blue (#146C94)
  /// - Background: Light greys and whites
  /// - Text: Dark colors for proper contrast
  /// - Components: Styled with light theme variants
  ///
  /// The theme includes comprehensive styling for:
  /// - Typography with Montserrat font
  /// - Buttons (Elevated, Outlined, Text)
  /// - Navigation elements (AppBar, TabBar)
  /// - Input fields and forms
  /// - Cards and surfaces
  ///
  /// Returns a fully configured [ThemeData] for light theme
  static ThemeData get lightTheme {
    final lightColorScheme = ColorScheme.fromSeed(
      primary: Color(0xFF2F7554),
      seedColor: const Color(0xFF146C94), // Using your primary color
      brightness: Brightness.light,
    );

    return ThemeData(
      // Primary color scheme using custom primary color
      colorScheme: lightColorScheme,
      fontFamily: GoogleFonts.montserrat().fontFamily,
      primaryColor: Color(0xFF2F7554),
      // Custom TextTheme with proper color assignments
      textTheme: _createTextTheme(lightColorScheme),

      /// Elevated button styling with primary color background
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lightColorScheme.primaryColor,
          foregroundColor: lightColorScheme.primaryWhite,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          elevation: 0,
          textStyle: TextStyle(
            fontSize: 11,
            fontFamily: GoogleFonts.montserrat().fontFamily,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      scrollbarTheme: ScrollbarThemeData(
        thickness: WidgetStateProperty.all(3), // small thickness globally
        radius: const Radius.circular(4),
        thumbColor: WidgetStateProperty.all(Colors.grey.shade400),
        trackColor: WidgetStateProperty.all(Colors.transparent),
        thumbVisibility: WidgetStateProperty.all(true), // always visible (optional)
      ),

      /// Outlined button styling with primary color border and text
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: lightColorScheme.primaryColor,
          side: BorderSide(color: lightColorScheme.primaryColor),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          textStyle: TextStyle(
            fontSize: 11,
            fontFamily: GoogleFonts.montserrat().fontFamily,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      /// Text button styling with primary color text
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: lightColorScheme.primaryColor,
          textStyle: TextStyle(
            fontSize: 11,
            fontFamily: GoogleFonts.montserrat().fontFamily,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      /// Tab bar styling with custom font and colors
      tabBarTheme: TabBarThemeData(
        labelStyle: TextStyle(
          fontFamily: GoogleFonts.montserrat().fontFamily,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: GoogleFonts.montserrat().fontFamily,
          fontWeight: FontWeight.w400,
        ),
        labelColor: lightColorScheme.primaryColor,
        unselectedLabelColor: lightColorScheme.elevation1,
      ),

      iconTheme: IconThemeData(
        size: 20,
        color: lightColorScheme.onSurface,
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: lightColorScheme.primaryWhite,
          borderRadius: BorderRadius.circular(4),
        ),
      ),

      /// App bar styling with primary color background
      appBarTheme: AppBarTheme(
        backgroundColor: lightColorScheme.primaryColor,
        foregroundColor: lightColorScheme.primaryWhite,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          fontFamily: GoogleFonts.montserrat().fontFamily,
          color: lightColorScheme.primaryWhite,
        ),
      ),

      /// Input field styling with soft grey background and custom borders
      // todo: uncomment if needed
      /*inputDecorationTheme: InputDecorationTheme(
        labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: lightColorScheme.textFieldLabelColor),
        hintStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w300, color: lightColorScheme.textFieldLabelColor),
        filled: true,
        fillColor: lightColorScheme.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: lightColorScheme.textFieldBorderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: lightColorScheme.textFieldBorderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: lightColorScheme.primaryColor, width: 2),
        ),
      ),*/
    );
  }

  /// Gets the complete dark theme configuration for the Fusion App.
  ///
  /// This theme uses a dark color palette with:
  /// - Primary color: Light blue (#80C7FF)
  /// - Background: Dark greys and blacks
  /// - Text: Light colors for proper contrast
  /// - Components: Styled with dark theme variants
  ///
  /// The theme includes comprehensive styling for:
  /// - Typography with Montserrat font (inverted colors)
  /// - Buttons (Elevated, Outlined, Text) with dark styling
  /// - Navigation elements (AppBar, TabBar) with dark backgrounds
  /// - Input fields with dark backgrounds
  /// - Cards and surfaces with dark themes
  ///
  /// Returns a fully configured [ThemeData] for dark theme
  static ThemeData get darkTheme {
    final darkColorScheme = ColorScheme.fromSeed(
      primary: Color(0xFF2F7554),
      onPrimary: Colors.white,
      surface: Color(0xFF1D1D1D),

      onSurface: Colors.white,
      surfaceDim: Color(0xFFC0C0C0),
      seedColor: const Color(0xFF80C7FF), // Using your dark primary color
      brightness: Brightness.dark,
    );

    return ThemeData(
      // Primary color scheme using custom dark primary color
      colorScheme: darkColorScheme,
      scaffoldBackgroundColor: darkColorScheme.surface,
      fontFamily: GoogleFonts.montserrat().fontFamily,
      primaryColor: Color(0xFF2F7554),

      // Custom TextTheme with proper dark theme color assignments
      textTheme: _createTextTheme(darkColorScheme),

      /// Elevated button styling with primary color background for dark theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkColorScheme.primaryColor,
          foregroundColor: darkColorScheme.primaryBlack,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          elevation: 0,
          textStyle: TextStyle(
            fontSize: 11,
            fontFamily: GoogleFonts.montserrat().fontFamily,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      scrollbarTheme: ScrollbarThemeData(
        thickness: WidgetStateProperty.all(3), // small thickness globally
        radius: const Radius.circular(4),
        thumbVisibility: WidgetStateProperty.all(true), // always visible (optional)
      ),

      /// Outlined button styling with primary color border for dark theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkColorScheme.primaryColor,
          side: BorderSide(color: darkColorScheme.primaryColor),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          textStyle: TextStyle(
            fontSize: 11,
            fontFamily: GoogleFonts.montserrat().fontFamily,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: darkColorScheme.primaryWhite,
          borderRadius: BorderRadius.circular(4),
        ),
      ),

      /// Text button styling with primary color text for dark theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: darkColorScheme.primaryColor,
          textStyle: TextStyle(
            fontSize: 11,
            fontFamily: GoogleFonts.montserrat().fontFamily,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: darkColorScheme.strokeDark,
        thickness: 1,
      ),

      iconTheme: IconThemeData(
        size: 20,
        color: darkColorScheme.onSurface,
      ),

      dialogTheme: DialogThemeData(
        barrierColor: Colors.black87,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: darkColorScheme.surface,
        elevation: 0,
      ),

      /// Tab bar styling with custom font and dark theme colors
      tabBarTheme: TabBarThemeData(
        labelStyle: TextStyle(
          fontFamily: GoogleFonts.montserrat().fontFamily,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: GoogleFonts.montserrat().fontFamily,
          fontWeight: FontWeight.w400,
        ),
        labelColor: darkColorScheme.primaryColor,
        unselectedLabelColor: darkColorScheme.elevation1,
      ),

      /// App bar styling with dark background for dark theme
      appBarTheme: AppBarTheme(
        backgroundColor: darkColorScheme.primary,
        foregroundColor: darkColorScheme.primaryWhite,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          fontFamily: GoogleFonts.montserrat().fontFamily,
          color: darkColorScheme.primaryWhite,
        ),
      ),

      /// Input field styling with dark backgrounds and borders for dark theme
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: darkColorScheme.textPrimary,
        ),
        hintStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w300,
          color: darkColorScheme.textPrimary,
        ),

        filled: true,
        fillColor: darkColorScheme.primaryWhite,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: darkColorScheme.textPrimary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: darkColorScheme.textPrimary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: darkColorScheme.primaryColor, width: 2),
        ),
      ),
    );
  }
}

/// Extension on [TextTheme] to provide custom text styles that follow the Fusion App typography guidelines.
extension FusionTextStyle on TextTheme {
  /// ------------------------
  /// H1 – 48 / 56 / -2
  /// ------------------------
  TextStyle get h1Regular => _fusionText(
    displayLarge!,
    size: 48,
    lineHeight: 56,
    letterSpacing: -2,
    weight: FontWeight.w400,
  );

  TextStyle get h1Bold => _fusionText(displayLarge!, size: 48, lineHeight: 56, letterSpacing: -2, weight: FontWeight.w700, fontFamily: 'EaseStd');

  /// ------------------------
  /// H2 – 40 / 48 / -1
  /// ------------------------
  TextStyle get h2Regular => _fusionText(displayMedium!, size: 40, lineHeight: 48, letterSpacing: -1, weight: FontWeight.w400, fontFamily: 'EaseStd');

  TextStyle get h2Bold => _fusionText(displayMedium!, size: 40, lineHeight: 48, letterSpacing: -1, weight: FontWeight.w700, fontFamily: 'EaseStd');

  /// ------------------------
  /// H3 – 32 / 40 / -1
  /// ------------------------
  TextStyle get h3Regular => _fusionText(headlineLarge!, size: 32, lineHeight: 40, letterSpacing: -1, weight: FontWeight.w400, fontFamily: 'EaseStd');

  TextStyle get h3Bold => _fusionText(headlineLarge!, size: 32, lineHeight: 40, letterSpacing: -1, weight: FontWeight.w700, fontFamily: 'EaseStd');

  /// ------------------------
  /// H4 – 24 / 32 / -1
  /// ------------------------
  TextStyle get h4Regular => _fusionText(headlineSmall!, size: 24, lineHeight: 32, letterSpacing: -1, weight: FontWeight.w400, fontFamily: 'Inter');

  TextStyle get h4SemiBold => _fusionText(headlineSmall!, size: 24, lineHeight: 32, letterSpacing: -1, weight: FontWeight.w600, fontFamily: 'Inter');

  TextStyle get h4Bold => _fusionText(headlineSmall!, size: 24, lineHeight: 32, letterSpacing: -1, weight: FontWeight.w700, fontFamily: 'Inter');

  /// ------------------------
  /// H5 – 20 / 24 / 0
  /// ------------------------
  TextStyle get h5Regular => _fusionText(titleLarge!, size: 20, lineHeight: 24, weight: FontWeight.w400, fontFamily: 'EaseStd');

  TextStyle get h5Bold => _fusionText(titleLarge!, size: 20, lineHeight: 24, weight: FontWeight.w700, fontFamily: 'EaseStd');

  /// ------------------------
  /// H6 – 18 / 24 / 0
  /// ------------------------
  TextStyle get h6Regular => _fusionText(titleMedium!, size: 18, lineHeight: 24, weight: FontWeight.w400, fontFamily: 'EaseStd');

  TextStyle get h6Bold => _fusionText(titleMedium!, size: 18, lineHeight: 24, weight: FontWeight.w700, fontFamily: 'EaseStd');

  /// ------------------------
  /// B1 – 16 / 24 / 0
  /// ------------------------
  TextStyle get b1Regular => _fusionText(bodyLarge!, size: 16, lineHeight: 24, weight: FontWeight.w400, fontFamily: 'EaseStd');

  TextStyle get b1Bold => _fusionText(bodyLarge!, size: 16, lineHeight: 24, weight: FontWeight.w700, fontFamily: 'EaseStd');

  /// ------------------------
  /// B2 – 16 / 24 / 0
  /// ------------------------
  TextStyle get b2Regular => _fusionText(bodyMedium!, size: 16, lineHeight: 24, weight: FontWeight.w400, fontFamily: 'Inter');

  TextStyle get b2Medium => _fusionText(bodyMedium!, size: 16, lineHeight: 24, weight: FontWeight.w500, fontFamily: 'Inter');

  TextStyle get b2SemiBold => _fusionText(bodyMedium!, size: 16, lineHeight: 24, weight: FontWeight.w600, fontFamily: 'Inter');

  TextStyle get b2Bold => _fusionText(bodyMedium!, size: 16, lineHeight: 24, weight: FontWeight.w700, fontFamily: 'Inter');

  /// ------------------------
  /// B3 – 14 / 20 / 0 & -3
  /// ------------------------
  TextStyle get b3Regular => _fusionText(bodySmall!, size: 14, lineHeight: 20, weight: FontWeight.w400, fontFamily: 'Inter');

  TextStyle get b3Medium => _fusionText(bodySmall!, size: 14, lineHeight: 20, weight: FontWeight.w500, fontFamily: 'Inter');

  TextStyle get b3SemiBold => _fusionText(bodySmall!, size: 14, lineHeight: 20, weight: FontWeight.w600, fontFamily: 'Inter');

  TextStyle get b3Bold => _fusionText(bodySmall!, size: 14, lineHeight: 20, weight: FontWeight.w700, fontFamily: 'Inter');

  TextStyle get b3MediumTight => _fusionText(bodySmall!, size: 14, lineHeight: 20, letterSpacing: -3, weight: FontWeight.w500, fontFamily: 'Inter');

  /// ------------------------
  /// L1 – 12 / 16 / 0 & -3
  /// ------------------------
  TextStyle get l1Regular => _fusionText(labelLarge!, size: 12, lineHeight: 16, weight: FontWeight.w400, fontFamily: 'Inter');

  TextStyle get l1Medium => _fusionText(labelLarge!, size: 12, lineHeight: 16, weight: FontWeight.w500, fontFamily: 'Inter');

  TextStyle get l1SemiBold => _fusionText(labelLarge!, size: 12, lineHeight: 16, weight: FontWeight.w600, fontFamily: 'Inter');

  TextStyle get l1Bold => _fusionText(labelLarge!, size: 12, lineHeight: 16, weight: FontWeight.w700, fontFamily: 'Inter');

  TextStyle get l1MediumTight => _fusionText(labelLarge!, size: 12, lineHeight: 16, letterSpacing: -3, weight: FontWeight.w500, fontFamily: 'Inter');

  /// ------------------------
  /// L2 – 10 / 12 / 0 & -2
  /// ------------------------
  TextStyle get l2Regular => _fusionText(labelMedium!, size: 10, lineHeight: 12, weight: FontWeight.w400, fontFamily: 'Inter');

  TextStyle get l2Medium => _fusionText(labelMedium!, size: 10, lineHeight: 12, weight: FontWeight.w500, fontFamily: 'Inter');

  TextStyle get l2SemiBold => _fusionText(labelMedium!, size: 10, lineHeight: 12, weight: FontWeight.w600, fontFamily: 'Inter');

  TextStyle get l2Bold => _fusionText(labelMedium!, size: 10, lineHeight: 12, weight: FontWeight.w700, fontFamily: 'Inter');

  TextStyle get l2SemiBoldTight => _fusionText(labelMedium!, size: 10, lineHeight: 12, letterSpacing: -2, weight: FontWeight.w600, fontFamily: 'Inter');

  /// ------------------------
  /// L3 – 8 / 12 / -2 / CAPS
  /// ------------------------
  TextStyle get l3Caps => _fusionText(labelSmall!, size: 8, lineHeight: 12, letterSpacing: -2, weight: FontWeight.w600, fontFamily: 'Inter');
}

/// Extension on [BuildContext] to easily access commonly used theme properties.
extension ColorContextExtension on BuildContext {
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
}

extension type FusionInputDecoration(InputDecoration _) {
  /// Creates a default Fusion App input decoration with customizable properties.
  static InputDecoration fusionDefault({
    required ColorScheme colorScheme,
    String? labelText,
    String? hintText,
    IconData? prefixIcon,
    IconData? suffixIcon,
    String? errorText,
    bool filled = true,
    Color? fillColor,
    double borderRadius = 8,
    EdgeInsets? contentPadding,
    bool isEnabled = true,
    bool isDense = false,
    FloatingLabelBehavior? floatingLabelBehavior,
    String? prefixText,
    String? suffixText,
    String? helperText,
    String? counterText,
  }) {
    final finalFillColor = fillColor ?? colorScheme.primaryWhite;
    final isError = errorText != null && errorText.isNotEmpty;
    final borderColor = isError ? const Color(0xFFD32F2F) : colorScheme.primaryBlack;

    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      helperText: helperText,
      counterText: counterText,
      prefixText: prefixText,
      suffixText: suffixText,
      errorText: errorText,
      filled: filled,
      fillColor: finalFillColor,
      isDense: isDense,
      enabled: isEnabled,
      floatingLabelBehavior: floatingLabelBehavior,
      contentPadding: contentPadding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: colorScheme.primaryBlack,
      ),
      hintStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w300,
        color: colorScheme.primaryBlack,
      ),
      helperStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: colorScheme.elevation1,
      ),
      errorStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: Color(0xFFD32F2F),
      ),
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: colorScheme.elevation1) : null,
      suffixIcon: suffixIcon != null ? Icon(suffixIcon, color: colorScheme.elevation1) : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide(color: colorScheme.primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide(color: colorScheme.elevation1),
      ),
    );
  }

  /// Creates a compact Fusion App input decoration with reduced padding and smaller text.
  static InputDecoration fusionCompact({
    required ColorScheme colorScheme,
    String? labelText,
    String? hintText,
    IconData? prefixIcon,
    IconData? suffixIcon,
    String? errorText,
  }) {
    return FusionInputDecoration.fusionDefault(
      colorScheme: colorScheme,
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      errorText: errorText,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      borderRadius: 6,
    );
  }

  /// Creates a filled Fusion App input decoration without borders.
  static InputDecoration fusionFilled({
    required ColorScheme colorScheme,
    String? labelText,
    String? hintText,
    IconData? prefixIcon,
    IconData? suffixIcon,
    String? errorText,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      errorText: errorText,
      filled: true,
      fillColor: colorScheme.elevation1,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: colorScheme.elevation1) : null,
      suffixIcon: suffixIcon != null ? Icon(suffixIcon, color: colorScheme.elevation1) : null,
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: colorScheme.primaryBlack,
      ),
      hintStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w300,
        color: colorScheme.primaryBlack,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.primaryColor, width: 2),
      ),
    );
  }

  /// Creates a minimal Fusion App input decoration with underline style.
  static InputDecoration fusionUnderline({
    required ColorScheme colorScheme,
    String? labelText,
    String? hintText,
    IconData? prefixIcon,
    IconData? suffixIcon,
    String? errorText,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      errorText: errorText,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: colorScheme.elevation1) : null,
      suffixIcon: suffixIcon != null ? Icon(suffixIcon, color: colorScheme.elevation1) : null,
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: colorScheme.primaryBlack,
      ),
      hintStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w300,
        color: colorScheme.primaryBlack,
      ),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: colorScheme.elevation1),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: colorScheme.primaryColor, width: 2),
      ),
    );
  }

  /// Creates a dense Fusion App input decoration with minimal padding.
  ///
  /// Useful for inline forms or inputs with character counters.
  /// Features borderRadius of 4 and isDense set to true.
  static InputDecoration fusionDense({
    required ColorScheme colorScheme,
    String? labelText,
    String? hintText,
    IconData? prefixIcon,
    IconData? suffixIcon,
    String? errorText,
    bool showCounter = false,
  }) {
    final isError = errorText != null && errorText.isNotEmpty;
    final focusedBorderColor = isError ? Colors.red : colorScheme.textPrimary;

    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      errorText: errorText,
      counterText: showCounter ? null : "",
      filled: true,
      fillColor: colorScheme.primaryBlack,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: colorScheme.elevation1) : null,
      suffixIcon: suffixIcon != null ? Icon(suffixIcon, color: colorScheme.elevation1) : null,
      hintStyle: TextStyle(
        color: colorScheme.elevation1,
        fontSize: 12,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: colorScheme.elevation1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: colorScheme.elevation1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: focusedBorderColor),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }
}

/// Extension on [TextStyle] to easily apply color changes while maintaining other style properties.
extension FusionTextStyleColor on TextStyle {
  TextStyle withColor(Color color) => copyWith(color: color);
}

/// Helper function to create a Fusion-styled TextStyle based on base style and parameters.
TextStyle _fusionText(TextStyle base, {required double size, required double lineHeight, double letterSpacing = 0, FontWeight? weight, String? fontFamily}) {
  return base.copyWith(
    fontSize: size,
    height: lineHeight / size,
    letterSpacing: letterSpacing,
    fontWeight: weight,
    fontFamily: fontFamily,
    color: base.color,
  );
}
