import 'dart:math';
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:fusion_lib/fusion_lib.dart';

class OrthogonalPathService {
  static const double _epsilon = 1e-6;
  static const double _obstaclePadding = 1.0;
  static const double _coordMergeTolerance = 0.01;

  Offset _snapOutside(Offset p, List<Rect> obstacles) {
    final int padding = 10;
    const double tieTolerance = 0.1;
    for (int i = 0; i < obstacles.length; i++) {
      if (_isBlockedPoint(p, obstacles, <_Segment>[])) {
        final double left = obstacles[i].left;
        final double right = obstacles[i].right;
        final double top = obstacles[i].top;
        final double bottom = obstacles[i].bottom;
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

  double _manhattan(Offset a, Offset b) => (a.dx - b.dx).abs() + (a.dy - b.dy).abs();

  List<Offset> findPath({
    required Offset start,
    required Offset end,
    required List<Rect> obstacles,
    required List<AxisLock> axisLocks,
    required List<List<Offset>> otherPaths,
    List<Offset>? previousPath,
  }) {
    final Offset adjustedStart = _snapOutside(start, obstacles);
    final Offset adjustedEnd = _snapOutside(end, obstacles);

    if (_arePointsEqual(adjustedStart, adjustedEnd)) {
      return <Offset>[adjustedStart, adjustedEnd];
    }

    final List<AxisLock> validLocks = _compressAxisLocks(
      axisLocks.where(_isValidAxisLock).toList(growable: false),
    );
    final List<_Segment> blockedPathSegments = _buildSegments(otherPaths);
    final List<_Segment> previousSegments = _buildSegments(<List<Offset>>[
      if (previousPath != null) previousPath,
    ]);

    final Set<double> xSet = <double>{};
    final Set<double> ySet = <double>{};

    _addCoord(xSet, adjustedStart.dx);
    _addCoord(ySet, adjustedStart.dy);
    _addCoord(xSet, adjustedEnd.dx);
    _addCoord(ySet, adjustedEnd.dy);

    for (final AxisLock lock in validLocks) {
      if (lock.x != null) {
        _addCoord(xSet, lock.x!);
      }
      if (lock.y != null) {
        _addCoord(ySet, lock.y!);
      }
    }

    for (final Rect obstacle in obstacles) {
      _addCoord(xSet, obstacle.left - _obstaclePadding);
      _addCoord(xSet, obstacle.right + _obstaclePadding);
      _addCoord(ySet, obstacle.top - _obstaclePadding);
      _addCoord(ySet, obstacle.bottom + _obstaclePadding);
      _addCoord(xSet, obstacle.left);
      _addCoord(xSet, obstacle.right);
      _addCoord(ySet, obstacle.top);
      _addCoord(ySet, obstacle.bottom);
    }

    for (final _Segment blocked in blockedPathSegments) {
      _addCoord(xSet, blocked.a.dx);
      _addCoord(ySet, blocked.a.dy);
      _addCoord(xSet, blocked.b.dx);
      _addCoord(ySet, blocked.b.dy);
    }

    for (final _Segment previous in previousSegments) {
      _addCoord(xSet, previous.a.dx);
      _addCoord(ySet, previous.a.dy);
      _addCoord(xSet, previous.b.dx);
      _addCoord(ySet, previous.b.dy);
    }

    final List<double> xs = _compactSortedCoords(xSet.toList()..sort());
    final List<double> ys = _compactSortedCoords(ySet.toList()..sort());

    final List<Offset> nodes = <Offset>[];
    final Map<String, int> nodeIndex = <String, int>{};

    void addNode(Offset p, {bool force = false}) {
      final String key = _pointKey(p);
      if (nodeIndex.containsKey(key)) {
        return;
      }
      if (!force && _isBlockedPoint(p, obstacles, blockedPathSegments)) {
        return;
      }
      nodeIndex[key] = nodes.length;
      nodes.add(p);
    }

    for (final double x in xs) {
      for (final double y in ys) {
        addNode(Offset(x, y));
      }
    }

    addNode(adjustedStart, force: true);
    addNode(adjustedEnd, force: true);

    final int? startIndex = nodeIndex[_pointKey(adjustedStart)];
    final int? endIndex = nodeIndex[_pointKey(adjustedEnd)];
    if (startIndex == null || endIndex == null) {
      return <Offset>[adjustedStart, adjustedEnd];
    }

    final List<List<_Edge>> adjacency = List<List<_Edge>>.generate(
      nodes.length,
      (_) => <_Edge>[],
      growable: false,
    );

    final Map<double, List<int>> byX = <double, List<int>>{};
    final Map<double, List<int>> byY = <double, List<int>>{};
    for (int i = 0; i < nodes.length; i++) {
      final Offset p = nodes[i];
      byX.putIfAbsent(_normalizeCoord(p.dx), () => <int>[]).add(i);
      byY.putIfAbsent(_normalizeCoord(p.dy), () => <int>[]).add(i);
    }

    void connect(int a, int b) {
      final Offset p1 = nodes[a];
      final Offset p2 = nodes[b];
      if (!_isOrthogonal(p1, p2)) {
        return;
      }
      final _Segment segment = _Segment(p1, p2);
      if (!_isValidSegment(segment, obstacles, blockedPathSegments)) {
        return;
      }
      final double distance = (p1.dx - p2.dx).abs() + (p1.dy - p2.dy).abs();
      adjacency[a].add(_Edge(to: b, length: distance, segment: segment));
      adjacency[b].add(_Edge(to: a, length: distance, segment: segment));
    }

    for (final List<int> indices in byX.values) {
      indices.sort((int a, int b) => nodes[a].dy.compareTo(nodes[b].dy));
      for (int i = 0; i < indices.length - 1; i++) {
        connect(indices[i], indices[i + 1]);
      }
    }

    for (final List<int> indices in byY.values) {
      indices.sort((int a, int b) => nodes[a].dx.compareTo(nodes[b].dx));
      for (int i = 0; i < indices.length - 1; i++) {
        connect(indices[i], indices[i + 1]);
      }
    }

    final int requiredLockProgress = validLocks.length;
    const int directionCount = 3;
    final int progressSpan = (requiredLockProgress + 1) * directionCount;

    int encodeState(int node, int progress, int direction) {
      return (node * progressSpan) + (progress * directionCount) + direction;
    }

    int decodeNode(int state) {
      return state ~/ progressSpan;
    }

    final PriorityQueue<_QueueEntry> queue = PriorityQueue<_QueueEntry>(_compareQueueEntry);
    final Map<int, _Cost> bestCost = <int, _Cost>{};
    final Map<int, int> previousState = <int, int>{};

    const int noDirection = 0;
    final int startState = encodeState(startIndex, 0, noDirection);
    const _Cost startCost = _Cost(length: 0.0, turns: 0, stability: 0.0);
    bestCost[startState] = startCost;
    queue.add(_QueueEntry(node: startIndex, lockProgress: 0, direction: noDirection, cost: startCost));

    int? winningState;

    while (queue.isNotEmpty) {
      final _QueueEntry current = queue.removeFirst();
      final int currentState = encodeState(current.node, current.lockProgress, current.direction);
      final _Cost? known = bestCost[currentState];
      if (known == null || _compareCost(current.cost, known) > 0) {
        continue;
      }

      if (current.node == endIndex && current.lockProgress == requiredLockProgress) {
        winningState = currentState;
        break;
      }

      for (final _Edge edge in adjacency[current.node]) {
        final int nextDirection = edge.segment.isHorizontal ? 1 : 2;
        final int turnCost = (current.direction == noDirection || current.direction == nextDirection) ? 0 : 1;
        final int nextProgress = _advanceLockProgress(edge.segment, current.lockProgress, validLocks);
        final _Cost nextCost = _Cost(
          length: current.cost.length + edge.length,
          turns: current.cost.turns + turnCost,
          stability: current.cost.stability + _stabilityPenaltyForSegment(edge.segment, previousSegments),
        );
        final int nextState = encodeState(edge.to, nextProgress, nextDirection);
        final _Cost? oldCost = bestCost[nextState];
        if (oldCost == null || _compareCost(nextCost, oldCost) < 0) {
          bestCost[nextState] = nextCost;
          previousState[nextState] = currentState;
          queue.add(_QueueEntry(node: edge.to, lockProgress: nextProgress, direction: nextDirection, cost: nextCost));
        }
      }
    }

    if (winningState == null) {
      return <Offset>[adjustedStart, adjustedEnd];
    }

    final List<Offset> reconstructed = <Offset>[];
    int state = winningState;
    while (true) {
      reconstructed.add(nodes[decodeNode(state)]);
      final int? previous = previousState[state];
      if (previous == null) {
        break;
      }
      state = previous;
    }

    return _simplifyPath(reconstructed.reversed.toList(growable: false));
  }

  static bool _isValidAxisLock(AxisLock lock) {
    final bool hasX = lock.x != null;
    final bool hasY = lock.y != null;
    return hasX != hasY;
  }

  static List<AxisLock> _compressAxisLocks(List<AxisLock> locks) {
    if (locks.isEmpty) {
      return locks;
    }

    final List<AxisLock> compressed = <AxisLock>[];
    for (final AxisLock lock in locks) {
      if (compressed.isEmpty) {
        compressed.add(lock);
        continue;
      }

      final AxisLock previous = compressed.last;
      final bool sameVertical = previous.x != null && lock.x != null && (previous.x! - lock.x!).abs() <= _coordMergeTolerance;
      final bool sameHorizontal = previous.y != null && lock.y != null && (previous.y! - lock.y!).abs() <= _coordMergeTolerance;

      if (sameVertical || sameHorizontal) {
        continue;
      }
      compressed.add(lock);
    }

    return compressed;
  }

  static List<double> _compactSortedCoords(List<double> sortedCoords) {
    if (sortedCoords.length <= 1) {
      return sortedCoords;
    }

    final List<double> compacted = <double>[sortedCoords.first];
    for (int i = 1; i < sortedCoords.length; i++) {
      final double value = sortedCoords[i];
      if ((value - compacted.last).abs() <= _coordMergeTolerance) {
        continue;
      }
      compacted.add(value);
    }
    return compacted;
  }

  static bool _isOrthogonal(Offset a, Offset b) {
    return _isClose(a.dx, b.dx) || _isClose(a.dy, b.dy);
  }

  static List<_Segment> _buildSegments(List<List<Offset>> paths) {
    final List<_Segment> segments = <_Segment>[];
    for (final List<Offset> path in paths) {
      if (path.length < 2) {
        continue;
      }
      for (int i = 0; i < path.length - 1; i++) {
        final Offset a = path[i];
        final Offset b = path[i + 1];
        if (_arePointsEqual(a, b)) {
          continue;
        }
        segments.add(_Segment(a, b));
      }
    }
    return segments;
  }

  static bool _isBlockedPoint(Offset p, List<Rect> obstacles, List<_Segment> blockedSegments) {
    for (final Rect obstacle in obstacles) {
      if (_pointInRectInclusive(p, obstacle)) {
        return true;
      }
    }
    for (final _Segment blocked in blockedSegments) {
      if (_pointOnSegmentInclusive(p, blocked)) {
        return true;
      }
    }
    return false;
  }

  static bool _isValidSegment(_Segment candidate, List<Rect> obstacles, List<_Segment> blockedSegments) {
    if (!candidate.isHorizontal && !candidate.isVertical) {
      return false;
    }

    for (final Rect obstacle in obstacles) {
      if (_segmentTouchesRectInclusive(candidate, obstacle)) {
        return false;
      }
    }

    for (final _Segment blocked in blockedSegments) {
      if (_segmentsIntersectInclusive(candidate, blocked)) {
        return false;
      }
    }

    return true;
  }

  static int _advanceLockProgress(_Segment segment, int lockProgress, List<AxisLock> locks) {
    int progress = lockProgress;
    while (progress < locks.length && _segmentSatisfiesLock(segment, locks[progress])) {
      progress += 1;
    }
    return progress;
  }

  static bool _segmentSatisfiesLock(_Segment segment, AxisLock lock) {
    if (lock.x != null && segment.isVertical && _isClose(segment.a.dx, lock.x!)) {
      return true;
    }
    if (lock.y != null && segment.isHorizontal && _isClose(segment.a.dy, lock.y!)) {
      return true;
    }
    return false;
  }

  static int _compareQueueEntry(_QueueEntry a, _QueueEntry b) {
    final int byCost = _compareCost(a.cost, b.cost);
    if (byCost != 0) {
      return byCost;
    }
    final int byNode = a.node.compareTo(b.node);
    if (byNode != 0) {
      return byNode;
    }
    final int byProgress = a.lockProgress.compareTo(b.lockProgress);
    if (byProgress != 0) {
      return byProgress;
    }
    return a.direction.compareTo(b.direction);
  }

  static int _compareCost(_Cost a, _Cost b) {
    final int byTurns = a.turns.compareTo(b.turns);
    if (byTurns != 0) {
      return byTurns;
    }
    final int byLength = a.length.compareTo(b.length);
    if (byLength != 0) {
      return byLength;
    }
    return a.stability.compareTo(b.stability);
  }

  static double _stabilityPenaltyForSegment(_Segment candidate, List<_Segment> previousSegments) {
    if (previousSegments.isEmpty) {
      return 0.0;
    }

    for (final _Segment previous in previousSegments) {
      if (_collinearOverlapLength(candidate, previous) > _epsilon) {
        return 0.0;
      }
    }

    final Offset midpoint = Offset((candidate.a.dx + candidate.b.dx) / 2, (candidate.a.dy + candidate.b.dy) / 2);
    double bestDistance = double.infinity;

    for (final _Segment previous in previousSegments) {
      final double d1 = _distancePointToSegment(candidate.a, previous);
      final double d2 = _distancePointToSegment(candidate.b, previous);
      final double dMid = _distancePointToSegment(midpoint, previous);
      bestDistance = min(bestDistance, min(d1, min(d2, dMid)));
    }

    if (bestDistance.isInfinite) {
      return 0.0;
    }
    return bestDistance;
  }

  static double _collinearOverlapLength(_Segment a, _Segment b) {
    if (a.isHorizontal && b.isHorizontal && _isClose(a.a.dy, b.a.dy)) {
      final double overlapStart = max(min(a.a.dx, a.b.dx), min(b.a.dx, b.b.dx));
      final double overlapEnd = min(max(a.a.dx, a.b.dx), max(b.a.dx, b.b.dx));
      return max(0.0, overlapEnd - overlapStart);
    }
    if (a.isVertical && b.isVertical && _isClose(a.a.dx, b.a.dx)) {
      final double overlapStart = max(min(a.a.dy, a.b.dy), min(b.a.dy, b.b.dy));
      final double overlapEnd = min(max(a.a.dy, a.b.dy), max(b.a.dy, b.b.dy));
      return max(0.0, overlapEnd - overlapStart);
    }
    return 0.0;
  }

  static double _distancePointToSegment(Offset point, _Segment segment) {
    if (segment.isHorizontal) {
      final double minX = min(segment.a.dx, segment.b.dx);
      final double maxX = max(segment.a.dx, segment.b.dx);
      final double clampedX = point.dx.clamp(minX, maxX);
      final double dx = point.dx - clampedX;
      final double dy = point.dy - segment.a.dy;
      return sqrt(dx * dx + dy * dy);
    }

    final double minY = min(segment.a.dy, segment.b.dy);
    final double maxY = max(segment.a.dy, segment.b.dy);
    final double clampedY = point.dy.clamp(minY, maxY);
    final double dx = point.dx - segment.a.dx;
    final double dy = point.dy - clampedY;
    return sqrt(dx * dx + dy * dy);
  }

  static bool _segmentTouchesRectInclusive(_Segment segment, Rect rect) {
    if (segment.isHorizontal) {
      final double y = segment.a.dy;
      if (y < rect.top - _epsilon || y > rect.bottom + _epsilon) {
        return false;
      }
      final double x1 = min(segment.a.dx, segment.b.dx);
      final double x2 = max(segment.a.dx, segment.b.dx);
      return _rangesOverlapInclusive(x1, x2, rect.left, rect.right);
    }
    final double x = segment.a.dx;
    if (x < rect.left - _epsilon || x > rect.right + _epsilon) {
      return false;
    }
    final double y1 = min(segment.a.dy, segment.b.dy);
    final double y2 = max(segment.a.dy, segment.b.dy);
    return _rangesOverlapInclusive(y1, y2, rect.top, rect.bottom);
  }

  static bool _segmentsIntersectInclusive(_Segment s1, _Segment s2) {
    final Offset p1 = s1.a;
    final Offset q1 = s1.b;
    final Offset p2 = s2.a;
    final Offset q2 = s2.b;

    final double o1 = _orientation(p1, q1, p2);
    final double o2 = _orientation(p1, q1, q2);
    final double o3 = _orientation(p2, q2, p1);
    final double o4 = _orientation(p2, q2, q1);

    if ((o1 > _epsilon && o2 < -_epsilon || o1 < -_epsilon && o2 > _epsilon) && (o3 > _epsilon && o4 < -_epsilon || o3 < -_epsilon && o4 > _epsilon)) {
      return true;
    }

    if (_isClose(o1, 0) && _pointOnRawSegmentInclusive(p2, p1, q1)) {
      return true;
    }
    if (_isClose(o2, 0) && _pointOnRawSegmentInclusive(q2, p1, q1)) {
      return true;
    }
    if (_isClose(o3, 0) && _pointOnRawSegmentInclusive(p1, p2, q2)) {
      return true;
    }
    if (_isClose(o4, 0) && _pointOnRawSegmentInclusive(q1, p2, q2)) {
      return true;
    }

    return false;
  }

  static bool _pointOnSegmentInclusive(Offset point, _Segment segment) {
    return _pointOnRawSegmentInclusive(point, segment.a, segment.b);
  }

  static bool _pointOnRawSegmentInclusive(Offset point, Offset a, Offset b) {
    final double cross = _orientation(a, b, point).abs();
    if (cross > _epsilon) {
      return false;
    }

    final double minX = min(a.dx, b.dx) - _epsilon;
    final double maxX = max(a.dx, b.dx) + _epsilon;
    final double minY = min(a.dy, b.dy) - _epsilon;
    final double maxY = max(a.dy, b.dy) + _epsilon;

    return point.dx >= minX && point.dx <= maxX && point.dy >= minY && point.dy <= maxY;
  }

  static double _orientation(Offset a, Offset b, Offset c) {
    return (b.dy - a.dy) * (c.dx - b.dx) - (b.dx - a.dx) * (c.dy - b.dy);
  }

  static bool _pointInRectInclusive(Offset point, Rect rect) {
    return point.dx >= rect.left - _epsilon && point.dx <= rect.right + _epsilon && point.dy >= rect.top - _epsilon && point.dy <= rect.bottom + _epsilon;
  }

  static bool _rangesOverlapInclusive(double a1, double a2, double b1, double b2) {
    final double left = max(min(a1, a2), min(b1, b2));
    final double right = min(max(a1, a2), max(b1, b2));
    return left <= right + _epsilon;
  }

  static List<Offset> _simplifyPath(List<Offset> path) {
    if (path.length <= 2) {
      return path;
    }

    final List<Offset> simplified = <Offset>[path.first];
    for (int i = 1; i < path.length - 1; i++) {
      final Offset prev = simplified.last;
      final Offset current = path[i];
      final Offset next = path[i + 1];
      final bool sameX = _isClose(prev.dx, current.dx) && _isClose(current.dx, next.dx);
      final bool sameY = _isClose(prev.dy, current.dy) && _isClose(current.dy, next.dy);
      if (sameX || sameY) {
        continue;
      }
      simplified.add(current);
    }
    simplified.add(path.last);
    return simplified;
  }

  static String _pointKey(Offset p) => '${_normalizeCoord(p.dx)},${_normalizeCoord(p.dy)}';

  static bool _arePointsEqual(Offset a, Offset b) {
    return _isClose(a.dx, b.dx) && _isClose(a.dy, b.dy);
  }

  static bool _isClose(double a, double b) => (a - b).abs() <= _epsilon;

  static double _normalizeCoord(double value) {
    return double.parse(value.toStringAsFixed(6));
  }

  static void _addCoord(Set<double> set, double value) {
    set.add(_normalizeCoord(value));
  }
}

class _Segment {
  final Offset a;
  final Offset b;

  const _Segment(this.a, this.b);

  bool get isHorizontal => (a.dy - b.dy).abs() <= OrthogonalPathService._epsilon;
  bool get isVertical => (a.dx - b.dx).abs() <= OrthogonalPathService._epsilon;
}

class _Edge {
  final int to;
  final double length;
  final _Segment segment;

  const _Edge({required this.to, required this.length, required this.segment});
}

class _Cost {
  final double length;
  final int turns;
  final double stability;

  const _Cost({required this.length, required this.turns, required this.stability});
}

class _QueueEntry {
  final int node;
  final int lockProgress;
  final int direction;
  final _Cost cost;

  const _QueueEntry({required this.node, required this.lockProgress, required this.direction, required this.cost});
}
