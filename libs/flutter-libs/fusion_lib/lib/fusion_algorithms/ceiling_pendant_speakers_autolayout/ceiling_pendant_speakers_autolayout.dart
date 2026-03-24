import 'dart:math';

/// Room shape type for ceiling/pendant speaker placement
enum RoomType {
  /// Rectangular room with standard width x length
  symmetrical,

  /// Custom room shape defined by a polygon of coordinate points
  asymmetrical,
}

/// Represents a 2D point/coordinate
class Point2D {
  final double x;
  final double y;

  const Point2D(this.x, this.y);

  @override
  String toString() => '($x, $y)';

  @override
  bool operator ==(Object other) => identical(this, other) || other is Point2D && runtimeType == other.runtimeType && x == other.x && y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;
}

/// Represents a rectangular or asymmetrical room
/// Supports both symmetrical (rectangular) and asymmetrical (custom polygon) room shapes
class Room {
  final double width;
  final double roomLength;
  final double ceilingHeight;
  final double listenerHeight;

  /// Room type - symmetrical (rectangular) or asymmetrical (custom polygon)
  final RoomType roomType;

  /// Custom room geometry points for asymmetrical rooms (optional)
  /// Must form a closed polygon with at least 3 points
  final List<Point2D>? customGeometry;

  Room({
    required this.width,
    required this.roomLength,
    required this.ceilingHeight,
    required this.listenerHeight,
    this.roomType = RoomType.symmetrical,
    this.customGeometry,
  }) {
    _validateDimensions();
    _validateGeometry();
  }

  /// Creates an asymmetrical room from custom geometry points
  Room.asymmetrical({
    required List<Point2D> geometry,
    required this.ceilingHeight,
    required this.listenerHeight,
  }) : roomType = RoomType.asymmetrical,
       customGeometry = List.unmodifiable(geometry),
       width = _calculateBoundingBoxWidth(geometry),
       roomLength = _calculateBoundingBoxLength(geometry) {
    _validateDimensions();
    _validateGeometry();
  }

  /// Calculate bounding box width from geometry points
  static double _calculateBoundingBoxWidth(List<Point2D> points) {
    if (points.isEmpty) return 0.0;
    double minX = points.first.x;
    double maxX = points.first.x;
    for (final point in points) {
      minX = min(minX, point.x);
      maxX = max(maxX, point.x);
    }
    return maxX - minX;
  }

  /// Calculate bounding box length from geometry points
  static double _calculateBoundingBoxLength(List<Point2D> points) {
    if (points.isEmpty) return 0.0;
    double minY = points.first.y;
    double maxY = points.first.y;
    for (final point in points) {
      minY = min(minY, point.y);
      maxY = max(maxY, point.y);
    }
    return maxY - minY;
  }

  /// Validates room dimensions
  void _validateDimensions() {
    // Validate room dimensions
    if (width <= 0) {
      throw ArgumentError('Room width must be positive, got: $width');
    }
    if (roomLength <= 0) {
      throw ArgumentError('Room length must be positive, got: $roomLength');
    }
    if (ceilingHeight <= 0) {
      throw ArgumentError('Ceiling height must be positive, got: $ceilingHeight');
    }
    if (listenerHeight < 0) {
      throw ArgumentError('Listener height must be non-negative, got: $listenerHeight');
    }
    if (ceilingHeight <= listenerHeight) {
      throw ArgumentError('Ceiling height ($ceilingHeight) must be greater than listener height ($listenerHeight)');
    }
  }

  /// Validates custom geometry for asymmetrical rooms
  void _validateGeometry() {
    if (roomType == RoomType.asymmetrical) {
      if (customGeometry == null || customGeometry!.length < 3) {
        throw ArgumentError('Asymmetrical rooms require at least 3 geometry points');
      }

      // Check for valid coordinates (all non-negative)
      for (final point in customGeometry!) {
        if (point.x < 0 || point.y < 0) {
          throw ArgumentError('Room geometry points must be non-negative: $point');
        }
      }

      // Check for reasonable polygon size
      final area = calculatePolygonArea(customGeometry!);
      if (area <= 0) {
        throw ArgumentError('Room geometry does not form a valid polygon (area <= 0)');
      }

      if (area > 10000) {
        // Large room warning
        print('Warning: Very large room area: ${area.toStringAsFixed(1)} sq units');
      }
    }
  }

  /// Calculate area of polygon using shoelace formula
  double calculatePolygonArea(List<Point2D> vertices) {
    if (vertices.length < 3) return 0.0;

    double area = 0.0;
    int n = vertices.length;

    for (int i = 0; i < n; i++) {
      int j = (i + 1) % n;
      area += vertices[i].x * vertices[j].y;
      area -= vertices[j].x * vertices[i].y;
    }

    return area.abs() / 2.0;
  }

