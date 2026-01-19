import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_logger/logger.dart';

import '../../domain/entities/audio_widget_entity.dart';

class AudioMeter extends StatelessWidget {
  final double minValue;
  final double maxValue;
  final AudioWidgetOrientation orientation;
  final double width;
  final double height;
  final double currentValue;
  final Color meterColor;
  final Color backgroundColor;
  final String name;
  static const int tickCount = 11;

  const AudioMeter({
    super.key,
    required this.minValue,
    required this.maxValue,
    required this.orientation,
    this.width = 100,
    this.height = 240,
    this.currentValue = 0,
    this.name = "",
    this.meterColor = const Color(0xFF4169E1), // Royal Blue
    this.backgroundColor = const Color(0xFFE0E0E0),
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Builder(
          builder: (BuildContext context) {
            if (orientation == AudioWidgetOrientation.vertical) {
              return SizedBox(
                width: width,
                height: height,
                child: Column(
                  children: <Widget>[
                    Container(
                      height: 44,
                      padding: const EdgeInsets.only(bottom: 8),
                      alignment: Alignment.center,
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Theme.of(context).dialogBackgroundColor.withValues(alpha: 0.5),
                        ),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Stack(
                          children: <Widget>[
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 4.0),
                                child: _buildVerticalTicks(context),
                              ),
                            ),
                            Align(
                              alignment: Alignment.center,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 20.0, top: 10.0, bottom: 10.0),
                                child: Container(
                                  width: 10,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: backgroundColor,
                                  ),
                                  child: CustomPaint(
                                    size: Size(
                                      40,
                                      height,
                                    ),
                                    painter: _MeterPainter(
                                      minValue: minValue,
                                      maxValue: maxValue,
                                      currentValue: currentValue,
                                      orientation: orientation,
                                      meterColor: meterColor,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        currentValue.toStringAsFixed(2),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.normal,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              );
            } else {
              return Column(
                children: <Widget>[
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8.0),
                  SizedBox(
                    width: height,
                    height: width,
                    child: Column(
                      children: <Widget>[
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Theme.of(context).dialogBackgroundColor.withValues(alpha: 0.5),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: Stack(
                              alignment: Alignment.topCenter,
                              children: <Widget>[
                                Align(
                                  alignment: Alignment.topCenter,
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 32.0),
                                    child: _buildHorizontalTicks(context),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 16.0),
                                  child: Align(
                                    alignment: Alignment.center,
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 10.0, right: 10.0),
                                      child: Container(
                                        height: 10,
                                        width: height,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: backgroundColor,
                                        ),
                                        child: CustomPaint(
                                          size: Size(
                                            height,
                                            40,
                                          ),
                                          painter: _MeterPainter(
                                            minValue: minValue,
                                            maxValue: maxValue,
                                            currentValue: currentValue,
                                            orientation: orientation,
                                            meterColor: meterColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ), //TODO: Add meter
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            currentValue.toStringAsFixed(2),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.normal,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildHorizontalTicks(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return SizedBox(
      height: 36, // increased height to allow room for labels
      child: Row(
        children: List<Widget>.generate(tickCount, (int index) {
          String? label;
          if (index == 0) {
            label = minValue.toStringAsFixed(0);
          } else if (index == tickCount - 1) {
            label = maxValue.toStringAsFixed(0);
          } else if (index == tickCount ~/ 2) {
            label = ((minValue + maxValue) / 2).toStringAsFixed(0);
          }
          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                label != null
                    ? Text(
                      label,
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryBlack,
                      ),
                    )
                    : const SizedBox(height: 12),
                const SizedBox(height: 2),
                Container(
                  height: label == null ? 4 : 6,
                  width: 1,
                  color: label == null ? Theme.of(context).primaryBlack.withValues(alpha: 0.5) : colors.tertiary,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildVerticalTicks(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: 36,
      child: Column(
        children: List<Widget>.generate(tickCount, (int index) {
          String? label;
          if (index == 0) {
            label = maxValue.toStringAsFixed(0);
          } else if (index == tickCount - 1) {
            label = minValue.toStringAsFixed(0);
          } else if (index == tickCount ~/ 2) {
            label = ((minValue + maxValue) / 2).toStringAsFixed(0);
          }
          return Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              spacing: 4,
              children: <Widget>[
                label != null
                    ? Text(
                      label,
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryBlack,
                      ),
                    )
                    : const SizedBox(width: 20),
                Container(
                  width: label == null ? 4 : 6,
                  height: 1,
                  color: label == null ? Theme.of(context).primaryBlack.withValues(alpha: 0.5) : colors.tertiary,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _MeterPainter extends CustomPainter {
  final double minValue;
  final double maxValue;
  final double currentValue;
  final AudioWidgetOrientation orientation;
  final Color meterColor;

  _MeterPainter({
    required this.minValue,
    required this.maxValue,
    required this.currentValue,
    required this.orientation,
    required this.meterColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint =
        Paint()
          ..color = meterColor
          ..style = PaintingStyle.fill;

    if (currentValue < minValue || currentValue > maxValue) {
      FusionLogger.log(
        tag: LogTag.debug,
        message: "WARNING: Value $currentValue is not in the range [$minValue, $maxValue].",
        logLevel: LogLevel.warning,
      );
    }

    // Make sure currentValue is not > maxValue and < minValue
    final double value = currentValue.clamp(
      min(minValue, maxValue),
      max(minValue, maxValue),
    );

    // Calculate the normalized value between 0 and 1
    double normalizedValue = (value - minValue) / (maxValue - minValue);

    if (normalizedValue == 0 && value == minValue) {
      normalizedValue = 0.01;
    }
    // Create gradient colors for the meter
    final LinearGradient gradient = LinearGradient(
      colors: const <Color>[
        Colors.green,
        Colors.yellow,
        Colors.red,
      ],
      stops: const <double>[0.0, 0.6, 0.8],
      begin: orientation == AudioWidgetOrientation.horizontal ? Alignment.centerLeft : Alignment.bottomCenter,
      end: orientation == AudioWidgetOrientation.horizontal ? Alignment.centerRight : Alignment.topCenter,
    );

    // Create shader from gradient
    final Shader shader = gradient.createShader(
      orientation == AudioWidgetOrientation.horizontal ? Rect.fromLTWH(0, 0, size.width, size.height) : Rect.fromLTWH(0, 0, size.width, size.height),
    );
    paint.shader = shader;

    if (orientation == AudioWidgetOrientation.horizontal) {
      // Draw horizontal meter
      final double meterWidth = size.width * normalizedValue;
      canvas.drawRect(
        Rect.fromLTWH(0, 0, meterWidth, size.height),
        paint,
      );
    } else {
      // Draw vertical meter
      final double meterHeight = size.height * normalizedValue;
      canvas.drawRect(
        Rect.fromLTWH(
          0,
          size.height - meterHeight,
          size.width,
          meterHeight,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_MeterPainter oldDelegate) {
    return oldDelegate.currentValue != currentValue;
  }
}
