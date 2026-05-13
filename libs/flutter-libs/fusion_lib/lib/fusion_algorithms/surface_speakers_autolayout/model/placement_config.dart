part of '../surface_speakers_autolayout.dart';

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
    this.coveragePreference = CoveragePreference.minimumOverlap,
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
