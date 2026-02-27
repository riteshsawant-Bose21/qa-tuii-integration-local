import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../wiring_design/view/painters/dotted_grid_painter.dart';
import '../../state/fusion_canvas_state.dart';

class FusionCanvasPainter extends CustomPainter {
  final FusionCanvasState state;
  final List<FusionBasePainter> layers;
  FusionCanvasPainter({required this.state, this.layers = const <FusionBasePainter>[]});
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    final Offset offset = state.offset;
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(state.scale);

    DottedGridPainter(color: Colors.grey.shade300).paint(
      canvas,
      size,
      offset,
      state.scale,
    );

    for (final FusionBasePainter painter in layers) {
      painter.paint(canvas, size, this);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

abstract class FusionBasePainter {
  void paint(Canvas canvas, Size size, FusionCanvasPainter painter);
  bool shouldRepaint(covariant FusionBasePainter oldDelegate);

  // ui.Image? getImage(String path) {
  //   return controller.imagesCache[path];
  // }

  // bool drawImage({
  //   required Canvas canvas,
  //   required String path,
  //   required Rect rect,
  //   Paint? paint,
  // }) {
  //   final ui.Image? image = getImage(path);
  //   if (image != null) {
  //     final Rect src = Rect.fromLTWH(
  //       0,
  //       0,
  //       image.width.toDouble(),
  //       image.height.toDouble(),
  //     );

  //     canvas.drawImageRect(image, src, rect, paint ?? Paint());
  //     return true;
  //   }
  //   return false;
  // }

  ///
  /// Util function for number that should not scale with canvas zoom
  ///
  double nonScaling(num value, FusionCanvasPainter painter) {
    return value * (1 / painter.state.scale);
  }

  ///
  /// All Paint functions which will help in painting.
  ///

  Size drawText({
    required Canvas canvas,
    required String text,
    TextStyle? style,
    required Offset position,
    double maxWidth = double.infinity,
    Alignment positionAlignment = Alignment.center,
    Paint? backgroundPaint,
    EdgeInsets backgroundPadding = EdgeInsets.zero,
    Radius backgroundBorderRadius = Radius.zero,
  }) {
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: text,
        style: style,
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);

    // Draw background if provided

    if (backgroundPaint != null) {
      final RRect bgRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          position.dx - tp.width / 2 - tp.width * 0.5 * positionAlignment.x - backgroundPadding.left,
          position.dy - tp.height / 2 - tp.height * 0.5 * positionAlignment.y - backgroundPadding.top,
          tp.width + backgroundPadding.horizontal,
          tp.height + backgroundPadding.vertical,
        ),
        backgroundBorderRadius,
      );
      canvas.drawRRect(bgRect, backgroundPaint);
    }

    tp.paint(
      canvas,
      Offset(
        position.dx - tp.width / 2 - tp.width * 0.5 * positionAlignment.x,
        position.dy - tp.height / 2 - tp.height * 0.5 * positionAlignment.y,
      ),
    );
    return Size(tp.width, tp.height);
  }

  void drawArrow(Canvas canvas, Offset from, Offset to, Paint paint, FusionCanvasPainter painter) {
    final double arrowLength = nonScaling(10.0, painter);
    final double arrowAngle = 0.5; // radians

    // Calculate direction vector
    final Offset direction = (to - from);
    final double distance = direction.distance;
    if (distance == 0) return;

    final Offset normalizedDirection = direction / distance;

    // Calculate arrow points
    final double angle = normalizedDirection.direction;
    final Offset arrowPoint1 =
        from +
        Offset(
          arrowLength * math.cos(angle - arrowAngle),
          arrowLength * math.sin(angle - arrowAngle),
        );
    final Offset arrowPoint2 =
        from +
        Offset(
          arrowLength * math.cos(angle + arrowAngle),
          arrowLength * math.sin(angle + arrowAngle),
        );

    // Draw arrow lines
    canvas.drawLine(from, arrowPoint1, paint);
    canvas.drawLine(from, arrowPoint2, paint);
  }
}