  /// Calculate geometric center (centroid) of rectangular room or polygon
  Point2D get centroid {
    if (roomType == RoomType.asymmetrical && customGeometry != null) {
      return _calculatePolygonCentroid(customGeometry!);
    }
    return Point2D(width / 2, roomLength / 2);
  }

  /// Calculate centroid of polygon
  Point2D _calculatePolygonCentroid(List<Point2D> vertices) {
    if (vertices.isEmpty) return const Point2D(0, 0);
    if (vertices.length == 1) return vertices[0];

    double cx = 0.0;
    double cy = 0.0;
    double area = 0.0;

    for (int i = 0; i < vertices.length; i++) {
      int j = (i + 1) % vertices.length;
      double cross = vertices[i].x * vertices[j].y - vertices[j].x * vertices[i].y;
      area += cross;
      cx += (vertices[i].x + vertices[j].x) * cross;
      cy += (vertices[i].y + vertices[j].y) * cross;
    }

    area *= 0.5;
    if (area.abs() < 1e-10) {
      // Fallback to arithmetic mean for degenerate cases
      double sumX = 0.0;
      double sumY = 0.0;
      for (final point in vertices) {
        sumX += point.x;
        sumY += point.y;
      }
      return Point2D(sumX / vertices.length, sumY / vertices.length);
    }

    cx = cx / (6.0 * area);
    cy = cy / (6.0 * area);

    return Point2D(cx, cy);
  }

  /// Check if a point is within room boundaries
  /// For symmetrical rooms: simple rectangle check
  /// For asymmetrical rooms: point-in-polygon algorithm
  bool contains(Point2D point) {
    if (roomType == RoomType.asymmetrical && customGeometry != null) {
      return _pointInPolygon(point, customGeometry!);
    }

    // Original rectangular room logic
    return point.x >= 0 && point.x <= width && point.y >= 0 && point.y <= roomLength;
  }

  /// Point-in-polygon algorithm using ray casting
  /// Returns true if point is inside the polygon defined by vertices
  /// Enhanced for asymmetrical rooms to exclude border points more aggressively
  bool _pointInPolygon(Point2D point, List<Point2D> vertices) {
    if (vertices.length < 3) return false;

    // First check if point is exactly on any edge (should be excluded)
    const double edgeTolerance = 0.001; // 1mm tolerance
    for (int i = 0; i < vertices.length; i++) {
      int j = (i + 1) % vertices.length;
      double distanceToEdge = _pointToLineDistance(point, vertices[i], vertices[j]);
      if (distanceToEdge < edgeTolerance) {
        return false; // Point is on or very close to edge - exclude it
      }
    }

    // Standard ray casting algorithm for interior points
    bool inside = false;
    int n = vertices.length;

    for (int i = 0, j = n - 1; i < n; j = i++) {
      final Point2D vi = vertices[i];
      final Point2D vj = vertices[j];

      if (((vi.y > point.y) != (vj.y > point.y)) && (point.x < (vj.x - vi.x) * (point.y - vi.y) / (vj.y - vi.y) + vi.x)) {
        inside = !inside;
      }
    }

    return inside;
  }

  /// Check if point is "near" boundary (within overlap region)
  bool isNearBoundary(Point2D point, double overlapDistance) {
    if (roomType == RoomType.asymmetrical && customGeometry != null) {
      // For asymmetrical rooms, check distance to any edge
      return _isNearPolygonBoundary(point, customGeometry!, overlapDistance);
    }

    // Original rectangular room logic
    return point.x < overlapDistance || point.x > (width - overlapDistance) || point.y < overlapDistance || point.y > (roomLength - overlapDistance);
  }

  /// Check if point is near any edge of the polygon
  bool _isNearPolygonBoundary(Point2D point, List<Point2D> vertices, double overlapDistance) {
    for (int i = 0; i < vertices.length; i++) {
      int j = (i + 1) % vertices.length;
      final Point2D v1 = vertices[i];
      final Point2D v2 = vertices[j];

      double distanceToEdge = _pointToLineDistance(point, v1, v2);
      if (distanceToEdge < overlapDistance) {
        return true;
      }
    }
    return false;
  }

  /// Calculate distance from point to line segment
  double _pointToLineDistance(Point2D point, Point2D lineStart, Point2D lineEnd) {
    double dx = lineEnd.x - lineStart.x;
    double dy = lineEnd.y - lineStart.y;

    if (dx == 0 && dy == 0) {
      // Line is actually a point
      dx = point.x - lineStart.x;
      dy = point.y - lineStart.y;
      return sqrt(dx * dx + dy * dy);
    }

    double t = ((point.x - lineStart.x) * dx + (point.y - lineStart.y) * dy) / (dx * dx + dy * dy);
    t = t.clamp(0.0, 1.0);

    double projX = lineStart.x + t * dx;
    double projY = lineStart.y + t * dy;

    dx = point.x - projX;
    dy = point.y - projY;

    return sqrt(dx * dx + dy * dy);
  }
}

