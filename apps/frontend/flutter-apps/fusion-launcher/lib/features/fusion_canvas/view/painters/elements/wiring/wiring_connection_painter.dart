import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/tools/select_tool_state.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_base_painter.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_canvas_painter.dart';
import 'package:fusion_launcher/features/wiring_design/algorithm/intersection_manager.dart';
import 'package:fusion_launcher/features/wiring_design/algorithm/path_system_storage.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../../state/fusion_tool_state.dart';
import '../mixin/fusion_canvas_interactable_mixin.dart';
import 'connection_color_util.dart';

class WiringConnectionPainter extends FusionBasePainter with FusionCanvasInteractibleMixin {
  final WiringConnectionModel connection;
  final PathSystemStorage pathStorage;
  final IntersectionManager intersectionManager;
  final double cornerRadius;

  WiringConnectionPainter({
    required this.connection,
    required this.pathStorage,
    required this.intersectionManager,
    this.cornerRadius = 30,
  });

  @override
  String? get id => connection.id;

  Path? paintedPath;
  FusionPath? fusionPath;
  List<FusionCanvasPoint>? pathPoints;
  List<AxisLock>? axisLocks;
  // Cached paint object — color/style/strokeWidth are constant for this painter.
  late final Paint _connectionPaint =
      Paint()
        ..color = Colors.green
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

  @override
  Set<FusionCanvasLayerInteraction> get possibleInteractions => <FusionCanvasLayerInteraction>{
    FusionCanvasLayerInteraction.select,
  };

  @override
  Set<FusionCanvasLayerInteraction>? possibleInteractionsForElement(
    FusionCanvasElement element,
  ) => <FusionCanvasLayerInteraction>{
    FusionCanvasLayerInteraction.select,
    FusionCanvasLayerInteraction.drag,
  };

