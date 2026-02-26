import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

class HorizontalScrollWithShadows extends StatefulWidget {
  final Widget child;
  final ScrollController? controller;

  const HorizontalScrollWithShadows({
    super.key,
    required this.child,
    this.controller,
  });

  @override
  State<HorizontalScrollWithShadows> createState() => _HorizontalScrollWithShadowsState();
}

class _HorizontalScrollWithShadowsState extends State<HorizontalScrollWithShadows> {
  late final ScrollController _internalController;
  late final ScrollController _effectiveController;

  bool _showLeftShadow = false;
  bool _showRightShadow = false;

  @override
  void initState() {
    super.initState();
    _internalController = ScrollController(); // Internal controller for scrolling if none is provided by the user.
    _effectiveController = widget.controller ?? _internalController;
    _effectiveController.addListener(_updateShadows);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateShadows());
  }

  void _updateShadows() {
    if (!mounted || !_effectiveController.hasClients) return;

    final ScrollPosition position = _effectiveController.position;
    setState(() {
      _showLeftShadow = position.pixels > 0;
      _showRightShadow = position.pixels < position.maxScrollExtent;
    });
  }

  @override
  void dispose() {
    if (widget.controller == null) _internalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color shadowColor = context.colorScheme.shadowDark.withAlpha(context.colorScheme.isDarkMode ? 50 : 20);
    const double shadowWidth = 2;
    const double shadowBlurRadius = 6;
    const double shadowSpreadRadius = 6;

    return Stack(
      children: <Widget>[
        SingleChildScrollView(
          controller: _effectiveController,
          physics: const ClampingScrollPhysics(),
          scrollDirection: Axis.horizontal,
          child: widget.child,
        ),

        // Right scroll shadow
        if (_showRightShadow)
          Positioned(
            right: 0,
            top: 5,
            bottom: -5,
            child: IgnorePointer(
              child: Container(
                height: double.infinity,
                width: shadowWidth,
                decoration: BoxDecoration(
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: shadowColor,
                      blurRadius: shadowBlurRadius,
                      spreadRadius: shadowSpreadRadius,
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Left scroll shadow
        if (_showLeftShadow)
          Positioned(
            left: 0,
            top: 5,
            bottom: -5,
            child: IgnorePointer(
              child: Container(
                height: double.infinity,
                width: shadowWidth,
                decoration: BoxDecoration(
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: shadowColor,
                      blurRadius: shadowBlurRadius,
                      spreadRadius: shadowSpreadRadius,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
