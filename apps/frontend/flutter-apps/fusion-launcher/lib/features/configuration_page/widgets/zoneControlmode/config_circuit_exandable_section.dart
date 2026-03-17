import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

class ConfigCircuitExpandableSection extends StatefulWidget {
  final String title;
  final List<Widget> children;
  final bool initiallyExpanded;
  final EdgeInsetsGeometry? padding;

  const ConfigCircuitExpandableSection({
    super.key,
    required this.title,
    required this.children,
    this.initiallyExpanded = false,
    this.padding,
  });

  @override
  State<ConfigCircuitExpandableSection> createState() => _ConfigCircuitExpandableSectionState();
}

class _ConfigCircuitExpandableSectionState extends State<ConfigCircuitExpandableSection> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _iconTurns;
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;

    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    // Rotates the icon: 0.0 turns (pointing right) to 0.25 turns (pointing down)
    _iconTurns = Tween<double>(begin: 0.0, end: 0.25).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    if (_isExpanded) {
      _controller.value = 1.0;
    }
  }

  void _handleTap() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
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
      color: context.colorScheme.elevation1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // --- HEADER ---
          InkWell(
            onTap: _handleTap,
            // Removed default splash to keep it clean like the screenshot
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            child: Padding(
              padding: widget.padding ?? const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
              child: Row(
                mainAxisSize: MainAxisSize.min, // Compact width
                children: <Widget>[
                  RotationTransition(
                    turns: _iconTurns,
                    child: Icon(
                      Icons.play_arrow, // Filled triangle shape
                      color: context.colorScheme.iconWhite,
                      size: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FusionAppText(
                    text: widget.title,
                    style: TextStyle(
                      color: context.colorScheme.iconWhite,
                      fontSize: 12,
                      fontWeight: FontWeight.w500, // Medium weight
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- EXPANDABLE BODY ---
          // Uses AnimatedSize for smooth height transition
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: SizedBox(
              width: double.infinity,
              // If collapsed, height is 0. If expanded, height is auto (null)
              height: _isExpanded ? null : 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SizedBox(height: 8), // Spacing between header and content
                  ...widget.children,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
