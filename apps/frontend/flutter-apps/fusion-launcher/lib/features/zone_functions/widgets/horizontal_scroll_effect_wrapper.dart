import 'package:flutter/material.dart';

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
    const Color shadowColor = Color(0x09000000);
    const double shadowWidth = 6;
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
            top: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Container(
                height: double.infinity,
                width: shadowWidth,
                decoration: const BoxDecoration(
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
            top: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Container(
                height: double.infinity,
                width: shadowWidth,
                decoration: const BoxDecoration(
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
