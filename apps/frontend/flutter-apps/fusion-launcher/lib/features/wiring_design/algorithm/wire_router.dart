import 'dart:math';
import 'dart:ui';

import '../controller/circuit_controller.dart';
import '../model/circuit_component.dart';
import '../model/circuit_port.dart';
import '../model/wire.dart';
import 'path_finder_algorithm.dart';

class WireRouter {
  WireRouter({
    required this.basePaths,
    required this.usedPaths,
    this.wireSpacing = 10.0,
  });
  final Map<PathSide, Map<PathSide, List<Offset>>> basePaths;
  final Map<PathSide, Map<PathSide, List<Wire>>> usedPaths;

  final Map<Wire, List<Offset>> wireBasePath = <Wire, List<Offset>>{};

  final double wireSpacing;

  List<List<Offset>> parallalPaths = <List<Offset>>[];
  List<Rect> outBounds = <Rect>[];
  List<Rect> inBounds = <Rect>[];

  /// Add a new wire and recompute parallel routes
  void addWire(
    PathSide from,
    PathSide to,
    Wire newWire,
    List<Obstacle> obstecles,
  ) {
    usedPaths[from] ??= <PathSide, List<Wire>>{};
    usedPaths[from]![to] ??= <Wire>[];
    usedPaths[from]![to]!.add(newWire);
    usedPaths[to] ??= <PathSide, List<Wire>>{};
    usedPaths[to]![from] ??= <Wire>[];
    usedPaths[to]![from]!.add(newWire);
    wireBasePath[newWire] = basePaths[from]?[to] ?? <Offset>[];
    // Recompute all parallel paths for this pair
    _reassignParallelPaths(from, to, obstecles);
  }

  void updateRouteForWire(Wire wire, List<Obstacle> obstecles) {
    _reassignParallelPaths(
      _constructPathSide(wire.from),
      _constructPathSide(wire.to),
      obstecles,
    );
  }

  PathSide _constructPathSide(CircuitPort port) {
    final CircuitComponent parent = port.parent;
    final Side side =
        port.absolutePositionWithOffset.dx > parent.position.dx
            ? Side.right
            : Side.left;
    return PathSide(component: parent, side: side);
  }

