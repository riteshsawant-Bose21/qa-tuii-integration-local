import 'dart:math';

/// Represents a 2D point/coordinate
class Point2D {
  final double x;
  final double y;
  
  const Point2D(this.x, this.y);
  
  @override
  String toString() => '($x, $y)';
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Point2D && runtimeType == other.runtimeType &&
      x == other.x && y == other.y;
  
  @override
  int get hashCode => x.hashCode ^ y.hashCode;
}

/// Represents a rectangular room
class Room {
  final double width;
  final double height;
  final double ceilingHeight;
  final double listenerHeight;
  
  const Room({
    required this.width,
    required this.height,
    required this.ceilingHeight,
    required this.listenerHeight,
  });
  
  /// Calculate geometric center (centroid) of rectangular room
  Point2D get centroid => Point2D(width / 2, height / 2);
  
  /// Check if a point is within room boundaries
  bool contains(Point2D point) {
    return point.x >= 0 && point.x <= width && 
           point.y >= 0 && point.y <= height;
  }
  
  /// Check if point is "near" boundary (within overlap region)
  bool isNearBoundary(Point2D point, double overlapDistance) {
    return point.x < overlapDistance || point.x > (width - overlapDistance) ||
           point.y < overlapDistance || point.y > (height - overlapDistance);
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
enum LayoutPattern {
  square,
  hexagonal
}

/// Speaker type for mounting calculations
/// This library supports only ceiling-mounted and pendant-mounted speakers
enum SpeakerType {
  /// Ceiling-mounted speakers installed flush with the ceiling
  ceiling,
  
  /// Pendant-mounted speakers suspended from the ceiling at a specified height
  pendant
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
  }) : assert(type == SpeakerType.ceiling || type == SpeakerType.pendant, 
             'Only ceiling and pendant speakers are supported');
}

/// Result of speaker placement calculation
class PlacementResult {
  final List<Point2D> speakerPositions;
  final double gridSpacing;
  final Point2D centroid;
  final double distance;
  final List<String> calculationSteps;
  
  const PlacementResult({
    required this.speakerPositions,
    required this.gridSpacing,
    required this.centroid,
    required this.distance,
    required this.calculationSteps,
  });
  
