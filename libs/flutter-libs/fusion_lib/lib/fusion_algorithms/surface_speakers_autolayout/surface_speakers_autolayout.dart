import 'dart:math';
import 'dart:ui' show Offset;

class _WallSegment {
  final Offset start;
  final Offset end;
  final int index;

  const _WallSegment(this.start, this.end, this.index);

  double get length => (end - start).distance;
}

class _PlacedSpeaker {
  final Offset point;
  final int wallIndex;
  final double perimeterPosition;

  /// Inward-facing rotation in degrees (angle of inward wall normal from +X axis).
  final double rotation;

  const _PlacedSpeaker({
    required this.point,
    required this.wallIndex,
    required this.perimeterPosition,
    required this.rotation,
  });
}

class _BoundaryProjection {
  final Offset point;
  final int wallIndex;
  final double perimeterPosition;
  final double rotation;

  const _BoundaryProjection({
    required this.point,
    required this.wallIndex,
    required this.perimeterPosition,
    required this.rotation,
  });
}

/// Coverage preference options for speaker overlap (aligned with ceiling/pendant placement).
///
/// This enum defines the overlap style using the same multiplier approach as ceiling speakers,
/// but note that surface speakers have **directional sector coverage** (not circular coverage).
/// Surface speakers project coverage in a wedge/sector pattern from the wall into the room.
enum CoveragePreference {
  /// Edge-to-edge coverage with no overlap (tangent sectors)
  edgeToEdge(1.0, "minimum/value-oriented arrangement"),

  /// Optimal layout with medium overlap for balanced coverage
  minimumOverlap(0.7, "optimal layout"),

  /// High overlap for critical applications with significant coverage redundancy
  centerToCenter(0.5, "significant interference");

  const CoveragePreference(this.overlapMultiplier, this.description);

  /// Multiplier applied to base coverage width for spacing calculation
  /// Note: This applies to directional coverage sectors, not circles
  final double overlapMultiplier;

  /// Human-readable description of the coverage preference
  final String description;
}

/// Represents a 3D position for a speaker in a room coordinate system.
///
/// The coordinate system follows these conventions:
/// - x: Length dimension (0 to room length)
/// - y: Width dimension (0 to room width)
/// - z: Height dimension (0 to ceiling height)
class SpeakerPosition {
  /// X coordinate in feet (length dimension)
  final double x;

  /// Y coordinate in feet (width dimension)
  final double y;

  /// Z coordinate in feet (height dimension)
  final double z;

  /// Rotation in degrees — inward-facing yaw angle from the +X axis (perpendicular to the wall, pointing into the room).
  final double rotation;

  /// Creates a speaker position with the given coordinates.
  ///
  /// All coordinates should be in feet and non-negative.
  const SpeakerPosition(this.x, this.y, this.z, [this.rotation = 0.0]);

  /// Creates a copy of this position with optionally updated coordinates.
  SpeakerPosition copyWith({double? x, double? y, double? z, double? rotation}) {
    return SpeakerPosition(
      x ?? this.x,
      y ?? this.y,
      z ?? this.z,
      rotation ?? this.rotation,
    );
  }

  /// Calculates the Euclidean distance to another position.
  double distanceTo(SpeakerPosition other) {
    final dx = x - other.x;
    final dy = y - other.y;
    final dz = z - other.z;
    return sqrt(dx * dx + dy * dy + dz * dz);
  }

  /// Validates that all coordinates are non-negative.
  bool get isValid => x >= 0 && y >= 0 && z >= 0;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SpeakerPosition && other.x == x && other.y == y && other.z == z && other.rotation == rotation;
  }

  @override
  int get hashCode => Object.hash(x, y, z, rotation);

  @override
  String toString() =>
      'SpeakerPosition(x: ${x.toStringAsFixed(2)}, y: ${y.toStringAsFixed(2)}, z: ${z.toStringAsFixed(2)}, rotation: ${rotation.toStringAsFixed(1)}°)';

  /// Returns a formatted string for display purposes.
  String toDisplayString() => 'X: ${x.toStringAsFixed(1)}m, Y: ${y.toStringAsFixed(1)}m, Z: ${z.toStringAsFixed(1)}m, Rot: ${rotation.toStringAsFixed(1)}°';

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'z': z,
      'rotation': rotation,
    };
  }

  factory SpeakerPosition.fromJson(Map<String, dynamic> map) {
    return SpeakerPosition(
      map['x']?.toDouble() ?? 0.0,
      map['y']?.toDouble() ?? 0.0,
      map['z']?.toDouble() ?? 0.0,
      map['rotation']?.toDouble() ?? 0.0,
    );
  }
}

/// Represents a room zone with physical dimensions and listener characteristics.
///
/// This class encapsulates all room-related parameters needed for speaker placement calculations.
class SurfaceRoom {
  /// Polygon corners in meters.
  ///
  /// Corners must define a simple polygon in clockwise or counter-clockwise order.
  final List<Offset> corners;