/// Coverage preference options as defined in document
enum CoveragePreference {
  edgeToEdge(1.0, "minimum/value-oriented arrangement"),
  minimumOverlap(0.7, "optimal layout"),
  centerToCenter(0.5, "significant interference");

  const CoveragePreference(this.overlapMultiplier, this.description);

  final double overlapMultiplier;
  final String description;
}

/// Layout pattern options
enum LayoutPattern { square, hexagonal }

/// Speaker type for mounting calculations
/// This library supports only ceiling-mounted and pendant-mounted speakers
enum SpeakerType {
  /// Ceiling-mounted speakers installed flush with the ceiling
  ceiling,

  /// Pendant-mounted speakers suspended from the ceiling at a specified height
  pendant,
}

/// Speaker specification for ceiling and pendant speakers only
class SpeakerSpec {
  final double coverageAngle; // in degrees
  final SpeakerType type; // ceiling or pendant only
  final double? pendantHeight; // required for pendant speakers, ignored for ceiling

  const SpeakerSpec({
    required this.coverageAngle,
    required this.type,
    this.pendantHeight,
  }) : assert(type == SpeakerType.ceiling || type == SpeakerType.pendant, 'Only ceiling and pendant speakers are supported');
}

/// Result of speaker placement calculation
class PlacementResult {
  final List<Point2D> speakerPositions;
  final double gridSpacing;
  final Point2D centroid; // Effective origin used for calculations
  final Point2D baseCentroid; // Original room centroid for UI reference
  final Point2D? customOriginOffset; // Offset applied to base centroid
  final double distance;
  final List<String> calculationSteps;

  const PlacementResult({
    required this.speakerPositions,
    required this.gridSpacing,
    required this.centroid,
    required this.baseCentroid,
    this.customOriginOffset,
    required this.distance,
    required this.calculationSteps,
  });

  @override
  String toString() {
    String originInfo = customOriginOffset != null
        ? '''
  Base Centroid: $baseCentroid
  Custom Origin Offset: $customOriginOffset
  Effective Origin: $centroid'''
        : '''
  Centroid (Origin): $centroid''';

    return '''
PlacementResult:
  Speakers: ${speakerPositions.length}
  Grid Spacing: ${gridSpacing.toStringAsFixed(2)}m$originInfo
  Distance: ${distance.toStringAsFixed(2)}m
  Positions: ${speakerPositions.join(', ')}
  
Calculation Steps:
${calculationSteps.map((step) => '  $step').join('\n')}
''';
  }
}

/// Main Auto-Loudspeaker Placement Library
///
/// This library calculates optimal placement for ceiling-mounted and pendant-mounted speakers only.
/// It does not support wall-mounted, floor-standing, or other speaker types.
class AutoSpeakerPlacement {
  /// DG correction factor - set to 1.0 (inactive)
  static const double dgCorrection = 1.0;

