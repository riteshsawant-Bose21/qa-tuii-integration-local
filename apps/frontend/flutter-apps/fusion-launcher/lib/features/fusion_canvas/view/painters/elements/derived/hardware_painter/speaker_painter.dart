import 'dart:math';
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_base_painter.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_canvas_painter.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../fusion_canvas_element_painter.dart';

class SpeakerPainter extends FusionCanvasElementPainter {
  final Speaker hardware;

  SpeakerPainter({required this.hardware}) : super(item: FusionCanvasItem(id: hardware.id));
  @override
  void paint(Canvas canvas, Size size, FusionCanvasPainter painter) {
    final Offset? position = hardware.pos;
    if (position != null) {
      final Rect rect = getTransformedRect(painter);
      _drawDirectionalCoverage(canvas, painter: painter);
      _drawSpeaker(rect, canvas, painter, hardware);
    }
  }

  @override
  bool shouldRepaint(covariant FusionBasePainter oldDelegate) {
    if (oldDelegate is! SpeakerPainter) return true;
    return oldDelegate.hardware != hardware;
  }

  void _drawDirectionalCoverage(Canvas canvas, {required FusionCanvasPainter painter}) {
    final double roll = hardware.roll;
    final double pitch = hardware.pitch;
    final double yaw = hardware.yaw;

    final Offset? position = hardware.pos;
    if (position == null) return;

    final double coverageAngle = (hardware.horizontalCoverageAngle ?? 90.0) / 2;

    final double coverageDistance = 200.0;

    final Offset origin = transformOffsetForLayer(position, painter, id);

    final double yawRad = yaw * pi / 180.0;
    final double pitchRad = pitch * pi / 180.0;
    final double rollRad = roll * pi / 180.0;
    final double halfAngleRad = (coverageAngle * pi / 180.0) / 2.0;

    final double axisProjection = coverageDistance * cos(pitchRad).abs();
    final Offset baseCenter = Offset(
      origin.dx + axisProjection * cos(yawRad),
      origin.dy + axisProjection * sin(yawRad),
    );

    final double baseRadius = (coverageDistance * tan(halfAngleRad)).abs().clamp(1.0, coverageDistance * 10.0).toDouble();
    final double minMinorRadius = nonScaling(2.0, painter);
    final double minEllipseMinorScale = (minMinorRadius / baseRadius).clamp(0.0, 1.0).toDouble();
    final double ellipseMinorScale = max(sin(pitchRad).abs(), minEllipseMinorScale).clamp(0.0, 1.0).toDouble();
    final double ellipseMinorRadius = (baseRadius * ellipseMinorScale).clamp(minMinorRadius, baseRadius).toDouble();
    final double ellipseRotation = yawRad + (pi / 2) + rollRad;

    final double cosR = cos(ellipseRotation);
    final double sinR = sin(ellipseRotation);

    final Offset tipFromBase = origin - baseCenter;
    // Convert tip to ellipse local space (axis-aligned ellipse centered at origin).
    final Offset tipLocal = Offset(
      tipFromBase.dx * cosR + tipFromBase.dy * sinR,
      -tipFromBase.dx * sinR + tipFromBase.dy * cosR,
    );

    final Paint outlinePaint = Paint();
    outlinePaint.color = const Color(0x80000000);
    outlinePaint.style = PaintingStyle.stroke;
    outlinePaint.strokeWidth = nonScaling(1.2, painter);
    final double dashLength = nonScaling(6.0, painter);
    final double gapLength = nonScaling(4.0, painter);

    final double ellipsePointFactor = sqrt(
      (tipLocal.dx * tipLocal.dx) / (baseRadius * baseRadius) + (tipLocal.dy * tipLocal.dy) / (ellipseMinorRadius * ellipseMinorRadius),
    );

    // If tip projects inside the base ellipse, tangents are undefined.
    // In that orientation, only the base rim silhouette is visible.
    if (ellipsePointFactor <= 1.0001) {
      canvas.save();
      canvas.translate(baseCenter.dx, baseCenter.dy);
      canvas.rotate(ellipseRotation);
      final Path rimPath =
          Path()..addOval(
            Rect.fromCenter(
              center: Offset.zero,
              width: baseRadius * 2,
              height: ellipseMinorRadius * 2,
            ),
          );
      _drawDashedPath(canvas: canvas, path: rimPath, paint: outlinePaint, dashLength: dashLength, gapLength: gapLength);
      canvas.restore();
      return;
    }

    final double aNorm = tipLocal.dx / baseRadius;
    final double bNorm = tipLocal.dy / ellipseMinorRadius;
    final double phi = atan2(bNorm, aNorm);
    final double delta = acos((1.0 / ellipsePointFactor).clamp(-1.0, 1.0));
    final double t1 = phi + delta;
    final double t2 = phi - delta;

    Offset pointOnEllipse(double t) => Offset(baseRadius * cos(t), ellipseMinorRadius * sin(t));

    Offset localToWorld(Offset local) => Offset(
      baseCenter.dx + local.dx * cosR - local.dy * sinR,
      baseCenter.dy + local.dx * sinR + local.dy * cosR,
    );

    final Offset p1 = localToWorld(pointOnEllipse(t1));
    final Offset p2 = localToWorld(pointOnEllipse(t2));

    final Path sidePath = Path();
    sidePath.moveTo(origin.dx, origin.dy);
    sidePath.lineTo(p1.dx, p1.dy);
    sidePath.moveTo(origin.dx, origin.dy);
    sidePath.lineTo(p2.dx, p2.dy);
    _drawDashedPath(canvas: canvas, path: sidePath, paint: outlinePaint, dashLength: dashLength, gapLength: gapLength);

    double normalizeAngle(double angle) {
      double a = angle % (2 * pi);
      if (a < 0) a += 2 * pi;
      return a;
    }

    double ccwSweep(double start, double end) {
      final double s = normalizeAngle(start);
      final double e = normalizeAngle(end);
      final double d = e - s;
      return d >= 0 ? d : (d + 2 * pi);
    }

    final double sweep12 = ccwSweep(t1, t2);
    final double sweep21 = (2 * pi) - sweep12;
    final double mid12 = t1 + (sweep12 / 2.0);
    final double mid21 = t2 + (sweep21 / 2.0);

    final Offset m12 = pointOnEllipse(mid12);
    final Offset m21 = pointOnEllipse(mid21);
    final double d12 = (m12 - tipLocal).distanceSquared;
    final double d21 = (m21 - tipLocal).distanceSquared;

    final double arcStart = d12 >= d21 ? t1 : t2;
    final double arcSweep = d12 >= d21 ? sweep12 : sweep21;

    canvas.save();
    canvas.translate(baseCenter.dx, baseCenter.dy);
    canvas.rotate(ellipseRotation);

    final Path arcPath = Path();
    arcPath.addArc(
      Rect.fromCenter(center: Offset.zero, width: baseRadius * 2, height: ellipseMinorRadius * 2),
      arcStart,
      arcSweep,
    );
    _drawDashedPath(canvas: canvas, path: arcPath, paint: outlinePaint, dashLength: dashLength, gapLength: gapLength);
    canvas.restore();
  }

