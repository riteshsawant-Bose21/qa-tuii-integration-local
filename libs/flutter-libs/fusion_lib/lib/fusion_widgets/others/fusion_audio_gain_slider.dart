import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_lib.dart';

class FusionAudioGainSlider extends StatefulWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? thumbColor;
  final Color? textColor;
  final TextStyle? labelTextStyle;

  const FusionAudioGainSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.inactiveColor,
    this.thumbColor,
    this.textColor,
    this.labelTextStyle,
  });

  @override
  State<FusionAudioGainSlider> createState() => _FusionAudioGainSliderState();
}

class _FusionAudioGainSliderState extends State<FusionAudioGainSlider> {
  // Shared notifier: [trackLeft, trackRight] in widget-local coordinates
  final ValueNotifier<List<double>?> _trackBounds = ValueNotifier(null);

  @override
  void dispose() {
    _trackBounds.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              thumbShape: const _SquareSliderThumbShape(
                thumbRadius: 6,
                cornerRadius: 3,
              ),
              trackHeight: 12,
              trackShape: _GainSliderTrackShape(
                activeColor: widget.activeColor ?? Theme.of(context).colorScheme.zone1Stroke,
                inactiveColor: widget.inactiveColor ?? Theme.of(context).colorScheme.surfaceVariant,
                onTrackRect: (left, right) {
                  if (_trackBounds.value == null || _trackBounds.value![0] != left || _trackBounds.value![1] != right) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _trackBounds.value = [left, right];
                    });
                  }
                },
              ),
              thumbColor: widget.thumbColor ?? Colors.white,
              activeTrackColor: widget.activeColor ?? Theme.of(context).colorScheme.zone1Stroke,
              inactiveTrackColor: widget.inactiveColor ?? Theme.of(context).colorScheme.surfaceVariant,
              overlayShape: SliderComponentShape.noOverlay,
            ),
            child: Slider(
              value: widget.value.clamp(-6.0, 6.0),
              min: -6,
              max: 6,
              onChanged: widget.onChanged,
            ),
          ),
          // Ticks + Labels aligned to exact track bounds from painter
          LayoutBuilder(
            builder: (context, constraints) {
              final tickColor = widget.textColor ?? Theme.of(context).colorScheme.onSurfaceVariant;
              final labelStyle =
                  widget.labelTextStyle ??
                  Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: tickColor,
                  );
              return ValueListenableBuilder<List<double>?>(
                valueListenable: _trackBounds,
                builder: (context, bounds, _) {
                  return _TicksAndLabels(
                    width: constraints.maxWidth,
                    trackLeft: bounds?[0],
                    trackRight: bounds?[1],
                    tickColor: tickColor,
                    labelStyle: labelStyle,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── Gain Track ───────────────────────────────────────────────────────────────

class _GainSliderTrackShape extends SliderTrackShape {
  final double cornerRadius;
  final Color activeColor;
  final Color inactiveColor;
  final void Function(double left, double right) onTrackRect;

  const _GainSliderTrackShape({
    this.cornerRadius = 4,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTrackRect,
  });

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = sliderTheme.trackHeight ?? 4;
    final double trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    return Rect.fromLTWH(
      offset.dx,
      trackTop,
      parentBox.size.width,
      trackHeight,
    );
  }

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isEnabled = false,
    bool isDiscrete = false,
    required TextDirection textDirection,
  }) {
    final Canvas canvas = context.canvas;
    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    // Report exact track left/right to widget so ticks align perfectly
    onTrackRect(trackRect.left, trackRect.right);

    final RRect trackRRect = RRect.fromRectAndRadius(trackRect, Radius.circular(cornerRadius));

    // Full inactive background
    canvas.drawRRect(trackRRect, Paint()..color = inactiveColor);

    // Center-origin active region
    final double centerX = trackRect.left + trackRect.width / 2;
    final double activeLeft = thumbCenter.dx < centerX ? thumbCenter.dx : centerX;
    final double activeRight = thumbCenter.dx < centerX ? centerX : thumbCenter.dx;

    if ((activeRight - activeLeft) > 0) {
      canvas.drawRect(
        Rect.fromLTRB(activeLeft, trackRect.top, activeRight, trackRect.bottom),
        Paint()..color = sliderTheme.activeTrackColor ?? activeColor,
      );
    }

    // Inset shadows
    void drawInsetShadow({
      required Color color,
      required Offset shadowOffset,
      required double blur,
    }) {
      canvas.save();
      canvas.clipRRect(trackRRect);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          trackRect.shift(shadowOffset),
          Radius.circular(cornerRadius),
        ),
        Paint()
          ..color = color
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur / 1.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = blur * 2,
      );
      canvas.restore();
    }

    drawInsetShadow(color: const Color(0x2A000000), shadowOffset: const Offset(1.5, 1.5), blur: 3);
    drawInsetShadow(color: const Color(0x0AFFFFFF), shadowOffset: const Offset(-1.5, -1.5), blur: 2);
  }
}

// ─── Ticks + Labels ──────────────────────────────────────────────────────────

class _TicksAndLabels extends StatelessWidget {
  final double width;
  final double? trackLeft;
  final double? trackRight;
  final Color tickColor;
  final TextStyle? labelStyle;

  const _TicksAndLabels({
    required this.width,
    required this.trackLeft,
    required this.trackRight,
    required this.tickColor,
    this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    const List<String> labels = ['-6', '-3', '0', '+3', '+6'];
    const List<double> tickValues = [-6, -3, 0, 3, 6];
    const double tickHeight = 6.0;
    const double tickWidth = 1.5;
    const double labelGap = 3.0;

    const double thumbRadius = 6.0;
    final double tLeft = (trackLeft ?? 0);
    final double tRight = (trackRight ?? width) - thumbRadius * 2;
    final double tWidth = tRight - tLeft;

    double xFor(int i) {
      final fraction = (tickValues[i] - (-6)) / (6 - (-6));
      return tLeft + fraction * tWidth;
    }

    return SizedBox(
      width: width,
      height: tickHeight + labelGap + 14,
      child: Stack(
        children: List.generate(labels.length, (i) {
          final double x = xFor(i);
          return Positioned(
            left: x - tickWidth / 2,
            top: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: tickWidth,
                  height: tickHeight,
                  decoration: BoxDecoration(
                    color: tickColor,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                SizedBox(height: labelGap),
                Transform.translate(
                  offset: Offset(
                    -(i == 0
                        ? 0.0
                        : i == labels.length - 1
                        ? tickWidth
                        : tickWidth / 2),
                    0,
                  ),
                  child: Text(
                    labels[i],
                    textAlign: i == 0
                        ? TextAlign.left
                        : i == labels.length - 1
                        ? TextAlign.right
                        : TextAlign.center,
                    style: labelStyle,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ─── Square Thumb ─────────────────────────────────────────────────────────────

class _SquareSliderThumbShape extends SliderComponentShape {
  final double thumbRadius;
  final double cornerRadius;

  const _SquareSliderThumbShape({
    required this.thumbRadius,
    this.cornerRadius = 3,
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isInteractive) {
    return Size(thumbRadius * 2, thumbRadius * 2);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    context.canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center,
          width: thumbRadius * 2,
          height: thumbRadius * 2,
        ),
        Radius.circular(cornerRadius),
      ),
      Paint()
        ..color = sliderTheme.thumbColor ?? Colors.white
        ..style = PaintingStyle.fill,
    );
  }
}
