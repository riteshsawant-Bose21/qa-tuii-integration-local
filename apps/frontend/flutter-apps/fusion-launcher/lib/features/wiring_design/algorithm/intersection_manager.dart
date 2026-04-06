import 'package:flutter/material.dart';

class IntersectionManager {
  static const double _epsilon = 0.001;

  String _lastSignature = '';
  final Map<String, List<Offset>> _jumpPointsByConnection = <String, List<Offset>>{};
  final Map<String, List<Offset>> _cutPointsByConnection = <String, List<Offset>>{};
  void removeKeysExcept(Set<String> keysToKeep) {
    _jumpPointsByConnection.removeWhere((String key, _) => !keysToKeep.contains(key));
    _cutPointsByConnection.removeWhere((String key, _) => !keysToKeep.contains(key));
  }

  List<Offset> jumpPointsForConnection(String connectionId, Map<String, List<Offset>> polylines) {
    final String signature = _signatureOf(polylines);
    if (_lastSignature != signature) {
      _recompute(polylines);
      _lastSignature = signature;
    }
    return _jumpPointsByConnection[connectionId] ?? <Offset>[];
  }

  List<Offset> cutPointsForConnection(String connectionId, Map<String, List<Offset>> polylines) {
    final String signature = _signatureOf(polylines);
    if (_lastSignature != signature) {
      _recompute(polylines);
      _lastSignature = signature;
    }
    return _cutPointsByConnection[connectionId] ?? <Offset>[];
  }

  void _recompute(Map<String, List<Offset>> polylines) {
    _jumpPointsByConnection.clear();
    _cutPointsByConnection.clear();

    final List<_ConnectionSegment> segments = <_ConnectionSegment>[];
    polylines.forEach((String connectionId, List<Offset> points) {
      for (int i = 0; i < points.length - 1; i++) {
        final Offset start = points[i];
        final Offset end = points[i + 1];
        if (_orientationOf(start, end) == _SegmentOrientation.diagonal) {
          continue;
        }
        segments.add(
          _ConnectionSegment(
            connectionId: connectionId,
            start: start,
            end: end,
          ),
        );
      }
    });

    for (int i = 0; i < segments.length; i++) {
      final _ConnectionSegment a = segments[i];
      for (int j = i + 1; j < segments.length; j++) {
        final _ConnectionSegment b = segments[j];
        if (a.connectionId == b.connectionId) {
          continue;
        }
        final Offset? intersection = _intersectionBetween(a, b);
        if (intersection == null) {
          continue;
        }

        final String jumperId = _pickJumper(a.connectionId, b.connectionId, intersection);
        final String straightId = jumperId == a.connectionId ? b.connectionId : a.connectionId;

        _addUniquePoint(_jumpPointsByConnection, jumperId, intersection);
        _addUniquePoint(_cutPointsByConnection, straightId, intersection);
      }
    }
  }

  void _addUniquePoint(Map<String, List<Offset>> target, String connectionId, Offset point) {
    final List<Offset> points = target.putIfAbsent(connectionId, () => <Offset>[]);
    if (points.any((Offset p) => _isSamePoint(p, point))) {
      return;
    }
    points.add(point);
  }

  String _pickJumper(String first, String second, Offset point) {
    final String combinedA = '$first@${point.dx.toStringAsFixed(3)}:${point.dy.toStringAsFixed(3)}';
    final String combinedB = '$second@${point.dx.toStringAsFixed(3)}:${point.dy.toStringAsFixed(3)}';
    return combinedA.compareTo(combinedB) <= 0 ? first : second;
  }

  Offset? _intersectionBetween(_ConnectionSegment a, _ConnectionSegment b) {
    final _SegmentOrientation aOrientation = _orientationOf(a.start, a.end);
    final _SegmentOrientation bOrientation = _orientationOf(b.start, b.end);

    if (aOrientation == bOrientation || aOrientation == _SegmentOrientation.diagonal || bOrientation == _SegmentOrientation.diagonal) {
      return null;
    }

    final _ConnectionSegment horizontal = aOrientation == _SegmentOrientation.horizontal ? a : b;
    final _ConnectionSegment vertical = aOrientation == _SegmentOrientation.vertical ? a : b;

    final double x = vertical.start.dx;
    final double y = horizontal.start.dy;

    final double horizontalMinX = _min(horizontal.start.dx, horizontal.end.dx);
    final double horizontalMaxX = _max(horizontal.start.dx, horizontal.end.dx);
    final double verticalMinY = _min(vertical.start.dy, vertical.end.dy);
    final double verticalMaxY = _max(vertical.start.dy, vertical.end.dy);

    final bool isInsideHorizontal = x > horizontalMinX + _epsilon && x < horizontalMaxX - _epsilon;
    final bool isInsideVertical = y > verticalMinY + _epsilon && y < verticalMaxY - _epsilon;

    if (!isInsideHorizontal || !isInsideVertical) {
      return null;
    }

    return Offset(x, y);
  }

  _SegmentOrientation _orientationOf(Offset start, Offset end) {
    if ((start.dx - end.dx).abs() <= _epsilon) {
      return _SegmentOrientation.vertical;
    }
    if ((start.dy - end.dy).abs() <= _epsilon) {
      return _SegmentOrientation.horizontal;
    }
    return _SegmentOrientation.diagonal;
  }

  String _signatureOf(Map<String, List<Offset>> polylines) {
    final List<String> keys = polylines.keys.toList()..sort();
    final StringBuffer buffer = StringBuffer();
    for (final String key in keys) {
      buffer.write('$key|');
      final List<Offset> points = polylines[key] ?? <Offset>[];
      for (final Offset point in points) {
        buffer.write('${point.dx.toStringAsFixed(2)},${point.dy.toStringAsFixed(2)};');
      }
      buffer.write('#');
    }
    return buffer.toString();
  }

  bool _isSamePoint(Offset a, Offset b) {
    return (a.dx - b.dx).abs() <= _epsilon && (a.dy - b.dy).abs() <= _epsilon;
  }

  double _min(double a, double b) => a < b ? a : b;
  double _max(double a, double b) => a > b ? a : b;
}

enum _SegmentOrientation { horizontal, vertical, diagonal }

class _ConnectionSegment {
  const _ConnectionSegment({
    required this.connectionId,
    required this.start,
    required this.end,
  });

  final String connectionId;
  final Offset start;
  final Offset end;
}
