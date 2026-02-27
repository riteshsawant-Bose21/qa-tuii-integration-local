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
  final SnapPoint? snapPoint;
  final bool hasSnapped;
  final Offset? referencePoint;

  const SnapResult({
    required this.snappedPosition,
    this.snapPoint,
    required this.hasSnapped,
    this.referencePoint,
  });

  SnapResult.noSnap(Offset originalPosition) : snappedPosition = originalPosition, snapPoint = null, hasSnapped = false, referencePoint = null;
}

/// Service for handling cursor snapping functionality
class SnapService {
  final SnapSettings settings;

  SnapService({this.settings = const SnapSettings()});

  /// Find snap points based on cursor position and available snap targets
  SnapResult findSnapPoint({
    required Offset cursorPosition,
    List<Offset> existingPoints = const <Offset>[],
    Offset? activeStartPoint,
    double scale = 1.0,
  }) {
    final double effectiveSnapDistance = settings.snapDistance / scale;
    SnapPoint? closestSnapPoint;
    double closestDistance = double.infinity;

    final List<SnapPoint> availableSnapPoints = _generateSnapPoints(
      cursorPosition: cursorPosition,
      existingPoints: existingPoints,
      activeStartPoint: activeStartPoint,
    );

    // Find the closest snap point within snap distance
    for (final SnapPoint snapPoint in availableSnapPoints) {
      final double distance = (snapPoint.position - cursorPosition).distance;
      if (distance <= effectiveSnapDistance && distance < closestDistance) {
        closestDistance = distance;
        closestSnapPoint = snapPoint;
      }
    }

    if (closestSnapPoint != null) {
      return SnapResult(
        snappedPosition: closestSnapPoint.position,
        snapPoint: closestSnapPoint,
        hasSnapped: true,
        referencePoint: closestSnapPoint.referencePosition,
      );
    }

    return SnapResult.noSnap(cursorPosition);
  }

  /// Generate all available snap points
  List<SnapPoint> _generateSnapPoints({
    required Offset cursorPosition,
    required List<Offset> existingPoints,
    Offset? activeStartPoint,
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
