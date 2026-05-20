part of '../surface_speakers_autolayout.dart';

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

    if (ceilingHeight < 2.1 || ceilingHeight > 9.1) {
      print('Warning: Unusual ceiling height: $ceilingHeight meters');
    }
    if (width > 61.0 || length > 61.0) {
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