  /// Calculate speaker placement for ceiling and pendant speakers
  ///
  /// Parameters:
  /// - [room]: Room dimensions and geometry
  /// - [speakerSpec]: Speaker specifications (coverage angle, type, pendant height)
  /// - [coveragePreference]: Coverage overlap preference (edgeToEdge, minimumOverlap, centerToCenter)
  /// - [layoutPattern]: Grid layout pattern (square or hexagonal)
  /// - [customOriginOffset]: Optional offset from room centroid for speaker grid origin (default: null = use centroid)
  /// - [boundaryOverlapThreshold]: Minimum fraction of speaker coverage that must be within room (default: 0.7 = 70%)
  ///   Lower values (e.g., 0.5) allow more speakers near boundaries, higher values (e.g., 0.9) are more conservative
  static PlacementResult calculatePlacement({
    required Room room,
    required SpeakerSpec speakerSpec,
    required CoveragePreference coveragePreference,
    LayoutPattern layoutPattern = LayoutPattern.square,
    Point2D? customOriginOffset,
    double boundaryOverlapThreshold = 0.7,
  }) {
    List<String> steps = [];

    // Step 1: Find geometric center (centroid) and apply custom offset if provided
    Point2D baseCentroid = room.centroid;
    Point2D effectiveOrigin = customOriginOffset != null ? Point2D(baseCentroid.x + customOriginOffset.x, baseCentroid.y + customOriginOffset.y) : baseCentroid;

    steps.add('Step 1: Base centroid calculated at $baseCentroid');
    if (customOriginOffset != null) {
      steps.add('Step 1.1: Custom origin offset applied: $customOriginOffset');
      steps.add('Step 1.2: Effective origin: $effectiveOrigin');
    }

    // Step 2: Calculate distance based on speaker type
    double distance = _calculateDistance(room, speakerSpec, steps);

    // Step 3: Calculate grid spacing with asymmetrical room optimization
    double gridSpacing = _calculateGridSpacing(speakerSpec.coverageAngle, distance, coveragePreference, steps);

    // Step 3.1: Apply asymmetrical room optimization to reduce speaker density
    if (room.roomType == RoomType.asymmetrical) {
      double originalSpacing = gridSpacing;
      gridSpacing = _optimizeGridSpacingForAsymmetricalRoom(room, gridSpacing, distance, steps);

      if (gridSpacing != originalSpacing) {
        steps.add('Step 3.1: Asymmetrical room optimization applied:');
        steps.add('  Original spacing: ${originalSpacing.toStringAsFixed(2)}m');
        steps.add('  Optimized spacing: ${gridSpacing.toStringAsFixed(2)}m');
        steps.add('  Reason: Reduce speaker density for irregular room shape');
      }
    }

    // Step 4: Create grid layout
    List<Point2D> gridPoints = _createGridLayout(room, effectiveOrigin, gridSpacing, layoutPattern, steps);

    // Step 5: Remove speakers whose coverage circles overlap with room boundaries
    List<Point2D> validSpeakers = _filterBoundariesByCoverage(gridPoints, room, distance, speakerSpec.coverageAngle, boundaryOverlapThreshold, steps);

    // Step 6: Final safety check for asymmetrical rooms - ensure practical speaker count
    if (room.roomType == RoomType.asymmetrical) {
      validSpeakers = _applyFinalSpeakerCountLimit(validSpeakers, room, steps);
    }

    return PlacementResult(
      speakerPositions: validSpeakers,
      gridSpacing: gridSpacing,
      centroid: effectiveOrigin,
      baseCentroid: baseCentroid,
      customOriginOffset: customOriginOffset,
      distance: distance,
      calculationSteps: steps,
    );
  }

  /// Step 2: Calculate distance from speaker to listener plane
  /// Supports ceiling and pendant speakers only
  static double _calculateDistance(Room room, SpeakerSpec speakerSpec, List<String> steps) {
    double distance;

    switch (speakerSpec.type) {
      case SpeakerType.ceiling:
        // Ceiling speakers: distance from ceiling to listener height
        distance = room.ceilingHeight - room.listenerHeight;
        steps.add('Step 2: d_ceiling = ${room.ceilingHeight} - ${room.listenerHeight} = ${distance}m');
        break;

      case SpeakerType.pendant:
        // Pendant speakers: distance from ceiling to speaker height (pendant height)
        if (speakerSpec.pendantHeight == null) {
          throw ArgumentError('Pendant height required for pendant speakers');
        }
        distance = room.ceilingHeight - speakerSpec.pendantHeight!;
        steps.add('Step 2: d_pendant = ${room.ceilingHeight} - ${speakerSpec.pendantHeight} = ${distance}m');
        break;
    }

    // Validate distance to prevent calculation errors
    if (distance <= 0) {
      throw ArgumentError(
        'Invalid room configuration: Distance from speaker to listener plane must be positive. '
        'Current distance: ${distance}m. '
        'For ceiling speakers: ceiling height (${room.ceilingHeight}m) must be greater than listener height (${room.listenerHeight}m). '
        'For pendant speakers: ceiling height must be greater than pendant height.',
      );
    }

    return distance;
  }

  /// Step 3: Calculate grid spacing using alternate formula from document
  /// Formula: Grid spacing = sin(θ/2) × 4d × overlap × DG correction
  static double _calculateGridSpacing(double coverageAngleDegrees, double distance, CoveragePreference preference, List<String> steps) {
    // Validate inputs
    if (coverageAngleDegrees <= 0 || coverageAngleDegrees >= 180) {
      throw ArgumentError('Coverage angle must be between 0 and 180 degrees, got: $coverageAngleDegrees');
    }

    if (distance <= 0) {
      throw ArgumentError('Distance must be positive, got: $distance');
    }

    // Convert angle to radians for sin calculation
    double halfAngleRadians = (coverageAngleDegrees / 2) * (pi / 180);
    double sinHalfAngle = sin(halfAngleRadians);

    // Apply alternate formula
    double gridSpacing = sinHalfAngle * 4 * distance * preference.overlapMultiplier * dgCorrection;

    steps.add('Step 3: Grid spacing calculation:');
    steps.add('  θ = $coverageAngleDegrees°, θ/2 = ${(coverageAngleDegrees / 2).toStringAsFixed(1)}°');
    steps.add('  sin(${coverageAngleDegrees / 2}°) = ${sinHalfAngle.toStringAsFixed(3)}');
    steps.add('  overlap = $preference.overlapMultiplier ($preference.name)');
    steps.add('  Grid spacing = ${sinHalfAngle.toStringAsFixed(3)} × 4 × $distance × ${preference.overlapMultiplier} × $dgCorrection');
    steps.add('  Grid spacing = ${gridSpacing.toStringAsFixed(2)}m');

    // Final validation for grid spacing
    if (gridSpacing <= 0 || !gridSpacing.isFinite) {
      throw ArgumentError('Invalid grid spacing calculated: $gridSpacing. Check input parameters.');
    }

    return gridSpacing;
  }

