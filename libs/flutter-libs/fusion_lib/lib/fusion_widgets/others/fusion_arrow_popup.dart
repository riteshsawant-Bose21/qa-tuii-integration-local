import 'dart:ui';

import 'package:flutter/material.dart';

enum _ArrowDirection { top, bottom }

class FusionArrowPopup extends StatefulWidget {
  final GlobalKey? anchorKey;
  final Widget content;
  final Widget child;
  final Color? backgroundColor;
  final Color? arrowColor;
  final Color? barrierColor;
  final bool showArrow;
  final double? contentRadius;
  final BoxDecoration? contentDecoration;
  final bool showOnCreate;
  final bool enabled;
  final VoidCallback? onDismiss;
  final bool shouldBlur;
  final double blurAmount;
  final double? maxHeight; // New: Optional max height
  final double? maxWidth; // New: Optional max width

  const FusionArrowPopup({
    super.key,
    required this.content,
    required this.child,
    this.anchorKey,
    this.backgroundColor,
    this.arrowColor,
    this.showArrow = true,
    this.barrierColor,
    this.contentRadius,
    this.contentDecoration,
    this.showOnCreate = false,
    this.enabled = true,
    this.onDismiss,
    this.shouldBlur = true,
    this.blurAmount = 1.0,
    this.maxHeight,
    this.maxWidth,
  });

  @override
  State<FusionArrowPopup> createState() => _FusionArrowPopupState();
}

class _FusionArrowPopupState extends State<FusionArrowPopup> {
  @override
  void initState() {
    super.initState();

    /// ✅ AUTO OPEN AFTER WIDGET IS BUILT
    if (widget.showOnCreate && widget.enabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _show(context);
        }
      });
    }
  }

  void _show(BuildContext context) {
    final anchor = widget.anchorKey?.currentContext ?? context;
    final renderBox = anchor.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final offset = renderBox.localToGlobal(Offset.zero);
    Navigator.of(context).push(
      _PopupRoute(
        targetRect: offset & renderBox.size,
        backgroundColor: widget.backgroundColor,
        showArrow: widget.showArrow,
        barriersColor: widget.barrierColor,
        content: widget.content,
        onDismiss: widget.onDismiss,
        shouldBlur: widget.shouldBlur,
        blurAmount: widget.blurAmount,
        childWidget: widget.child,
        maxHeight: widget.maxHeight,
        maxWidth: widget.maxWidth,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapUp: widget.enabled ? (_) => _show(context) : null,
      child: widget.child,
    );
  }
}

class _PopupContent extends StatelessWidget {
  final Widget content;
  final _ArrowDirection arrowDirection;
  final double arrowX;
  final Color backgroundColor;
  final Color borderColor;
  final bool showArrow;
  final double maxHeight;

  const _PopupContent({
    super.key,
    required this.content,
    required this.arrowDirection,
    required this.arrowX,
    required this.backgroundColor,
    required this.borderColor,
    required this.showArrow,
    required this.maxHeight,
  });

