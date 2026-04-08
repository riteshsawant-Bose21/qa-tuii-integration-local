import 'dart:math';
import 'dart:ui';

import 'package:collection/collection.dart';
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

class _Node implements Comparable<_Node> {
  const _Node(this.p, this.f, this.g, this.turns, this.parent);
  final Offset p;
  final double f;
  final double g;
  final int turns;
  final Offset? parent;

  @override
  int compareTo(_Node other) {
    final int byF = f.compareTo(other.f);
    if (byF != 0) return byF;

    final int byTurns = turns.compareTo(other.turns);
    if (byTurns != 0) return byTurns;

    final int byG = g.compareTo(other.g);
    if (byG != 0) return byG;

    final int byX = p.dx.compareTo(other.p.dx);
    if (byX != 0) return byX;
    return p.dy.compareTo(other.p.dy);
  }
}

class _SegmentData {
  const _SegmentData({
    required this.ax,
    required this.ay,
    required this.bx,
    required this.by,
    required this.abx,
    required this.aby,
    required this.lengthSquared,
  });

  final double ax;
  final double ay;
  final double bx;
  final double by;
  final double abx;
  final double aby;
  final double lengthSquared;
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

  bool _isBlocked(Offset p) {
    final double probeLeft = p.dx;
    final double probeRight = p.dx + _probeSize;
    final double probeTop = p.dy;
    final double probeBottom = p.dy + _probeSize;

    for (int i = 0; i < obstacles.length; i++) {
      if (_obstacleLeft[i] < probeRight && _obstacleRight[i] > probeLeft && _obstacleTop[i] < probeBottom && _obstacleBottom[i] > probeTop) {
        return true;
      }
    }
    return false;
  }

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

