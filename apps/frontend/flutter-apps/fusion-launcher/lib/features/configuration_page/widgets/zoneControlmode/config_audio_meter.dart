// --- usage Example ---
import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'dart:math';

import 'package:fusion_lib/fusion_lib.dart';

class ConfigAudioMeter extends StatefulWidget {
  final double marginHorizontal;
  final double marginVertical;
  final bool muted;

  const ConfigAudioMeter({
    super.key,
    this.marginHorizontal = 16,
    this.marginVertical = 0,
    this.muted = false,
  });

  @override
  State<ConfigAudioMeter> createState() => _ConfigAudioMeterState();
}

class _ConfigAudioMeterState extends State<ConfigAudioMeter> {
  // Initial value
  double _targetValue = -60;
  Timer? _simulationTimer;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    // Update frequency: 120ms (approx 8 updates/sec) for fluid motion
    if (!widget.muted) {
      _startSimulation();
    }
  }

  void _startSimulation() {
    _simulationTimer?.cancel();
    _simulationTimer = Timer.periodic(const Duration(milliseconds: 150), (Timer timer) {
      if (mounted && !widget.muted) {
        setState(() {
          _targetValue = _generateRealisticDb();
        });
      }
    });
  }

  double _generateRealisticDb() {
    final double roll = _random.nextDouble(); // 0.0 to 1.0

    if (roll < 0.70) {
      // --- NORMAL SPEECH/MUSIC (70% Chance) ---
      // Range: -36 to -12
      // This is the "green/yellow" active zone
      return -36 + (_random.nextDouble() * 24);
    } else if (roll < 0.90) {
      // --- QUIET / PAUSE (20% Chance) ---
      // Range: -55 to -40
      return -55 + (_random.nextDouble() * 15);
    } else {
      // --- PEAK / LOUD (10% Chance) ---
      // Range: -12 to +1.5 (occasionally clips)
      return -12 + (_random.nextDouble() * 13.5);
    }
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ConfigAudioMeter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.muted != oldWidget.muted) {
      if (widget.muted) {
        _simulationTimer?.cancel();
        if (mounted) {
          setState(() {
            _targetValue = -60; // Reset to silence when muted
          });
        }
      } else {
        _startSimulation();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        height: 40,
        // width: double.infinity,
        margin: EdgeInsets.symmetric(
          horizontal: widget.marginHorizontal,
          vertical: widget.marginVertical,
        ),
        color: Colors.transparent,
        // TweenAnimationBuilder interpolates from "old value" to "new value"
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: -60, end: _targetValue),
          // Duration slightly longer than timer tick (150ms vs 120ms) creates a
          // "lag" effect that feels like a real analog needle physics
          duration: const Duration(milliseconds: 150),
          curve: Curves.fastOutSlowIn,
          builder: (BuildContext context, double animatedValue, Widget? child) {
            return AudioMeterWidget(
              currentValue: animatedValue,
              minDb: -60,
              maxDb: 0,
              limitDb: -10,
            );
          },
        ),
      ),
    );
  }
}

// --- The Custom Audio Meter Widget (Unchanged logic, slimmer visual) ---

class AudioMeterWidget extends StatefulWidget {
  final double currentValue;
  final double minDb;
  final double maxDb;
  final double limitDb;

  const AudioMeterWidget({
    super.key,
    required this.currentValue,
    this.minDb = -60,
    this.maxDb = 0,
    this.limitDb = -10,
  });

  @override
  State<AudioMeterWidget> createState() => _AudioMeterWidgetState();
}

class _AudioMeterWidgetState extends State<AudioMeterWidget> {
  bool _isLimitLightOn = false;
  Timer? _limitTimer;

  @override
  void didUpdateWidget(covariant AudioMeterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Logic: If we cross the limit, turn light on and reset 10s timer
    if (widget.currentValue > widget.limitDb) {
      _triggerLimitLight();
    }
  }

  void _triggerLimitLight() {
    // Cancel existing timer if dragging continues above limit
    _limitTimer?.cancel();

    if (!_isLimitLightOn) {
      setState(() {
        _isLimitLightOn = true;
      });
    }

    // Keep light on for 10 seconds
    _limitTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() {
          _isLimitLightOn = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _limitTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _AudioMeterPainter(
        currentValue: widget.currentValue,
        minDb: widget.minDb,
        maxDb: widget.maxDb,
        limitDb: widget.limitDb,
        isLimitLightOn: _isLimitLightOn,
        trackColor: context.colorScheme.elevation3,
      ),
    );
  }
}

class _AudioMeterPainter extends CustomPainter {
  final double currentValue;
  final double minDb;
  final double maxDb;
  final double limitDb;
  final bool isLimitLightOn;
  final Color trackColor;

  _AudioMeterPainter({
    required this.currentValue,
    required this.minDb,
    required this.maxDb,
    required this.limitDb,
    required this.isLimitLightOn,
    this.trackColor = const Color(0xFF1A1A1A), // Default dark gray track
  });

