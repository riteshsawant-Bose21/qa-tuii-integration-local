import 'package:flutter/material.dart';

extension ClickWidgetExtension on Widget {
  Widget clickWidget({
    required VoidCallback onTap,
    bool enableFeedback = true,
    BorderRadius? borderRadius,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: borderRadius,
      splashFactory:
      enableFeedback ? InkRipple.splashFactory : NoSplash.splashFactory,
      child: this,
    );
  }
}