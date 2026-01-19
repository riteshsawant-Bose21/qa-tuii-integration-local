import 'package:flutter/material.dart';

/// Extension on [ColorScheme] that provides custom colors for both light and dark themes.
///
/// This extension automatically switches colors based on the current brightness mode,
/// ensuring consistent theming across the entire application.
///
/// Example usage:
/// ```dart
/// final colorScheme = Theme.of(context).colorScheme;
/// Container(
///   color: colorScheme.primaryColor, // Automatically adapts to theme
///   child: Text('Hello', style: TextStyle(color: colorScheme.black)),
/// )
/// ```
extension ColorExtends on ColorScheme {
  /// Dark and light theme variables
  // Primary Colors
  static const Color _emeraldL = Color(0xFF3E996E);
  static const Color _emeraldD = Color(0xFF3E996E);
  static const Color _whiteL = Color(0xFF000000);
  static const Color _whiteD = Color(0xFFFFFFFF);
  static const Color _blackL = Color(0xFFFFFFFF);
  static const Color _blackD = Color(0xFF000000);

  // Text Colors
  static const Color _textPrimaryL = Color(0xFF1A1A18);
  static const Color _textPrimaryD = Color(0xFFFFFFFF);
  static const Color _textSecondaryL = Color(0xFF595752);
  static const Color _textSecondaryD = Color(0xFFDBD7CE);
  static const Color _textBodyL = Color(0xFF77746E);
  static const Color _textBodyD = Color(0xFFB4AFA6);
  static const Color _textLabelL = Color(0xFF1A1A18);
  static const Color _textLabelD = Color(0xFFF5F3F0);
  static const Color _textPlaceholderL = Color(0xFF77746E);
  static const Color _textPlaceholderD = Color(0xFF77746E);
  static const Color _textDisabledL = Color(0xFFC6C2BA);
  static const Color _textDisabledD = Color(0xFF595752);

  // Elevation Colors
  static const Color _elevation1L = Color(0xFFF5F3F0);
  static const Color _elevation1D = Color(0xFF1A1A18);
  static const Color _elevation2L = Color(0xFFEBE7E1);
  static const Color _elevation2D = Color(0xFF292826);
  static const Color _elevation3L = Color(0xFFDBD7CE);
  static const Color _elevation3D = Color(0xFF3D3C38);
  static const Color _elevation4L = Color(0xFFC6C2BA);
  static const Color _elevation4D = Color(0xFF595752);
  static const Color _elevation5L = Color(0xFF77746E);
  static const Color _elevation5D = Color(0xFF77746E);

  // Stroke Colors
  static const Color _strokeLightL = Color(0xFFDBD7CE);
  static const Color _strokeLightD = Color(0xFF3D3C38);
  static const Color _strokeDarkL = Color(0xFFB4AFA6);
  static const Color _strokeDarkD = Color(0xFF77746E);

  // Icon Colors
  static const Color _iconDefaultL = Color(0xFF595752);
  static const Color _iconDefaultD = Color(0xFFC6C2BA);
  static const Color _iconDisabledL = Color(0xFFC6C2BA);
  static const Color _iconDisabledD = Color(0xFF595752);
  static const Color _iconWhiteL = Color(0xFF000000);
  static const Color _iconWhiteD = Color(0xFFFFFFFF);

  // Volume Colors
  static const Color _volumeGreenL = Color(0xFF2F7554);
  static const Color _volumeGreenD = Color(0xFF2F7554);
  static const Color _volumeYellowL = Color(0xFFFAB62E);
  static const Color _volumeYellowD = Color(0xFFFAB62E);
  static const Color _volumeRedL = Color(0xFFD03B1E);
  static const Color _volumeRedD = Color(0xFFD03B1E);

  // Success Colors
  static const Color _successTextL = Color(0xFF0D9543);
  static const Color _successTextD = Color(0xFF17B054);
  static const Color _successFillL = Color(0xFFECFFF4);
  static const Color _successFillD = Color(0xFF05421D);
  static const Color _successStrokeL = Color(0xFFC1F8D7);
  static const Color _successStrokeD = Color(0xFF065E29);

