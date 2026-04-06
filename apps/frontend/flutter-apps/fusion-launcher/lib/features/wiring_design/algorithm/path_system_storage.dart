import 'package:flutter/material.dart';
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
  void removeKeysExcept(Set<String> keysToKeep) {
    _paths.removeWhere((String key, _) => !keysToKeep.contains(key));
    _livePaths.removeWhere((String key, _) => !keysToKeep.contains(key));
    _previousPolylines.removeWhere((String key, _) => !keysToKeep.contains(key));
    _pathMeta.removeWhere((String key, _) => !keysToKeep.contains(key));
  }

  FusionPath? getPath(WiringConnectionModel connection, FusionCanvasPainter painter, [List<Offset>? additionalStops]) {
    final String key = _keyOf(connection);
    if (_paths.containsKey(key)) {
      final FusionPath? path = _paths[key];
      if (path != null) {
        final FusionBasePainter? sourceLayer = painter.getLayerById(connection.deviceId);
        final FusionBasePainter? destLayer = painter.getLayerById(connection.targetDeviceId);
        Offset? start = sourceLayer is PortPainter ? sourceLayer.getPortPosition(connection.portId, painter) : null;
        Offset? end = destLayer is PortPainter ? destLayer.getPortPosition(connection.targetPortId, painter) : null;
        if (start == null || end == null) {
          for (final FusionBasePainter element in painter.layers) {
            if (element is PortPainter) {
              start ??= element.getPortPosition(connection.portId, painter);
              end ??= element.getPortPosition(connection.targetPortId, painter);
            }
          }
        }

        if (start != null && end != null) {
          if (path.start == start && path.end == end && additionalStops == null) {
            return path;
          }
        }
      }
    }

    final FusionPath? constructPath = _constructPath(
      connection,
      painter,
      connectionKey: key,
      additionalStops: additionalStops ?? <Offset>[],
    );
    // print("Constructed path for connection ${connection.id}: $constructPath");
    if (constructPath == null) {
      return null;
    }
    _storePath(key, connection, constructPath);
    return _paths[key];
  }

  FusionPath? getLivePath(WiringConnectionModel connection, FusionCanvasPainter painter, List<Offset> additionalStops) {
    // return getPath(connection, painter, additionalStops);
    final String key = _keyOf(connection);
    final List<Offset> normalizedStops = _normalizeStops(additionalStops);
    final FusionPath? livePath = _constructPath(
      connection,
      painter,
      connectionKey: key,
      additionalStops: normalizedStops,
    );
    if (livePath == null) {
      return null;
    }
    _storeLivePath(key, connection, livePath);
    return livePath;
    // _storePath(key, connection, livePath);
    // return _paths[key];

    // final FusionPath? cached = _paths[key];
    // if (cached != null && cached.start == livePath.start && cached.end == livePath.end) {
    //   final double cachedScore = _pathScore(_polylineForPath(cached));
    //   final double liveScore = _pathScore(_polylineForPath(livePath));
    //   if (liveScore + _liveSwitchEpsilon >= cachedScore) {
    //     return cached;
    //   }
    // }

    // _storePath(key, connection, livePath);
    // return livePath;
  }

  FusionPath? _constructPath(
    WiringConnectionModel connection,
    FusionCanvasPainter painter, {
    required String connectionKey,
    List<Offset> additionalStops = const <Offset>[],
  }) {
    final FusionBasePainter? sourceLayer = painter.getLayerById(connection.deviceId);
    final FusionBasePainter? destLayer = painter.getLayerById(connection.targetDeviceId);
    Offset? start = sourceLayer is PortPainter ? sourceLayer.getPortPosition(connection.portId, painter) : null;
    Offset? end = destLayer is PortPainter ? destLayer.getPortPosition(connection.targetPortId, painter) : null;
    if (start == null || end == null) {
      for (final FusionBasePainter element in painter.layers) {
        if (element is PortPainter) {
          start ??= element.getPortPosition(connection.portId, painter);
          end ??= element.getPortPosition(connection.targetPortId, painter);
        }
      }
    }

    if (start == null || end == null) {
      return null;
    }
    // if (points.isNotEmpty) {
    //   return FusionPath(start: start, end: end, points: points);
    // }
    final List<Rect> obstacles = painter.layers.whereType<FusionCanvasElementPainter>().map((FusionCanvasElementPainter p) => p.getBounds(painter)).toList();
    // final List<PathSegment> segments = segmentsOfAllPathExcept(connection.id);
    final List<Offset> pathPoints = OrthogonalRouter(<Rect>[
      ...obstacles,
      // ...segments.map((PathSegment e) => Rect.fromCircle(center: e.start, radius: 10)),
      // .expand((List<Offset> elements) => elements.map((Offset p) => Rect.fromCircle(center: p, radius: 10))),
    ]).findPath(
      start,
      end,
      stops: additionalStops,
      previousPath: _previousPolylines[connectionKey],
    );
    final List<Offset> intermediatePoints = _extractIntermediatePoints(pathPoints, start, end);
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
    }
  }

  String _keyOf(WiringConnectionModel connection) => connection.id;

  void _storePath(String key, WiringConnectionModel connection, FusionPath path) {
    _paths[key] = path;
    _previousPolylines[key] = _polylineForPath(path);
    _pathMeta[key] = _ConnectionPathMeta(
      deviceId: connection.deviceId,
      targetDeviceId: connection.targetDeviceId,
    );
  }

  void _storeLivePath(String key, WiringConnectionModel connection, FusionPath path) {
    _livePaths[key] = path;
    _previousPolylines[key] = _polylineForPath(path);
    _pathMeta[key] = _ConnectionPathMeta(
      deviceId: connection.deviceId,
      targetDeviceId: connection.targetDeviceId,
    );
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

  List<Offset> _normalizeStops(List<Offset> stops) {
    final List<Offset> normalized = <Offset>[];
    for (final Offset stop in stops) {
      if (normalized.isEmpty || normalized.last != stop) {
        normalized.add(stop);
      }
    }
    return normalized;
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
