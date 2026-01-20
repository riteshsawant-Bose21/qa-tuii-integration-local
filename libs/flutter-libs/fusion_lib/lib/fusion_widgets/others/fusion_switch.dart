import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

class FusionSwitch extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final double height;
  final double width;
  final Color? activeTrackColor;
  final Color? inactiveTrackColor;

  final Color? activeThumbColor;
  final Color? inactiveThumbColor;

  ///
  /// [radiusFactor] Value should be between 0.0 and 1 where 0.0 means no rounding and 1 means fully rounded corners.
  ///
  final double radiusFactor;

  const FusionSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.height = 50,
    this.width = 75,
    this.activeTrackColor,
    this.inactiveTrackColor,
    this.activeThumbColor,
    this.inactiveThumbColor,
    this.radiusFactor = 0.25,
  });

  @override
  State<FusionSwitch> createState() => _FusionSwitchState();
}

class _FusionSwitchState extends State<FusionSwitch> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _positionAnimation;
  late Animation<Color?> _trackColorAnimation;
  late Animation<Color?> _thumbColorAnimation;

  bool _isDragging = false;
  double? _dragStartValue;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _positionAnimation =
        Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ),
        );

    // Initialize animations - will be updated in didChangeDependencies
    _trackColorAnimation = AlwaysStoppedAnimation(Colors.grey);
    _thumbColorAnimation = AlwaysStoppedAnimation(Colors.white);

    if (widget.value) {
      _animationController.value = 1.0;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateColorAnimations();
  }

  void _updateColorAnimations() {
    _trackColorAnimation = ColorTween(
      begin: widget.inactiveTrackColor ?? context.colorScheme.elevation2,
      end: widget.activeTrackColor ?? context.colorScheme.primaryColor,
    ).animate(_animationController);

    _thumbColorAnimation = ColorTween(
      begin: widget.inactiveThumbColor ?? context.colorScheme.elevation3,
      end: widget.activeThumbColor ?? Colors.grey.shade200, //context.colorScheme.primaryWhite,
    ).animate(_animationController);
  }

  @override
  void didUpdateWidget(FusionSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      if (widget.value) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
    _updateColorAnimations();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTap() {
    if (!_isDragging) {
      widget.onChanged(!widget.value);
    }
  }

  void _onPanStart(DragStartDetails details) {
    _isDragging = true;
    _dragStartValue = _animationController.value;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;

    final thumbWidth = widget.height * 0.7;
    final trackWidth = widget.width;
    final dragDistance = trackWidth - thumbWidth - 8; // Available drag distance (4px padding on each side)

    final newValue = (_dragStartValue! + (details.localPosition.dx - thumbWidth / 2 - 4) / dragDistance).clamp(0.0, 1.0);

    _animationController.value = newValue;
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_isDragging) return;

    _isDragging = false;

    // Determine final state based on current position and velocity
    final velocity = details.velocity.pixelsPerSecond.dx;
    final currentValue = _animationController.value;

    bool shouldBeOn;

    if (velocity.abs() > 300) {
      // If moving fast, use velocity direction
      shouldBeOn = velocity > 0;
    } else {
      // Otherwise, use position (snap to nearest)
      shouldBeOn = currentValue > 0.5;
    }

    // Call onChanged if the determined state differs from current value
    if (shouldBeOn != widget.value) {
      widget.onChanged(shouldBeOn);
    }

    // Always animate to the correct position after a short delay
    // This ensures the thumb returns to the correct position even if onChanged didn't update the value
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) {
        if (widget.value) {
          _animationController.forward();
        } else {
          _animationController.reverse();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final thumbWidth = widget.height * 0.7;
    final thumbHeight = widget.height * 0.7;
    final trackWidth = widget.width;
    final trackHeight = widget.height;

    final padding = trackHeight - thumbHeight;

    final radius = min(thumbHeight, thumbWidth) * widget.radiusFactor;

    return GestureDetector(
      onTap: _onTap,
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: SizedBox(
        height: widget.height,
        width: widget.width,
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            final thumbPosition = _positionAnimation.value * (trackWidth - thumbWidth - (padding / 2)); // 8 for padding (4px on each side)

            return Stack(
              children: [
                // Track
                FusionContainer(
                  width: trackWidth,
                  borderRadius: radius,
                  // height: trackHeight,
                  // decoration: BoxDecoration(
                  color: _trackColorAnimation.value,
                  child: SizedBox(
                    width: trackWidth,
                    height: trackHeight,
                  ),
                  // borderRadius: BorderRadius.circular(2),
                  // ),
                ),
                // Thumb
                Positioned(
                  left: (padding / 2) + thumbPosition, // 4px padding from left
                  top: padding / 2, // 4px padding from top
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 100),
                    curve: Curves.elasticInOut,
                    child: Container(
                      // raised: true,
                      // borderRadius: min(thumbHeight, thumbWidth) / 4,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(radius),
                        color: _thumbColorAnimation.value,
                      ),
                      child: SizedBox(
                        width: thumbWidth,
                        height: thumbHeight,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
