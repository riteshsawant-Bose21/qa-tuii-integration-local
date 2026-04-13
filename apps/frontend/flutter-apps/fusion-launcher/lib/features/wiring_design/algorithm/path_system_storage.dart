import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/elements/fusion_canvas_element_painter.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/elements/wiring/port_painter.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_base_painter.dart' show FusionBasePainter;
import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_canvas_painter.dart';
import 'package:fusion_launcher/features/wiring_design/algorithm/path_finder_algorithm.dart';
import 'package:fusion_lib/fusion_lib.dart';

class PathSystemStorage {
  final Map<String, FusionPath> _paths = <String, FusionPath>{};
  final Map<String, FusionPath> _livePaths = <String, FusionPath>{};
  final Map<String, List<Offset>> _previousPolylines = <String, List<Offset>>{};
  final Map<String, _ConnectionPathMeta> _pathMeta = <String, _ConnectionPathMeta>{};
  final Map<String, List<AxisLock>> _pathAxisLocks = <String, List<AxisLock>>{};
  final Map<String, List<AxisLock>> _livePathAxisLocks = <String, List<AxisLock>>{};
  Duration? _obstacleCacheFrameTime;
  int? _obstacleCachePainterIdentity;
  List<Rect> _obstacleCache = <Rect>[];

  void removeKeysExcept(Set<String> keysToKeep) {
    _paths.removeWhere((String key, _) => !keysToKeep.contains(key));
    _livePaths.removeWhere((String key, _) => !keysToKeep.contains(key));
    _previousPolylines.removeWhere((String key, _) => !keysToKeep.contains(key));
    _pathMeta.removeWhere((String key, _) => !keysToKeep.contains(key));
    _pathAxisLocks.removeWhere((String key, _) => !keysToKeep.contains(key));
    _livePathAxisLocks.removeWhere((String key, _) => !keysToKeep.contains(key));
    _invalidateFrameCaches();
  }

  FusionPath? getPath(WiringConnectionModel connection, FusionCanvasPainter painter, [List<AxisLock>? additionalStops]) {
    final _ConnectionEndpoints? endpoints = _resolveConnectionEndpoints(connection, painter);
    if (endpoints == null) {
      return null;
    }

    final String key = _keyOf(connection);
    final FusionPath? path = _paths[key];
    final List<AxisLock> cachedLocks = _pathAxisLocks[key] ?? const <AxisLock>[];
    if (path != null) {
      if (path.start == endpoints.start && path.end == endpoints.end && _axisLocksEqual(cachedLocks, connection.axisLocks)) {
        return path;
      }
    }

    final FusionPath? constructPath = _constructPath(
      connection,
      painter,
      connectionKey: key,
      start: endpoints.start,
      end: endpoints.end,
      axisLocks: connection.axisLocks,
      previousAxisLocks: cachedLocks,
    );
    if (constructPath == null) {
      return null;
    }
    _storePath(key, connection, constructPath);
    return _paths[key];
  }

  FusionPath? getLivePath(WiringConnectionModel connection, FusionCanvasPainter painter, List<AxisLock> additionalStops, FusionPath? previousPath) {
    final _ConnectionEndpoints? endpoints = _resolveConnectionEndpoints(connection, painter);
    if (endpoints == null) {
      return null;
    }

    final String key = _keyOf(connection);
    final FusionPath? cachedLivePath = _livePaths[key];
    final List<AxisLock> cachedLiveLocks = _livePathAxisLocks[key] ?? const <AxisLock>[];
    if (cachedLivePath != null) {
      if (cachedLivePath.start == endpoints.start && cachedLivePath.end == endpoints.end && _axisLocksEqual(cachedLiveLocks, additionalStops)) {
        return cachedLivePath;
      }
    }

    final FusionPath? livePath = _constructPath(
      connection,
      painter,
      connectionKey: key,
      start: endpoints.start,
      end: endpoints.end,
      axisLocks: additionalStops,
      previousAxisLocks: cachedLiveLocks,
    );
    if (livePath == null) {
      return null;
    }
    _storeLivePath(key, connection, livePath, additionalStops);
    return livePath;
  }

