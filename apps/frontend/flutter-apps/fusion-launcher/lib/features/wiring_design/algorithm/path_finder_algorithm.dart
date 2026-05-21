import 'dart:ui';

import 'package:fusion_launcher/features/wiring_design/algorithm/orthogonal_path_service.dart';
import 'package:fusion_lib/fusion_lib.dart';

class Obstacle {
  const Obstacle(this.rect);
  final Rect rect;
  bool contains(Offset p) => rect.contains(p);

  double get padding => 10;
  double get left => rect.left - padding;
  double get right => rect.right + padding;
  double get top => rect.top - padding;
  double get bottom => rect.bottom + padding;

  Rect get expanded => rect.inflate(padding);
}

class OrthogonalRouter {
  OrthogonalRouter(this.obstacles)
    : _obstacleLeft = obstacles.map((Rect r) => r.left).toList(growable: false),
      _obstacleRight = obstacles.map((Rect r) => r.right).toList(growable: false),
      _obstacleTop = obstacles.map((Rect r) => r.top).toList(growable: false),
      _obstacleBottom = obstacles.map((Rect r) => r.bottom).toList(growable: false);

  final List<Rect> obstacles;
  final List<double> _obstacleLeft;
  final List<double> _obstacleRight;
  final List<double> _obstacleTop;
  final List<double> _obstacleBottom;

  static const double _padding = 10;
  static const double _probeSize = 50;

  double get padding => _padding;
  double get spacing => 10;

  double _manhattan(Offset a, Offset b) => (a.dx - b.dx).abs() + (a.dy - b.dy).abs();

  Offset _snapOutside(Offset p) {
    const double tieTolerance = 0.1;
    for (int i = 0; i < obstacles.length; i++) {
      if (_isBlockedByObstacle(i, p.dx, p.dy)) {
        final double left = _obstacleLeft[i];
        final double right = _obstacleRight[i];
        final double top = _obstacleTop[i];
        final double bottom = _obstacleBottom[i];
        final List<Offset> candidates = <Offset>[
          Offset(left - padding, p.dy),
          Offset(right + padding, p.dy),
          Offset(p.dx, top - padding),
          Offset(p.dx, bottom + padding),
        ];

        Offset best = candidates.first;
        double bestDistance = _manhattan(p, best);
        for (int i = 1; i < candidates.length; i++) {
          final Offset candidate = candidates[i];
          final double distance = _manhattan(p, candidate);
          if (distance + tieTolerance < bestDistance) {
            best = candidate;
            bestDistance = distance;
          }
        }
        return best;
      }
    }
    return p;
  }

  /// Public API: finds a path through axis-locked intermediate waypoints.
  /// Each [AxisLock] constrains the path to pass through a vertical line (x set)
  /// or a horizontal line (y set). The opposite coordinate is derived from the
  /// previous waypoint so the path moves orthogonally into the lock first.
  List<Offset> findPath(
    Offset start,
    Offset end, {
    List<AxisLock> axisLocks = const <AxisLock>[],
    List<Offset>? previousPath,
    List<List<Offset>>? otherPaths,
  }) {
    final Offset actualStart = _snapOutside(start);
    final Offset actualEnd = _snapOutside(end);
    // print("Calculating path from $actualStart to $actualEnd with axis locks: $axisLocks");
    return <Offset>[
      start,
      ...OrthogonalPathService().findPath(
        start: actualStart,
        end: actualEnd,
        obstacles: obstacles,
        axisLocks: axisLocks,
        otherPaths: <List<Offset>>[],
        previousPath: previousPath,
        // otherPaths: previousPath != null ? <List<Offset>>[previousPath] : <List<Offset>>[],
      ),
      end,
    ];
    // Convert axis locks to concrete intermediate stops.
    // final List<Offset> stops = <Offset>[];
    // Offset from = start;
    // for (final AxisLock lock in axisLocks) {
    //   final Offset stop = lock.x != null ? Offset(lock.x!, from.dy) : Offset(from.dx, lock.y!);
    //   stops.add(stop);
    //   from = stop;
    // }

    // final List<Offset> points = <Offset>[start, ...stops, end];
    // final List<Offset> result = <Offset>[];

    // for (int i = 0; i < points.length - 1; i++) {
    //   final List<Offset> seg = _findPathSegment(
    //     points[i],
    //     points[i + 1],
    //     previousPath: previousPath,
    //   );
    //   if (seg.isEmpty) return <Offset>[];
    //   if (result.isNotEmpty) {
    //     result.removeLast(); // avoid duplicating joints
    //   }
    //   result.addAll(seg);
    // }
    // return result;
  }

  bool _isBlockedByObstacle(int index, double pointX, double pointY) {
    final double probeLeft = pointX;
    final double probeRight = pointX + _probeSize;
    final double probeTop = pointY;
    final double probeBottom = pointY + _probeSize;
    return _obstacleLeft[index] < probeRight && _obstacleRight[index] > probeLeft && _obstacleTop[index] < probeBottom && _obstacleBottom[index] > probeTop;
  }
}
