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
  final double roomLength;
  final double ceilingHeight;
  final double listenerHeight;
  
  Room({
    required this.width,
    required this.roomLength,
    required this.ceilingHeight,
    required this.listenerHeight,
  }) {
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
      throw ArgumentError(
        'Ceiling height ($ceilingHeight) must be greater than listener height ($listenerHeight)'
      );
    }
  }
  
  /// Calculate geometric center (centroid) of rectangular room
  Point2D get centroid => Point2D(width / 2, roomLength / 2);
  
  /// Check if a point is within room boundaries
  bool contains(Point2D point) {
    return point.x >= 0 && point.x <= width && 
           point.y >= 0 && point.y <= roomLength;
  }
  
  /// Check if point is "near" boundary (within overlap region)
  bool isNearBoundary(Point2D point, double overlapDistance) {
    return point.x < overlapDistance || point.x > (width - overlapDistance) ||
           point.y < overlapDistance || point.y > (roomLength - overlapDistance);
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
  Grid Spacing: ${gridSpacing.toStringAsFixed(2)}m
  Centroid: $centroid
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
  
  /// Calculate speaker placement  
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
    
    // Step 3: Calculate grid spacing 
    double gridSpacing = _calculateGridSpacing(
      speakerSpec.coverageAngle, 
      distance, 
      coveragePreference,
      steps
    );
    
    // Step 4: Create grid layout
    List<Point2D> gridPoints = _createGridLayout(
      room,
      centroid, 
      gridSpacing, 
      layoutPattern,
      steps
    );
    
    // Step 5: Remove speakers whose coverage circles overlap with room boundaries
    List<Point2D> validSpeakers = _filterBoundariesByCoverage(
      gridPoints, 
      room, 
      distance,
      speakerSpec.coverageAngle,
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
        'For pendant speakers: ceiling height must be greater than pendant height.'
      );
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
    steps.add('  θ = $coverageAngleDegrees°, θ/2 = ${(coverageAngleDegrees/2).toStringAsFixed(1)}°');
    steps.add('  sin(${coverageAngleDegrees/2}°) = ${sinHalfAngle.toStringAsFixed(3)}');
    steps.add('  overlap = $preference.overlapMultiplier ($preference.name)');
    steps.add('  Grid spacing = ${sinHalfAngle.toStringAsFixed(3)} × 4 × $distance × ${preference.overlapMultiplier} × $dgCorrection');
    steps.add('  Grid spacing = ${gridSpacing.toStringAsFixed(2)}m');
    
    // Final validation for grid spacing
    if (gridSpacing <= 0 || !gridSpacing.isFinite) {
      throw ArgumentError('Invalid grid spacing calculated: $gridSpacing. Check input parameters.');
    }
    
    return gridSpacing;
  }
  
  /// Step 4: Create grid layout (square or hexagonal)
  static List<Point2D> _createGridLayout(
    Room room,
    Point2D centroid, 
    double gridSpacing, 
    LayoutPattern pattern,
    List<String> steps
  ) {
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
    if (!maxStepsXDouble.isFinite || !maxStepsYDouble.isFinite || 
        !minStepsXDouble.isFinite || !minStepsYDouble.isFinite) {
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
    if (!maxStepsXDouble.isFinite || !maxStepsYDouble.isFinite || 
        !minStepsXDouble.isFinite || !minStepsYDouble.isFinite) {
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
  static List<Point2D> _filterBoundariesByCoverage(
    List<Point2D> gridPoints,
    Room room,
    double distance,
    double coverageAngleDegrees,
    List<String> steps
  ) {
    List<Point2D> validSpeakers = [];
    List<Point2D> removedSpeakers = [];
    
    // Calculate coverage radius at listener plane
    double coverageRadius = _calculateCoverageRadius(distance, coverageAngleDegrees);
    
    for (Point2D point in gridPoints) {
      bool isValid = _isCoverageCircleWithinRoom(point, coverageRadius, room);
      
      if (isValid) {
        validSpeakers.add(point);
      } else {
        removedSpeakers.add(point);
      }
    }
    
    steps.add('Step 5: Coverage circle boundary filtering:');
    steps.add('  Coverage radius at listener plane: ${coverageRadius.toStringAsFixed(2)}m');
    steps.add('  Total initial positions: ${gridPoints.length}');
    steps.add('  Removed (coverage circle overlaps boundary): ${removedSpeakers.length}');
    steps.add('  Valid speakers remaining: ${validSpeakers.length}');
    
    if (removedSpeakers.isNotEmpty) {
      steps.add('  Removed positions: ${removedSpeakers.join(', ')}');
    }
    
    return validSpeakers;
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

  /// Check if speaker's coverage circle is completely within room boundaries
  static bool _isCoverageCircleWithinRoom(Point2D speakerPosition, double coverageRadius, Room room) {
    // Check if the coverage circle extends beyond any room boundary
    
    // Left boundary
    if (speakerPosition.x - coverageRadius < 0) return false;
    
    // Right boundary  
    if (speakerPosition.x + coverageRadius > room.width) return false;
    
    // Bottom boundary
    if (speakerPosition.y - coverageRadius < 0) return false;
    
    // Top boundary
    if (speakerPosition.y + coverageRadius > room.roomLength) return false;
    
    // If all checks pass, coverage circle is within room
    return true;
  }
}