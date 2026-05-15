part of '../surface_speakers_autolayout.dart';

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