  // Warning Colors
  static const Color _warningTextL = Color(0xFFD66913);
  static const Color _warningTextD = Color(0xFFE78024);
  static const Color _warningFillL = Color(0xFFFFFDF2);
  static const Color _warningFillD = Color(0xFF3D210C);
  static const Color _warningStrokeL = Color(0xFFFEF2CC);
  static const Color _warningStrokeD = Color(0xFF933E03);

  // Error Colors
  static const Color _errorTextL = Color(0xFFD62C29);
  static const Color _errorTextD = Color(0xFFE74B49);
  static const Color _errorFillL = Color(0xFFFFF2F2);
  static const Color _errorFillD = Color(0xFF3D0E0D);
  static const Color _errorStrokeL = Color(0xFFFEDDDD);
  static const Color _errorStrokeD = Color(0xFF600101);

  // Information Colors
  static const Color _infoTextL = Color(0xFF0B84B8);
  static const Color _infoTextD = Color(0xFF0FA4E0);
  static const Color _infoFillL = Color(0xFFE6F6FF);
  static const Color _infoFillD = Color(0xFF04344A);
  static const Color _infoStrokeL = Color(0xFFC8ECFF);
  static const Color _infoStrokeD = Color(0xFF064F70);

  // Zone 1 Colors
  static const Color _zone1LightL = Color(0x5C3A63C4);
  static const Color _zone1LightD = Color(0x5C3A63C4);
  static const Color _zone1StrokeL = Color(0xFFB8C7EA);
  static const Color _zone1StrokeD = Color(0xFFB8C7EA);
  static const Color _zone1FillL = Color(0xFF3A63C4);
  static const Color _zone1FillD = Color(0xFF3A63C4);
  static const Color _zone1DarkL = Color(0xFF213970);
  static const Color _zone1DarkD = Color(0xFF213970);

  // Zone 2 Colors
  static const Color _zone2LightL = Color(0x5CE16C53);
  static const Color _zone2LightD = Color(0x5CE16C53);
  static const Color _zone2StrokeL = Color(0xFFF4CAC1);
  static const Color _zone2StrokeD = Color(0xFFF4CAC1);
  static const Color _zone2FillL = Color(0xFFE16C53);
  static const Color _zone2FillD = Color(0xFFE16C53);
  static const Color _zone2DarkL = Color(0xFF96301A);
  static const Color _zone2DarkD = Color(0xFF96301A);

  // Zone 3 Colors
  static const Color _zone3LightL = Color(0x5C3DA172);
  static const Color _zone3LightD = Color(0x5C3DA172);
  static const Color _zone3StrokeL = Color(0xFFB9DDCC);
  static const Color _zone3StrokeD = Color(0xFFB9DDCC);
  static const Color _zone3FillL = Color(0xFF3DA172);
  static const Color _zone3FillD = Color(0xFF3DA172);
  static const Color _zone3DarkL = Color(0xFF235C42);
  static const Color _zone3DarkD = Color(0xFF235C42);

  // Zone 4 Colors
  static const Color _zone4LightL = Color(0x5CC878D8);
  static const Color _zone4LightD = Color(0x5CC878D8);
  static const Color _zone4StrokeL = Color(0xFFEBCEF1);
  static const Color _zone4StrokeD = Color(0xFFEBCEF1);
  static const Color _zone4FillL = Color(0xFFC878D8);
  static const Color _zone4FillD = Color(0xFFC878D8);
  static const Color _zone4DarkL = Color(0xFF832B95);
  static const Color _zone4DarkD = Color(0xFF832B95);

  // Zone 5 Colors
  static const Color _zone5LightL = Color(0x5CE0C01F);
  static const Color _zone5LightD = Color(0x5CE0C01F);
  static const Color _zone5StrokeL = Color(0xFFF4E8AE);
  static const Color _zone5StrokeD = Color(0xFFF4E8AE);
  static const Color _zone5FillL = Color(0xFFE0C01F);
  static const Color _zone5FillD = Color(0xFFE0C01F);
  static const Color _zone5DarkL = Color(0xFF806E12);
  static const Color _zone5DarkD = Color(0xFF806E12);

