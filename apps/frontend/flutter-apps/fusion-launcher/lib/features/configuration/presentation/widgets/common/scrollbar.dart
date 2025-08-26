import 'package:flutter/material.dart';

class FusionScrollbar extends StatefulWidget {
  final Widget child;
  final ScrollController controller;
  final Axis scrollDirection;
  final double? thickness;
  final Color? thumbColor;
  final Color? trackColor;
  final double? radius;
  final EdgeInsets? margin;

  const FusionScrollbar({
    super.key,
    required this.child,
    required this.controller,
    this.scrollDirection = Axis.vertical,
    this.thickness,
    this.thumbColor,
    this.trackColor,
    this.radius,
    this.margin,
  });

  @override
  State<FusionScrollbar> createState() => _FusionScrollbarState();
}

class _FusionScrollbarState extends State<FusionScrollbar>
    with TickerProviderStateMixin {
  late AnimationController _hoverController;
  late AnimationController _activeController;
  late Animation<double> _hoverAnimation;
  late Animation<double> _activeAnimation;

  bool _isHovering = false;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();

    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _activeController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _hoverAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOutCubic),
    );

    _activeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _activeController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    _activeController.dispose();
    super.dispose();
  }

  void _onHoverEnter() {
    if (!_isHovering) {
      setState(() => _isHovering = true);
      _hoverController.forward();
    }
  }

  void _onHoverExit() {
    if (_isHovering && !_isDragging) {
      setState(() => _isHovering = false);
      _hoverController.reverse();
    }
  }

  void _onDragStart() {
    setState(() => _isDragging = true);
    _activeController.forward();
  }

  void _onDragEnd() {
    setState(() => _isDragging = false);
    _activeController.reverse();
    if (!_isHovering) {
      _hoverController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    // Default colors with theme awareness
    final Color defaultThumbColor =
        isDark
            ? Colors.white.withAlpha((0.3 * 255).toInt())
            : Colors.black.withAlpha((0.3 * 255).toInt());
    final Color defaultTrackColor =
        isDark
            ? Colors.white.withAlpha((0.1 * 255).toInt())
            : Colors.black.withAlpha((0.1 * 255).toInt());

    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable?>[
        _hoverAnimation,
        _activeAnimation,
      ]),
      builder: (BuildContext context, Widget? child) {
        final double hoverValue = _hoverAnimation.value;
        final double activeValue = _activeAnimation.value;

        // Calculate dynamic properties
        final double baseThickness = widget.thickness ?? 8.0;
        final double currentThickness =
            baseThickness + (hoverValue * 4.0) + (activeValue * 2.0);

        final double baseOpacity = 0.4;
        final double currentOpacity =
            baseOpacity + (hoverValue * 0.4) + (activeValue * 0.2);

        final Color thumbColor = widget.thumbColor ?? defaultThumbColor;
        final Color trackColor = widget.trackColor ?? defaultTrackColor;

        return MouseRegion(
          onEnter: (_) => _onHoverEnter(),
          onExit: (_) => _onHoverExit(),
          child: RawScrollbar(
            controller: widget.controller,
            thumbVisibility: true,
            trackVisibility: true,
            thickness: currentThickness,
            radius: Radius.circular(widget.radius ?? currentThickness / 2),
            thumbColor: thumbColor.withAlpha((currentOpacity * 255).toInt()),
            trackColor: trackColor.withAlpha(
              ((currentOpacity * 255) * 0.5).toInt(),
            ),
            trackRadius: Radius.circular(widget.radius ?? currentThickness / 2),
            trackBorderColor: Colors.transparent,
            crossAxisMargin: 2.0,
            mainAxisMargin: widget.margin?.top ?? 4.0,
            minThumbLength: 40.0,
            interactive: true,
            scrollbarOrientation:
                widget.scrollDirection == Axis.horizontal
                    ? ScrollbarOrientation.bottom
                    : ScrollbarOrientation.right,
            notificationPredicate: (ScrollNotification notification) {
              // Handle drag start/end for smooth animations
              if (notification is ScrollStartNotification && _isHovering) {
                _onDragStart();
              } else if (notification is ScrollEndNotification) {
                _onDragEnd();
              }
              return true;
            },
            child: widget.child,
          ),
        );
      },
    );
  }
}