  /// Ceiling height in meters
  final double ceilingHeight;

  /// Listener ear height in meters (typically 1.1-1.4m for seated, 1.7-1.8m for standing, max 2.4m)
  final double listenerHeight;

  /// Creates a room zone with the specified dimensions.
  ///
  /// The polygon must have at least 3 corners and non-zero area.
  ///
  /// Throws [ArgumentError] if any dimension is invalid.
  SurfaceRoom({
    required List<Offset> corners,
    required this.ceilingHeight,
    required this.listenerHeight,
  }) : corners = _normalizeCorners(corners) {
    _validateDimensions();
  }

  static List<Offset> _normalizeCorners(List<Offset> corners) {
    if (corners.isEmpty) return corners;

    final List<Offset> normalized = List<Offset>.from(corners);
    if (normalized.length > 1 && normalized.first == normalized.last) {
      normalized.removeLast();
    }
    return normalized;
  }

  /// Validates that all room dimensions are reasonable.
  void _validateDimensions() {
    if (corners.length < 3) {
      throw ArgumentError('Room polygon must contain at least 3 corners, got: ${corners.length}');
    }
    if (ceilingHeight <= 0) {
      throw ArgumentError('Ceiling height must be positive, got: $ceilingHeight');
    }
    if (listenerHeight <= 0) {
      throw ArgumentError('Listener height must be positive, got: $listenerHeight');
    }
    if (listenerHeight > 2.4) {
      // 2.4 meters max (8 feet equivalent)
      throw ArgumentError('Listener height cannot exceed 2.4 meters, got: $listenerHeight meters');
    }
    if (listenerHeight >= ceilingHeight) {
      throw ArgumentError('Listener height ($listenerHeight m) must be less than ceiling height ($ceilingHeight m)');
    }

    for (int i = 0; i < corners.length; i++) {
      final Offset current = corners[i];
      final Offset next = corners[(i + 1) % corners.length];
      if ((next - current).distance < 0.001) {
        throw ArgumentError('Room polygon contains duplicate or zero-length edge at index $i');
      }
    }

    if (area <= 0.001) {
      throw ArgumentError('Room polygon area must be greater than zero');
    }

    // Check for reasonable dimensions
    if (ceilingHeight < 2.1 || ceilingHeight > 9.1) {
      // 7-30 feet equivalent
      print('Warning: Unusual ceiling height: $ceilingHeight meters');
    }
    if (width > 61.0 || length > 61.0) {
      // 200 feet equivalent
      print('Warning: Very large room dimensions may require different approach');
    }
  }

  /// Room walls as connected segments.
  List<_WallSegment> get walls {
    final List<_WallSegment> segments = <_WallSegment>[];
    for (int i = 0; i < corners.length; i++) {
      segments.add(_WallSegment(corners[i], corners[(i + 1) % corners.length], i));
    }
    return segments;
  }

  /// Axis-aligned room width from polygon bounds.
  double get width => maxX - minX;

  /// Axis-aligned room length from polygon bounds.
  double get length => maxY - minY;

  double get minX => corners.map((Offset p) => p.dx).reduce(min);
  double get maxX => corners.map((Offset p) => p.dx).reduce(max);
  double get minY => corners.map((Offset p) => p.dy).reduce(min);
  double get maxY => corners.map((Offset p) => p.dy).reduce(max);

  /// Room area in square meters
  double get area {
    double sum = 0;
    for (int i = 0; i < corners.length; i++) {
      final Offset current = corners[i];
      final Offset next = corners[(i + 1) % corners.length];
      sum += (current.dx * next.dy) - (next.dx * current.dy);
    }
    return sum.abs() * 0.5;
  }

  /// Room volume in cubic meters
  double get volume => area * ceilingHeight;

  /// Room perimeter in meters
  double get perimeter {
    double total = 0;
    for (final _WallSegment wall in walls) {
      total += wall.length;
    }
    return total;
  }

  /// Room aspect ratio (length/width)
  double get aspectRatio => width == 0 ? 0 : length / width;

  /// Returns true if the polygon corners are wound counter-clockwise (standard math orientation).
  bool get isCCW {
    double sum = 0;
    for (int i = 0; i < corners.length; i++) {
      final Offset current = corners[i];
      final Offset next = corners[(i + 1) % corners.length];
      sum += (current.dx * next.dy) - (next.dx * current.dy);
    }
    return sum > 0;
  }

  @override
  String toString() {
    return 'SurfaceRoom(corners: ${corners.length}, area: ${area.toStringAsFixed(1)}m2, ceiling: ${ceilingHeight.toStringAsFixed(1)}m, listener: ${listenerHeight.toStringAsFixed(1)}m)';
  }
}

/// Represents a loudspeaker with its physical and acoustic characteristics.
///
/// This class encapsulates all speaker-related parameters needed for placement calculations.
class Loudspeaker {
  /// Physical height of the speaker in meters (hardcoded to 0.91 meters / 3 feet)
  static const double defaultHeight = 0.91; // 0.91 meters (3 feet)

