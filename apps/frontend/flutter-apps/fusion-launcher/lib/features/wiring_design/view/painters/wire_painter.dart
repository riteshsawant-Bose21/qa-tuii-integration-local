import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/wiring_design/algorithm/wire_router.dart';
import 'package:fusion_launcher/features/wiring_design/model/canvas_element.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

import '../../model/wire.dart';
import 'base_painter.dart';

class WirePainter extends BasePainter {
  WirePainter({
    required this.wire,
    required super.controller,
    required super.colorScheme,
    this.strokeWidth = 5.0,
    this.strokeCap = StrokeCap.round,
    this.strokeJoin = StrokeJoin.round,
  });
  final Wire wire;
  final double strokeWidth;
  final StrokeCap strokeCap;
  final StrokeJoin strokeJoin;

  Path? path;
  List<Offset>? _points; // ordered polyline points
  Rect? _inflatedBounds;

  @override
  void paint(Canvas canvas, Size size) {
    _rebuildCacheIfNeeded();
    final Paint paint =
        Paint()
          ..color =
              isSelected(wire) ? Colors.greenAccent : colorScheme.wireColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = strokeCap
          ..strokeJoin = strokeJoin;

    if (path != null) {
      canvas.drawPath(path!, paint);
    }
    // for (var i = 0; i < wire.joints.length; i++) {
    //   canvas.drawPoints(PointMode.polygon, [], paint);
    // }
    // for (var segment in wire.joints) {
    //   canvas.drawOval(
    //     Rect.fromCenter(center: segment, width: 10, height: 10),
    //     paint,
    //   );
    // }
  }

  @override
  CanvasElement? isHit(Offset position) {
    _rebuildCacheIfNeeded();

    final List<Offset>? pts = _points;
    if (pts == null || pts.length < 2) return null;

    // cheap bounding-box reject
    if (!(_inflatedBounds?.contains(position) ?? false)) return null;

    final double half = strokeWidth / 2;
    final int nSeg = pts.length - 1;

    for (int i = 0; i < nSeg; i++) {
      Offset a = pts[i];
      Offset b = pts[i + 1];

      // handle degenerate segment quickly
      if ((a - b).distance == 0.0) {
        if ((position - a).distance <= half) return wire;
        continue;
      }

      // For stroke caps: only start (i==0) and end (i==nSeg-1) get cap behaviour.
      // For square cap we extend the first/last segments by half along their directions.
      if (strokeCap == StrokeCap.square) {
        // extend start backward for first segment
        if (i == 0) {
          final Offset dir = (b - a);
          final double len = dir.distance;
          if (len > 0) {
            final double ux = dir.dx / len;
            final double uy = dir.dy / len;
            a = Offset(a.dx - ux * half, a.dy - uy * half);
          }
        }
        // extend end forward for last segment
        if (i == nSeg - 1) {
          final Offset dir = (b - a);
          final double len = dir.distance;
          if (len > 0) {
            final double ux = dir.dx / len;
            final double uy = dir.dy / len;
            b = Offset(b.dx + ux * half, b.dy + uy * half);
          }
        }
      }

      // compute projection-distance relative to the (possibly extended) segment
      final double dx = b.dx - a.dx;
      final double dy = b.dy - a.dy;
      final double l2 = dx * dx + dy * dy;
      final double t =
          ((position.dx - a.dx) * dx + (position.dy - a.dy) * dy) / l2;

      if (t >= 0.0 && t <= 1.0) {
        // perpendicular projection falls inside the segment
        final Offset proj = Offset(a.dx + t * dx, a.dy + t * dy);
        if ((position - proj).distance <= half) return wire;
      } else {
        // projection is outside the segment:
        // - For round caps, allow endpoint-circle at start/end only
        // - For butt cap, do NOT include outside-of-segment points (but endpoints themselves are part of the stroke)
        if (strokeCap == StrokeCap.round) {
          if (t < 0.0 && i == 0) {
            if ((position - a).distance <= half) return wire;
          } else if (t > 1.0 && i == nSeg - 1) {
            if ((position - b).distance <= half) return wire;
          }
        } else {
          // For butt cap: points outside (t<0 or t>1) are not in the stroke region for this segment.
          // However, the exact endpoint belongs to stroke; if position is exactly on endpoint and within half,
          // we can check endpoints separately after the loop.
        }
      }
    }

    // final explicit endpoint checks:
    if (strokeCap == StrokeCap.round) {
      if ((position - pts.first).distance <= half) return wire;
      if ((position - pts.last).distance <= half) return wire;
    } else {
      // for butt cap: the endpoints are included only for their perpendicular projection inside segment;
      // but to be safe about exact touches on endpoints:
      if ((position - pts.first).distance <= 0.0001) return wire;
      if ((position - pts.last).distance <= 0.0001) return wire;
    }

    return null;
  }

