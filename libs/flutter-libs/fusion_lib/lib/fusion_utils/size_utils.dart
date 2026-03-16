import 'package:flutter/material.dart';

extension SizeUtils on BuildContext {
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  Size get screenSize => mediaQuery.size;
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;
}

extension RadiusUtils on BuildContext {
  double get smallRadius => 8;
  double get mediumRadius => 16;
  double get largeRadius => 24;

  BorderRadius get borderRadiusSmall => BorderRadius.circular(smallRadius);
  BorderRadius get borderRadiusMedium => BorderRadius.circular(mediumRadius);
  BorderRadius get borderRadiusLarge => BorderRadius.circular(largeRadius);
}

extension PaddingUtils on BuildContext {
  double get smallGap => 4;
  double get mediumGap => 16;
  double get largeGap => 24;
}