  /// Physical height of the speaker in meters
  final double height;

  /// Horizontal coverage angle in degrees (e.g., 90, 120)
  final double horizontalCoverageAngle;

  /// Speaker type/model identifier
  final String type;

  /// Optional vertical coverage angle in degrees
  final double? verticalCoverageAngle;

  /// Optional maximum SPL capability
  final double? maxSpl;

  /// Creates a loudspeaker with the specified characteristics.
  ///
  /// [height] defaults to 0.91 meters if not specified.
  /// [horizontalCoverageAngle] must be between 30 and 180 degrees.
  /// [type] is a descriptive name for the speaker model.
  ///
  /// Throws [ArgumentError] if any parameter is invalid.
  Loudspeaker({
    this.height = defaultHeight,
    required this.horizontalCoverageAngle,
    required this.type,
    this.verticalCoverageAngle,
    this.maxSpl,
  }) {
    _validateParameters();
  }

  /// Validates speaker parameters.
  void _validateParameters() {
    if (height <= 0) {
      throw ArgumentError('Speaker height must be positive, got: $height');
    }
    // Updated threshold since we're using 0.91 meters as standard
    if (height > 1.8) {
      // 6 feet equivalent
      print('Warning: Speaker height seems unusually large: $height meters');
    }
    if (horizontalCoverageAngle < 30 || horizontalCoverageAngle > 180) {
      throw ArgumentError('Horizontal coverage angle must be between 30-180 degrees, got: $horizontalCoverageAngle');
    }
    if (verticalCoverageAngle != null && (verticalCoverageAngle! < 30 || verticalCoverageAngle! > 180)) {
      throw ArgumentError('Vertical coverage angle must be between 30-180 degrees, got: $verticalCoverageAngle');
    }
    if (maxSpl != null && (maxSpl! < 80 || maxSpl! > 140)) {
      print('Warning: Max SPL seems unusual: $maxSpl dB');
    }
  }

  /// Returns true if this is a wide-coverage speaker (>100 degrees)
  bool get isWideCoverage => horizontalCoverageAngle > 100;

  /// Returns true if this is a narrow-coverage speaker (<60 degrees)
  bool get isNarrowCoverage => horizontalCoverageAngle < 60;

  /// Coverage category as a string
  String get coverageCategory {
    if (isNarrowCoverage) return 'Narrow';
    if (isWideCoverage) return 'Wide';
    return 'Medium';
  }

  @override
  String toString() {
    return 'Loudspeaker($type, ${horizontalCoverageAngle.toStringAsFixed(0)}°, ${height.toStringAsFixed(1)}m)';
  }
}

/// Configuration options for surface speaker placement.
class PlacementConfig {
  /// Coverage preference using tangent circle approach (aligned with ceiling/pendant)
  final CoveragePreference coveragePreference;

  /// Whether to enable debug output
  final bool enableDebugOutput;

  /// Custom down-angle override (if provided, ignores height-based calculation)
  final double? customDownAngle;

  /// Minimum speakers per wall
  final int minSpeakersPerWall;

  /// Maximum speakers per wall
  final int maxSpeakersPerWall;

  /// Creates placement configuration with the specified options.
  const PlacementConfig({
    this.coveragePreference = CoveragePreference.minimumOverlap, // Default to optimal layout
    this.enableDebugOutput = false,
    this.customDownAngle,
    this.minSpeakersPerWall = 1,
    this.maxSpeakersPerWall = 20,
  });

  /// Creates a copy of this configuration with optionally updated values.
  PlacementConfig copyWith({
    CoveragePreference? coveragePreference,
    bool? enableDebugOutput,
    double? customDownAngle,
    int? minSpeakersPerWall,
    int? maxSpeakersPerWall,
  }) {
    return PlacementConfig(
      coveragePreference: coveragePreference ?? this.coveragePreference,
      enableDebugOutput: enableDebugOutput ?? this.enableDebugOutput,
      customDownAngle: customDownAngle ?? this.customDownAngle,
      minSpeakersPerWall: minSpeakersPerWall ?? this.minSpeakersPerWall,
      maxSpeakersPerWall: maxSpeakersPerWall ?? this.maxSpeakersPerWall,
    );
  }

  /// Default configuration with optimal overlap
  static const PlacementConfig standard = PlacementConfig();

  /// Configuration with edge-to-edge coverage (no overlap)
  static const PlacementConfig edgeToEdge = PlacementConfig(coveragePreference: CoveragePreference.edgeToEdge);

  /// Configuration with high overlap for critical applications
  static const PlacementConfig highOverlap = PlacementConfig(coveragePreference: CoveragePreference.centerToCenter);

  /// Configuration with debug output enabled
  static const PlacementConfig debug = PlacementConfig(enableDebugOutput: true);

