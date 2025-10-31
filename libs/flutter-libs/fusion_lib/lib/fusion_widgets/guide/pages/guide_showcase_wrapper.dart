import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show SchedulerBinding;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_lib/fusion_widgets/fusion_widgets.dart';

import '../controller/guide_showcase_controller.dart';

class GuideShowcaseWrapper extends StatelessWidget {
  final GuideShowCaseSteps step;
  final Widget child;
  final VoidCallback? onHighlightedSpotTap;
  final bool show;

  const GuideShowcaseWrapper({
    super.key,
    required this.step,
    required this.child,
    this.onHighlightedSpotTap,
    this.show = true,
  });

  @override
  Widget build(BuildContext context) {
    final GuideShowCaseController controller = context.watch<GuideShowCaseController>();
    // Only show if this is the current step and not completed
    final bool shouldShow = controller.shouldShowStep(step);

    if (!show || !shouldShow) return child;

    return FussionPopup(
      show: true,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      spotlightBorderRadius: 12.0,
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.3,
        ),
        child: Column(
          spacing: 10,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Step indicator
            Row(
              spacing: 10,
              children: <Widget>[
                Expanded(
                  child: FusionAppText(
                    text: 'Step ${GuideShowCaseSteps.values.indexOf(step) + 1} of ${GuideShowCaseSteps.values.length}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    context.read<GuideShowCaseController>().skipGuide();
                    Navigator.pop(context);
                  },
                  behavior: HitTestBehavior.translucent,
                  child: FusionAppText(
                    text: 'skip',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            FusionAppText(text: step.description),
          ],
        ),
      ),
      onSpotTap: () {
        Navigator.pop(context);
        onHighlightedSpotTap?.call();
      },
      child: child,
    );
  }

  static void askGuideNeededDialog(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          constraints: const BoxConstraints(maxWidth: 600),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(6))),
          title: Text(
            'Do you want guide to how to use Fussion Launcher ?',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'A quick walkthrough to help you use Fussion Launcher efficiently.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          actions: <Widget>[
            FusionOutlinedButton(
              height: 32,
              width: 80,
              label: "No",
              textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 12),
              onTap: () {
                context.read<GuideShowCaseController>().skipGuide();
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(width: 8),
            FusionButton(
              height: 32,
              width: 80,
              label: "Yes",
              activeBackgroundColor: Theme.of(context).colorScheme.primary,
              textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontSize: 12,
                color: Colors.white,
              ),
              onTap: () {
                Navigator.pop(context);
                context.read<GuideShowCaseController>().guideNeeded();
              },
            ),
          ],
        );
      },
    );
  }
}

enum _ArrowDirection { top, bottom }

class FussionPopup extends StatefulWidget {
  final GlobalKey? anchorKey;
  final Widget content;
  final Widget child;
  final Color? backgroundColor;
  final Color? arrowColor;
  final Color? barrierColor;
  final bool barrierDismissible;
  final bool showArrow;
  final double? contentRadius;
  final BoxDecoration? contentDecoration;
  final bool show;
  final double spotlightBorderRadius;
  final VoidCallback onSpotTap;

  const FussionPopup({
    super.key,
    required this.content,
    required this.child,
    this.anchorKey,
    this.backgroundColor,
    this.arrowColor,
    this.showArrow = true,
    this.barrierColor,
    this.barrierDismissible = true,
    this.contentRadius,
    this.contentDecoration,
    this.show = false,
    this.spotlightBorderRadius = 8.0,
    required this.onSpotTap,
  });

  @override
  State<FussionPopup> createState() => _FussionPopupState();
}