  void _reassignParallelPaths(
    PathSide from,
    PathSide to,
    List<Obstacle> obstecles,
  ) {
    final List<Wire>? wires = usedPaths[from]?[to];
    final List<Offset>? basePath = basePaths[from]?[to];

    if (wires == null || basePath == null) return;

    // for (var element in wires) {

    // }
    // // Generate parallel versions of base path
    parallalPaths = makeParallelRoutes(
      wires,
      basePath,
      spacing: 15,
      obstecles: obstecles,
    );

    // Assign each wire a path
    wires.sort(
      (Wire a, Wire b) => a.from.absolutePositionWithOffset.dy.compareTo(
        b.from.absolutePositionWithOffset.dy,
      ),
    );
    for (int i = 0; i < wires.length; i++) {
      final Wire wire = wires[i];
      final bool isReversed = from.component == wire.to.parent;
      final List<Offset> parallalPath =
          isReversed ? parallalPaths[i].reversed.toList() : parallalPaths[i];
      if (parallalPath.isEmpty) continue;

      /// For Starting
      final LineDirection direction = getLineDirection(
        parallalPath.first,
        parallalPath[1],
      );

      final Offset lineStartPoint = parallalPath.first;
      if (direction == LineDirection.upToDown) {
        final bool isAbove =
            lineStartPoint.dy < wire.from.absolutePositionWithOffset.dy;

        if (isAbove) {
          parallalPath.removeAt(0);
        }
        parallalPath.insert(
          0,
          Offset(lineStartPoint.dx, wire.from.absolutePositionWithOffset.dy),
        );
      } else if (direction == LineDirection.downToUp) {
        final bool isAbove =
            lineStartPoint.dy > wire.from.absolutePositionWithOffset.dy;

        if (isAbove) {
          parallalPath.removeAt(0);
        }
        parallalPath.insert(
          0,
          Offset(lineStartPoint.dx, wire.from.absolutePositionWithOffset.dy),
        );
      } else if (direction == LineDirection.leftToRight) {
        parallalPath.removeAt(0);
        parallalPath.insert(
          0,
          Offset(wire.from.absolutePositionWithOffset.dx, lineStartPoint.dy),
        );
        parallalPath.insert(0, wire.from.absolutePositionWithOffset);
      } else if (direction == LineDirection.rightToLeft) {
        parallalPath.removeAt(0);
        parallalPath.insert(
          0,
          Offset(wire.from.absolutePositionWithOffset.dx, lineStartPoint.dy),
        );
        parallalPath.insert(0, wire.from.absolutePositionWithOffset);
      }

      final LineDirection endDirection = getLineDirection(
        parallalPath[parallalPath.length - 2],
        parallalPath.last,
      );

      final Offset lineEndPoint = parallalPath.last;
      if (endDirection == LineDirection.upToDown) {
        final bool isAbove =
            lineEndPoint.dy > wire.to.absolutePositionWithOffset.dy;

        if (isAbove) {
          parallalPath.removeLast();
        }
        parallalPath.add(
          Offset(lineEndPoint.dx, wire.to.absolutePositionWithOffset.dy),
        );
      } else if (endDirection == LineDirection.downToUp) {
        final bool isAbove =
            lineEndPoint.dy > wire.to.absolutePositionWithOffset.dy;
        parallalPath.removeLast();
        if (isAbove) {}
        parallalPath.add(
          Offset(lineEndPoint.dx, wire.to.absolutePositionWithOffset.dy),
        );
      } else if (endDirection == LineDirection.leftToRight) {
        parallalPath.removeLast();
        // wire.to.padding = Offset(10 * (wires.length - i) + 5, 0);
        parallalPath.add(
          Offset(wire.to.absolutePositionWithOffset.dx, lineEndPoint.dy),
        );
        parallalPath.add(wire.to.absolutePositionWithOffset);
      } else if (endDirection == LineDirection.rightToLeft) {
        parallalPath.removeLast();
        // wire.to.padding = Offset(-10 * (wires.length - i) - 5, 0);
        parallalPath.add(
          Offset(wire.to.absolutePositionWithOffset.dx, lineEndPoint.dy),
        );
        parallalPath.add(wire.to.absolutePositionWithOffset);
      }
      wires[i].joints = parallalPath;
    }
  }

  List<List<Offset>> makeParallelRoutes(
    List<Wire> wires,
    List<Offset> basePath, {
    double spacing = 12.0,
    required List<Obstacle> obstecles,
  }) {
    if (wires.isEmpty) return <List<Offset>>[];
    bool isBlocked(Rect p) {
      for (final Obstacle r in obstecles) {
        if (p.overlaps(r.expanded)) {
          return true;
        }
      }
      return false;
    }

    final List<List<Offset>> allPaths = <List<Offset>>[];
    allPaths.addAll(
      List<List<Offset>>.generate(
        wires.length,
        (int index) => <Offset>[...basePath],
      ),
    );
    outBounds.clear();

    void shiftLineUp(int index, double offset) {
      for (int i = 0; i < allPaths.length; i++) {
        final double distance = ((i + 1) * spacing) + offset;
        allPaths[i][index] += Offset(0, -distance);
        allPaths[i][index + 1] += Offset(0, -distance);
      }
    }

    void shiftLineDown(int index, double offset) {
      bool isShifingReverse = true;
      if (index > 0) {
        final LineDirection prevLD = getLineDirection(
          basePath[index - 1],
          basePath[index],
        );
        final LineDirection currentLD = getLineDirection(
          basePath[index],
          basePath[index + 1],
        );
        isShifingReverse = (prevLD == LineDirection.downToUp);
        // print("Prev Direction: $prevLD. CurrentLD: $currentLD");
      }

      for (int i = 0; i < allPaths.length; i++) {
        final double distance =
            ((isShifingReverse ? i + 1 : allPaths.length - i) * spacing) +
            offset;
        allPaths[i][index] += Offset(0, distance);
        allPaths[i][index + 1] += Offset(0, distance);
      }
    }

    void shiftLineLeft(int index, double offset) {
      for (int i = 0; i < allPaths.length; i++) {
        final double distance = ((i + 1) * spacing) + offset;
        allPaths[i][index] += Offset(-distance, 0);
        allPaths[i][index + 1] += Offset(-distance, 0);
      }
    }

    void shiftLineRight(int index, double offset) {
      for (int i = 0; i < allPaths.length; i++) {
        final double distance = ((i + 1) * spacing) + offset;
        allPaths[i][index] += Offset(distance, 0);
        allPaths[i][index + 1] += Offset(distance, 0);
      }
    }

    /// Max Rquired width for all parallal wires.
    final double requiredSize = (wires.length * 10 + (wires.length) * spacing);

    for (int i = 0; i < basePath.length - 1; i++) {
      final Offset lineDifference = basePath[i + 1] - basePath[i];
      final bool isVericalLine = lineDifference.dx == 0;
      final Rect outsideBound = _createBound(
        basePath[i],
        basePath[i + 1],
        requiredSize,
      );
      const double offset = 0;

      if (!isBlocked(outsideBound)) {
        if (isVericalLine) {
          shiftLineRight(i, offset);
        } else {
          shiftLineDown(i, offset);
        }
      } else {
        if (isVericalLine) {
          shiftLineLeft(i, offset);
        } else {
          shiftLineUp(i, offset);
        }
      }
    }

    return allPaths;
  }