  /// Legacy support - converts old percentage to coverage preference
  @Deprecated('Use coveragePreference instead. This will be removed in a future version.')
  static PlacementConfig fromOverlapPercentage(double overlapPercentage) {
    if (overlapPercentage <= 0.1) {
      return const PlacementConfig(coveragePreference: CoveragePreference.edgeToEdge);
    } else if (overlapPercentage <= 0.2) {
      return const PlacementConfig(coveragePreference: CoveragePreference.minimumOverlap);
    } else {
      return const PlacementConfig(coveragePreference: CoveragePreference.centerToCenter);
    }
  }
}

/// Results from surface speaker placement calculation.
class SurfacePlacementResult {
  /// List of calculated speaker positions
  final List<SpeakerPosition> positions;

  /// Calculated mounting height
  final double mountingHeight;

  /// Applied down-angle in degrees
  final double downAngle;

  /// Distance from speaker to listener plane
  final double distanceToListenerPlane;

  /// Total coverage width per speaker
  final double coverageWidth;

  /// Effective coverage per speaker (after overlap)
  final double effectiveCoverage;

  /// Number of speakers on length walls
  final int speakersOnLength;

  /// Number of speakers on width walls
  final int speakersOnWidth;

  /// Horizontal coverage angle in degrees
  final double horizontalCoverageAngle;

  /// Room length in meters
  final double roomLength;

  /// Room width in meters
  final double roomWidth;

  /// Total number of speakers required
  int get totalSpeakers => positions.length;

  /// Creates a placement result with the calculated values.
  const SurfacePlacementResult({
    required this.positions,
    required this.mountingHeight,
    required this.downAngle,
    required this.distanceToListenerPlane,
    required this.coverageWidth,
    required this.effectiveCoverage,
    required this.speakersOnLength,
    required this.speakersOnWidth,
    required this.horizontalCoverageAngle,
    required this.roomLength,
    required this.roomWidth,
  });

  @override
  String toString() {
    return 'PlacementResult(totalSpeakers: $totalSpeakers, mountingHeight: ${mountingHeight.toStringAsFixed(1)}m, downAngle: ${downAngle.toStringAsFixed(1)}°)';
  }

  Map<String, dynamic> toJson() {
    return {
      'positions': positions.map((x) => x.toJson()).toList(),
      'mountingHeight': mountingHeight,
      'downAngle': downAngle,
      'distanceToListenerPlane': distanceToListenerPlane,
      'coverageWidth': coverageWidth,
      'effectiveCoverage': effectiveCoverage,
      'speakersOnLength': speakersOnLength,
      'speakersOnWidth': speakersOnWidth,
      'horizontalCoverageAngle': horizontalCoverageAngle,
      'roomLength': roomLength,
      'roomWidth': roomWidth,
    };
  }

  factory SurfacePlacementResult.fromJson(Map<String, dynamic> map) {
    return SurfacePlacementResult(
      positions: List<SpeakerPosition>.from(map['positions']?.map((x) => SpeakerPosition.fromJson(x))),
      mountingHeight: map['mountingHeight']?.toDouble() ?? 0.0,
      downAngle: map['downAngle']?.toDouble() ?? 0.0,
      distanceToListenerPlane: map['distanceToListenerPlane']?.toDouble() ?? 0.0,
      coverageWidth: map['coverageWidth']?.toDouble() ?? 0.0,
      effectiveCoverage: map['effectiveCoverage']?.toDouble() ?? 0.0,
      speakersOnLength: map['speakersOnLength']?.toInt() ?? 0,
      speakersOnWidth: map['speakersOnWidth']?.toInt() ?? 0,
      horizontalCoverageAngle: map['horizontalCoverageAngle']?.toDouble() ?? 0.0,
      roomLength: map['roomLength']?.toDouble() ?? 0.0,
      roomWidth: map['roomWidth']?.toDouble() ?? 0.0,
    );
  }
}

/// Main class for calculating surface speaker placement in rooms.
///
/// This class provides both static methods for simple calculations and instance methods
/// for more complex scenarios with custom configuration.
class SurfaceSpeakerPlacer {
  /// Determines the down-angle based on mounting height according to design guide.
  ///
  /// This follows industry best practices for surface-mounted speakers with
  /// a minimum down-angle to ensure intersection with listener plane:
  /// - Heights less than 2.4m: Minimum down-angle (-5°) to ensure listener plane intersection
  /// - Heights 2.4-4.6m: Light down-angle (-15°)
  /// - Heights 4.6-5.5m: Medium down-angle (-30°)
  /// - Heights 5.5m and above: Steep down-angle (-45°)
  ///
  /// The minimum -5° angle prevents infinite horizontal projection at low ceiling heights.
  static double getDownAngle(double mountingHeight) {
    if (mountingHeight < 2.4) {
      // 8 feet equivalent
      return -5.0; // Minimum angle to ensure listener plane intersection
    } else if (mountingHeight <= 4.6) {
      // 15 feet equivalent
      return -15.0;
    } else if (mountingHeight <= 5.5) {
      // 18 feet equivalent
      return -30.0;
    } else {
      return -45.0;
    }
  }