  // Zone 6 Colors
  static const Color _zone6LightL = Color(0x5CDA7398);
  static const Color _zone6LightD = Color(0x5CDA7398);
  static const Color _zone6StrokeL = Color(0xFFF2CDDA);
  static const Color _zone6StrokeD = Color(0xFFF2CDDA);
  static const Color _zone6FillL = Color(0xFFDA7398);
  static const Color _zone6FillD = Color(0xFFDA7398);
  static const Color _zone6DarkL = Color(0xFF972850);
  static const Color _zone6DarkD = Color(0xFF972850);

  // Zone 7 Colors
  static const Color _zone7LightL = Color(0x5CDE7C42);
  static const Color _zone7LightD = Color(0x5CDE7C42);
  static const Color _zone7StrokeL = Color(0xFFF3D0BB);
  static const Color _zone7StrokeD = Color(0xFFF3D0BB);
  static const Color _zone7FillL = Color(0xFFDE7C42);
  static const Color _zone7FillD = Color(0xFFDE7C42);
  static const Color _zone7DarkL = Color(0xFF8C4418);
  static const Color _zone7DarkD = Color(0xFF8C4418);

  // Zone 8 Colors
  static const Color _zone8LightL = Color(0x5C2AB9B4);
  static const Color _zone8LightD = Color(0x5C2AB9B4);
  static const Color _zone8StrokeL = Color(0xFFB2E6E4);
  static const Color _zone8StrokeD = Color(0xFFB2E6E4);
  static const Color _zone8FillL = Color(0xFF2AB9B4);
  static const Color _zone8FillD = Color(0xFF2AB9B4);
  static const Color _zone8DarkL = Color(0xFF186A67);
  static const Color _zone8DarkD = Color(0xFF186A67);

  // Zone 9 Colors
  static const Color _zone9LightL = Color(0x5CA0BE1E);
  static const Color _zone9LightD = Color(0x5CA0BE1E);
  static const Color _zone9StrokeL = Color(0xFFDDE8AE);
  static const Color _zone9StrokeD = Color(0xFFDDE8AE);
  static const Color _zone9FillL = Color(0xFFA0BE1E);
  static const Color _zone9FillD = Color(0xFFA0BE1E);
  static const Color _zone9DarkL = Color(0xFF5C6D11);
  static const Color _zone9DarkD = Color(0xFF5C6D11);

  // SPL Colors
  static const Color _spl100L = Color(0xFF3E996E);
  static const Color _spl100D = Color(0xFFE8F3EE);
  static const Color _spl200L = Color(0xFF5BA884);
  static const Color _spl200D = Color(0xFFCAE5D9);
  static const Color _spl300L = Color(0xFF78B899);
  static const Color _spl300D = Color(0xFF9ECCB6);
  static const Color _spl400L = Color(0xFF9ECCB6);
  static const Color _spl400D = Color(0xFF78B899);
  static const Color _spl500L = Color(0xFFCAE5D9);
  static const Color _spl500D = Color(0xFF5BA884);
  static const Color _spl600L = Color(0xFFE8F3EE);
  static const Color _spl600D = Color(0xFF3E996E);

  // Expressive Dark mode
  static const Color _expressiveShadowDarkD = Color(0xFF000000);
  static const Color _expressiveShadowLightD = Color(0xFFFFFFFF);
  static const Color _expressiveShadowDarkL = Color(0xFF000000);
  static const Color _expressiveShadowLightL = Color(0xFFFFFFFF);

  /// Dark and light mode switch
  bool get isDarkMode => brightness == Brightness.dark;

  // Primary Colors
  Color get primaryColor => _emeraldL;
  Color get primaryWhite => isDarkMode ? _whiteD : _whiteL;
  Color get primaryBlack => isDarkMode ? _blackD : _blackL;