  /// Optimize grid spacing for asymmetrical rooms to reduce speaker density
  /// This ensures practical speaker counts for irregular room shapes
  static double _optimizeGridSpacingForAsymmetricalRoom(Room room, double originalSpacing, double distance, List<String> steps) {
    if (room.roomType != RoomType.asymmetrical || room.customGeometry == null) {
      return originalSpacing;
    }

    // Calculate room area for density analysis
    double roomArea = room.calculatePolygonArea(room.customGeometry!);

    // Estimate initial speaker count with original spacing
    double estimatedSpeakers = roomArea / (originalSpacing * originalSpacing);

    // Define practical speaker count limits based on room area
    double maxPracticalSpeakers;
    if (roomArea <= 20) {
      // Small rooms (≤20 m²)
      maxPracticalSpeakers = 4;
    } else if (roomArea <= 50) {
      // Medium rooms (20-50 m²)
      maxPracticalSpeakers = 8;
    } else if (roomArea <= 100) {
      // Large rooms (50-100 m²)
      maxPracticalSpeakers = 12;
    } else {
      // Very large rooms (>100 m²)
      maxPracticalSpeakers = 16;
    }

    // If estimated speakers exceed practical limit, increase spacing
    if (estimatedSpeakers > maxPracticalSpeakers) {
      double densityReductionFactor = sqrt(estimatedSpeakers / maxPracticalSpeakers);
      double optimizedSpacing = originalSpacing * densityReductionFactor;

      // Ensure minimum spacing of 2.0m for asymmetrical rooms (industry standard)
      optimizedSpacing = max(optimizedSpacing, 2.0);

      // Also ensure we don't exceed reasonable maximum spacing (4.0m)
      optimizedSpacing = min(optimizedSpacing, 4.0);

      return optimizedSpacing;
    }

    // If spacing is already reasonable, ensure minimum 1.5m for asymmetrical rooms
    return max(originalSpacing, 1.5);
  }

  /// Apply final speaker count limit for asymmetrical rooms as a safety measure
  /// If the algorithm still produces too many speakers, intelligently reduce them
  static List<Point2D> _applyFinalSpeakerCountLimit(List<Point2D> speakers, Room room, List<String> steps) {
    if (room.customGeometry == null) return speakers;

    double roomArea = room.calculatePolygonArea(room.customGeometry!);

    // Define absolute maximum limits (conservative approach)
    int maxAllowedSpeakers;
    if (roomArea <= 25) {
      // Small rooms (≤25 m²)
      maxAllowedSpeakers = 6;
    } else if (roomArea <= 60) {
      // Medium rooms (25-60 m²)
      maxAllowedSpeakers = 10;
    } else if (roomArea <= 120) {
      // Large rooms (60-120 m²)
      maxAllowedSpeakers = 16;
    } else {
      // Very large rooms (>120 m²)
      maxAllowedSpeakers = 20;
    }

    if (speakers.length <= maxAllowedSpeakers) {
      return speakers; // No reduction needed
    }

    // Need to reduce speaker count - use intelligent selection
    List<Point2D> optimizedSpeakers = _selectOptimalSpeakers(speakers, maxAllowedSpeakers, room);

    steps.add('Step 6: Final speaker count optimization for asymmetrical room:');
    steps.add('  Room area: ${roomArea.toStringAsFixed(1)} m²');
    steps.add('  Initial speakers after filtering: ${speakers.length}');
    steps.add('  Maximum practical speakers: $maxAllowedSpeakers');
    steps.add('  Final optimized speakers: ${optimizedSpeakers.length}');

    return optimizedSpeakers;
  }

