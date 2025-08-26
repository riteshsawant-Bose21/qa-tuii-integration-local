import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/constants.dart';

import '../../../../core/constants.dart';
import '../../domain/entities/audio_widget_entity.dart';

class AudioGainFader extends StatefulWidget {
  final double minValue;
  final double maxValue;
  final AudioWidgetOrientation orientation;
  final ValueChanged<double>? onChanged;
  final double width;
  final double height;
  final double currentValue;
  final String name;

  const AudioGainFader({
    super.key,
    required this.minValue,
    required this.maxValue,
    required this.orientation,
    this.onChanged,
    this.width = 100,
    this.height = 240,
    this.currentValue = 0,
    this.name = "",
  });

  @override
  AudioGainFaderState createState() => AudioGainFaderState();
}

class AudioGainFaderState extends State<AudioGainFader> {
  late double _currentValue;
  static const int tickCount = 11;
  Timer? _debounce;

  /// FIXME: For now, this adds a delay between sending updates to the server.
  /// However, the latest value will always be sent
  void _updateValue(double value) {
    if (mounted) {
      setState(() {
        _currentValue = value;
      });
    }

    // Cancel any previously scheduled update
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // Schedule a new update after a delay
    _debounce = Timer(const Duration(milliseconds: 100), () {
      widget.onChanged?.call(value);
    });
  }

  @override
  void initState() {
    super.initState();
    _currentValue = widget.currentValue;
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Slider slider = Slider(
      min: widget.minValue,
      max: widget.maxValue,
      value: _currentValue.clamp(widget.minValue, widget.maxValue),
      onChanged: (double value) {
        _updateValue(value);
      },
      onChangeEnd: (double value) {
        widget.onChanged?.call(value);
      },
    );

    final SliderTheme sliderTheme = SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 6,
        trackShape: const RectangularSliderTrackShape(),
        thumbColor: colors.tertiary,
        overlayShape: SliderComponentShape.noOverlay,
        activeTrackColor: colors.tertiary,
        inactiveTrackColor: Colors.grey.withAlpha(128),
      ),
      child: slider,
    );

    return Column(
      children: <Widget>[
        Builder(
          builder: (BuildContext context) {
            if (widget.orientation == AudioWidgetOrientation.vertical) {
              return SizedBox(
                width: widget.width,
                height: widget.height,
                child: Column(
                  children: <Widget>[
                    Container(
                      height: 44,
                      padding: const EdgeInsets.only(bottom: 8),
                      alignment: Alignment.center,
                      child: Text(
                        widget.name,
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
                            Padding(
                              padding: const EdgeInsets.only(left: 4.0),
                              child: _buildVerticalTicks(),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 18.0),
                              child: RotatedBox(
                                quarterTurns: -1,
                                child: sliderTheme,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        _currentValue.toStringAsFixed(2),
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
                    widget.name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8.0),
                  SizedBox(
                    width: widget.height,
                    height: widget.width,
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
                                    child: _buildHorizontalTicks(),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 16.0),
                                  child: sliderTheme,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            _currentValue.toStringAsFixed(2),
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

  Widget _buildHorizontalTicks() {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return SizedBox(
      height: 36, // increased height to allow room for labels
      child: Row(
        children: List<Widget>.generate(tickCount, (int index) {
          String? label;
          if (index == 0) {
            label = widget.minValue.toStringAsFixed(0);
          } else if (index == tickCount - 1) {
            label = widget.maxValue.toStringAsFixed(0);
          } else if (index == tickCount ~/ 2) {
            label = ((widget.minValue + widget.maxValue) / 2).toStringAsFixed(0);
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
                        color: AppColors.primarySoft.withValues(alpha: 0.8),
                      ),
                    )
                    : const SizedBox(height: 12),
                const SizedBox(height: 2),
                Container(
                  height: label == null ? 4 : 6,
                  width: 1,
                  color: label == null ? AppColors.primarySoft.withValues(alpha: 0.5) : colors.tertiary,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildVerticalTicks() {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: 36,
      child: Column(
        children: List<Widget>.generate(tickCount, (int index) {
          String? label;
          if (index == 0) {
            label = widget.maxValue.toStringAsFixed(0);
          } else if (index == tickCount - 1) {
            label = widget.minValue.toStringAsFixed(0);
          } else if (index == tickCount ~/ 2) {
            label = ((widget.minValue + widget.maxValue) / 2).toStringAsFixed(0);
          }
          return Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
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
                          color: AppColors.primarySoft.withValues(alpha: 0.8),
                        ),
                      )
                      : const SizedBox(width: 20),
                  Container(
                    width: label == null ? 4 : 6,
                    height: 1,
                    color: label == null ? AppColors.primarySoft.withValues(alpha: 0.5) : colors.tertiary,
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
