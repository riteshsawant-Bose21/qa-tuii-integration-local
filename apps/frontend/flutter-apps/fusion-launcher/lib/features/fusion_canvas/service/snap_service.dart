import 'dart:ui';

/// Represents a point that can be snapped to
class SnapPoint {
  final Offset referencePosition;
  final Offset position;
  final SnapPointType type;
  final String? label;

  const SnapPoint({
    required this.referencePosition,
    required this.position,
    required this.type,
    this.label,
  });
}

/// Types of snap points available
enum SnapPointType {
  point,
  orthogonalX,
  orthogonalY,
}

/// Configuration for snapping behavior
class SnapSettings {
  final double snapDistance;
  final bool enableGridSnap;
  final bool enablePointSnap;
  final bool enableOrthogonalSnap;
  final double gridSize;

  const SnapSettings({
    this.snapDistance = 20.0,
    this.enableGridSnap = false,
    this.enablePointSnap = true,
    this.enableOrthogonalSnap = true,
    this.gridSize = 50.0,
  });
}

/// Result of snap detection
class SnapResult {
  final Offset snappedPosition;
  final List<SnapPoint> snapPoints;
  final bool hasSnapped;

  /// Index of the cursor position that was used for snapping (for multi-point snapping)
  final int? cursorIndex;

  const SnapResult({
    required this.snappedPosition,
    this.snapPoints = const <SnapPoint>[],
    required this.hasSnapped,
    this.cursorIndex,
  });

  SnapResult.noSnap(Offset originalPosition) : snappedPosition = originalPosition, snapPoints = const <SnapPoint>[], hasSnapped = false, cursorIndex = null;

  /// Get snap point by type (for backward compatibility)
  SnapPoint? getSnapPointByType(SnapPointType type) {
    for (final SnapPoint sp in snapPoints) {
      if (sp.type == type) return sp;
    }
    return null;
  }

  /// Check if a specific snap type is active
  bool hasSnapType(SnapPointType type) => getSnapPointByType(type) != null;
}

/// Service for handling cursor snapping functionality
class SnapService {
  final SnapSettings settings;

  SnapService({this.settings = const SnapSettings()});

  /// Find the best snap point from multiple cursor positions (for polygon dragging)
  /// Returns the snap result with the shortest snap distance among all cursor positions
  SnapResult findBestSnapPoint({
    required List<Offset> cursorPositions,
    List<Offset> existingPoints = const <Offset>[],
    double scale = 1.0,
  }) {
    if (cursorPositions.isEmpty) {
      return SnapResult.noSnap(Offset.zero);
    }

    SnapResult? bestResult;
    double bestDistance = double.infinity;
    int bestIndex = 0;

    for (int i = 0; i < cursorPositions.length; i++) {
      final Offset cursorPosition = cursorPositions[i];
      final SnapResult result = findSnapPoint(
        cursorPosition: cursorPosition,
        existingPoints: existingPoints,
        scale: scale,
      );

      if (result.hasSnapped) {
        final double distance = (result.snappedPosition - cursorPosition).distance;
        if (distance < bestDistance) {
          bestDistance = distance;
          bestResult = result;
          bestIndex = i;
        }
      }
    }

    // Return the best snap result if found, otherwise return no-snap for first position
    if (bestResult != null) {
      return SnapResult(
        snappedPosition: bestResult.snappedPosition,
        snapPoints: bestResult.snapPoints,
        hasSnapped: true,
        cursorIndex: bestIndex,
      );
    }

    return SnapResult.noSnap(cursorPositions.first);
  }

