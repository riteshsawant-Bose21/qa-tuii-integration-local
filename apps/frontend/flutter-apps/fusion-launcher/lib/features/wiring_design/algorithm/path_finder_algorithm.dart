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
  const _Node(this.p, this.f, this.parent);
  final Offset p;
  final double f;
  final Offset? parent;

  @override
  int compareTo(_Node other) => f.compareTo(other.f);
}

class OrthogonalRouter {
  OrthogonalRouter(this.obstacles);
  final List<Rect> obstacles;

  double get padding => 10;
  double get spacing => 10;
  Rect _expandPoint(Offset p) => p & const Size(50, 50);
  bool _isBlocked(Offset p) =>
      obstacles.any((Rect r) => r.overlaps(_expandPoint(p)));

  double _manhattan(Offset a, Offset b) =>
      (a.dx - b.dx).abs() + (a.dy - b.dy).abs();

  Offset _snapOutside(Offset p) {
    for (final Rect r in obstacles) {
      if (r.overlaps(_expandPoint(p))) {
        final Offset left = Offset(r.left - padding, p.dy);
        final Offset right = Offset(r.right + padding, p.dy);
        final Offset top = Offset(p.dx, r.top - padding);
        final Offset bottom = Offset(p.dx, r.bottom + padding);
        final List<Offset> candidates = <Offset>[left, right, top, bottom];
        candidates.sort(
          (Offset a, Offset b) => _manhattan(p, a).compareTo(_manhattan(p, b)),
        );
        return candidates.first;
      }
    }
    return p;
  }

  /// Public API: finds a path through optional stops
  List<Offset> findPath(
    Offset start,
    Offset end, {
    List<Offset> stops = const <Offset>[],
  }) {
    final List<Offset> points = <Offset>[start, ...stops, end];
    final List<Offset> result = <Offset>[];

    for (int i = 0; i < points.length - 1; i++) {
      final List<Offset> seg = _findPathSegment(points[i], points[i + 1]);
      if (seg.isEmpty) return <Offset>[];
      if (result.isNotEmpty) {
        result.removeLast(); // avoid duplicating joints
      }
      result.addAll(seg);
    }
    return result;
  }

  List<Offset> _findPathSegment(Offset start, Offset end) {
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
      final List<double> columnYs =
          ysList.where((double y) => nodes.contains(Offset(x, y))).toList();
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
      final List<double> rowXs =
          xsList.where((double x) => nodes.contains(Offset(x, y))).toList();
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
    final Map<Offset, Offset> cameFrom = <Offset, Offset>{};
    final Set<Offset> closed = <Offset>{};
    final PriorityQueue<_Node> open = PriorityQueue<_Node>();

    for (final Offset n in nodes) gScore[n] = INF;
    gScore[actualStart] = 0;
    open.add(_Node(actualStart, _manhattan(actualStart, actualEnd), null));

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
        double penalty = 0;
        if (cameFrom.containsKey(cur)) {
          final Offset prev = cameFrom[cur]!;
          final bool wasVertical = prev.dx == cur.dx;
          final bool nowVertical = cur.dx == nb.dx;
          if (wasVertical != nowVertical) {
            penalty = 50; // large enough to strongly discourage extra turns
          }
        }

        final double newCost = tentative + penalty;
        if (newCost < (gScore[nb] ?? INF)) {
          cameFrom[nb] = cur;
          gScore[nb] = newCost;
          final double f = newCost + _manhattan(nb, actualEnd);
          open.add(_Node(nb, f, cur));
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
      final bool straight =
          (prev.dx == curr.dx && curr.dx == next.dx) ||
          (prev.dy == curr.dy && curr.dy == next.dy);
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
}