  @override
  String toString() {
    return '''
PlacementResult:
  Speakers: ${speakerPositions.length}
  Grid Spacing: ${gridSpacing.toStringAsFixed(2)}ft
  Centroid: $centroid
  Distance: ${distance.toStringAsFixed(2)}ft
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
  /// DG correction factor - set to 1.0 (inactive) as per document
  static const double dgCorrection = 1.0;
  
  /// Calculate speaker placement following the exact algorithm from document
  static PlacementResult calculatePlacement({
    required Room room,
    required SpeakerSpec speakerSpec,
    required CoveragePreference coveragePreference,
    LayoutPattern layoutPattern = LayoutPattern.square,
    Point2D? customOrigin,
  }) {
    List<String> steps = [];
    
    // Step 1: Find geometric center (centroid)
    Point2D centroid = customOrigin ?? room.centroid;
    steps.add('Step 1: Centroid calculated at $centroid');
    
    // Step 2: Calculate distance based on speaker type
    double distance = _calculateDistance(room, speakerSpec, steps);
    
    // Step 3: Calculate grid spacing using alternate formula
    double gridSpacing = _calculateGridSpacing(
      speakerSpec.coverageAngle, 
      distance, 
      coveragePreference,
      steps
    );
    
    // Step 4: Create grid layout
    List<Point2D> gridPoints = _createGridLayout(
      centroid, 
      gridSpacing, 
      layoutPattern,
      steps
    );
    
    // Step 5: Remove out-of-bounds speakers
    List<Point2D> validSpeakers = _filterBoundaries(
      gridPoints, 
      room, 
      gridSpacing * coveragePreference.overlapMultiplier,
      steps
    );
    
    return PlacementResult(
      speakerPositions: validSpeakers,
      gridSpacing: gridSpacing,
      centroid: centroid,
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
        steps.add('Step 2: d_ceiling = ${room.ceilingHeight} - ${room.listenerHeight} = ${distance}ft');
        break;
        
      case SpeakerType.pendant:
        // Pendant speakers: distance from ceiling to speaker height (pendant height)
        if (speakerSpec.pendantHeight == null) {
          throw ArgumentError('Pendant height required for pendant speakers');
        }
        distance = room.ceilingHeight - speakerSpec.pendantHeight!;
        steps.add('Step 2: d_pendant = ${room.ceilingHeight} - ${speakerSpec.pendantHeight} = ${distance}ft');
        break;
    }
    
    return distance;
  }
  
  /// Step 3: Calculate grid spacing using alternate formula from document
  /// Formula: Grid spacing = sin(θ/2) × 4d × overlap × DG correction
  static double _calculateGridSpacing(
    double coverageAngleDegrees, 
    double distance, 
    CoveragePreference preference,
    List<String> steps
  ) {
    // Convert angle to radians for sin calculation
    double halfAngleRadians = (coverageAngleDegrees / 2) * (pi / 180);
    double sinHalfAngle = sin(halfAngleRadians);
    
    // Apply alternate formula
    double gridSpacing = sinHalfAngle * 4 * distance * preference.overlapMultiplier * dgCorrection;
    
    steps.add('Step 3: Grid spacing calculation:');
    steps.add('  θ = ${coverageAngleDegrees}°, θ/2 = ${coverageAngleDegrees/2}°');
    steps.add('  sin(${coverageAngleDegrees/2}°) = ${sinHalfAngle.toStringAsFixed(3)}');
    steps.add('  overlap = ${preference.overlapMultiplier} (${preference.name})');
    steps.add('  Grid spacing = ${sinHalfAngle.toStringAsFixed(3)} × 4 × $distance × ${preference.overlapMultiplier} × $dgCorrection');
    steps.add('  Grid spacing = ${gridSpacing.toStringAsFixed(2)}ft');
    
    return gridSpacing;
  }
  
  /// Step 4: Create grid layout (square or hexagonal)
  static List<Point2D> _createGridLayout(
    Point2D centroid, 
    double gridSpacing, 
    LayoutPattern pattern,
    List<String> steps
  ) {
    List<Point2D> gridPoints = [];
    
    switch (pattern) {
      case LayoutPattern.square:
        gridPoints = _createSquareGrid(centroid, gridSpacing);
        steps.add('Step 4: Created square grid layout with ${gridPoints.length} initial positions');
        break;
        
      case LayoutPattern.hexagonal:
        gridPoints = _createHexagonalGrid(centroid, gridSpacing);
        steps.add('Step 4: Created hexagonal grid layout with ${gridPoints.length} initial positions');
        break;
    }
    
    return gridPoints;
  }
  
  /// Create square grid pattern
  static List<Point2D> _createSquareGrid(Point2D centroid, double spacing) {
    List<Point2D> points = [];
    
    // Create 3x3 grid centered on centroid
    for (int i = -1; i <= 1; i++) {
      for (int j = -1; j <= 1; j++) {
        double x = centroid.x + (i * spacing);
        double y = centroid.y + (j * spacing);
        points.add(Point2D(x, y));
      }
    }
    
    return points;
  }
  
  /// Create hexagonal grid pattern
  static List<Point2D> _createHexagonalGrid(Point2D centroid, double spacing) {
    List<Point2D> points = [];
    
    // Hexagonal offset calculations as per document
    double xOffset = spacing / 2;
    double yOffset = sqrt(3) * (spacing / 2); // Pythagorean theorem
    
    // Create hexagonal pattern (simplified 3x3 with offsets)
    for (int row = -1; row <= 1; row++) {
      for (int col = -1; col <= 1; col++) {
        double x = centroid.x + (col * spacing);
        double y = centroid.y + (row * yOffset);
        
        // Apply hexagonal offset for every other row
        if (row % 2 != 0) {
          x += xOffset;
        }
        
        points.add(Point2D(x, y));
      }
    }
    
    return points;
  }
  
  /// Step 5: Filter speakers based on room boundaries
  static List<Point2D> _filterBoundaries(
    List<Point2D> gridPoints, 
    Room room, 
    double overlapDistance,
    List<String> steps
  ) {
    List<Point2D> validSpeakers = [];
    List<Point2D> removedSpeakers = [];
    
    for (Point2D point in gridPoints) {
      if (room.contains(point)) {
        // Additional check for "near" boundary as defined in document
        if (!room.isNearBoundary(point, overlapDistance)) {
          validSpeakers.add(point);
        } else {
          // Speaker is within bounds but "near" boundary (within overlap region)
          validSpeakers.add(point); // Keep it but note the condition
        }
      } else {
        removedSpeakers.add(point);
      }
    }
    
    steps.add('Step 5: Boundary filtering:');
    steps.add('  Total initial positions: ${gridPoints.length}');
    steps.add('  Removed (out of bounds): ${removedSpeakers.length}');
    steps.add('  Valid speakers remaining: ${validSpeakers.length}');
    
    if (removedSpeakers.isNotEmpty) {
      steps.add('  Removed positions: ${removedSpeakers.join(', ')}');
    }
    
    return validSpeakers;
  }
}