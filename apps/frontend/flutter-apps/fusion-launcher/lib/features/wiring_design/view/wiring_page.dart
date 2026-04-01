import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/fusion_tool_state.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/tools/connection_tool_params.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/elements/fusion_canvas_element_painter.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/elements/wiring/port_painter.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_base_painter.dart' show FusionBasePainter;
import 'package:fusion_launcher/features/wiring_design/controller/circuit_controller.dart';
import 'package:fusion_launcher/features/wiring_design/controller/helpers/initialization_handler_mixin.dart';
import 'package:fusion_launcher/features/wiring_design/controller/helpers/project_manager_methods.dart';
import 'package:fusion_launcher/features/wiring_design/usecase/connection_usecase.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../fusion_canvas/view/fusion_canvas.dart';
import '../../fusion_canvas/view/painters/elements/wiring/wiring_connection_painter.dart';
import '../../fusion_canvas/view/painters/elements/wiring/wiring_devices_painter.dart';
import '../../fusion_canvas/view/painters/elements/wiring/wiring_source_painter.dart' show WiringSourcePainter;
import '../../fusion_canvas/view/painters/fusion_canvas_painter.dart';
import '../../fusion_canvas/viewmodel/tools/fusion_canvas_tool.dart';
import '../algorithm/path_finder_algorithm.dart';
import 'circuit_view.dart';

class WiringPage extends StatefulWidget {
  const WiringPage({super.key});

  @override
  State<WiringPage> createState() => _WiringPageState();
}

class _WiringPageState extends State<WiringPage> {
  late CircuitController controller = CircuitController(
    serviceLocator<ProjectViewModel>(),
  );
  final PathSystemStorage pathStorage = PathSystemStorage();
  final IntersectionManager intersectionManager = IntersectionManager();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fitToViewPort();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return BlocListener<ProjectViewModel, ProjectViewModelState>(
        listener: (BuildContext context, ProjectViewModelState state) {
          if (state is DeviceSelectionChanged) {
            controller.selectElementFromPM(state.selectedDevice?.id);
          }
          if (state is ProjectUpdated) {
            controller.loadFromPM();
          }
        },
        child: CircuitView(controller: controller),
      );
    }
    return BlocBuilder<ProjectViewModel, ProjectViewModelState>(
      builder: (BuildContext context, ProjectViewModelState state) {
        final ProjectViewModel projectViewModel = context.watch<ProjectViewModel>();
        return FusionCanvas(
          tools: <FusionCanvasTool<FusionToolState>>[
            FusionCanvasTool.measureTool,
            FusionCanvasTool.penTool,
            FusionCanvasTool.dragTool,
            FusionCanvasTool.connectionTool(
              connectionParams: ConnectionToolParams(
                onConnectionDrop: (WiringPortData source, Offset pos, WiringPortData? dest) {
                  if (dest == null) {
                    return;
                  }
                  projectViewModel.addWiringConnection(
                    connection: ConnectionUseCase().createConnection(
                      fromDeviceId: source.deviceId,
                      fromPort: source.port,
                      toDeviceId: dest.deviceId,
                      toPort: dest.port,
                    ),
                  );
                  // controller.handleConnectionDrop(source: source, pos: pos, dest: dest);
                },
              ),
            ),
            FusionCanvasTool.multiSelectionTool,
          ],
          elements: <FusionBasePainter>[
            for (HardwareComponent source in projectViewModel.hardwareComponents)
              if (source is Source)
                WiringSourcePainter(source: source)
              else if (source is! Speaker && source is! HardwareRack)
                WiringDevicesPainter(device: source),

            for (WiringConnectionModel connection in projectViewModel.getAllWiringConnections())
              // if (connection.sourcePortId != null)
              WiringConnectionPainter(
                connection: connection,
                pathStorage: pathStorage,
                intersectionManager: intersectionManager,
              ),
          ],
          builder:
              (BuildContext context) => Align(
                alignment: Alignment.bottomCenter,
                child: FusionFlatContainer(
                  child: IconButton(
                    onPressed: () {
                      final List<WiringConnectionModel> allConnections = projectViewModel.getAllWiringConnections();
                      for (final WiringConnectionModel element in allConnections) {
                        projectViewModel.removeWiringConnection(connectionId: element.id);
                      }
                    },
                    icon: const Icon(Icons.close),
                  ),
                ),
              ),
          toolbarEvents: FusionCanvasEvents(
            onDeleteLayer: (FusionBasePainter painter) {
              if (painter is WiringConnectionPainter) {
                final WiringConnectionModel connection = painter.connection;
                projectViewModel.removeWiringConnection(connectionId: connection.id);
              }
            },
            onMovePoints: (FusionBasePainter painter, List<String> points, Offset delta) {
              if (painter is WiringConnectionPainter) {
                print(" Moving points for connection ${painter.connection.id}, delta=$delta");
                final WiringConnectionModel connection = painter.connection;
                final List<FusionCanvasPoint>? updatedPoints = painter.pathPoints;
                if (updatedPoints == null) return;
                final Map<int, FusionCanvasPoint> newPoints = <int, FusionCanvasPoint>{};
                for (String pointId in points) {
                  if (updatedPoints.any((FusionCanvasPoint p) => p.id == pointId)) {
                    final int index = updatedPoints.indexWhere((FusionCanvasPoint p) => p.id == pointId);
                    // updatedPoints[index] = FusionCanvasPoint(position: updatedPoints[index].position);
                    newPoints[index] = updatedPoints[index].copyWith(position: updatedPoints[index].position);
                  }
                }
                projectViewModel.updateWiringConnection(
                  connection: connection.copyWith(
                    points: newPoints.isEmpty ? <FusionCanvasPoint>[] : newPoints.entries.map((MapEntry<int, FusionCanvasPoint> e) => e.value).toList(),
                  ),
                );
                pathStorage.clearPathForLayer(painter.id);
              }
            },
            onMoveLayer: (FusionBasePainter painter, Offset offset) {
              pathStorage.clearPathForLayer(painter.id);
              if (painter is WiringSourcePainter) {
                final Source source = painter.source;
                projectViewModel.updateHardware(hardware: source.copyWith(wiringPos: (source.wiringPos ?? Offset.zero) + offset));
              }
              if (painter is WiringDevicesPainter) {
                final HardwareComponent device = painter.device;
                projectViewModel.updateHardware(hardware: device.copyWith(wiringPos: (device.wiringPos ?? Offset.zero) + offset));
              }
            },
          ),
        );
      },
    );
  }
}

