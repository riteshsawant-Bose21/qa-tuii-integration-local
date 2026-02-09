import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_widgets/fusion_widgets.dart';

import '../../fusion_theme/color_pallette.dart';
import '../buttons/fusion_neumorphic_button.dart';

class MediaPlayerCard extends StatefulWidget {
  final String label;
  final bool currentstate;
  final double? width;
  final double? height;

  final VoidCallback? onEdit;

  const MediaPlayerCard({
    super.key,
    required this.label,
    required this.currentstate,
    this.width,
    this.height,
    this.onEdit,
  });

  @override
  State<MediaPlayerCard> createState() => _MediaPlayerCardState();
}

class _MediaPlayerCardState extends State<MediaPlayerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  final Random _random = Random();

  // Initial static heights
  List<double> _heights = [20, 16, 19, 15];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..addListener(_updateBars);

    // Start only if playing
    if (widget.currentstate) {
      _controller.repeat(reverse: true);
    }
  }

  // Listen for currentstate changes
  @override
  void didUpdateWidget(covariant MediaPlayerCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // ▶️ Start animation
    if (widget.currentstate && !oldWidget.currentstate) {
      _controller.repeat(reverse: true);
    }

    // ⏸️ Stop animation
    if (!widget.currentstate && oldWidget.currentstate) {
      _controller.stop();
    }
  }

  // Update bar heights
  void _updateBars() {
    setState(() {
      _heights = List.generate(
        4,
            (_) => 10 + _random.nextInt(18).toDouble(),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FusionDarkColorPallette.dark80,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _bar(height: _heights[0]),
              _bar(height: _heights[1]),
              _bar(height: _heights[2]),
              _bar(height: _heights[3]),
            ],
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.label,
                  style: TextStyle(
                    color: context.colorScheme.canvasBG,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  widget.currentstate ? "Now Playing" : "Not Playing",
                  style: TextStyle(
                    color: context.colorScheme.textGrey,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          if (widget.onEdit != null)
            FusionNeumorphicButton(
              onTap: () => widget.onEdit!.call(),
              borderRadius: 6,
              width: 28,
              height: 28,
              child: const Icon(Icons.tune, size: 18),
            ),
        ],
      ),
    );
  }
  Widget _bar({required double height}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      width: 5,
      height: height,
      alignment: Alignment.bottomCenter,
      decoration: BoxDecoration(
        color: FusionDarkColorPallette.green20,
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }
}
