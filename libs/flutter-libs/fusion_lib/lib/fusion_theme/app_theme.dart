import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/color_scheme.dart';
import 'package:google_fonts/google_fonts.dart';

export 'color_scheme.dart';

/// Main theme class for the Fusion App that provides both light and dark theme configurations.
///
/// This class follows Material Design 3 guidelines and integrates with the custom [ColorExtends]
/// extension to provide consistent theming across the entire application.
///
/// Features:
/// - Complete Material Design 3 typography with Montserrat font
/// - Custom color palette that adapts to light/dark themes
/// - Comprehensive component theming (buttons, inputs, cards, etc.)
/// - Accessible color contrast ratios
///
/// Usage:
/// ```dart
/// MaterialApp(
///   theme: FusionAppTheme.lightTheme,
///   darkTheme: FusionAppTheme.darkTheme,
///   themeMode: ThemeMode.system, // Follows system theme
/// )
/// ```
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
        fontFamily: GoogleFonts.montserrat().fontFamily,
        color: colorScheme.textPrimary,
      ),
      displayMedium: TextStyle(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        fontFamily: GoogleFonts.montserrat().fontFamily,
        color: colorScheme.textPrimary,
      ),
      displaySmall: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        fontFamily: GoogleFonts.montserrat().fontFamily,
        color: colorScheme.textPrimary,
      ),

      /// Headline styles - high-emphasis text for short, important text or numerals
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        fontFamily: GoogleFonts.montserrat().fontFamily,
        color: colorScheme.textPrimary,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        fontFamily: GoogleFonts.montserrat().fontFamily,
        color: colorScheme.textPrimary,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        fontFamily: GoogleFonts.montserrat().fontFamily,
        color: colorScheme.textPrimary,
      ),

      /// Title styles - medium-emphasis text for titles of medium length
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        fontFamily: GoogleFonts.montserrat().fontFamily,
        color: colorScheme.textPrimary,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
        fontFamily: GoogleFonts.montserrat().fontFamily,
        color: colorScheme.textPrimary,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        fontFamily: GoogleFonts.montserrat().fontFamily,
        color: colorScheme.textPrimary,
      ),

      /// Label styles - small utility text (buttons, tabs, captions)
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        fontFamily: GoogleFonts.montserrat().fontFamily,
        color: colorScheme.textPrimary,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        fontFamily: GoogleFonts.montserrat().fontFamily,
        color: colorScheme.textPrimary,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        fontFamily: GoogleFonts.montserrat().fontFamily,
        color: colorScheme.textPrimary,
      ),

      /// Body styles - regular text content
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        fontFamily: GoogleFonts.montserrat().fontFamily,
        color: colorScheme.textPrimary,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        fontFamily: GoogleFonts.montserrat().fontFamily,
        color: colorScheme.textPrimary,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        fontFamily: GoogleFonts.montserrat().fontFamily,
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
        size: 16,
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

/// Extension on [BuildContext] to easily access commonly used theme properties.
extension ColorContextExtension on BuildContext {
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
}

/// Extension on [InputDecoration] that provides factory methods for common Fusion App input styles.
///
/// This extension allows you to create pre-styled input decorations that match the Fusion App theme
/// while maintaining the ability to customize any property through named parameters.
///
/// Example usage:
/// ```dart
/// TextField(
///   decoration: inputDecorationFusionDefault(
///     hintText: 'Enter your name',
///     colorScheme: Theme.of(context).colorScheme,
///     prefixIcon: Icons.person,
///   ),
/// )
/// ```
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