  void _rebuildCacheIfNeeded() {
    // Rebuild the points list and bounds if missing (lazy; kept simple)
    if (_points != null && path != null && _inflatedBounds != null) return;

    if (wire.joints.isEmpty) return;
    final List<Offset> pts = <Offset>[];
    final LineDirection direction = getLineDirection(
      wire.from.absolutePosition,
      wire.joints.first,
    );
    final Offset point = wire.from.absolutePosition;
    final double fpRadius = wire.from.parent.data.portRadius;
    switch (direction) {
      case LineDirection.upToDown:
        pts.add(Offset(point.dx, point.dy + fpRadius));
        break;
      case LineDirection.downToUp:
        pts.add(Offset(point.dx, point.dy - fpRadius));
        break;
      case LineDirection.leftToRight:
        pts.add(Offset(point.dx + fpRadius, point.dy));
        break;
      case LineDirection.rightToLeft:
        pts.add(Offset(point.dx - fpRadius, point.dy));
        break;
    }
    // pts.add(wire.from.absolutePosition);
    // pts.add(wire.from.absolutePositionWithOffset);

    for (final Offset j in wire.joints) {
      pts.add(j);
    }

    // final isHorizontalEnd =
    //     wire.joints.isEmpty ||
    //     wire.joints.last.dy == wire.to.absolutePositionWithOffset.dy;
    // if (isHorizontalEnd) {
    //   pts.add(Offset(wire.to.absolutePosition.dx, wire.joints.last.dy));
    // } else {
    //   pts.add(Offset(wire.joints.last.dx, wire.to.absolutePosition.dy));
    // }
    // pts.add(wire.to.absolutePositionWithOffset);
    // pts.add(wire.to.absolutePosition);

    final Offset toPoint = wire.to.absolutePosition;
    final LineDirection eDirection = getLineDirection(
      toPoint,
      pts.last,
    );
    final double epRadius = wire.to.parent.data.portRadius;
    switch (eDirection) {
      case LineDirection.upToDown:
        pts.add(
          Offset(toPoint.dx, toPoint.dy + epRadius),
        );
        break;
      case LineDirection.downToUp:
        pts.add(
          Offset(toPoint.dx, toPoint.dy - epRadius),
        );
        break;
      case LineDirection.leftToRight:
        pts.add(
          Offset(toPoint.dx + epRadius, toPoint.dy),
        );
        break;
      case LineDirection.rightToLeft:
        pts.add(
          Offset(toPoint.dx - epRadius, toPoint.dy),
        );
        break;
    }

    // Build path for drawing & bounds
    final Path p = Path();
    if (pts.isNotEmpty) {
      p.moveTo(pts[0].dx, pts[0].dy);
      for (int i = 1; i < pts.length; i++) {
        p.lineTo(pts[i].dx, pts[i].dy);
      }
    }

    path = p;
    _points = pts;
    _inflatedBounds = path!.getBounds().inflate(strokeWidth / 2);
  }
}
