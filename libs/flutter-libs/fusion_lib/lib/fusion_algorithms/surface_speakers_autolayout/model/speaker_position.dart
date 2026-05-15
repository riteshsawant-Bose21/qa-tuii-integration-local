part of '../surface_speakers_autolayout.dart';

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