  /// Converts degrees to radians.
  static double degreesToRadians(double degrees) {
    return degrees * pi / 180.0;
  }

  /// Calculate horizontal distance from speaker to listener plane.
  ///
  /// CORRECTED ALGORITHM: Uses proper trigonometry for horizontal distance calculation.
  /// For a surface speaker, the horizontal distance is: (mounting_height - listener_height) / tan(down_angle)
  ///
  /// [mountingHeight] - Height of speaker mounting point in meters
  /// [listenerHeight] - Height of listener ears in meters
  /// [downAngleDegrees] - Down-angle in degrees (negative for downward)
  static double calculateDistanceToListenerPlane(
    double mountingHeight,
    double listenerHeight,
    double downAngleDegrees,
  ) {
    if (mountingHeight <= listenerHeight) {
      throw ArgumentError('Mounting height must be greater than listener height');
    }

    final verticalDistance = mountingHeight - listenerHeight;

    // With minimum -5° down-angle, we no longer have zero angle issues
    if (downAngleDegrees.abs() < 0.001) {
      throw ArgumentError('Down-angle too small: $downAngleDegrees degrees. Minimum -5° required.');
    }

    final downAngleRadians = degreesToRadians(downAngleDegrees.abs());
    return verticalDistance / tan(downAngleRadians);
  }

  /// Calculate horizontal coverage width at listener plane for surface speakers.
  ///
  /// Surface speakers have DIRECTIONAL coverage patterns (sector/wedge shaped),
  /// unlike ceiling speakers which have circular coverage. This method calculates
  /// the width of the coverage sector at the listener plane distance.
  ///
  /// Uses trigonometry to determine the coverage width based on:
  /// - Distance from speaker to listener plane
  /// - Speaker's horizontal coverage angle (defines the sector width)
  ///
  /// Returns the width of the coverage sector (not a circle radius).
  static double calculateHorizontalCoverage(
    double distance,
    double horizontalCoverageAngleDegrees,
  ) {
    if (distance <= 0) {
      throw ArgumentError('Distance must be positive, got: $distance');
    }

    final angleRadians = degreesToRadians(horizontalCoverageAngleDegrees);
    // Calculate width of coverage sector at listener plane
    return 2 * tan(angleRadians / 2) * distance;
  }

  /// Main function to calculate surface speaker placement with full configuration support.
  ///
  /// Returns a [SurfacePlacementResult] containing all calculated positions and parameters.
  ///
  /// [room] - Room dimensions and listener characteristics
  /// [speaker] - Speaker specifications
  /// [config] - Placement configuration options
  static SurfacePlacementResult calculatePlacement({
    required SurfaceRoom room,
    required Loudspeaker speaker,
    PlacementConfig config = PlacementConfig.standard,
  }) {
    // Step 1: Calculate mounting height for surface speakers
    // Surface speakers should be mounted as high as possible on walls
    // For low ceilings, mount speakers at ceiling height minus minimal clearance
    final mountingHeight = room.ceilingHeight - 0.15; // 15 cm (0.15m) below ceiling for mounting clearance

    // Validate that speakers can be mounted above listener height
    // Allow minimal clearance (just 10 cm / 0.1m) for practical scenarios
    final minimumClearance = 0.1; // 10 cm minimum clearance above listener
    if (mountingHeight <= room.listenerHeight + minimumClearance) {
      final minimumCeilingHeight = room.listenerHeight + minimumClearance + 0.15; // listener + clearance + mounting space
      throw ArgumentError(
        'Ceiling height (${room.ceilingHeight.toStringAsFixed(1)} m) too low for listener height (${room.listenerHeight.toStringAsFixed(1)} m). Need at least ${minimumCeilingHeight.toStringAsFixed(1)} m ceiling.',
      );
    }

    // Step 2: Determine down-angle (use custom if provided)
    final downAngle = config.customDownAngle ?? getDownAngle(mountingHeight);

    // Step 3: Calculate distance to listener plane
    final distance = calculateDistanceToListenerPlane(
      mountingHeight,
      room.listenerHeight,
      downAngle,
    );

    // Step 4: Calculate horizontal coverage
    final coverageWidth = calculateHorizontalCoverage(
      distance,
      speaker.horizontalCoverageAngle,
    );

    // Step 5: Apply coverage preference (directional sector approach)
    // Note: Surface speakers have directional coverage (sectors), not circular like ceiling speakers
    // The overlap mechanism uses the same multipliers but applies to sector width, not circle radius
    final effectiveCoverage = coverageWidth * config.coveragePreference.overlapMultiplier;

    if (effectiveCoverage <= 0) {
      throw ArgumentError('Effective coverage is zero or negative - check coverage preference');
    }

    // Step 6: Place speakers on each polygon wall.
    final List<_PlacedSpeaker> provisionalSpeakers = _placeSpeakersOnPolygonWalls(
      room: room,
      mountingHeight: mountingHeight,
      effectiveCoverage: effectiveCoverage,
      config: config,
    );

    // Step 7: Resolve overlaps and corner-wall collisions.
    final List<SpeakerPosition> positions = _resolveSpeakerOverlaps(
      provisionalSpeakers: provisionalSpeakers,
      room: room,
      mountingHeight: mountingHeight,
      effectiveCoverage: effectiveCoverage,
    );

    final List<int> speakersPerWall = _countSpeakersPerWall(provisionalSpeakers);
    final int speakersOnLength = speakersPerWall.isEmpty ? 0 : speakersPerWall.reduce(max);
    final int speakersOnWidth = speakersPerWall.isEmpty ? 0 : speakersPerWall.reduce(min);

    // Step 8: Debug output if enabled
    if (config.enableDebugOutput) {
      _printCalculationDetails(
        room: room,
        speaker: speaker,
        config: config,
        mountingHeight: mountingHeight,
        downAngle: downAngle,
        distance: distance,
        coverageWidth: coverageWidth,
        effectiveCoverage: effectiveCoverage,
        speakersOnLength: speakersOnLength,
        speakersOnWidth: speakersOnWidth,
      );
    }

    // Always print key values for debugging optimization
    print('=== DEBUG: Optimization Check ===');
    print('Room: ${room.length}m x ${room.width}m');
    print('Coverage Width: ${coverageWidth.toStringAsFixed(2)}m');
    print('Effective Coverage: ${effectiveCoverage.toStringAsFixed(2)}m');
    print('Walls: ${room.walls.length}');
    print('Provisional speakers: ${provisionalSpeakers.length}');
    print('Speakers after overlap resolution: ${positions.length}');
    print('=====================================');

    return SurfacePlacementResult(
      positions: positions,
      mountingHeight: mountingHeight,
      downAngle: downAngle,
      distanceToListenerPlane: distance,
      coverageWidth: coverageWidth,
      effectiveCoverage: effectiveCoverage,
      speakersOnLength: speakersOnLength,
      speakersOnWidth: speakersOnWidth,
      horizontalCoverageAngle: speaker.horizontalCoverageAngle,
      roomLength: room.length,
      roomWidth: room.width,
    );
  }

