part of '../surface_speakers_autolayout.dart';

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

  /// Optional debug info produced during placement resolution.
  final SurfacePlacementDebugInfo? debugInfo;

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
    this.debugInfo,
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