  // Text Colors
  Color get textPrimary => isDarkMode ? _textPrimaryD : _textPrimaryL;
  Color get textSecondary => isDarkMode ? _textSecondaryD : _textSecondaryL;
  Color get textBody => isDarkMode ? _textBodyD : _textBodyL;
  Color get textLabel => isDarkMode ? _textLabelD : _textLabelL;
  Color get textPlaceholder => isDarkMode ? _textPlaceholderD : _textPlaceholderL;
  Color get textDisabled => isDarkMode ? _textDisabledD : _textDisabledL;

  // Elevation Colors
  Color get elevation1 => isDarkMode ? _elevation1D : _elevation1L;
  Color get elevation2 => isDarkMode ? _elevation2D : _elevation2L;
  Color get elevation3 => isDarkMode ? _elevation3D : _elevation3L;
  Color get elevation4 => isDarkMode ? _elevation4D : _elevation4L;
  Color get elevation5 => isDarkMode ? _elevation5D : _elevation5L;

  // Stroke Colors
  Color get strokeLight => isDarkMode ? _strokeLightD : _strokeLightL;
  Color get strokeDark => isDarkMode ? _strokeDarkD : _strokeDarkL;

  // Icon Colors
  Color get iconDefault => isDarkMode ? _iconDefaultD : _iconDefaultL;
  Color get iconDisabled => isDarkMode ? _iconDisabledD : _iconDisabledL;
  Color get iconWhite => isDarkMode ? _iconWhiteD : _iconWhiteL;

  // Volume Colors
  Color get volumeGreen => isDarkMode ? _volumeGreenD : _volumeGreenL;
  Color get volumeYellow => isDarkMode ? _volumeYellowD : _volumeYellowL;
  Color get volumeRed => isDarkMode ? _volumeRedD : _volumeRedL;

  // Success Colors
  Color get successText => isDarkMode ? _successTextD : _successTextL;
  Color get successFill => isDarkMode ? _successFillD : _successFillL;
  Color get successStroke => isDarkMode ? _successStrokeD : _successStrokeL;

  // Warning Colors
  Color get warningText => isDarkMode ? _warningTextD : _warningTextL;
  Color get warningFill => isDarkMode ? _warningFillD : _warningFillL;
  Color get warningStroke => isDarkMode ? _warningStrokeD : _warningStrokeL;

  // Error Colors
  Color get errorText => isDarkMode ? _errorTextD : _errorTextL;
  Color get errorFill => isDarkMode ? _errorFillD : _errorFillL;
  Color get errorStroke => isDarkMode ? _errorStrokeD : _errorStrokeL;

  // Information Colors
  Color get infoText => isDarkMode ? _infoTextD : _infoTextL;
  Color get infoFill => isDarkMode ? _infoFillD : _infoFillL;
  Color get infoStroke => isDarkMode ? _infoStrokeD : _infoStrokeL;

  // Zone Colors
  Color get zone1Light => isDarkMode ? _zone1LightD : _zone1LightL;
  Color get zone1Stroke => isDarkMode ? _zone1StrokeD : _zone1StrokeL;
  Color get zone1Fill => isDarkMode ? _zone1FillD : _zone1FillL;
  Color get zone1Dark => isDarkMode ? _zone1DarkD : _zone1DarkL;

  Color get zone2Light => isDarkMode ? _zone2LightD : _zone2LightL;
  Color get zone2Stroke => isDarkMode ? _zone2StrokeD : _zone2StrokeL;
  Color get zone2Fill => isDarkMode ? _zone2FillD : _zone2FillL;
  Color get zone2Dark => isDarkMode ? _zone2DarkD : _zone2DarkL;

  Color get zone3Light => isDarkMode ? _zone3LightD : _zone3LightL;
  Color get zone3Stroke => isDarkMode ? _zone3StrokeD : _zone3StrokeL;
  Color get zone3Fill => isDarkMode ? _zone3FillD : _zone3FillL;
  Color get zone3Dark => isDarkMode ? _zone3DarkD : _zone3DarkL;