  /// Find snap points based on cursor position and available snap targets
  SnapResult findSnapPoint({
    required Offset cursorPosition,
    List<Offset> existingPoints = const <Offset>[],

    double scale = 1.0,
  }) {
    final double effectiveSnapDistance = settings.snapDistance / scale;

    final List<SnapPoint> availableSnapPoints = _generateSnapPoints(
      cursorPosition: cursorPosition,
      existingPoints: existingPoints,
    );

    // Find all snap points within snap distance, grouped by type
    SnapPoint? closestPointSnap;
    SnapPoint? closestOrthogonalX;
    SnapPoint? closestOrthogonalY;
    double closestPointDistance = double.infinity;
    double closestOrthogonalXDistance = double.infinity;
    double closestOrthogonalYDistance = double.infinity;

    for (final SnapPoint snapPoint in availableSnapPoints) {
      final double distance = (snapPoint.position - cursorPosition).distance;
      if (distance > effectiveSnapDistance) continue;

      switch (snapPoint.type) {
        case SnapPointType.point:
          if (distance < closestPointDistance) {
            closestPointDistance = distance;
            closestPointSnap = snapPoint;
          }
          break;
        case SnapPointType.orthogonalX:
          if (distance < closestOrthogonalXDistance) {
            closestOrthogonalXDistance = distance;
            closestOrthogonalX = snapPoint;
          }
          break;
        case SnapPointType.orthogonalY:
          if (distance < closestOrthogonalYDistance) {
            closestOrthogonalYDistance = distance;
            closestOrthogonalY = snapPoint;
          }
          break;
      }
    }

    // Collect active snap points
    final List<SnapPoint> activeSnapPoints = <SnapPoint>[];

    // Point snap takes highest priority
    if (closestPointSnap != null) {
      activeSnapPoints.add(closestPointSnap);
      return SnapResult(
        snappedPosition: closestPointSnap.position,
        snapPoints: activeSnapPoints,
        hasSnapped: true,
      );
    }

    // Combine orthogonal snaps if both are active
    if (closestOrthogonalX != null) activeSnapPoints.add(closestOrthogonalX);
    if (closestOrthogonalY != null) activeSnapPoints.add(closestOrthogonalY);

    if (activeSnapPoints.isNotEmpty) {
      // Calculate combined snapped position
      Offset snappedPosition = cursorPosition;

      if (closestOrthogonalX != null && closestOrthogonalY != null) {
        // Both X and Y orthogonal - snap to intersection
        snappedPosition = Offset(
          closestOrthogonalX.position.dx,
          closestOrthogonalY.position.dy,
        );
      } else if (closestOrthogonalX != null) {
        snappedPosition = closestOrthogonalX.position;
      } else if (closestOrthogonalY != null) {
        snappedPosition = closestOrthogonalY.position;
      }

      return SnapResult(
        snappedPosition: snappedPosition,
        snapPoints: activeSnapPoints,
        hasSnapped: true,
      );
    }

    return SnapResult.noSnap(cursorPosition);
  }

  /// Generate all available snap points
  List<SnapPoint> _generateSnapPoints({
    required Offset cursorPosition,
    required List<Offset> existingPoints,
  }) {
    final List<SnapPoint> snapPoints = <SnapPoint>[];

    // Existing point snap
    if (settings.enablePointSnap) {
      snapPoints.addAll(_generatePointSnapPoints(existingPoints));
    }

    // Orthogonal snap points (relative to active start point)
    if (settings.enableOrthogonalSnap) {
      for (final Offset element in existingPoints) {
        snapPoints.addAll(_generateOrthogonalSnapPoints(element, cursorPosition));
      }
    }

    return snapPoints;
  }

  /// Generate snap points for existing points
  List<SnapPoint> _generatePointSnapPoints(List<Offset> existingPoints) {
    return existingPoints
        .map(
          (Offset point) => SnapPoint(
            referencePosition: point,
            position: point,
            type: SnapPointType.point,
            label: 'Point',
          ),
        )
        .toList();
  }

  /// Generate orthogonal snap points relative to a start point
  List<SnapPoint> _generateOrthogonalSnapPoints(Offset startPoint, Offset cursorPosition) {
    final List<SnapPoint> orthogonalPoints = <SnapPoint>[];

    // Horizontal line (same Y as start)
    orthogonalPoints.add(
      SnapPoint(
        position: Offset(cursorPosition.dx, startPoint.dy),
        type: SnapPointType.orthogonalY,
        label: 'Horizontal',
        referencePosition: startPoint,
      ),
    );

    // Vertical line (same X as start)
    orthogonalPoints.add(
      SnapPoint(
        position: Offset(startPoint.dx, cursorPosition.dy),
        type: SnapPointType.orthogonalX,
        label: 'Vertical',
        referencePosition: startPoint,
      ),
    );

    return orthogonalPoints;
  }

  /// Check if snapping is enabled for a specific type
  bool isSnapTypeEnabled(SnapPointType type) {
    switch (type) {
      case SnapPointType.point:
        return settings.enablePointSnap;
      case SnapPointType.orthogonalX:
      case SnapPointType.orthogonalY:
        return settings.enableOrthogonalSnap;
    }
  }
}