  List<Offset> _findPathSegment(
    Offset start,
    Offset end, {
    List<Offset>? previousPath,
  }) {
    final Offset actualStart = _snapOutside(start);
    final Offset actualEnd = _snapOutside(end);

    final Set<double> xs = <double>{actualStart.dx, actualEnd.dx};
    final Set<double> ys = <double>{actualStart.dy, actualEnd.dy};
    for (final Rect r in obstacles) {
      xs.addAll(<double>[r.left - padding, r.left, r.right, r.right + padding]);
      ys.addAll(<double>[r.top - padding, r.top, r.bottom, r.bottom + padding]);
    }

    final List<double> xsList = xs.toList()..sort();
    final List<double> ysList = ys.toList()..sort();

    final Set<Offset> nodes = <Offset>{};
    final Map<double, List<double>> xToYs = <double, List<double>>{};
    final Map<double, List<double>> yToXs = <double, List<double>>{};

    void addNode(Offset p) {
      if (!nodes.add(p)) return;
      xToYs.putIfAbsent(p.dx, () => <double>[]).add(p.dy);
      yToXs.putIfAbsent(p.dy, () => <double>[]).add(p.dx);
    }

    for (final double x in xsList) {
      for (final double y in ysList) {
        final Offset p = Offset(x, y);
        if (!_isBlocked(p)) addNode(p);
      }
    }
    addNode(actualStart);
    addNode(actualEnd);

    for (final List<double> values in xToYs.values) {
      values.sort();
    }
    for (final List<double> values in yToXs.values) {
      values.sort();
    }

    bool verticalClear(double x, double y1, double y2) {
      final double top = min(y1, y2);
      final double bottom = max(y1, y2);
      for (int i = 0; i < obstacles.length; i++) {
        if (x >= _obstacleLeft[i] && x <= _obstacleRight[i] && bottom >= _obstacleTop[i] && top <= _obstacleBottom[i]) {
          return false;
        }
      }
      return true;
    }

    bool horizontalClear(double y, double x1, double x2) {
      final double left = min(x1, x2);
      final double right = max(x1, x2);
      for (int i = 0; i < obstacles.length; i++) {
        if (y >= _obstacleTop[i] && y <= _obstacleBottom[i] && right >= _obstacleLeft[i] && left <= _obstacleRight[i]) {
          return false;
        }
      }
      return true;
    }

    final List<_SegmentData>? previousSegments = _buildSegments(previousPath);

    final Map<Offset, List<Offset>> neighbors = <Offset, List<Offset>>{};
    for (final double x in xsList) {
      final List<double>? columnYs = xToYs[x];
      if (columnYs == null || columnYs.length < 2) continue;
      for (int i = 0; i < columnYs.length - 1; i++) {
        final Offset p1 = Offset(x, columnYs[i]);
        final Offset p2 = Offset(x, columnYs[i + 1]);
        if (verticalClear(x, columnYs[i], columnYs[i + 1])) {
          neighbors.putIfAbsent(p1, () => <Offset>[]).add(p2);
          neighbors.putIfAbsent(p2, () => <Offset>[]).add(p1);
        }
      }
    }
    for (final double y in ysList) {
      final List<double>? rowXs = yToXs[y];
      if (rowXs == null || rowXs.length < 2) continue;
      for (int i = 0; i < rowXs.length - 1; i++) {
        final Offset p1 = Offset(rowXs[i], y);
        final Offset p2 = Offset(rowXs[i + 1], y);
        if (horizontalClear(y, rowXs[i], rowXs[i + 1])) {
          neighbors.putIfAbsent(p1, () => <Offset>[]).add(p2);
          neighbors.putIfAbsent(p2, () => <Offset>[]).add(p1);
        }
      }
    }

    const double inf = 1e9;
    final Map<Offset, double> gScore = <Offset, double>{};
    final Map<Offset, int> turnScore = <Offset, int>{};
    final Map<Offset, Offset> cameFrom = <Offset, Offset>{};
    final Set<Offset> closed = <Offset>{};
    final PriorityQueue<_Node> open = PriorityQueue<_Node>();

    for (final Offset n in nodes) {
      gScore[n] = inf;
      turnScore[n] = 1 << 30;
    }
    gScore[actualStart] = 0;
    turnScore[actualStart] = 0;
    open.add(_Node(actualStart, _manhattan(actualStart, actualEnd), 0, 0, null));

    while (open.isNotEmpty) {
      final _Node curNode = open.removeFirst();
      final Offset cur = curNode.p;
      if (closed.contains(cur)) continue;

      if (cur == actualEnd) {
        final List<Offset> full = _reconstruct(cameFrom, cur);
        final List<Offset> adjusted = <Offset>[
          start,
          ..._extractTurns(full),
          end,
        ];
        final List<Offset> result = _dedup(adjusted);
        return result;
      }

      closed.add(cur);
      final double currentG = gScore[cur]!;
      final int currentTurns = turnScore[cur]!;
      final Offset? prevOfCur = cameFrom[cur];
      for (final Offset nb in neighbors[cur] ?? <Offset>[]) {
        if (closed.contains(nb)) continue;

        final double tentative = currentG + _manhattan(cur, nb);

        // Add turn penalty if direction changes
        double turnPenalty = 0;
        int turns = currentTurns;
        if (prevOfCur != null) {
          final bool wasVertical = prevOfCur.dx == cur.dx;
          final bool nowVertical = cur.dx == nb.dx;
          if (wasVertical != nowVertical) {
            turnPenalty = 50;
            turns += 1;
          }
        }

        final double continuityPenalty = _continuityPenalty(nb, previousSegments);
        final double newCost = tentative + turnPenalty + continuityPenalty;
        final double oldCost = gScore[nb] ?? inf;
        final int oldTurns = turnScore[nb] ?? (1 << 30);
        if (newCost < oldCost || (newCost == oldCost && turns < oldTurns)) {
          cameFrom[nb] = cur;
          gScore[nb] = newCost;
          turnScore[nb] = turns;
          final double f = newCost + _manhattan(nb, actualEnd);
          open.add(_Node(nb, f, newCost, turns, cur));
        }
      }
    }

    // Replaced print with error handling - you can customize this
    // log(false, '[No Path Found] from $start to $end');
    return <Offset>[];
  }