  /// Computes the inward-facing normal angle (degrees, from +X axis) for a wall segment.
  static double _wallInwardNormalAngle(_WallSegment wall, bool isCCW) {
    final double dx = wall.end.dx - wall.start.dx;
    final double dy = wall.end.dy - wall.start.dy;
    // Right-hand perpendicular (CW from wall direction): (dy, -dx)
    // Left-hand perpendicular (CCW from wall direction): (-dy, dx)
    // For a CCW polygon the inward normal is the right-hand perpendicular.
    final double nx = isCCW ? dy : -dy;
    final double ny = isCCW ? -dx : dx;
    return atan2(ny, nx) * 180.0 / pi;
  }

  /// Projects a point to the nearest wall segment and returns edge-constrained placement data.
  static _BoundaryProjection _projectPointToClosestWall(Offset point, SurfaceRoom room) {
    final List<_WallSegment> walls = room.walls;
    final bool isCCW = room.isCCW;

    double bestDistanceSquared = double.infinity;
    late _BoundaryProjection best;

    double cumulativePerimeter = 0;
    for (final _WallSegment wall in walls) {
      final Offset wallVector = wall.end - wall.start;
      final double wallLengthSquared = (wallVector.dx * wallVector.dx) + (wallVector.dy * wallVector.dy);

      final double tRaw = (((point.dx - wall.start.dx) * wallVector.dx) + ((point.dy - wall.start.dy) * wallVector.dy)) / wallLengthSquared;
      final double t = tRaw.clamp(0.0, 1.0);

      final Offset projection = Offset(
        wall.start.dx + (wallVector.dx * t),
        wall.start.dy + (wallVector.dy * t),
      );

      final double dx = point.dx - projection.dx;
      final double dy = point.dy - projection.dy;
      final double distanceSquared = (dx * dx) + (dy * dy);

      if (distanceSquared < bestDistanceSquared) {
        bestDistanceSquared = distanceSquared;
        best = _BoundaryProjection(
          point: projection,
          wallIndex: wall.index,
          perimeterPosition: cumulativePerimeter + (wall.length * t),
          rotation: _wallInwardNormalAngle(wall, isCCW),
        );
      }

      cumulativePerimeter += wall.length;
    }

    return best;
  }