  @override
  void paint(Canvas canvas, Size size) {
    // --- Layout Constants ---
    const double barHeight = 10.0;
    const double labelSectionHeight = 20.0;

    // The light box is a square, its size matches the bar height
    final double lightBoxSize = barHeight;

    // CHANGED: Increased from 12.0 to 24.0 to create more gap
    const double rightPadding = 24.0;

    // The width available for the actual meter bar
    // (Total Width - Light Box Width - The Gap we just increased)
    final double barWidth = size.width - lightBoxSize - rightPadding;

    // Y position centering
    final double contentCenterY = (size.height - labelSectionHeight) / 2;
    final double barTop = contentCenterY;
    final double barBottom = barTop + barHeight;

    // Helper to normalize dB value to 0.0 - 1.0 range
    double normalize(double db) => (db - minDb) / (maxDb - minDb);

    // --- 1. Draw Background Track ---
    final Paint trackPaint =
        Paint()
          ..color = trackColor
          ..style = PaintingStyle.fill;

    final RRect trackRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, barTop, barWidth, barHeight),
      const Radius.circular(barHeight / 2),
    );
    canvas.drawRRect(trackRRect, trackPaint);

    // --- 2. Draw Gradient Active Level ---
    final double effectiveValue = currentValue.clamp(minDb, maxDb + 1);
    final double fillPercentage = normalize(effectiveValue);

    if (fillPercentage > 0) {
      final Paint activePaint =
          Paint()
            ..shader = ui.Gradient.linear(
              Offset.zero,
              Offset(barWidth, 0),
              <ui.Color>[
                const Color(0xFF388E3C), // Darker Green
                const Color(0xFF8BC34A), // Light Green
                const Color(0xFFFFEB3B), // Yellow
                const Color(0xFFFF9800), // Orange
              ],
              <double>[0.0, 0.6, 0.85, 1.0],
            );

      final double currentWidth = barWidth * fillPercentage;
      final RRect activeRRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, barTop, currentWidth, barHeight),
        const Radius.circular(barHeight / 2),
      );
      canvas.drawRRect(activeRRect, activePaint);
    }

    // --- 3. Draw Ticks and Labels ---
    final Paint tickPaint =
        Paint()
          ..color = Colors.grey.shade700
          ..strokeWidth = 1.0;

    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    const double step = 12;

    for (double db = minDb; db <= maxDb; db += step) {
      if (db > maxDb + 0.001) break;

      final double norm = normalize(db);
      final double xPos = norm * barWidth;

      // Draw Tick
      canvas.drawLine(Offset(xPos, barBottom + 2), Offset(xPos, barBottom + 6), tickPaint);

      // Draw Text
      textPainter.text = TextSpan(
        text: db.abs() < 0.1 ? "0" : db.toInt().toString(),
        style: TextStyle(
          color: Colors.grey.shade500,
          fontSize: 8,
          fontWeight: FontWeight.w500,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(xPos - (textPainter.width / 2), barBottom + 8));
    }

    // --- 4. Draw Limit Marker ---
    if (limitDb >= minDb && limitDb <= maxDb) {
      final double limitX = normalize(limitDb) * barWidth;
      final Paint limitLinePaint =
          Paint()
            ..color = const Color(0xFFD32F2F).withOpacity(0.7)
            ..strokeWidth = 1.5;

      canvas.drawLine(Offset(limitX, barTop), Offset(limitX, barBottom), limitLinePaint);
    }

    // --- 5. Draw Limit Light Box ---
    // Calculates position to be flush with the right edge of the canvas
    final double lightBoxLeft = barWidth + rightPadding;
    final double lightBoxTop = barTop + (barHeight / 2) - (lightBoxSize / 2);

    final Rect lightBoxRect = Rect.fromLTWH(lightBoxLeft, lightBoxTop, lightBoxSize, lightBoxSize);
    final RRect lightBoxRRect = RRect.fromRectAndRadius(lightBoxRect, const Radius.circular(4));

    final Paint lightBoxPaint =
        Paint()
          ..style = isLimitLightOn ? PaintingStyle.fill : PaintingStyle.stroke
          ..color = isLimitLightOn ? const Color(0xFFD32F2F) : Colors.grey.shade700
          ..strokeWidth = 1.5;

    if (isLimitLightOn) {
      canvas.drawRRect(
        lightBoxRRect.inflate(2),
        Paint()
          ..color = Colors.red.withOpacity(0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }

    canvas.drawRRect(lightBoxRRect, lightBoxPaint);

    // Draw "LIMIT" Text
    textPainter.text = TextSpan(
      text: "LIMIT",
      style: TextStyle(
        color: Colors.grey.shade600,
        fontSize: 8,
        fontWeight: FontWeight.w500,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        lightBoxLeft + (lightBoxSize / 2) - (textPainter.width / 2),
        lightBoxRect.bottom + 4,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _AudioMeterPainter oldDelegate) {
    return oldDelegate.currentValue != currentValue || oldDelegate.isLimitLightOn != isLimitLightOn;
  }
}
