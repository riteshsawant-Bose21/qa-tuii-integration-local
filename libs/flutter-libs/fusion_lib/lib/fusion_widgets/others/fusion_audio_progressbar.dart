import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

class FusionAudioSlider extends StatelessWidget {
  final Duration currentPosition;
  final Duration? totalDuration;
  final ValueChanged<Duration> onSeek;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? thumbColor;
  final Color? textColor;
  final TextStyle? timeTextStyle;

  const FusionAudioSlider({
    super.key,
    required this.currentPosition,
    required this.totalDuration,
    required this.onSeek,
    this.activeColor,
    this.inactiveColor,
    this.thumbColor,
    this.textColor,
    this.timeTextStyle,
  });

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final total = totalDuration ?? Duration.zero;
    final current = currentPosition;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            thumbShape: const _SquareSliderThumbShape(
              thumbRadius: 6,
              cornerRadius: 3,
            ),
            trackHeight: 12,
            trackShape: _RoundedRectSliderTrackShape(
              tickColor: Theme.of(context).colorScheme.strokeDark,
            ),
            thumbColor: thumbColor ?? Colors.white,
            activeTrackColor: activeColor ?? Theme.of(context).colorScheme.primary,
            inactiveTrackColor: inactiveColor ?? Theme.of(context).colorScheme.surfaceVariant,
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
          ),
          child: Slider(
            value: current.inSeconds.toDouble().clamp(
              0,
              (total.inSeconds > 0 ? total.inSeconds : 1).toDouble(),
            ),
            min: 0,
            max: (total.inSeconds > 0 ? total.inSeconds : 1).toDouble(),
            onChanged: (double value) {
              onSeek(Duration(seconds: value.toInt()));
            },
          ),
        ),
        const SizedBox(height: 4),
        // Time labels
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(current),
                style:
                    timeTextStyle ??
                    Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: textColor ?? Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              Text(
                _formatDuration(total),
                style:
                    timeTextStyle ??
                    Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: textColor ?? Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Square Thumb ────────────────────────────────────────────────────────────

class _SquareSliderThumbShape extends SliderComponentShape {
  final double thumbRadius;
  final double cornerRadius;

  const _SquareSliderThumbShape({
    required this.thumbRadius,
    this.cornerRadius = 10,
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
    final Canvas canvas = context.canvas;
    final Paint paint = Paint()
      ..color = sliderTheme.thumbColor ?? Colors.white
      ..style = PaintingStyle.fill;

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center,
        width: thumbRadius * 2,
        height: thumbRadius * 2,
      ),
      Radius.circular(cornerRadius),
    );

    canvas.drawRRect(rrect, paint);
  }
}

// ─── Rounded Rect Track ──────────────────────────────────────────────────────

class _RoundedRectSliderTrackShape extends SliderTrackShape {
  final double cornerRadius;
  final Color? tickColor;
  final double tickWidth;
  final double tickHeight;

  const _RoundedRectSliderTrackShape({
    this.cornerRadius = 4,
    this.tickColor,
    this.tickWidth = 1.5,
    this.tickHeight = 6,
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

    // Inactive (full) track
    final Paint inactivePaint = Paint()..color = sliderTheme.inactiveTrackColor ?? Colors.grey;
    canvas.drawRRect(
      RRect.fromRectAndRadius(trackRect, Radius.circular(cornerRadius)),
      inactivePaint,
    );

    // Active track
    final Paint activePaint = Paint()..color = sliderTheme.activeTrackColor ?? Colors.blue;
    final Rect activeRect = Rect.fromLTRB(
      trackRect.left,
      trackRect.top,
      thumbCenter.dx,
      trackRect.bottom,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(activeRect, Radius.circular(cornerRadius)),
      activePaint,
    );

    // ── Inset shadows ──────────────────────────────────────────────────────
    final RRect trackRRect = RRect.fromRectAndRadius(trackRect, Radius.circular(cornerRadius));

    // Helper to draw one inset shadow layer
    void drawInsetShadow({
      required Color color,
      required Offset offset,
      required double blur,
    }) {
      final Paint shadowPaint = Paint()
        ..color = color
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur / 2);

      canvas.save();
      canvas.clipRRect(trackRRect);

      // Draw a shifted copy of the track outline OUTSIDE the clip,
      // so only the bleed-in edge is visible inside — true inset effect
      final RRect shadowRRect = RRect.fromRectAndRadius(
        trackRect.shift(offset),
        Radius.circular(cornerRadius),
      );

      // Paint a solid rect the size of the track shifted by offset,
      // then stroke a thick border so shadow bleeds inward
      final Paint borderPaint = Paint()
        ..color = color
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur / 1.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = blur * 2;

      canvas.drawRRect(shadowRRect, borderPaint);
      canvas.restore();
    }

    // Dark inset shadow: 1.5px 1.5px 5px #0000007A
    drawInsetShadow(
      color: const Color(0x2A000000),
      offset: const Offset(1.5, 1.5),
      blur: 3,
    );

    // Light inset shadow: -1.5px -1.5px 3px #FFFFFF14
    drawInsetShadow(
      color: const Color(0x0AFFFFFF),
      offset: const Offset(-1.5, -1.5),
      blur: 2,
    );

    // Tick marks flush below track
    if (tickColor != null) {
      final Paint tickPaint = Paint()
        ..color = tickColor!
        ..style = PaintingStyle.fill;

      final double tickTop = trackRect.bottom + 2;
      final double tickBottom = tickTop + tickHeight + 2;
      const double tickGap = 6;
      final RRect leftTick = RRect.fromRectAndRadius(
        Rect.fromLTRB(
          trackRect.left + tickGap,
          tickTop,
          trackRect.left + tickGap + tickWidth,
          tickBottom,
        ),
        const Radius.circular(1),
      );
      final RRect rightTick = RRect.fromRectAndRadius(
        Rect.fromLTRB(
          trackRect.right - tickGap - tickWidth,
          tickTop,
          trackRect.right - tickGap,
          tickBottom,
        ),
        const Radius.circular(1),
      );

      canvas.drawRRect(leftTick, tickPaint);
      canvas.drawRRect(rightTick, tickPaint);
    }
  }
}
