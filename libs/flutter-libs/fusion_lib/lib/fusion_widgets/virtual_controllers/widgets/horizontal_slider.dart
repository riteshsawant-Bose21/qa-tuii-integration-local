import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_widgets/virtual_controllers/volume_meter_painter.dart';

import '../../../fusion_theme/app_theme.dart';

class HorizontalAudioSlider extends StatefulWidget {
  final double initialValue;
  final ValueChanged<double>? onChanged;
  final bool isMuted;

  const HorizontalAudioSlider({
    super.key,
    this.initialValue = 50,
    this.onChanged,
    required this.isMuted,
  });

  @override
  State<HorizontalAudioSlider> createState() =>
      HorizontalAudioSliderState();
}

class HorizontalAudioSliderState
    extends State<HorizontalAudioSlider>
    with SingleTickerProviderStateMixin {
  late double value;
  double previousValue = 0;

  late AnimationController _controller;
  Animation<double>? _animation;

  @override
  void initState() {
    value = widget.initialValue;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 300,
      ),
    );

    _controller.addListener(() {
      setState(() {
        value =
            _animation!.value;
      });

      widget.onChanged?.call(
        value,
      );
    });

    super.initState();
  }

  @override
  void didUpdateWidget(
      covariant HorizontalAudioSlider oldWidget) {
    super.didUpdateWidget(
      oldWidget,
    );

    if (oldWidget.initialValue !=
        widget.initialValue) {
      value =
          widget.initialValue;
    }
  }

  void _updateValue(
      Offset localPosition,
      double width,
      ) {
    double newValue =
        (localPosition.dx /
            width) *
            100;

    newValue = newValue.clamp(
      0,
      100,
    );

    setState(() {
      value = newValue;
    });

    widget.onChanged?.call(
      newValue,
    );
  }

  void animateTo(
      double target,
      ) {
    _animation = Tween<double>(
      begin: value,
      end: target,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve:
        Curves.easeInOut,
      ),
    );

    _controller.forward(
      from: 0,
    );
  }

  void toggleMute(
      bool onChange) {
    // keep same logic if needed
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(
      BuildContext context) {
    previousValue = value;

    return LayoutBuilder(
      builder:
          (context, constraints) {
        return GestureDetector(
          onHorizontalDragUpdate:
              (details) {
            _updateValue(
              details.localPosition,
              constraints.maxWidth,
            );
          },
          onTapDown: (details) {
            _updateValue(
              details.localPosition,
              constraints.maxWidth,
            );
          },
          child: RotatedBox(
            quarterTurns: 1,
            child: CustomPaint(
              size: Size(
                constraints
                    .maxHeight,
                constraints
                    .maxWidth,
              ),
              painter:
              VolumeMeterPainterBG(
                value: value,
                showThumb:false,
                trackColor: context
                    .colorScheme
                    .elevation2,
                gradientColors:
                widget.isMuted
                    ? [
                  context
                      .colorScheme
                      .textBody,
                  context
                      .colorScheme
                      .iconWhite,
                ]
                    : [
                  context
                      .colorScheme
                      .primary,
                  context
                      .colorScheme
                      .iconWhite,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}