  @override
  void paint(Canvas canvas, Size size, FusionCanvasPainter painter) {
    final bool isSelected = painter.isSelected(id);
    FusionPath? path = pathStorage.getPath(connection, painter);
    if (path == null) return;
    // print("Path for connection ${connection.id}: $path");
    List<FusionCanvasPoint> rawPoints = _buildPathPoints(path);
    if (isSelected) {
      _connectionPaint.color = Colors.blue;
      final FusionToolState toolState = painter.toolState;
      final Set<String> selectedElements = toolState is SelectToolState ? toolState.selectedElementIds : <String>{};

      final Map<int, AxisLock> selectedAxisLocksBySegmentIndex = <int, AxisLock>{};
      for (int i = 0; i < rawPoints.length - 1; i++) {
        final FusionCanvasPathSegment line = FusionCanvasPathSegment(start: rawPoints[i], end: rawPoints[i + 1]);
        if (!selectedElements.contains(line.id)) {
          continue;
        }

        final Offset start = transformOffsetForLayer(rawPoints[i].position, painter, id);
        selectedAxisLocksBySegmentIndex[i] = line.isVerticalLine ? AxisLock(x: start.dx) : AxisLock(y: start.dy);
      }
      // print("Lenght of selected points: ${selectedElements.length}, lines: ${lines.length}, rawPoints: ${rawPoints.length}");
      if (selectedAxisLocksBySegmentIndex.isNotEmpty) {
        final List<AxisLock> previousAxisLocks = connection.axisLocks;
        // print(
        //   "Previous axis locks from connection: \n Previous : $previousAxisLocks.  \n selectedAxisLocksBySegmentIndex: $selectedAxisLocksBySegmentIndex \n rawPoints: $rawPoints",
        // );
        axisLocks = _mergeAxisLocksByPathOrder(
          rawPoints: rawPoints,
          painter: painter,
          previousAxisLocks: previousAxisLocks,
          selectedAxisLocksBySegmentIndex: selectedAxisLocksBySegmentIndex,
        );
        // print("Axis Locks Result  : $axisLocks");
        // print("\n\n\n");
        path =
            pathStorage.getLivePath(
              connection,
              painter,
              axisLocks ?? <AxisLock>[],
            ) ??
            path;
        rawPoints = _buildPathPoints(path);
      }
    } else {
      _connectionPaint.color = ConnectionColorUtil.getColorForConnectionType(connection.type);
    }

    // Resolve all positions in a single pass to avoid repeated toolState /
    // snapState lookups inside _buildRoundedPath.
    pathPoints = rawPoints.toList();
    fusionPath = path;
    final List<Offset> positions = rawPoints
        .map(
          (FusionCanvasPoint p) => p.position, //getEffectivePosition(p, painter, id)
        )
        .toList(growable: false);

    final Map<String, List<Offset>> polylines = pathStorage.allPolylines();
    polylines[connection.id] = positions;
    final List<Offset> jumpPoints = intersectionManager.jumpPointsForConnection(connection.id, polylines);
    final List<Offset> cutPoints = intersectionManager.cutPointsForConnection(connection.id, polylines);

    final Path drawingPath = _buildRoundedPath(positions, cornerRadius);
    canvas.saveLayer(null, Paint());
    canvas.drawPath(drawingPath, _connectionPaint);

    final Paint cutPaint =
        Paint()
          ..blendMode = BlendMode.clear
          ..style = PaintingStyle.stroke
          ..strokeWidth = _connectionPaint.strokeWidth + 2
          ..strokeCap = StrokeCap.round;

    for (final Offset cutPoint in cutPoints) {
      final _SegmentDirection? direction = _directionAtPoint(positions, cutPoint);
      if (direction == null) {
        continue;
      }
      const double cutHalfGap = 8;
      final Offset before = cutPoint - direction.direction * cutHalfGap;
      final Offset after = cutPoint + direction.direction * cutHalfGap;
      canvas.drawLine(before, after, cutPaint);
    }

    for (final Offset jumpPoint in jumpPoints) {
      final _SegmentDirection? direction = _directionAtPoint(positions, jumpPoint);
      if (direction == null) {
        continue;
      }
      const double jumpRadius = 20;
      const double jumpHeight = 30;
      final Offset before = jumpPoint - direction.direction * jumpRadius;
      final Offset after = jumpPoint + direction.direction * jumpRadius;
      final Path jumpPath =
          Path()
            ..moveTo(before.dx, before.dy)
            ..quadraticBezierTo(
              jumpPoint.dx + direction.normal.dx * jumpHeight,
              jumpPoint.dy + direction.normal.dy * jumpHeight,
              after.dx,
              after.dy,
            );
      canvas.drawLine(before, after, cutPaint);
      canvas.drawPath(jumpPath, _connectionPaint);
    }

    canvas.restore();
    paintedPath = drawingPath;
  }

  _SegmentDirection? _directionAtPoint(List<Offset> positions, Offset point) {
    const double epsilon = 0.001;
    for (int i = 0; i < positions.length - 1; i++) {
      final Offset start = positions[i];
      final Offset end = positions[i + 1];
      final bool isHorizontal = (start.dy - end.dy).abs() <= epsilon;
      final bool isVertical = (start.dx - end.dx).abs() <= epsilon;

      if (!isHorizontal && !isVertical) {
        continue;
      }

      if (isHorizontal) {
        final double minX = start.dx < end.dx ? start.dx : end.dx;
        final double maxX = start.dx > end.dx ? start.dx : end.dx;
        if ((point.dy - start.dy).abs() <= epsilon && point.dx > minX + epsilon && point.dx < maxX - epsilon) {
          final Offset direction = (end - start).distance <= epsilon ? const Offset(1, 0) : (end - start) / (end - start).distance;
          return _SegmentDirection(direction: direction, normal: const Offset(0, -1));
        }
      }

      if (isVertical) {
        final double minY = start.dy < end.dy ? start.dy : end.dy;
        final double maxY = start.dy > end.dy ? start.dy : end.dy;
        if ((point.dx - start.dx).abs() <= epsilon && point.dy > minY + epsilon && point.dy < maxY - epsilon) {
          final Offset direction = (end - start).distance <= epsilon ? const Offset(0, 1) : (end - start) / (end - start).distance;
          return _SegmentDirection(direction: direction, normal: const Offset(1, 0));
        }
      }
    }
    return null;
  }