  Color get zone4Light => isDarkMode ? _zone4LightD : _zone4LightL;
  Color get zone4Stroke => isDarkMode ? _zone4StrokeD : _zone4StrokeL;
  Color get zone4Fill => isDarkMode ? _zone4FillD : _zone4FillL;
  Color get zone4Dark => isDarkMode ? _zone4DarkD : _zone4DarkL;

  Color get zone5Light => isDarkMode ? _zone5LightD : _zone5LightL;
  Color get zone5Stroke => isDarkMode ? _zone5StrokeD : _zone5StrokeL;
  Color get zone5Fill => isDarkMode ? _zone5FillD : _zone5FillL;
  Color get zone5Dark => isDarkMode ? _zone5DarkD : _zone5DarkL;

  Color get zone6Light => isDarkMode ? _zone6LightD : _zone6LightL;
  Color get zone6Stroke => isDarkMode ? _zone6StrokeD : _zone6StrokeL;
  Color get zone6Fill => isDarkMode ? _zone6FillD : _zone6FillL;
  Color get zone6Dark => isDarkMode ? _zone6DarkD : _zone6DarkL;

  Color get zone7Light => isDarkMode ? _zone7LightD : _zone7LightL;
  Color get zone7Stroke => isDarkMode ? _zone7StrokeD : _zone7StrokeL;
  Color get zone7Fill => isDarkMode ? _zone7FillD : _zone7FillL;
  Color get zone7Dark => isDarkMode ? _zone7DarkD : _zone7DarkL;

  Color get zone8Light => isDarkMode ? _zone8LightD : _zone8LightL;
  Color get zone8Stroke => isDarkMode ? _zone8StrokeD : _zone8StrokeL;
  Color get zone8Fill => isDarkMode ? _zone8FillD : _zone8FillL;
  Color get zone8Dark => isDarkMode ? _zone8DarkD : _zone8DarkL;

  Color get zone9Light => isDarkMode ? _zone9LightD : _zone9LightL;
  Color get zone9Stroke => isDarkMode ? _zone9StrokeD : _zone9StrokeL;
  Color get zone9Fill => isDarkMode ? _zone9FillD : _zone9FillL;
  Color get zone9Dark => isDarkMode ? _zone9DarkD : _zone9DarkL;

  // SPL Colors
  Color get spl100 => isDarkMode ? _spl100D : _spl100L;
  Color get spl200 => isDarkMode ? _spl200D : _spl200L;
  Color get spl300 => isDarkMode ? _spl300D : _spl300L;
  Color get spl400 => isDarkMode ? _spl400D : _spl400L;
  Color get spl500 => isDarkMode ? _spl500D : _spl500L;
  Color get spl600 => isDarkMode ? _spl600D : _spl600L;

  ///
  /// Wiring view color scheme
  ///
  Color get canvasBG => Color(0xFFFFFFFF);
  Color get componentBG => Color(0xFFFBFBFB);
  Color get componentBorder => Color(0xFFC4C4C4);
  Color get componentHeadingBG => Color(0xFF181717);
  Color get wireColor => Color(0xFFC89450);
  Color get componentFG => Colors.black;

  ///
  /// Component Port
  ///
  Color get activePortBG => Colors.black;
  Color get activePortFG => Colors.white;
  Color get inactivePortBG => Color(0xFFAEAEAE);
  Color get inactivePortFG => Colors.black;

  ///
  ///
  ///
  Color get portOverlayTitle => Color(0xFF929292);

  Color get green => Color(0xFF78B899);

  ///
  /// Shadow Colors
  ///
  Color get shadowDark => isDarkMode ? _expressiveShadowDarkD.withValues(alpha: 0.84) : _expressiveShadowDarkD.withValues(alpha: 0.14);
  Color get shadowLight => isDarkMode ? _expressiveShadowLightD.withAlpha((0.1 * 255).toInt()) : _expressiveShadowLightL;
}