  /// Select optimal subset of speakers using distance-based optimization
  /// Prioritizes speakers that are well-distributed and away from boundaries
  static List<Point2D> _selectOptimalSpeakers(List<Point2D> allSpeakers, int targetCount, Room room) {
    if (allSpeakers.length <= targetCount) return allSpeakers;

    List<Point2D> selected = [];
    List<Point2D> remaining = List.from(allSpeakers);

    // Step 1: Always include the speaker closest to centroid
    Point2D centroid = room.centroid;
    remaining.sort((a, b) {
      double distA = sqrt(pow(a.x - centroid.x, 2) + pow(a.y - centroid.y, 2));
      double distB = sqrt(pow(b.x - centroid.x, 2) + pow(b.y - centroid.y, 2));
      return distA.compareTo(distB);
    });

    selected.add(remaining.removeAt(0));

    // Step 2: Iteratively select speakers that maximize minimum distance to already selected speakers
    while (selected.length < targetCount && remaining.isNotEmpty) {
      Point2D? bestCandidate;
      double bestMinDistance = 0;

      for (Point2D candidate in remaining) {
        double minDistance = double.infinity;

        for (Point2D selectedSpeaker in selected) {
          double distance = sqrt(pow(candidate.x - selectedSpeaker.x, 2) + pow(candidate.y - selectedSpeaker.y, 2));
          minDistance = min(minDistance, distance);
        }

        if (minDistance > bestMinDistance) {
          bestMinDistance = minDistance;
          bestCandidate = candidate;
        }
      }

      if (bestCandidate != null) {
        selected.add(bestCandidate);
        remaining.remove(bestCandidate);
      } else {
        break;
      }
    }

    return selected;
  }

  /// Step 4: Create grid layout (square or hexagonal)
  static List<Point2D> _createGridLayout(Room room, Point2D centroid, double gridSpacing, LayoutPattern pattern, List<String> steps) {
    List<Point2D> gridPoints = [];

    switch (pattern) {
      case LayoutPattern.square:
        gridPoints = _createSquareGrid(room, centroid, gridSpacing);
        steps.add('Step 4: Created square grid layout with ${gridPoints.length} initial positions');
        break;

      case LayoutPattern.hexagonal:
        gridPoints = _createHexagonalGrid(room, centroid, gridSpacing);
        steps.add('Step 4: Created hexagonal grid layout with ${gridPoints.length} initial positions');
        break;
    }

    return gridPoints;
  }

  /// Create square grid pattern - starting from centroid
  static List<Point2D> _createSquareGrid(Room room, Point2D centroid, double spacing) {
    List<Point2D> points = [];

    // Safety check for spacing
    if (spacing <= 0 || !spacing.isFinite) {
      throw ArgumentError('Invalid spacing for grid creation: $spacing');
    }

    // Step 1: Always place the first speaker at the centroid
    points.add(centroid);

    // Step 2: Calculate how many additional speakers we can fit in each direction
    // Use safe division and bounds checking
    double maxStepsXDouble = (room.width - centroid.x) / spacing;
    double maxStepsYDouble = (room.roomLength - centroid.y) / spacing;
    double minStepsXDouble = centroid.x / spacing;
    double minStepsYDouble = centroid.y / spacing;

    // Check for finite values before converting to int
    if (!maxStepsXDouble.isFinite || !maxStepsYDouble.isFinite || !minStepsXDouble.isFinite || !minStepsYDouble.isFinite) {
      throw ArgumentError('Invalid step calculations for grid creation. Check spacing value: $spacing');
    }

    int maxStepsX = maxStepsXDouble.floor();
    int maxStepsY = maxStepsYDouble.floor();
    int minStepsX = minStepsXDouble.floor();
    int minStepsY = minStepsYDouble.floor();

    // Limit maximum steps to prevent excessive grid sizes
    const int maxGridSteps = 1000;
    maxStepsX = maxStepsX.clamp(0, maxGridSteps);
    maxStepsY = maxStepsY.clamp(0, maxGridSteps);
    minStepsX = minStepsX.clamp(0, maxGridSteps);
    minStepsY = minStepsY.clamp(0, maxGridSteps);

    // Step 3: Create grid radiating outward from centroid
    for (int i = -minStepsX; i <= maxStepsX; i++) {
      for (int j = -minStepsY; j <= maxStepsY; j++) {
        // Skip the centroid position as it's already added
        if (i == 0 && j == 0) continue;

        double x = centroid.x + (i * spacing);
        double y = centroid.y + (j * spacing);

        // Only add positions that are within room bounds
        if (x >= 0 && x <= room.width && y >= 0 && y <= room.roomLength) {
          points.add(Point2D(x, y));
        }
      }
    }

    return points;
  }

