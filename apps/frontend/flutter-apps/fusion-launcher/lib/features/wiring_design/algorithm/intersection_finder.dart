import 'package:flutter/widgets.dart';

import '../model/wire.dart';

class IntersectionFinder {
  final List<Wire> wires;

  IntersectionFinder({required this.wires});

  List<Offset> getIntersectionPoints(Wire wire) {
    final Set<Offset> intersections = <Offset>{};
    for (Wire otherWire in wires) {
      if (otherWire == wire) continue;
      for (int i = 0; i < wire.joints.length - 1; i++) {
        for (int j = 0; j < otherWire.joints.length - 1; j++) {
          final Offset p1 = wire.joints[i];
          final Offset p2 = wire.joints[i + 1];
          final Offset q1 = otherWire.joints[j];
          final Offset q2 = otherWire.joints[j + 1];

          final Offset? intersection = _getLineIntersection(p1, p2, q1, q2);
          if (intersection != null) {
            intersections.add(intersection);
          }
        }
      }
    }
    return intersections.toList();
  }

  Map<Wire, List<Offset>> findIntersections() {
   final Map<Wire, List<Offset>> wireIntersections = <Wire,List<Offset>>{};
    for (Wire wire in wires) {
      wireIntersections[wire] = getIntersectionPoints(wire);
    }
    return wireIntersections;
  }

  Offset? _getLineIntersection(Offset p1, Offset p2, Offset q1, Offset q2) {
    final double a1 = p2.dy - p1.dy;
    final double b1 = p1.dx - p2.dx;
    final double c1 = a1 * p1.dx + b1 * p1.dy;

    final double a2 = q2.dy - q1.dy;
    final double b2 = q1.dx - q2.dx;
    final double c2 = a2 * q1.dx + b2 * q1.dy;

    final double determinant = a1 * b2 - a2 * b1;

    if (determinant == 0) {
      return null; // Lines are parallel
    } else {
      final double x = (b2 * c1 - b1 * c2) / determinant;
      final double y = (a1 * c2 - a2 * c1) / determinant;
      final Offset intersection = Offset(x, y);

      if (_isPointOnSegment(intersection, p1, p2) &&
          _isPointOnSegment(intersection, q1, q2)) {
        return intersection;
      }
    }
    return null;
  }

  bool _isPointOnSegment(Offset pt, Offset segStart, Offset segEnd) {
    return (pt.dx >= segStart.dx && pt.dx <= segEnd.dx ||
            pt.dx <= segStart.dx && pt.dx >= segEnd.dx) &&
        (pt.dy >= segStart.dy && pt.dy <= segEnd.dy ||
            pt.dy <= segStart.dy && pt.dy >= segEnd.dy);
  }
}
