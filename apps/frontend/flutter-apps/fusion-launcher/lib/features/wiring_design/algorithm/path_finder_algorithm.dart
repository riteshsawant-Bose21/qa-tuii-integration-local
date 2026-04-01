import 'dart:math';
import 'dart:ui';

import 'package:collection/collection.dart';

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

class OrthogonalRouter {
  OrthogonalRouter(this.obstacles);
  final List<Rect> obstacles;

  double get padding => 10;
  double get spacing => 10;
  Rect _expandPoint(Offset p) => p & const Size(50, 50);
  bool _isBlocked(Offset p) => obstacles.any((Rect r) => r.overlaps(_expandPoint(p)));

  double _manhattan(Offset a, Offset b) => (a.dx - b.dx).abs() + (a.dy - b.dy).abs();

  Offset _snapOutside(Offset p) {
    const double tieTolerance = 0.1;
    for (final Rect r in obstacles) {
      if (r.overlaps(_expandPoint(p))) {
        final List<Offset> candidates = <Offset>[
          Offset(r.left - padding, p.dy),
          Offset(r.right + padding, p.dy),
          Offset(p.dx, r.top - padding),
          Offset(p.dx, r.bottom + padding),
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

  /// Public API: finds a path through optional stops
  List<Offset> findPath(
    Offset start,
    Offset end, {
    List<Offset> stops = const <Offset>[],
    List<Offset>? previousPath,
  }) {
    final List<Offset> points = <Offset>[start, ...stops, end];
    final List<Offset> result = <Offset>[];

    for (int i = 0; i < points.length - 1; i++) {
      final List<Offset> seg = _findPathSegment(
        points[i],
        points[i + 1],
        previousPath: previousPath,
      );
      if (seg.isEmpty) return <Offset>[];
      if (result.isNotEmpty) {
        result.removeLast(); // avoid duplicating joints
      }
      result.addAll(seg);
    }
    return result;
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
    for (final double x in xsList) {
      for (final double y in ysList) {
        final Offset p = Offset(x, y);
        if (!_isBlocked(p)) nodes.add(p);
      }
    }
    nodes.add(actualStart);
    nodes.add(actualEnd);

    bool verticalClear(double x, double y1, double y2) {
      final double top = min(y1, y2);
      final double bottom = max(y1, y2);
      for (final Rect r in obstacles) {
        if (x >= r.left && x <= r.right && bottom >= r.top && top <= r.bottom) {
          return false;
        }
      }
      return true;
    }

    bool horizontalClear(double y, double x1, double x2) {
      final double left = min(x1, x2);
      final double right = max(x1, x2);
      for (final Rect r in obstacles) {
        if (y >= r.top && y <= r.bottom && right >= r.left && left <= r.right) {
          return false;
        }
      }
      return true;
    }

    final Map<Offset, List<Offset>> neighbors = <Offset, List<Offset>>{};
    for (final double x in xsList) {
      final List<double> columnYs = ysList.where((double y) => nodes.contains(Offset(x, y))).toList();
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
      final List<double> rowXs = xsList.where((double x) => nodes.contains(Offset(x, y))).toList();
      for (int i = 0; i < rowXs.length - 1; i++) {
        final Offset p1 = Offset(rowXs[i], y);
        final Offset p2 = Offset(rowXs[i + 1], y);
        if (horizontalClear(y, rowXs[i], rowXs[i + 1])) {
          neighbors.putIfAbsent(p1, () => <Offset>[]).add(p2);
          neighbors.putIfAbsent(p2, () => <Offset>[]).add(p1);
        }
      }
    }

    const double INF = 1e9;
    final Map<Offset, double> gScore = <Offset, double>{};
    final Map<Offset, int> turnScore = <Offset, int>{};
    final Map<Offset, Offset> cameFrom = <Offset, Offset>{};
    final Set<Offset> closed = <Offset>{};
    final PriorityQueue<_Node> open = PriorityQueue<_Node>();

    for (final Offset n in nodes) {
      gScore[n] = INF;
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
      for (final Offset nb in neighbors[cur] ?? <Offset>[]) {
        if (closed.contains(nb)) continue;

        final double tentative = gScore[cur]! + _manhattan(cur, nb);

        // Add turn penalty if direction changes
        double turnPenalty = 0;
        int turns = turnScore[cur]!;
        if (cameFrom.containsKey(cur)) {
          final Offset prev = cameFrom[cur]!;
          final bool wasVertical = prev.dx == cur.dx;
          final bool nowVertical = cur.dx == nb.dx;
          if (wasVertical != nowVertical) {
            turnPenalty = 50;
            turns += 1;
          }
        }

        final double continuityPenalty = _continuityPenalty(nb, previousPath);
        final double newCost = tentative + turnPenalty + continuityPenalty;
        final double oldCost = gScore[nb] ?? INF;
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

  double _continuityPenalty(Offset p, List<Offset>? previousPath) {
    if (previousPath == null || previousPath.length < 2) {
      return 0;
    }

    final double distance = _distanceToPolyline(p, previousPath);
    return min(distance, 80) * 0.25;
  }

  double _distanceToPolyline(Offset p, List<Offset> polyline) {
    double best = double.infinity;
    for (int i = 0; i < polyline.length - 1; i++) {
      final double d = _distanceToSegment(p, polyline[i], polyline[i + 1]);
      if (d < best) {
        best = d;
      }
    }
    return best.isFinite ? best : 0;
  }

  double _distanceToSegment(Offset p, Offset a, Offset b) {
    final double lengthSquared = (b - a).distanceSquared;
    if (lengthSquared == 0) {
      return (p - a).distance;
    }
    final double t = ((p - a).dx * (b - a).dx + (p - a).dy * (b - a).dy) / lengthSquared;
    if (t <= 0) {
      return (p - a).distance;
    }
    if (t >= 1) {
      return (p - b).distance;
    }
    final Offset projection = a + (b - a) * t;
    return (p - projection).distance;
  }
}
