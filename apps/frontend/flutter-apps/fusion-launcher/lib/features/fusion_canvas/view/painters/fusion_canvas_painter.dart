import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../wiring_design/view/painters/dotted_grid_painter.dart';
import '../../state/fusion_canvas_state.dart';
import '../../viewmodel/fusion_canvas_image_viewmodel.dart';

class FusionCanvasPainter extends CustomPainter {
  final FusionCanvasState state;
  final List<FusionBasePainter> layers;
  final BuildContext context;
  FusionCanvasPainter({
    required this.state,
    this.layers = const <FusionBasePainter>[],
    required this.context,
  });
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
    return oldDelegate is! FusionCanvasPainter ||
        oldDelegate.state != state ||
        oldDelegate.layers != layers ||
        layers.any(
          (FusionBasePainter p) =>
              !oldDelegate.layers.contains(p) ||
              p.shouldRepaint(oldDelegate.layers.firstWhere((FusionBasePainter op) => op.runtimeType == p.runtimeType, orElse: () => p)),
        );
  }

  ui.Image? getImage(String s) {
    return context.read<FusionCanvasImageViewModel>().getImage(s);
  }
}

abstract class FusionBasePainter {
  void paint(Canvas canvas, Size size, FusionCanvasPainter painter);
  bool shouldRepaint(covariant FusionBasePainter oldDelegate);

  bool isHit(Offset position, FusionCanvasPainter painter) {
    // By default, painters are not interactive. Override this method in interactive painters.
    return false;
  }

  ///
  /// Util function for number that should not scale with canvas zoom
  ///

  double nonScaling(num value, FusionCanvasPainter painter) {
    return value * (1 / painter.state.scale);
  }

  bool drawImage({
    required Canvas canvas,
    required String imagePath,
    required Rect rect,
    required FusionCanvasPainter painter,
    Paint? paint,
  }) {
    final ui.Image? image = painter.getImage(imagePath);
    if (image != null) {
      final Rect src = Rect.fromLTWH(
        0,
        0,
        image.width.toDouble(),
        image.height.toDouble(),
      );

      canvas.drawImageRect(image, src, rect, paint ?? Paint());
      return true;
    }
    return false;
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

  void drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint, FusionCanvasPainter painter) {
    const double dashLength = 5.0;
    const double gapLength = 3.0;

    final double distance = (end - start).distance;
    final Offset direction = (end - start) / distance;

    double currentDistance = 0;
    bool isDash = true;

    while (currentDistance < distance) {
      final double segmentLength = isDash ? dashLength : gapLength;
      final double remainingDistance = distance - currentDistance;
      final double actualLength = segmentLength > remainingDistance ? remainingDistance : segmentLength;

      if (isDash) {
        final Offset segmentStart = start + direction * currentDistance;
        final Offset segmentEnd = start + direction * (currentDistance + actualLength);
        canvas.drawLine(segmentStart, segmentEnd, paint);
      }

      currentDistance += actualLength;
      isDash = !isDash;
    }
  }

  void drawClosedPath({required Canvas canvas, required List<FusionCanvasPoint> points, required Paint fillPaint, required Paint strokePaint}) {
    if (points.length < 2) return;

    final Path path = Path()..moveTo(points[0].position.dx, points[0].position.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].position.dx, points[i].position.dy);
    }
    path.close();
    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);
  }
}
