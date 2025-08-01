import 'package:flutter/material.dart';

class GradientActionButton extends StatelessWidget {
  /// Width of the button. Defaults to 240.
  final double width;

  /// Height of the button. Defaults to 60.
  final double height;

  /// Corner radius. Defaults to 30.
  final double borderRadius;

  /// Gradient colors. Defaults to [Color(0xFF2F45FA), Color(0xFF3490FA)].
  final List<Color> gradientColors;

  /// Box shadow. If null, a default shadow matching the second gradient color is used.
  final List<BoxShadow>? boxShadow;

  /// Text label.
  final String label;

  /// Text style. Defaults to bold white, size 18.
  final TextStyle textStyle;

  /// Callback when tapped.
  final VoidCallback onTap;

  /// Optional widget to display after the label (e.g. an animated icon).
  final Widget? trailing;

  const GradientActionButton({
    super.key,
    this.width = 240,
    this.height = 60,
    this.borderRadius = 30,
    this.gradientColors = const <Color>[
      Color(0xFF2F45FA),
      Color(0xFF3490FA),
    ],
    this.boxShadow,
    required this.label,
    this.textStyle = const TextStyle(
      color: Colors.white,
      fontSize: 18,
      fontWeight: FontWeight.bold,
    ),
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final List<BoxShadow> shadows = boxShadow ??
        <BoxShadow>[
          BoxShadow(
            color: gradientColors.last.withValues(alpha: 0.5),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ];

    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: shadows,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(borderRadius),
            onTap: onTap,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(label, style: textStyle),
                  if (trailing != null) ...<Widget>[
                    const SizedBox(width: 12),
                    trailing!,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