  void _drawDashedPath({
    required Canvas canvas,
    required Path path,
    required Paint paint,
    required double dashLength,
    required double gapLength,
  }) {
    for (final PathMetric metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final double next = min(distance + dashLength, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + gapLength;
      }
    }
  }

  void _drawSpeaker(Rect rect, Canvas canvas, FusionCanvasPainter painter, Speaker speaker) {
    final Paint paint = Paint()..color = painter.context.colorScheme.black;

    final MountingType? mountingType = speaker.mountingType;
    switch (mountingType) {
      case MountingType.surface:
        paint.color = paint.color.withValues(alpha: 0.8);
        final double yawRad = speaker.yaw * pi / 180.0;
        canvas.save();
        canvas.translate(rect.center.dx, rect.center.dy);
        canvas.rotate(yawRad);
        final RRect rRect = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: rect.width, height: rect.height),
          Radius.circular(rect.shortestSide * 0.15),
        );
        canvas.drawRRect(rRect, paint);
        canvas.restore();
        return;
      case MountingType.pendant:
        return canvas.drawPath(
          Path()
            ..moveTo(rect.topCenter.dx, rect.topCenter.dy)
            ..lineTo(rect.bottomRight.dx, rect.bottomRight.dy)
            ..lineTo(rect.bottomLeft.dx, rect.bottomLeft.dy)
            ..close(),
          paint,
        );
      case MountingType.ceiling:
      case null:
        final double radius = rect.width / 2;
        final Rect layerBounds = Rect.fromCircle(center: rect.center, radius: radius).inflate(radius * 0.2);
        canvas.saveLayer(layerBounds, Paint());
        canvas.drawCircle(rect.center, radius, paint);

        final Paint cutoutPaint =
            Paint()
              ..blendMode = BlendMode.clear
              ..style = PaintingStyle.stroke
              ..strokeCap = StrokeCap.round
              ..strokeJoin = StrokeJoin.round
              ..strokeWidth = radius * 0.22;

        final Offset c = rect.center;
        final Path cutoutPath =
            Path()
              ..moveTo(c.dx - radius * 0.58, c.dy + radius * 0.08)
              ..cubicTo(c.dx - radius * 0.62, c.dy + radius * 0.55, c.dx - radius * 0.12, c.dy + radius * 0.72, c.dx + radius * 0.23, c.dy + radius * 0.60);
        canvas.drawPath(cutoutPath, cutoutPaint);
        canvas.restore();
        return;
    }
  }

  @override
  Offset getOffset() => hardware.pos ?? Offset.zero;

  @override
  Size getSize() {
    if (hardware.mountingType == MountingType.surface) {
      return const Size(40, 80); // portrait base — rotated by yaw when drawing
    } else if (hardware.mountingType == MountingType.pendant) {
      return const Size(100, 100);
    } else {
      return const Size(100, 100);
    }
  }
}
