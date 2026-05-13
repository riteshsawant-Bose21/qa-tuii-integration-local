import 'dart:math';
import 'dart:ui' show Offset;

part 'model/_boundary_projection.dart';
part 'model/_placed_speaker.dart';
part 'model/_wall_segment.dart';
part 'model/coverage_preference.dart';
part 'model/loudspeaker.dart';
part 'model/placement_config.dart';
part 'model/speaker_position.dart';
part 'model/surface_placement_result.dart';
part 'model/surface_room.dart';

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
    print("Provisional speakers placed on walls: ${provisionalSpeakers.length}");

    // Step 7: Resolve overlaps and corner-wall collisions.
    final List<SpeakerPosition> positions = _resolveSpeakerOverlaps(
      provisionalSpeakers: provisionalSpeakers,
      room: room,
      mountingHeight: mountingHeight,
      effectiveCoverage: effectiveCoverage,
    );
    print("Positions after resolving overlaps: ${positions.length}");

    final List<int> speakersPerWall = _countSpeakersPerWall(provisionalSpeakers);
    final int speakersOnLength = speakersPerWall.isEmpty ? 0 : speakersPerWall.reduce(max);
    final int speakersOnWidth = speakersPerWall.isEmpty ? 0 : speakersPerWall.reduce(min);

    // Step 8: Debug output if enabled

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

  static bool _isPointInPolygon(Offset point, List<Offset> polygon) {
    bool inside = false;
    for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      final Offset pi = polygon[i];
      final Offset pj = polygon[j];
      final bool intersects =
          ((pi.dy > point.dy) != (pj.dy > point.dy)) && (point.dx < (pj.dx - pi.dx) * (point.dy - pi.dy) / ((pj.dy - pi.dy) + 1e-12) + pi.dx);
      if (intersects) {
        inside = !inside;
      }
    }
    return inside;
  }

  /// Computes the inward-facing normal angle (degrees, from +X axis) for a wall segment.
  static double _wallInwardNormalAngle(_WallSegment wall, SurfaceRoom room) {
    final double dx = wall.end.dx - wall.start.dx;
    final double dy = wall.end.dy - wall.start.dy;

    // Candidate normals: right-hand and left-hand perpendicular to wall direction.
    final Offset rightNormal = Offset(dy, -dx);
    final Offset leftNormal = Offset(-dy, dx);

    final double rightLen = rightNormal.distance;
    final double leftLen = leftNormal.distance;
    if (rightLen == 0 || leftLen == 0) return 0;

    final Offset rightUnit = Offset(rightNormal.dx / rightLen, rightNormal.dy / rightLen);
    final Offset leftUnit = Offset(leftNormal.dx / leftLen, leftNormal.dy / leftLen);

    final Offset mid = Offset((wall.start.dx + wall.end.dx) / 2, (wall.start.dy + wall.end.dy) / 2);
    const double probeDistance = 0.01;
    final Offset rightProbe = Offset(mid.dx + rightUnit.dx * probeDistance, mid.dy + rightUnit.dy * probeDistance);
    final Offset leftProbe = Offset(mid.dx + leftUnit.dx * probeDistance, mid.dy + leftUnit.dy * probeDistance);

    final bool rightInside = _isPointInPolygon(rightProbe, room.corners);
    final bool leftInside = _isPointInPolygon(leftProbe, room.corners);

    final double nx;
    final double ny;
    if (rightInside && !leftInside) {
      nx = rightUnit.dx;
      ny = rightUnit.dy;
    } else if (leftInside && !rightInside) {
      nx = leftUnit.dx;
      ny = leftUnit.dy;
    } else {
      // Fallback for ambiguous probe cases.
      final bool isCCW = room.isCCW;
      nx = isCCW ? rightUnit.dx : leftUnit.dx;
      ny = isCCW ? rightUnit.dy : leftUnit.dy;
    }

    return atan2(ny, nx) * 180.0 / pi;
  }

  /// Projects a point to the nearest wall segment and returns edge-constrained placement data.
  static _BoundaryProjection _projectPointToClosestWall(Offset point, SurfaceRoom room) {
    final List<_WallSegment> walls = room.walls;

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
          rotation: _wallInwardNormalAngle(wall, room),
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

    double cumulativePerimeter = 0;
    for (final _WallSegment wall in walls) {
      final int wallSpeakerCount = (wall.length / effectiveCoverage).ceil().clamp(config.minSpeakersPerWall, config.maxSpeakersPerWall);
      final double wallRotation = _wallInwardNormalAngle(wall, room);

      // Keep equal margin from both wall ends:
      // - 1 speaker => centered at L/2
      // - N speakers => positions at L/(2N), 3L/(2N), ..., (2N-1)L/(2N)
      final double spacingBetweenCenters = wall.length / wallSpeakerCount;
      final double edgeInset = spacingBetweenCenters / 2;

      for (int i = 0; i < wallSpeakerCount; i++) {
        final double along = edgeInset + (i * spacingBetweenCenters);
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
    print(
      "Resolving overlaps for ${working.length} provisional speakers... Positions: ${working.map((s) => '(${s.point.dx.toStringAsFixed(2)}, ${s.point.dy.toStringAsFixed(2)})').join('\n ')}",
    );
    // Step 5: Remove speakers that fall on a corner (speaker overlap with wall at corners).
    final double cornerThreshold = max(0.1, effectiveCoverage * 0.15);
    bool isCornerCollision(_PlacedSpeaker speaker) {
      return room.corners.any((Offset corner) {
        var distance2 = (speaker.point - corner).distance;
        if (distance2 <= cornerThreshold) {
          print(
            "Corner collision detected for speaker at (${speaker.point.dx.toStringAsFixed(2)}, ${speaker.point.dy.toStringAsFixed(2)}) with corner at (${corner.dx.toStringAsFixed(2)}, ${corner.dy.toStringAsFixed(2)}). Distance: ${distance2.toStringAsFixed(3)} m, Threshold: ${cornerThreshold.toStringAsFixed(3)} m",
          );
        }
        return distance2 <= cornerThreshold;
      });
    }

    final List<_PlacedSpeaker> cornerCollisionSpeakers = working.where(isCornerCollision).toList(growable: false);
    print(
      "Corner collision selection (${cornerCollisionSpeakers.length}): ${cornerCollisionSpeakers.map((s) => '(${s.point.dx.toStringAsFixed(2)}, ${s.point.dy.toStringAsFixed(2)})').join(', ')}",
    );
    working.removeWhere(
      isCornerCollision,
    );
    print("After removing corner collisions: ${working.length} speakers remain Corner threshold: ${cornerThreshold.toStringAsFixed(2)} m");

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
    print("After merging overlaps: ${working.length} speakers remain");
    // Remove corner points again after midpoint merges (midpoint may land on a corner).
    working.removeWhere(
      (_PlacedSpeaker speaker) => room.corners.any((Offset corner) => (speaker.point - corner).distance <= cornerThreshold),
    );
    print("After final corner collision check: ${working.length} speakers remain");

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
}