  /// Places speakers on each wall segment of the polygon room.
  static List<_PlacedSpeaker> _placeSpeakersOnPolygonWalls({
    required SurfaceRoom room,
    required double mountingHeight,
    required double effectiveCoverage,
    required PlacementConfig config,
  }) {
    final List<_PlacedSpeaker> speakers = <_PlacedSpeaker>[];
    final List<_WallSegment> walls = room.walls;
    final bool isCCW = room.isCCW;

    double cumulativePerimeter = 0;
    for (final _WallSegment wall in walls) {
      final int wallSpeakerCount = (wall.length / effectiveCoverage).ceil().clamp(config.minSpeakersPerWall, config.maxSpeakersPerWall);
      final double wallRotation = _wallInwardNormalAngle(wall, isCCW);

      final double spacing = wall.length / wallSpeakerCount;
      for (int i = 0; i < wallSpeakerCount; i++) {
        final double along = spacing * (i + 0.5);
        final double t = along / wall.length;
        final Offset point = Offset(
          wall.start.dx + ((wall.end.dx - wall.start.dx) * t),
          wall.start.dy + ((wall.end.dy - wall.start.dy) * t),
        );

        speakers.add(
          _PlacedSpeaker(
            point: point,
            wallIndex: wall.index,
            perimeterPosition: cumulativePerimeter + along,
            rotation: wallRotation,
          ),
        );
      }

      cumulativePerimeter += wall.length;
    }

    return speakers;
  }

  /// Resolves overlap and corner collisions based on polygon geometry.
  static List<SpeakerPosition> _resolveSpeakerOverlaps({
    required List<_PlacedSpeaker> provisionalSpeakers,
    required SurfaceRoom room,
    required double mountingHeight,
    required double effectiveCoverage,
  }) {
    final List<_PlacedSpeaker> working = List<_PlacedSpeaker>.from(provisionalSpeakers);

    // Step 5: Remove speakers that fall on a corner (speaker overlap with wall at corners).
    final double cornerThreshold = max(0.1, effectiveCoverage * 0.15);
    working.removeWhere(
      (_PlacedSpeaker speaker) => room.corners.any((Offset corner) => (speaker.point - corner).distance <= cornerThreshold),
    );

    // Step 3 & 4: Merge adjacent overlapping speakers by replacing each pair with midpoint.
    final double adjacentOverlapThreshold = max(0.1, effectiveCoverage * 0.5);
    bool hasChange = true;

    while (hasChange && working.length > 1) {
      hasChange = false;
      working.sort((a, b) => a.perimeterPosition.compareTo(b.perimeterPosition));

      for (int i = 0; i < working.length; i++) {
        final int nextIndex = (i + 1) % working.length;
        if (nextIndex == i) continue;

        final _PlacedSpeaker a = working[i];
        final _PlacedSpeaker b = working[nextIndex];
        final double spacing = (a.point - b.point).distance;

        if (spacing <= adjacentOverlapThreshold) {
          final Offset midpoint = Offset(
            (a.point.dx + b.point.dx) / 2,
            (a.point.dy + b.point.dy) / 2,
          );
          final _BoundaryProjection snapped = _projectPointToClosestWall(midpoint, room);

          final int removeFirst = max(i, nextIndex);
          final int removeSecond = min(i, nextIndex);
          working.removeAt(removeFirst);
          working.removeAt(removeSecond);

          working.add(
            _PlacedSpeaker(
              point: snapped.point,
              wallIndex: snapped.wallIndex,
              perimeterPosition: snapped.perimeterPosition,
              rotation: snapped.rotation,
            ),
          );

          hasChange = true;
          break;
        }
      }
    }

    // Remove corner points again after midpoint merges (midpoint may land on a corner).
    working.removeWhere(
      (_PlacedSpeaker speaker) => room.corners.any((Offset corner) => (speaker.point - corner).distance <= cornerThreshold),
    );

    final List<_PlacedSpeaker> edgeConstrained = working
        .map((speaker) {
          final _BoundaryProjection snapped = _projectPointToClosestWall(speaker.point, room);
          return _PlacedSpeaker(
            point: snapped.point,
            wallIndex: snapped.wallIndex,
            perimeterPosition: snapped.perimeterPosition,
            rotation: snapped.rotation,
          );
        })
        .toList(growable: false);

    return edgeConstrained.map((s) => SpeakerPosition(s.point.dx, s.point.dy, mountingHeight, s.rotation)).toList(growable: false);
  }

  static List<int> _countSpeakersPerWall(List<_PlacedSpeaker> placed) {
    final Map<int, int> counts = <int, int>{};
    for (final _PlacedSpeaker speaker in placed) {
      if (speaker.wallIndex < 0) continue;
      counts[speaker.wallIndex] = (counts[speaker.wallIndex] ?? 0) + 1;
    }
    return counts.values.toList(growable: false);
  }

  /// Legacy method for backward compatibility.
  ///
  /// Use [calculatePlacement] for new code as it provides more detailed results.
  @Deprecated('Use calculatePlacement with CoveragePreference instead')
  static List<SpeakerPosition> placeSurfaceSpeakers({
    required SurfaceRoom room,
    required Loudspeaker speaker,
    double overlapPercentage = 0.1,
  }) {
    final config = PlacementConfig.fromOverlapPercentage(overlapPercentage);
    final result = calculatePlacement(room: room, speaker: speaker, config: config);
    return result.positions;
  }