  List<Offset> _reconstruct(Map<Offset, Offset> cameFrom, Offset cur) {
    final List<Offset> path = <Offset>[];
    Offset? p = cur;
    while (p != null) {
      path.add(p);
      p = cameFrom[p];
    }
    return path.reversed.toList();
  }

  List<Offset> _extractTurns(List<Offset> path) {
    if (path.length <= 2) return path;
    final List<Offset> res = <Offset>[path.first];
    for (int i = 1; i < path.length - 1; i++) {
      final Offset prev = path[i - 1];
      final Offset curr = path[i];
      final Offset next = path[i + 1];
      final bool straight = (prev.dx == curr.dx && curr.dx == next.dx) || (prev.dy == curr.dy && curr.dy == next.dy);
      if (!straight) res.add(curr);
    }
    res.add(path.last);
    return res;
  }

  List<Offset> _dedup(List<Offset> pts) {
    final List<Offset> res = <Offset>[];
    for (final Offset p in pts) {
      if (res.isEmpty || res.last != p) res.add(p);
    }
    return res;
  }

  bool _isBlockedByObstacle(int index, double pointX, double pointY) {
    final double probeLeft = pointX;
    final double probeRight = pointX + _probeSize;
    final double probeTop = pointY;
    final double probeBottom = pointY + _probeSize;
    return _obstacleLeft[index] < probeRight && _obstacleRight[index] > probeLeft && _obstacleTop[index] < probeBottom && _obstacleBottom[index] > probeTop;
  }

  List<_SegmentData>? _buildSegments(List<Offset>? previousPath) {
    if (previousPath == null || previousPath.length < 2) {
      return null;
    }

    final List<_SegmentData> segments = <_SegmentData>[];
    for (int i = 0; i < previousPath.length - 1; i++) {
      final Offset a = previousPath[i];
      final Offset b = previousPath[i + 1];
      final double abx = b.dx - a.dx;
      final double aby = b.dy - a.dy;
      segments.add(
        _SegmentData(
          ax: a.dx,
          ay: a.dy,
          bx: b.dx,
          by: b.dy,
          abx: abx,
          aby: aby,
          lengthSquared: abx * abx + aby * aby,
        ),
      );
    }
    return segments;
  }

  double _continuityPenalty(Offset p, List<_SegmentData>? previousSegments) {
    if (previousSegments == null || previousSegments.isEmpty) {
      return 0;
    }

    final double distance = _distanceToPolyline(p, previousSegments);
    return min(distance, 80) * 0.25;
  }

  double _distanceToPolyline(Offset p, List<_SegmentData> segments) {
    double best = double.infinity;
    for (final _SegmentData segment in segments) {
      final double d = _distanceToSegment(p, segment);
      if (d < best) {
        best = d;
      }
    }
    return best.isFinite ? best : 0;
  }

  double _distanceToSegment(Offset p, _SegmentData segment) {
    final double pax = p.dx - segment.ax;
    final double pay = p.dy - segment.ay;

    if (segment.lengthSquared == 0) {
      return sqrt(pax * pax + pay * pay);
    }

    final double t = (pax * segment.abx + pay * segment.aby) / segment.lengthSquared;
    if (t <= 0) {
      return sqrt(pax * pax + pay * pay);
    }
    if (t >= 1) {
      final double pbx = p.dx - segment.bx;
      final double pby = p.dy - segment.by;
      return sqrt(pbx * pbx + pby * pby);
    }

    final double projX = segment.ax + segment.abx * t;
    final double projY = segment.ay + segment.aby * t;
    final double dx = p.dx - projX;
    final double dy = p.dy - projY;
    return sqrt(dx * dx + dy * dy);
  }
}