  FusionPath? _constructPath(
    WiringConnectionModel connection,
    FusionCanvasPainter painter, {
    required String connectionKey,
    required Offset start,
    required Offset end,
    required List<AxisLock> axisLocks,
    required List<AxisLock> previousAxisLocks,
    // List<Offset> additionalStops = const <Offset>[],
  }) {
    final List<Rect> obstacles = _obstaclesForPainter(painter);
    final List<Offset>? previousPath = _previousPolylines[connectionKey];
    final List<Offset> pathPoints = _buildReconstructedPath(
      obstacles: obstacles,
      start: start,
      end: end,
      axisLocks: axisLocks,
      previousAxisLocks: previousAxisLocks,
      previousPath: previousPath,
    );
    final List<Offset> intermediatePoints = _extractIntermediatePoints(pathPoints, start, end);
    // print(
    //   "Calculated path for connection ${connection.id} in ${duration.inMilliseconds}ms",
    // );
    // print(
    //   "Constructed path for connection ${connection.id} with additional stops ${additionalStops.length}: start=$start, end=$end, intermediatePoints=$intermediatePoints",
    // );
    return FusionPath(
      start: start,
      end: end,
      points: List<FusionCanvasPoint>.generate(
        intermediatePoints.length,
        (int index) => FusionCanvasPoint(id: '${connection.id}_$index', position: intermediatePoints[index]),
      ),
    );
  }

  void clearPathForLayer(String? id) {
    if (id == null) {
      return;
    }
    final List<String> keysToRemove = _pathMeta.entries
        .where((MapEntry<String, _ConnectionPathMeta> entry) => entry.value.deviceId == id || entry.value.targetDeviceId == id)
        .map((MapEntry<String, _ConnectionPathMeta> entry) => entry.key)
        .toList(growable: false);

    for (final String key in keysToRemove) {
      _paths.remove(key);
      _previousPolylines.remove(key);
      _pathMeta.remove(key);
      _livePaths.remove(key);
      _pathAxisLocks.remove(key);
      _livePathAxisLocks.remove(key);
    }

    _invalidateFrameCaches();
  }

  String _keyOf(WiringConnectionModel connection) => connection.id;

  void _storePath(String key, WiringConnectionModel connection, FusionPath path) {
    _paths[key] = path;
    _previousPolylines[key] = _polylineForPath(path);
    _pathAxisLocks[key] = List<AxisLock>.unmodifiable(connection.axisLocks);
    _pathMeta[key] = _ConnectionPathMeta(
      deviceId: connection.deviceId,
      targetDeviceId: connection.targetDeviceId,
    );
    _livePaths.remove(key);
    _livePathAxisLocks.remove(key);
  }

  void _storeLivePath(String key, WiringConnectionModel connection, FusionPath path, List<AxisLock> axisLocks) {
    _livePaths[key] = path;
    _previousPolylines[key] = _polylineForPath(path);
    _livePathAxisLocks[key] = List<AxisLock>.unmodifiable(axisLocks);
    // _pathMeta is already set by _storePath — no need to update here
  }

  List<Offset> _polylineForPath(FusionPath path) {
    return <Offset>[path.start, ...path.points.map((FusionCanvasPoint p) => p.position), path.end];
  }

  List<Offset> _extractIntermediatePoints(List<Offset> fullPath, Offset start, Offset end) {
    final List<Offset> deduped = <Offset>[];
    for (final Offset point in fullPath) {
      if (deduped.isEmpty || deduped.last != point) {
        deduped.add(point);
      }
    }

    int from = 0;
    int to = deduped.length;
    if (deduped.isNotEmpty && deduped.first == start) {
      from = 1;
    }
    if (to > from && deduped.last == end) {
      to -= 1;
    }
    if (from >= to) {
      return <Offset>[];
    }
    return deduped.sublist(from, to);
  }