  /// Create hexagonal grid pattern - starting from centroid
  /// Follows the hexagonal layout pattern as shown in design documentation
  static List<Point2D> _createHexagonalGrid(Room room, Point2D centroid, double spacing) {
    List<Point2D> points = [];

    // Safety check for spacing
    if (spacing <= 0 || !spacing.isFinite) {
      throw ArgumentError('Invalid spacing for grid creation: $spacing');
    }

    // Step 1: Always place the first speaker at the centroid
    points.add(centroid);

    // Hexagonal grid calculations as per documentation and design pattern
    // For hexagonal packing: horizontal spacing = spacing, vertical spacing = spacing * sqrt(3)/2
    double horizontalSpacing = spacing;
    double verticalSpacing = spacing * sqrt(3) / 2;
    double rowOffset = spacing / 2; // Offset for alternating rows

    // Step 2: Calculate how many steps we can take in each direction from centroid
    double maxStepsXDouble = (room.width - centroid.x) / horizontalSpacing;
    double maxStepsYDouble = (room.roomLength - centroid.y) / verticalSpacing;
    double minStepsXDouble = centroid.x / horizontalSpacing;
    double minStepsYDouble = centroid.y / verticalSpacing;

    // Check for finite values before converting to int
    if (!maxStepsXDouble.isFinite || !maxStepsYDouble.isFinite || !minStepsXDouble.isFinite || !minStepsYDouble.isFinite) {
      throw ArgumentError('Invalid step calculations for hexagonal grid creation. Check spacing value: $spacing');
    }

    int maxStepsX = maxStepsXDouble.floor();
    int maxStepsY = maxStepsYDouble.floor();
    int minStepsX = minStepsXDouble.floor();
    int minStepsY = minStepsYDouble.floor();

    // Limit maximum steps to prevent excessive grid sizes
    const int maxGridSteps = 1000;
    maxStepsX = maxStepsX.clamp(0, maxGridSteps);
    maxStepsY = maxStepsY.clamp(0, maxGridSteps);
    minStepsX = minStepsX.clamp(0, maxGridSteps);
    minStepsY = minStepsY.clamp(0, maxGridSteps);

    // Step 3: Create hexagonal grid radiating outward from centroid
    for (int rowIndex = -minStepsY; rowIndex <= maxStepsY; rowIndex++) {
      for (int colIndex = -minStepsX; colIndex <= maxStepsX; colIndex++) {
        // Skip the centroid position as it's already added
        if (rowIndex == 0 && colIndex == 0) continue;

        double x = centroid.x + (colIndex * horizontalSpacing);
        double y = centroid.y + (rowIndex * verticalSpacing);

        // Apply hexagonal offset: every other row is shifted by half spacing
        // This creates the characteristic hexagonal pattern
        if (rowIndex % 2 != 0) {
          x += rowOffset;
        }

        // Only add positions that are within room bounds
        if (x >= 0 && x <= room.width && y >= 0 && y <= room.roomLength) {
          points.add(Point2D(x, y));
        }
      }
    }

    return points;
  }

  /// Step 5: Filter speakers based on coverage circle boundary overlap
  /// Enhanced boundary filtering based on coverage circle overlap
  /// Remove speakers whose coverage circles extend beyond room boundaries
  /// Works with both rectangular and asymmetrical rooms
  static List<Point2D> _filterBoundariesByCoverage(
    List<Point2D> gridPoints,
    Room room,
    double distance,
    double coverageAngleDegrees,
    double boundaryOverlapThreshold,
    List<String> steps,
  ) {
    List<Point2D> validSpeakers = [];
    List<Point2D> removedSpeakers = [];

    // Calculate coverage radius at listener plane
    double coverageRadius = _calculateCoverageRadius(distance, coverageAngleDegrees);

    for (Point2D point in gridPoints) {
      bool isValid;

      if (room.roomType == RoomType.asymmetrical) {
        // For asymmetrical rooms, check if the speaker position is within the room boundary
        // and if the coverage circle doesn't extend too far beyond room edges
        isValid = _isSpeakerValidInAsymmetricalRoom(point, coverageRadius, room, boundaryOverlapThreshold);
      } else {
        // For rectangular rooms, also use threshold-based filtering
        isValid = _isSpeakerValidInRectangularRoom(point, coverageRadius, room, boundaryOverlapThreshold);
      }

      if (isValid) {
        validSpeakers.add(point);
      } else {
        removedSpeakers.add(point);
      }
    }

    String roomTypeDesc = room.roomType == RoomType.asymmetrical ? 'asymmetrical' : 'rectangular';
    String filteringDesc = 'Threshold-based filtering (requires ${(boundaryOverlapThreshold * 100).toStringAsFixed(0)}% coverage within room)';

    steps.add('Step 5: Coverage circle boundary filtering ($roomTypeDesc room):');
    steps.add('  $filteringDesc');
    steps.add('  Coverage radius at listener plane: ${coverageRadius.toStringAsFixed(2)}m');
    steps.add('  Boundary overlap threshold: ${(boundaryOverlapThreshold * 100).toStringAsFixed(0)}% coverage within room');
    steps.add('  Total initial positions: ${gridPoints.length}');
    steps.add('  Removed (coverage issues or outside boundary): ${removedSpeakers.length}');
    steps.add('  Valid speakers remaining: ${validSpeakers.length}');

    if (removedSpeakers.isNotEmpty) {
      steps.add('  Removed positions: ${removedSpeakers.join(', ')}');
    }

    return validSpeakers;
  }