  Rect _createBound(Offset pointA, Offset pointB, double size) {
    final bool isVericalLine = (pointA - pointB).dx == 0;
    // return Rect.fromPoints(pointA, pointB);
    if (isVericalLine) {
      return Rect.fromLTWH(
        min(pointB.dx, pointA.dx),
        min(pointB.dy, pointA.dy),
        size,
        (pointB.dy - pointA.dy).abs(),
      );
    }
    return Rect.fromLTWH(
      min(pointB.dx, pointA.dx),
      min(pointB.dy, pointA.dy),
      (pointB.dx - pointA.dx).abs(),
      size,
    );
  }

  //   ///
  //   /// Returns a shifted version of the given path [points].
  //   /// Offset is perpendicular to each segment, averaged for joints.
  //   ///
  //   List<Offset> _offsetPath(List<Offset> points, double distance) {
  //     if (points.length < 2 || distance == 0) return List.of(points);

  //     List<Offset> shifted = [...points];

  //     void _shiftLineUp(int index) {
  //       shifted[index] += Offset(0, -distance);
  //       shifted[index + 1] += Offset(0, -distance);
  //     }

  //     void _shiftLineDown(int index) {
  //       shifted[index] += Offset(0, distance);
  //       shifted[index + 1] += Offset(0, distance);
  //     }

  //     void _shiftLineLeft(int index) {
  //       shifted[index] += Offset(-distance, 0);
  //       shifted[index + 1] += Offset(-distance, 0);
  //     }

  //     void _shiftLineRight(int index) {
  //       shifted[index] += Offset(distance, 0);
  //       shifted[index + 1] += Offset(distance, 0);
  //     }

  //     for (int i = 0; i < points.length - 1; i++) {
  //       final lineDifference = points[i + 1] - points[i];
  //       if (lineDifference.dx == 0) {
  //         if (lineDifference.dy < 0)
  //           _shiftLineRight(i);
  //         else
  //           _shiftLineLeft(i);
  //       } else {
  //         if (lineDifference.dx < 0)
  //           _shiftLineUp(i);
  //         else
  //           _shiftLineDown(i);
  //       }
  //     }

  //     return shifted;
  //   }
}

LineDirection getLineDirection(Offset from, Offset to) {
  if ((to.dx - from.dx).abs() >= (to.dy - from.dy).abs()) {
    // Horizontal movement dominates
    return to.dx > from.dx
        ? LineDirection.leftToRight
        : LineDirection.rightToLeft;
  } else {
    // Vertical movement dominates
    return to.dy > from.dy ? LineDirection.upToDown : LineDirection.downToUp;
  }
}

enum LineDirection { upToDown, downToUp, leftToRight, rightToLeft }
