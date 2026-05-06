import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_widgets/virtual_controllers/volume_meter_painter.dart';

import '../../../fusion_theme/app_theme.dart';

class VerticalAudioSlider extends StatefulWidget {
  final double initialValue;
  final ValueChanged<double>? onChanged;
  final bool isMuted;

  const VerticalAudioSlider({
    super.key,
    this.initialValue = 50,
    this.onChanged,
    required this.isMuted,
  });

  @override
  State<VerticalAudioSlider> createState() => VerticalAudioSliderState();
}

class VerticalAudioSliderState extends State<VerticalAudioSlider> with SingleTickerProviderStateMixin {
  late double value;
  double previousValue = 0;

  late AnimationController _controller;
  Animation<double>? _animation;
  @override
  void initState() {

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _controller.addListener(() {
      setState(() {
        value = _animation!.value;
      });
      widget.onChanged?.call(value);
    });
    super.initState();
  }

  void _updateValue(Offset localPosition, double height) {
    double newValue = (1 - (localPosition.dy / height)) * 100;

    newValue = newValue.clamp(0, 100);

    setState(() => value = newValue);
    widget.onChanged?.call(newValue);
  }

  void animateTo(double target) {
    _animation = Tween<double>(
      begin: value,
      end: target,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _controller.forward(from: 0);
  }

  void toggleMute(bool onChange) {
    // if (value > 0) {
    //   previousValue = value;
    //   _animateTo(0);
    // } else {
    //   _animateTo(previousValue == 0 ? 50 : previousValue);
    // }
    // widget.onMuted?.call(!onChange);
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    value = widget.initialValue;
    previousValue = value;
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onVerticalDragUpdate: (details) {
            _updateValue(details.localPosition, constraints.maxHeight);
          },
          onTapDown: (details) {
            _updateValue(details.localPosition, constraints.maxHeight);
          },
          child: CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter:  VolumeMeterPainterBG(
                  value: value,
                  trackColor: context.colorScheme.elevation2,
                  gradientColors: widget.isMuted ?
                  [
                    context.colorScheme.textBody,
                    context.colorScheme.iconWhite
                  ] : [

                    context.colorScheme.primary,
                    context.colorScheme.iconWhite
                  ]

              )
          ),
        );
      },
    );
  }
}