  /// Check if speaker is valid in rectangular room using threshold-based filtering
  /// Allows configurable amount of coverage to extend outside room boundaries
  static bool _isSpeakerValidInRectangularRoom(Point2D speakerPosition, double coverageRadius, Room room, double boundaryOverlapThreshold) {
    // First check if speaker position itself is within room
    if (speakerPosition.x < 0 || speakerPosition.x > room.width || speakerPosition.y < 0 || speakerPosition.y > room.roomLength) {
      return false;
    }

    // Sample points around the coverage circle to check how much is within room
    int samplePoints = 8; // Check 8 points around the circle (every 45 degrees)
    int validPoints = 0;

    // Also check the center point
    validPoints++; // Speaker position is already confirmed to be within room

    for (int i = 0; i < samplePoints; i++) {
      double angle = (i * 2 * pi) / samplePoints;
      double sampleX = speakerPosition.x + coverageRadius * cos(angle);
      double sampleY = speakerPosition.y + coverageRadius * sin(angle);

      // Check if this sample point is within room boundaries
      if (sampleX >= 0 && sampleX <= room.width && sampleY >= 0 && sampleY <= room.roomLength) {
        validPoints++;
      }
    }

    // Calculate percentage of coverage within room
    double totalSamplePoints = samplePoints + 1; // +1 for center point
    double validPercentage = validPoints / totalSamplePoints;

    // Use the configurable threshold
    return validPercentage >= boundaryOverlapThreshold;
  }

  /// Check if speaker is valid in asymmetrical room
  /// Combines position check with coverage area validation
  static bool _isSpeakerValidInAsymmetricalRoom(Point2D speakerPosition, double coverageRadius, Room room, double boundaryOverlapThreshold) {
    // First check if speaker position itself is within room
    if (!room.contains(speakerPosition)) {
      return false;
    }

    // For asymmetrical rooms, we need to be more aggressive about excluding border speakers
    // to ensure good coverage and avoid speakers that are too close to irregular edges

    // Calculate minimum distance from edges - should be at least 50% of coverage radius
    // This ensures the speaker's coverage circle is well within the room boundaries
    double minDistanceFromEdge = coverageRadius * boundaryOverlapThreshold;

    // Check if speaker is too close to any boundary
    if (room.isNearBoundary(speakerPosition, minDistanceFromEdge)) {
      return false;
    }

    // Additional check: ensure the coverage circle doesn't extend too far outside room boundaries
    // Sample points around the coverage circle to verify most of the coverage area is within room
    return _validateCoverageAreaInAsymmetricalRoom(speakerPosition, coverageRadius, room, boundaryOverlapThreshold);
  }

  /// Validate that most of the speaker's coverage area is within the asymmetrical room
  static bool _validateCoverageAreaInAsymmetricalRoom(Point2D speakerPosition, double coverageRadius, Room room, double boundaryOverlapThreshold) {
    // Sample points around the coverage circle
    int samplePoints = 8; // Check 8 points around the circle (every 45 degrees)
    int validPoints = 0;

    for (int i = 0; i < samplePoints; i++) {
      double angle = (i * 2 * pi) / samplePoints;
      double sampleX = speakerPosition.x + coverageRadius * cos(angle);
      double sampleY = speakerPosition.y + coverageRadius * sin(angle);
      Point2D samplePoint = Point2D(sampleX, sampleY);

      if (room.contains(samplePoint)) {
        validPoints++;
      }
    }

    // Require the configured threshold of coverage area to be within room boundaries
    // This is now configurable - default is 70% but can be adjusted for more/less strict boundary requirements
    print("Valid coverage points: $validPoints out of $samplePoints.  $boundaryOverlapThreshold");
    double validPercentage = validPoints / samplePoints;
    return validPercentage >= boundaryOverlapThreshold;
  }

  /// Calculate coverage radius at listener plane using coverage angle and distance
  static double _calculateCoverageRadius(double distance, double coverageAngleDegrees) {
    // Convert half angle to radians
    double halfAngleRadians = (coverageAngleDegrees / 2) * (pi / 180);

    // Calculate radius using tan(θ/2) = radius / distance
    // Therefore: radius = distance × tan(θ/2)
    double coverageRadius = distance * tan(halfAngleRadians);

    return coverageRadius;
  }
}