  bool _axisLocksEqual(List<AxisLock> a, List<AxisLock> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].x != b[i].x || a[i].y != b[i].y) return false;
    }
    return true;
  }

  static const double _lockTolerance = 0.01;

  List<Offset> _buildReconstructedPath({
    required List<Rect> obstacles,
    required Offset start,
    required Offset end,
    required List<AxisLock> axisLocks,
    required List<AxisLock> previousAxisLocks,
    required List<Offset>? previousPath,
  }) {
    final OrthogonalRouter router = OrthogonalRouter(<Rect>[...obstacles]);
    if (previousPath == null || previousPath.length < 2) {
      return router.findPath(
        start,
        end,
        previousPath: previousPath,
        axisLocks: axisLocks,
      );
    }

    final Offset previousStart = previousPath.first;
    final Offset previousEnd = previousPath.last;
    final bool startChanged = !_offsetNear(previousStart, start);
    final bool endChanged = !_offsetNear(previousEnd, end);

    if (startChanged && endChanged) {
      return router.findPath(
        start,
        end,
        previousPath: previousPath,
        axisLocks: axisLocks,
      );
    }

    final List<AxisLock> locks = _validAxisLocks(previousAxisLocks.isNotEmpty ? previousAxisLocks : axisLocks);
    if (locks.length < 2) {
      return router.findPath(
        start,
        end,
        previousPath: previousPath,
        axisLocks: axisLocks,
      );
    }

    final AxisLock secondLock = locks[1];
    final int? secondLockIndex = _findLockPointIndex(previousPath, secondLock);
    if (secondLockIndex == null) {
      return router.findPath(
        start,
        end,
        previousPath: previousPath,
        axisLocks: axisLocks,
      );
    }

    final Offset anchorPoint = previousPath[secondLockIndex];

    if (startChanged && !endChanged) {
      final List<Offset> rebuiltPrefix = router.findPath(
        start,
        anchorPoint,
        previousPath: previousPath.sublist(0, secondLockIndex + 1),
        axisLocks: locks.take(2).toList(growable: false),
      );
      return _mergePathParts(rebuiltPrefix, previousPath.sublist(secondLockIndex));
    }

    if (!startChanged && endChanged) {
      final List<Offset> rebuiltSuffix = router.findPath(
        anchorPoint,
        end,
        previousPath: previousPath.sublist(secondLockIndex),
        axisLocks: locks.skip(2).toList(growable: false),
      );
      return _mergePathParts(previousPath.sublist(0, secondLockIndex + 1), rebuiltSuffix);
    }

    return router.findPath(
      start,
      end,
      previousPath: previousPath,
      axisLocks: axisLocks,
    );
  }

  List<AxisLock> _validAxisLocks(List<AxisLock> locks) {
    return locks.where((AxisLock lock) => lock.x != null || lock.y != null).toList(growable: false);
  }

  int? _findLockPointIndex(List<Offset> path, AxisLock lock) {
    if (path.length < 2) {
      return null;
    }

    bool matchesLock(Offset point) {
      final bool matchesX = lock.x != null && (point.dx - lock.x!).abs() <= _lockTolerance;
      final bool matchesY = lock.y != null && (point.dy - lock.y!).abs() <= _lockTolerance;
      return matchesX || matchesY;
    }

    for (int i = 1; i < path.length - 1; i++) {
      if (matchesLock(path[i])) {
        return i;
      }
    }

    for (int i = 1; i < path.length; i++) {
      final Offset a = path[i - 1];
      final Offset b = path[i];
      final bool vertical = (a.dx - b.dx).abs() <= _lockTolerance;
      final bool horizontal = (a.dy - b.dy).abs() <= _lockTolerance;
      if (lock.x != null && vertical && (a.dx - lock.x!).abs() <= _lockTolerance) {
        return i;
      }
      if (lock.y != null && horizontal && (a.dy - lock.y!).abs() <= _lockTolerance) {
        return i;
      }
    }

    return null;
  }

  List<Offset> _mergePathParts(List<Offset> first, List<Offset> second) {
    if (first.isEmpty) {
      return second;
    }
    if (second.isEmpty) {
      return first;
    }
    if (_offsetNear(first.last, second.first)) {
      return <Offset>[...first, ...second.skip(1)];
    }
    return <Offset>[...first, ...second];
  }

  bool _offsetNear(Offset a, Offset b) {
    return (a.dx - b.dx).abs() <= _lockTolerance && (a.dy - b.dy).abs() <= _lockTolerance;
  }

  _ConnectionEndpoints? _resolveConnectionEndpoints(WiringConnectionModel connection, FusionCanvasPainter painter) {
    final FusionBasePainter? sourceLayer = painter.getLayerById(connection.deviceId);
    final FusionBasePainter? destLayer = painter.getLayerById(connection.targetDeviceId);

    Offset? start = sourceLayer is PortPainter ? sourceLayer.getPortPosition(connection.portId, painter) : null;
    Offset? end = destLayer is PortPainter ? destLayer.getPortPosition(connection.targetPortId, painter) : null;

    if (start != null && end != null) {
      return _ConnectionEndpoints(start: start, end: end);
    }

    for (final FusionBasePainter element in painter.layers) {
      if (element is! PortPainter) {
        continue;
      }
      start ??= element.getPortPosition(connection.portId, painter);
      end ??= element.getPortPosition(connection.targetPortId, painter);
      if (start != null && end != null) {
        return _ConnectionEndpoints(start: start, end: end);
      }
    }

    return null;
  }

  List<Rect> _obstaclesForPainter(FusionCanvasPainter painter) {
    final Duration frameTime = SchedulerBinding.instance.currentFrameTimeStamp;
    final int painterIdentity = identityHashCode(painter);
    if (_obstacleCacheFrameTime == frameTime && _obstacleCachePainterIdentity == painterIdentity) {
      return _obstacleCache;
    }

    _obstacleCacheFrameTime = frameTime;
    _obstacleCachePainterIdentity = painterIdentity;
    _obstacleCache = painter.layers
        .whereType<FusionCanvasElementPainter>()
        .map((FusionCanvasElementPainter elementPainter) => elementPainter.getBounds(painter).inflate(40))
        .toList(growable: false);
    return _obstacleCache;
  }

  void _invalidateFrameCaches() {
    _obstacleCacheFrameTime = null;
    _obstacleCachePainterIdentity = null;
    _obstacleCache = <Rect>[];
  }

  List<PathSegment> segmentsOfAllPathExcept(String connectionId) {
    final List<PathSegment> segments = <PathSegment>[];
    for (final MapEntry<String, FusionPath> entry in _paths.entries) {
      if (entry.key == connectionId) {
        continue;
      }
      segments.addAll(buildSegments(entry.value));
    }
    return segments;
  }

  List<PathSegment> buildSegments(FusionPath path) {
    final List<Offset> points = _polylineForPath(path);
    final List<PathSegment> segments = <PathSegment>[];
    for (int i = 0; i < points.length - 1; i++) {
      segments.add(PathSegment(start: points[i], end: points[i + 1]));
    }
    return segments;
  }

  Map<String, List<Offset>> allPolylines() {
    final Map<String, List<Offset>> polylines = <String, List<Offset>>{};
    for (final MapEntry<String, FusionPath> entry in _paths.entries) {
      polylines[entry.key] = _polylineForPath(entry.value);
    }
    // for (final MapEntry<String, FusionPath> entry in _livePaths.entries) {
    //   polylines[entry.key] = _polylineForPath(entry.value);
    // }
    return polylines;
  }
}

class _ConnectionPathMeta {
  const _ConnectionPathMeta({required this.deviceId, required this.targetDeviceId});

  final String deviceId;
  final String targetDeviceId;
}

class _ConnectionEndpoints {
  const _ConnectionEndpoints({required this.start, required this.end});

  final Offset start;
  final Offset end;
}

class FusionPath {
  final Offset start;
  final Offset end;
  final List<FusionCanvasPoint> points;

  FusionPath({
    required this.start,
    required this.end,
    required this.points,
  });
}

class PathSegment {
  final Offset start;
  final Offset end;

  PathSegment({
    required this.start,
    required this.end,
  });
}