class _FussionPopupState extends State<FussionPopup> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (Duration timeStamp) {
        if (widget.show) {
          Future<void>.delayed(
            const Duration(milliseconds: 500),
            // ignore: use_build_context_synchronously
            () => _show(context),
          );
        }
      },
    );
  }

  void _show(BuildContext context) {
    final BuildContext anchor = widget.anchorKey?.currentContext ?? context;
    final RenderBox? renderBox = anchor.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final Offset offset = renderBox.localToGlobal(renderBox.paintBounds.topLeft);
    Navigator.of(context).push(
      _PopupRoute(
        targetRect: offset & renderBox.paintBounds.size,
        backgroundColor: widget.backgroundColor,
        arrowColor: widget.arrowColor,
        showArrow: widget.showArrow,
        barriersColor: widget.barrierColor,
        barrierDismissible: widget.barrierDismissible,
        contentRadius: widget.contentRadius,
        contentDecoration: widget.contentDecoration,
        spotlightBorderRadius: widget.spotlightBorderRadius,
        child: widget.content,
        onSpotTap: widget.onSpotTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class _PopupContent extends StatelessWidget {
  final Widget child;
  final GlobalKey childKey;
  final GlobalKey arrowKey;
  final _ArrowDirection arrowDirection;
  final double arrowHorizontal;
  final Color? backgroundColor;
  final Color? arrowColor;
  final bool showArrow;
  final double? contentRadius;
  final BoxDecoration? contentDecoration;

  const _PopupContent({
    required this.child,
    required this.childKey,
    required this.arrowKey,
    required this.arrowHorizontal,
    required this.showArrow,
    this.arrowDirection = _ArrowDirection.top,
    this.backgroundColor,
    this.arrowColor,
    this.contentRadius,
    this.contentDecoration,
  });

  @override
  Widget build(BuildContext context) {
    final bool isTopArrow = arrowDirection == _ArrowDirection.top;

    return Stack(
      children: <Widget>[
        Container(
          key: childKey,
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.symmetric(vertical: 20).copyWith(
            top: !isTopArrow ? 0 : null,
            bottom: isTopArrow ? 0 : null,
          ),
          constraints: const BoxConstraints(minWidth: 50),
          decoration:
              contentDecoration ??
              BoxDecoration(
                color: backgroundColor ?? Colors.white,
                borderRadius: BorderRadius.circular(contentRadius ?? 10),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                  ),
                ],
              ),
          child: child,
        ),
        Positioned(
          top: isTopArrow ? 12 : null,
          bottom: !isTopArrow ? 12 : null,
          left: arrowHorizontal,
          child: RotatedBox(
            key: arrowKey,
            quarterTurns: isTopArrow ? 2 : 4,
            child: CustomPaint(
              size: showArrow ? const Size(16, 8) : Size.zero,
              painter: _TrianglePainter(color: arrowColor ?? Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;

  const _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint();
    final Path path = Path();
    paint.isAntiAlias = true;
    paint.color = color;

    path.lineTo(size.width * 0.66, size.height * 0.86);
    path.cubicTo(
      size.width * 0.58,
      size.height * 1.05,
      size.width * 0.42,
      size.height * 1.05,
      size.width * 0.34,
      size.height * 0.86,
    );
    path.cubicTo(size.width * 0.34, size.height * 0.86, 0, 0, 0, 0);
    path.cubicTo(0, 0, size.width, 0, size.width, 0);
    path.cubicTo(size.width, 0, size.width * 0.66, size.height * 0.86, size.width * 0.66, size.height * 0.86);
    path.cubicTo(
      size.width * 0.66,
      size.height * 0.86,
      size.width * 0.66,
      size.height * 0.86,
      size.width * 0.66,
      size.height * 0.86,
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

// Custom painter for spotlight barrier
class _SpotlightBarrierPainter extends CustomPainter {
  final Rect spotlightRect;
  final Color barrierColor;
  final double borderRadius;

  const _SpotlightBarrierPainter({
    required this.spotlightRect,
    required this.barrierColor,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = barrierColor
      ..style = PaintingStyle.fill;

    final Path outerPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final Path innerPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          spotlightRect, // <-- Adds padding around spotlight
          const Radius.circular(0), // Optional: slightly rounder edge
        ),
      );

    final Path combinedPath = Path.combine(
      PathOperation.difference,
      outerPath,
      innerPath,
    );

    canvas.drawPath(combinedPath, paint);
  }

  @override
  bool shouldRepaint(_SpotlightBarrierPainter oldDelegate) {
    return oldDelegate.spotlightRect != spotlightRect ||
        oldDelegate.barrierColor != barrierColor ||
        oldDelegate.borderRadius != borderRadius;
  }
}

class _PopupRoute extends PopupRoute<void> {
  final Rect targetRect;
  final Widget child;
  final VoidCallback onSpotTap;

  static const double _margin = 10;
  static final Rect _viewportRect = Rect.fromLTWH(
    _margin,
    _Screen.statusBar + _margin,
    _Screen.width - _margin * 2,
    _Screen.height - _Screen.statusBar - _Screen.bottomBar - _margin * 2,
  );

  final GlobalKey _childKey = GlobalKey();
  final GlobalKey _arrowKey = GlobalKey();
  final Color? backgroundColor;
  final Color? arrowColor;
  final bool showArrow;
  final Color? barriersColor;
  final double spotlightBorderRadius;

  @override
  final bool barrierDismissible;

  final double? contentRadius;
  final BoxDecoration? contentDecoration;

  _ArrowDirection _arrowDirection = _ArrowDirection.top;
  double _arrowHorizontal = 0;
  double _scaleAlignDx = 0.5;
  double _scaleAlignDy = 0.5;
  double? _bottom;
  double? _top;
  double? _left;
  double? _right;

  _PopupRoute({
    required this.child,
    required this.targetRect,
    this.backgroundColor,
    this.arrowColor,
    required this.showArrow,
    this.barriersColor,
    this.barrierDismissible = true,
    this.contentRadius,
    this.contentDecoration,
    required this.spotlightBorderRadius,
    required this.onSpotTap,
  });

  @override
  Color? get barrierColor => Colors.transparent;

  @override
  String? get barrierLabel => 'Popup';

  @override
  TickerFuture didPush() {
    super.offstage = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      final Rect? childRect = _getRect(_childKey);
      final Rect? arrowRect = _getRect(_arrowKey);
      _calculateArrowOffset(arrowRect, childRect);
      _calculateChildOffset(childRect);
      super.offstage = false;
    });
    return super.didPush();
  }

  Rect? _getRect(GlobalKey key) {
    final BuildContext? currentContext = key.currentContext;
    final RenderBox? renderBox = currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return null;
    final Offset offset = renderBox.localToGlobal(renderBox.paintBounds.topLeft);
    return offset & renderBox.paintBounds.size;
  }

  void _calculateArrowOffset(Rect? arrowRect, Rect? childRect) {
    if (childRect == null || arrowRect == null) return;
    double leftEdge = targetRect.center.dx - childRect.center.dx;
    final double rightEdge = leftEdge + childRect.width;
    leftEdge = leftEdge < _viewportRect.left ? _viewportRect.left : leftEdge;
    if (rightEdge > _viewportRect.right) {
      leftEdge -= rightEdge - _viewportRect.right;
    }
    final double center = targetRect.center.dx - leftEdge - arrowRect.center.dx;
    if (center + arrowRect.center.dx > childRect.width - 15) {
      _arrowHorizontal = center - 15;
    } else if (center < 15) {
      _arrowHorizontal = 15;
    } else {
      _arrowHorizontal = center;
    }

    _scaleAlignDx = (_arrowHorizontal + arrowRect.center.dx) / childRect.width;
  }

  void _calculateChildOffset(Rect? childRect) {
    if (childRect == null) return;

    final double topHeight = targetRect.top - _viewportRect.top;
    final double bottomHeight = _viewportRect.bottom - targetRect.bottom;
    final double maximum = max(topHeight, bottomHeight);
    final double maxHeight = childRect.height > maximum ? maximum : childRect.height;
    if (maxHeight > bottomHeight) {
      _bottom = _Screen.height - targetRect.top;
      _arrowDirection = _ArrowDirection.bottom;
      _scaleAlignDy = 1;
    } else {
      _top = targetRect.bottom;
      _arrowDirection = _ArrowDirection.top;
      _scaleAlignDy = 0;
    }

    final double left = targetRect.center.dx - childRect.center.dx;
    final double right = left + childRect.width;
    if (right > _viewportRect.right) {
      _right = _margin;
    } else {
      _left = left < _margin ? _margin : left;
    }
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return child;
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    child = _PopupContent(
      childKey: _childKey,
      arrowKey: _arrowKey,
      arrowHorizontal: _arrowHorizontal,
      arrowDirection: _arrowDirection,
      backgroundColor: backgroundColor,
      arrowColor: arrowColor,
      showArrow: showArrow,
      contentRadius: contentRadius,
      contentDecoration: contentDecoration,
      child: child,
    );

    Widget content = child;
    if (!animation.isCompleted) {
      content = FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          alignment: FractionalOffset(_scaleAlignDx, _scaleAlignDy),
          scale: animation,
          child: child,
        ),
      );
    }

    return Stack(
      children: <Widget>[
        // Custom spotlight barrier
        // Custom spotlight barrier with tap detection
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTapDown: (TapDownDetails details) {
              final Offset tapPos = details.globalPosition;
              final Rect spotArea = targetRect.inflate(8.0); // add small padding for clarity

              if (spotArea.contains(tapPos)) {
                // User tapped inside spotlight
                onSpotTap();
              } else if (barrierDismissible) {
                // Optional: dismiss when tapping outside the spotlight
                Navigator.of(context).maybePop();
              }
            },
            child: CustomPaint(
              painter: _SpotlightBarrierPainter(
                spotlightRect: targetRect.inflate(8.0),
                barrierColor: barriersColor ?? Colors.black.withValues(alpha: 0.7),
                borderRadius: spotlightBorderRadius,
              ),
            ),
          ),
        ),

        // Popup content
        Positioned(
          left: _left,
          right: _right,
          top: _top,
          bottom: _bottom,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: _viewportRect.width,
            ),
            child: Material(
              color: Colors.transparent,
              type: MaterialType.transparency,
              child: content,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Duration get transitionDuration => const Duration(milliseconds: 150);
}

abstract class _Screen {
  static MediaQueryData get mediaQuery => MediaQueryData.fromView(
    PlatformDispatcher.instance.views.first,
  );

  static double get width => mediaQuery.size.width;

  static double get height => mediaQuery.size.height;

  static double get statusBar => mediaQuery.padding.top;

  static double get bottomBar => mediaQuery.padding.bottom;
}