  EdgeInsets get _padding {
    const arrowHeight = 8.0;
    return EdgeInsets.only(
      top: arrowDirection == _ArrowDirection.top ? arrowHeight : 0.0,
      bottom: arrowDirection == _ArrowDirection.bottom ? arrowHeight : 0.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BubblePainter(
        arrowDirection: arrowDirection,
        arrowX: arrowX,
        color: backgroundColor,
        borderColor: borderColor,
        showArrow: showArrow,
      ),
      child: Padding(
        padding: _padding,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_radius),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: maxHeight,
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}

const double _radius = 12;

class _BubblePainter extends CustomPainter {
  final _ArrowDirection arrowDirection;
  final double arrowX;
  final Color color;
  final Color borderColor;
  final bool showArrow;

  static const Size _arrowSize = Size(16, 8);

  _BubblePainter({
    required this.arrowDirection,
    required this.arrowX,
    required this.color,
    required this.borderColor,
    required this.showArrow,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final r = _radius;
    final aw = _arrowSize.width;
    final ah = showArrow ? _arrowSize.height : 0.0;

    final arrowCenter = arrowX.clamp(r + aw / 2, size.width - r - aw / 2);

    final path = Path();

    // ───── TOP ─────
    if (arrowDirection == _ArrowDirection.top && showArrow) {
      path.moveTo(r, ah);
      path.lineTo(arrowCenter - aw / 2, ah);
      path.lineTo(arrowCenter, 0);
      path.lineTo(arrowCenter + aw / 2, ah);
      path.lineTo(size.width - r, ah);
    } else {
      path.moveTo(r, 0);
      path.lineTo(size.width - r, 0);
    }

    path.arcToPoint(
      Offset(size.width, r + (arrowDirection == _ArrowDirection.top ? ah : 0)),
      radius: Radius.circular(r),
    );

    path.lineTo(
      size.width,
      size.height - r - (arrowDirection == _ArrowDirection.bottom ? ah : 0),
    );

    path.arcToPoint(
      Offset(
        size.width - r,
        size.height - (arrowDirection == _ArrowDirection.bottom ? ah : 0),
      ),
      radius: Radius.circular(r),
    );

    // ───── BOTTOM ─────
    if (arrowDirection == _ArrowDirection.bottom && showArrow) {
      path.lineTo(arrowCenter + aw / 2, size.height - ah);
      path.lineTo(arrowCenter, size.height);
      path.lineTo(arrowCenter - aw / 2, size.height - ah);
    }

    path.lineTo(
      r,
      size.height - (arrowDirection == _ArrowDirection.bottom ? ah : 0),
    );

    path.arcToPoint(
      Offset(
        0,
        size.height - r - (arrowDirection == _ArrowDirection.bottom ? ah : 0),
      ),
      radius: Radius.circular(r),
    );

    path.lineTo(0, r + (arrowDirection == _ArrowDirection.top ? ah : 0));

    path.arcToPoint(
      Offset(r, arrowDirection == _ArrowDirection.top ? ah : 0),
      radius: Radius.circular(r),
    );

    path.close();

    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final stroke = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..isAntiAlias = true;

    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant _BubblePainter old) => old.arrowX != arrowX || old.arrowDirection != arrowDirection || old.showArrow != showArrow;
}

class _PopupRoute extends PopupRoute<void> {
  final Rect targetRect;
  final Widget content;
  final Widget childWidget;
  final Color? backgroundColor;
  final Color? barriersColor;
  final bool showArrow;
  final VoidCallback? onDismiss;
  final bool shouldBlur;
  final double blurAmount;
  final double? maxHeight;
  final double? maxWidth;

  _PopupRoute({
    required this.targetRect,
    required this.content,
    required this.childWidget,
    required this.showArrow,
    this.backgroundColor,
    this.barriersColor,
    this.onDismiss,
    required this.shouldBlur,
    required this.blurAmount,
    this.maxHeight,
    this.maxWidth,
  });

  @override
  Color? get barrierColor => Colors.transparent;

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => 'Popup';

  @override
  Widget buildModalBarrier() {
    return AnimatedBuilder(
      animation: animation!,
      builder: (context, child) {
        final blur = Tween<double>(begin: 0, end: blurAmount).evaluate(animation!);

        return Stack(
          children: [
            // Blurred background
            GestureDetector(
              onTap: () {
                onDismiss?.call();
                navigator?.pop();
              },
              child: Builder(
                builder: (context) {
                  if (shouldBlur) {
                    return BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                      child: Container(
                        color: (barriersColor ?? Colors.black).withValues(
                          alpha: animation!.value * 0.2,
                        ),
                      ),
                    );
                  } else {
                    return Container(
                      color: (barriersColor ?? Colors.black12).withValues(
                        alpha: animation!.value,
                      ),
                    );
                  }
                },
              ),
            ),

            // Child widget overlay - stays visible and unblurred
            if (shouldBlur)
              Positioned(
                left: targetRect.left,
                top: targetRect.top,
                width: targetRect.width,
                height: targetRect.height,
                child: IgnorePointer(
                  child: childWidget,
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return _PopupPositioner(
      targetRect: targetRect,
      backgroundColor: backgroundColor,
      showArrow: showArrow,
      animation: animation,
      content: content,
      maxHeight: maxHeight,
      maxWidth: maxWidth,
    );
  }

  @override
  Duration get transitionDuration => const Duration(milliseconds: 160);
}

class _PopupPositioner extends StatefulWidget {
  final Rect targetRect;
  final Widget content;
  final Color? backgroundColor;
  final bool showArrow;
  final Animation<double> animation;
  final double? maxHeight;
  final double? maxWidth;

  const _PopupPositioner({
    required this.targetRect,
    required this.content,
    required this.backgroundColor,
    required this.showArrow,
    required this.animation,
    this.maxHeight,
    this.maxWidth,
  });

  @override
  State<_PopupPositioner> createState() => _PopupPositionerState();
}

class _PopupPositionerState extends State<_PopupPositioner> {
  static const double _margin = 10;
  static const double _arrowHeight = 8.0;

  _ArrowDirection _arrowDirection = _ArrowDirection.top;
  double _arrowX = 0;
  double _popupLeft = 0;
  double? _top;
  double? _bottom;
  double _maxContentHeight = double.infinity;
  final GlobalKey _popupKey = GlobalKey();
  bool _positioned = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculatePosition();
    });
  }

  void _calculatePosition() {
    if (!mounted) return;

    final screen = MediaQueryData.fromView(
      PlatformDispatcher.instance.views.first,
    ).size;

    // Get the actual popup size after layout
    final RenderBox? popupBox = _popupKey.currentContext?.findRenderObject() as RenderBox?;

    if (popupBox == null) {
      // Retry on next frame if not ready
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _calculatePosition();
      });
      return;
    }

    final popupWidth = popupBox.size.width;
    final targetCenterX = widget.targetRect.center.dx;

    // Center the popup horizontally relative to the target widget
    double left = targetCenterX - popupWidth / 2;
    left = left.clamp(_margin, screen.width - popupWidth - _margin);

    // Calculate arrow X position relative to the popup's left edge
    final arrowX = targetCenterX - left;

    // Calculate available space above and below the target
    final spaceAbove = widget.targetRect.top - _margin;
    final spaceBelow = screen.height - widget.targetRect.bottom - _margin;

    // Determine if popup should appear above or below based on available space
    final bool showBelow = spaceBelow >= spaceAbove;

    // Calculate maximum height for content area
    double maxContentHeight;
    if (showBelow) {
      // Space below minus arrow height and padding
      maxContentHeight = spaceBelow - _arrowHeight - (_margin * 2);
    } else {
      // Space above minus arrow height and padding
      maxContentHeight = spaceAbove - _arrowHeight - (_margin * 2);
    }

    // Apply user-defined maxHeight if provided
    if (widget.maxHeight != null) {
      maxContentHeight = maxContentHeight.clamp(0, widget.maxHeight!);
    }

    // Ensure minimum height
    maxContentHeight = maxContentHeight.clamp(100.0, double.infinity);

    setState(() {
      _popupLeft = left;
      _arrowX = arrowX;
      _arrowDirection = showBelow ? _ArrowDirection.top : _ArrowDirection.bottom;
      _top = showBelow ? widget.targetRect.bottom : null;
      _bottom = showBelow ? null : screen.height - widget.targetRect.top;
      _maxContentHeight = maxContentHeight;
      _positioned = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth = widget.maxWidth ?? (Screen.width - (_margin * 2));

    return Stack(
      children: [
        // The popup content
        Positioned(
          left: _positioned ? _popupLeft : widget.targetRect.center.dx,
          top: _top,
          bottom: _bottom,
          child: Opacity(
            opacity: _positioned ? 1.0 : 0.0,
            child: Material(
              color: Colors.transparent,
              child: FadeTransition(
                opacity: widget.animation,
                child: ScaleTransition(
                  scale: CurvedAnimation(
                    parent: widget.animation,
                    curve: Curves.easeOutBack,
                  ),
                  alignment: _arrowDirection == _ArrowDirection.top ? Alignment.topCenter : Alignment.bottomCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: maxWidth,
                    ),
                    child: _PopupContent(
                      key: _popupKey,
                      arrowDirection: _arrowDirection,
                      arrowX: _arrowX,
                      backgroundColor: widget.backgroundColor ?? Theme.of(context).colorScheme.surface,
                      borderColor: Theme.of(context).dividerColor.withOpacity(0.3),
                      showArrow: widget.showArrow,
                      content: widget.content,
                      maxHeight: _maxContentHeight,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

abstract class Screen {
  static MediaQueryData get mediaQuery => MediaQueryData.fromView(
    PlatformDispatcher.instance.views.first,
  );

  /// screen width
  static double get width => mediaQuery.size.width;

  /// screen height
  static double get height => mediaQuery.size.height;

  /// dp
  static double get scale => mediaQuery.devicePixelRatio;

  /// top
  static double get statusBar => mediaQuery.padding.top;

  /// bottom
  static double get bottomBar => mediaQuery.padding.bottom;
}