class PathSystemStorage {
  final Map<String, FusionPath> _paths = <String, FusionPath>{};
  final Map<String, List<Offset>> _previousPolylines = <String, List<Offset>>{};
  final Map<String, _ConnectionPathMeta> _pathMeta = <String, _ConnectionPathMeta>{};

  FusionPath? getPath(WiringConnectionModel connection, FusionCanvasPainter painter) {
    final String key = _keyOf(connection);
    if (_paths.containsKey(key)) {
      final FusionPath? path = _paths[key];
      if (path != null) {
        final FusionBasePainter? sourceLayer = painter.getLayerById(connection.deviceId);
        final FusionBasePainter? destLayer = painter.getLayerById(connection.targetDeviceId);

        if (sourceLayer != null && destLayer != null && sourceLayer is PortPainter && destLayer is PortPainter) {
          final Offset? start = sourceLayer.getPortPosition(connection.portId, painter);
          final Offset? end = destLayer.getPortPosition(connection.targetPortId, painter);

          if (path.start == start && path.end == end) {
            return path;
          }
        }
      }
    }

    final FusionPath? constructPath = _constructPath(
      connection,
      painter,
      connectionKey: key,
      additionalStops: connection.points?.map((FusionCanvasPoint p) => p.position).toList() ?? <Offset>[],
    );
    // print("Constructed path for connection ${connection.id}: $constructPath");
    if (constructPath == null) {
      return null;
    }
    _storePath(key, connection, constructPath);
    return _paths[key];
  }

  FusionPath? getLivePath(WiringConnectionModel connection, FusionCanvasPainter painter, List<Offset> additionalStops) {
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
    if (sourceLayer == null || destLayer == null || sourceLayer is! PortPainter || destLayer is! PortPainter) {
      return null;
    }
    final Offset? start = sourceLayer.getPortPosition(connection.portId, painter);
    final Offset? end = destLayer.getPortPosition(connection.targetPortId, painter);
    if (start == null || end == null) {
      return null;
    }
    // if (points.isNotEmpty) {
    //   return FusionPath(start: start, end: end, points: points);
    // }
    final List<Rect> obstacles = painter.layers.whereType<FusionCanvasElementPainter>().map((FusionCanvasElementPainter p) => p.getBounds(painter)).toList();
    final List<Offset> pathPoints = OrthogonalRouter(obstacles).findPath(
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
    return polylines;
  }
}

class IntersectionManager {
  static const double _epsilon = 0.001;

  String _lastSignature = '';
  final Map<String, List<Offset>> _jumpPointsByConnection = <String, List<Offset>>{};
  final Map<String, List<Offset>> _cutPointsByConnection = <String, List<Offset>>{};

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