  /// Builds a path through [positions] with rounded corners of [radius].
  /// All positions must already be resolved to canvas-space offsets.
  Path _buildRoundedPath(List<Offset> positions, double radius) {
    final Path drawingPath = Path();
    if (positions.isEmpty) return drawingPath;

    drawingPath.moveTo(positions.first.dx, positions.first.dy);

    if (positions.length < 3 || radius <= 0) {
      for (int i = 1; i < positions.length; i++) {
        drawingPath.lineTo(positions[i].dx, positions[i].dy);
      }
      return drawingPath;
    }

    for (int i = 1; i < positions.length - 1; i++) {
      final Offset previous = positions[i - 1];
      final Offset current = positions[i];
      final Offset next = positions[i + 1];

      final Offset incoming = current - previous;
      final Offset outgoing = next - current;
      final double incomingLength = incoming.distance;
      final double outgoingLength = outgoing.distance;

      if (incomingLength == 0 || outgoingLength == 0) {
        drawingPath.lineTo(current.dx, current.dy);
        continue;
      }

      final Offset incomingDirection = incoming / incomingLength;
      final Offset outgoingDirection = outgoing / outgoingLength;

      final double effectiveRadius = radius.clamp(
        0,
        (incomingLength < outgoingLength ? incomingLength : outgoingLength) / 2,
      );

      final Offset cornerStart = current - incomingDirection * effectiveRadius;
      final Offset cornerEnd = current + outgoingDirection * effectiveRadius;

      drawingPath.lineTo(cornerStart.dx, cornerStart.dy);
      drawingPath.quadraticBezierTo(
        current.dx,
        current.dy,
        cornerEnd.dx,
        cornerEnd.dy,
      );
    }

    final Offset end = positions.last;
    drawingPath.lineTo(end.dx, end.dy);
    return drawingPath;
  }

  @override
  bool shouldRepaint(covariant FusionBasePainter oldDelegate) {
    if (oldDelegate is! WiringConnectionPainter) return true;
    return oldDelegate.connection != connection ||
        oldDelegate.cornerRadius != cornerRadius ||
        oldDelegate.pathStorage != pathStorage ||
        oldDelegate.intersectionManager != intersectionManager;
  }

  @override
  FusionCanvasElement? isHit(Offset position, FusionCanvasPainter painter) {
    final FusionPath? path = fusionPath ?? pathStorage.getPath(connection, painter); //this.fusionPath ??
    if (path == null) return null;

    final List<FusionCanvasPoint> vertices = _buildPathPoints(path);

    final double hitThreshold = nonScaling(8, painter);

    for (int i = 0; i < vertices.length - 1; i++) {
      final FusionCanvasPoint start = vertices[i];
      final FusionCanvasPoint end = vertices[i + 1];
      final double distance = _distanceFromPointToSegment(
        position,
        start.position,
        end.position,
      );
      if (distance <= hitThreshold) {
        return FusionCanvasPathSegment(start: start, end: end);
      }
    }

    return null;
  }

  double _distanceFromPointToSegment(Offset p, Offset a, Offset b) {
    final double lengthSquared = (b - a).distanceSquared;
    if (lengthSquared == 0) return (p - a).distance;
    final double t = ((p - a).dx * (b - a).dx + (p - a).dy * (b - a).dy) / lengthSquared;
    if (t < 0) return (p - a).distance;
    if (t > 1) return (p - b).distance;
    final Offset projection = a + (b - a) * t;
    return (p - projection).distance;
  }

  @override
  Rect getBounds(FusionCanvasPainter painter) {
    return paintedPath?.getBounds() ?? const Rect.fromLTWH(0, 0, 0, 0);
  }