  /// Internal method for detailed calculation output.
  static void _printCalculationDetails({
    required SurfaceRoom room,
    required Loudspeaker speaker,
    required PlacementConfig config,
    required double mountingHeight,
    required double downAngle,
    required double distance,
    required double coverageWidth,
    required double effectiveCoverage,
    required int speakersOnLength,
    required int speakersOnWidth,
  }) {
    print('=== Surface Speaker Placement Calculations ===');
    print('Room: ${room.length}ft x ${room.width}ft x ${room.ceilingHeight}ft');
    print('Listener Height: ${room.listenerHeight}ft');
    print('Speaker: ${speaker.type}');
    print('Speaker Height: ${speaker.height}ft');
    print('Horizontal Coverage: ${speaker.horizontalCoverageAngle}°');
    print('');
    print('Calculated Parameters:');
    print('Mounting Height: ${mountingHeight.toStringAsFixed(1)}ft');
    print('Down Angle: ${downAngle.toStringAsFixed(1)}°');
    print('Distance to Listener Plane: ${distance.toStringAsFixed(2)}ft');
    print('Coverage Width: ${coverageWidth.toStringAsFixed(2)}ft');
    print(
      'Effective Coverage: ${effectiveCoverage.toStringAsFixed(2)}ft (${config.coveragePreference.name} - ${config.coveragePreference.overlapMultiplier}x)',
    );
    print('');
    print('Speaker Distribution:');
    print('Length walls: $speakersOnLength speakers each');
    print('Width walls: $speakersOnWidth speakers each');
    print('Total speakers: ${2 * (speakersOnLength + speakersOnWidth)}');
    print('');
  }

  /// Print detailed calculation results for debugging.
  ///
  /// Use [calculatePlacement] with debug config for new code.
  @Deprecated('Use calculatePlacement with debug config and CoveragePreference instead')
  static void printCalculationDetails({
    required SurfaceRoom room,
    required Loudspeaker speaker,
    double overlapPercentage = 0.1,
  }) {
    final config = PlacementConfig.fromOverlapPercentage(overlapPercentage).copyWith(enableDebugOutput: true);
    calculatePlacement(room: room, speaker: speaker, config: config);
  }
}

/// Example usage demonstrating the Surface Speaker Placement Library.
/// 
/// This library provides acoustic calculations for optimal placement of surface-mounted 
/// speakers around room perimeters. It follows industry best practices for:
/// 
/// - Down-angle selection based on mounting height
/// - Coverage calculations considering speaker dispersion
/// - Overlap management to avoid coverage gaps
/// - Perimeter placement with even distribution
/// 
/// ## Basic Usage:
/// 
/// ```dart
/// // Define room and speaker
/// final room = SurfaceRoom(
///   width: 1.86, length: 2.77, 
///   ceilingHeight: 1.13, listenerHeight: 0.37
/// );
/// final speaker = Loudspeaker(
///   // height defaults to 0.91 meters
///   horizontalCoverageAngle: 90.0, 
///   type: 'Surface Mount Speaker'
/// );
/// 
/// // Calculate placement
/// final result = SurfaceSpeakerPlacer.calculatePlacement(
///   room: room, 
///   speaker: speaker,
///   config: PlacementConfig.standard,
/// );
/// 
/// print('Total speakers needed: ${result.totalSpeakers}');
/// for (var position in result.positions) {
///   print(position.toDisplayString());
/// }
/// ```
/// 
/// ## Advanced Usage with Custom Configuration:
/// 
/// ```dart
/// final customConfig = PlacementConfig(
///   coveragePreference: CoveragePreference.centerToCenter,  // High overlap
///   enableDebugOutput: true,
///   customDownAngle: -20.0,   // Override auto-calculation
/// );
/// 
/// final result = SurfaceSpeakerPlacer.calculatePlacement(
///   room: room,
///   speaker: speaker, 
///   config: customConfig,
/// );
/// ```
/// 
/// ## Algorithm Verification:
/// 
/// The algorithm has been verified against acoustic engineering principles:
/// 
/// ✅ **Corrected Distance Calculation**: Uses proper trigonometry (tan) for horizontal 
///    distance to listener plane, not cosine projection
/// ✅ **Industry Standard Down-angles**: Follows established guidelines for mounting height
///    with minimum -5° to ensure listener plane intersection at all ceiling heights
/// ✅ **Directional Coverage Accuracy**: Proper geometric calculation of sector-shaped 
///    dispersion patterns (not circular like ceiling speakers)
/// ✅ **Overlap Management**: Configurable overlap using same multipliers as ceiling/pendant
///    but applied to directional coverage sectors
/// ✅ **Input Validation**: Comprehensive validation of room and speaker parameters
/// ✅ **Edge Case Handling**: Handles special cases like low ceiling heights gracefully
/// 
/// This implementation provides a production-ready, reusable library for surface-mounted
/// acoustic system design applications with proper directional coverage modeling.