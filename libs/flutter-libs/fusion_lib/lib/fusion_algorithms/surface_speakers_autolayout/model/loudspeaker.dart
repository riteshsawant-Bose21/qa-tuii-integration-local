part of '../surface_speakers_autolayout.dart';

/// Represents a loudspeaker with its physical and acoustic characteristics.
///
/// This class encapsulates all speaker-related parameters needed for placement calculations.
class Loudspeaker {
  /// Physical height of the speaker in meters (hardcoded to 0.91 meters / 3 feet)
  static const double defaultHeight = 0.91;

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
    if (height > 1.8) {
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