  List<FusionCanvasPoint> _buildPathPoints(FusionPath path) {
    return <FusionCanvasPoint>[
      FusionCanvasPoint(position: path.start, id: '${connection.id}_start'),
      ...path.points,
      FusionCanvasPoint(position: path.end, id: '${connection.id}_end'),
    ];
  }

  List<AxisLock> _mergeAxisLocksByPathOrder({
    required List<FusionCanvasPoint> rawPoints,
    required FusionCanvasPainter painter,
    required List<AxisLock> previousAxisLocks,
    required Map<int, AxisLock> selectedAxisLocksBySegmentIndex,
  }) {
    // Build orderedPathLocks and a mapping from rawPoints segment index → ordered index.
    final List<AxisLock> merged = <AxisLock>[
      ...previousAxisLocks,
      ...selectedAxisLocksBySegmentIndex.values,
    ];
    final List<AxisLock> previous = <AxisLock>[...previousAxisLocks];

    final Map<int, AxisLock> previousPathOrderedByIndex = <int, AxisLock>{};
    int currentRPIndex = 0;
    for (AxisLock lock in previous) {
      final int index = (rawPoints.sublist(currentRPIndex)).indexWhere(
        (FusionCanvasPoint p) => (lock.x != null && (p.position.dx - lock.x!).abs() <= 0.001) || (lock.y != null && (p.position.dy - lock.y!).abs() <= 0.001),
      );
      if (index != -1) {
        previousPathOrderedByIndex[index + currentRPIndex] = lock;
        currentRPIndex += index + 1;
      }
    }

    //     print(
    //       '''Ordered PreviousPathLocks by rawPoints index: ${previousPathOrderedByIndex.entries.map((MapEntry<int, AxisLock> e) => 'index ${e.key}: ${e.value}').join('\n ')}
    // Selected locks by rawPoints segment index: ${selectedAxisLocksBySegmentIndex.entries.map((MapEntry<int, AxisLock> e) => 'segment index ${e.key}: ${e.value}').join('\n ')}

    // RawPoints: ${rawPoints.map((FusionCanvasPoint p) => '(${p.position.dx}, ${p.position.dy})').join('\n ')}
    //       ''',
    //     );

    final Map<int, AxisLock> mergedByIndex = <int, AxisLock>{...previousPathOrderedByIndex, ...selectedAxisLocksBySegmentIndex};
    final List<MapEntry<int, AxisLock>> sortedMergedByIndex =
        mergedByIndex.entries.toList()..sort((MapEntry<int, AxisLock> a, MapEntry<int, AxisLock> b) => a.key.compareTo(b.key));
    return _removeDuplicates(sortedMergedByIndex.map((MapEntry<int, AxisLock> e) => e.value).toList());
  }

  bool _axisLocksMatch(AxisLock a, AxisLock b) {
    const double epsilon = 10;
    // print("Comparing axis locks: $a vs $b");
    if (a.x != null && b.x != null) {
      // print("Comparing x values: ${a.x} vs ${b.x}  : ${(a.x! - b.x!).abs().floor()} <= $epsilon   = ${(a.x! - b.x!).abs().floor() <= epsilon}");
      return (a.x! - b.x!).abs().floor() <= epsilon;
    }
    if (a.y != null && b.y != null) {
      // print("Comparing y values: ${a.y} vs ${b.y}  : ${(a.y! - b.y!).abs().floor()} <= $epsilon   = ${(a.y! - b.y!).abs().floor() <= epsilon}");
      return (a.y! - b.y!).abs().floor() <= epsilon;
    }
    return false;
  }

  List<AxisLock> _removeDuplicates(List<AxisLock> locks) {
    final List<AxisLock> unique = <AxisLock>[];
    for (final AxisLock lock in locks) {
      if (!unique.any((AxisLock l) => _axisLocksMatch(l, lock))) {
        unique.add(lock);
      }
    }
    return unique;
  }
}

class _SegmentDirection {
  const _SegmentDirection({required this.direction, required this.normal});

  final Offset direction;
  final Offset normal;
}
