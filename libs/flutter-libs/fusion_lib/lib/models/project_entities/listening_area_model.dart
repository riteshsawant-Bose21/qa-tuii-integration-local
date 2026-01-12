import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../../fusion_utils/fusion_utilities.dart';

enum VenueType {
  indoor,
  outdoor,
  mixed,
}

extension VenueTypeExtension on VenueType {
  String get name {
    switch (this) {
      case VenueType.indoor:
        return 'Indoor';
      case VenueType.outdoor:
        return 'Outdoor';
      case VenueType.mixed:
        return 'Indoor+Outdoor';
    }
  }
}

enum MountingType {
  surface,
  pendant,
  ceiling;

  String get name {
    switch (this) {
      case MountingType.ceiling:
        return 'Ceiling';
      case MountingType.pendant:
        return 'Pendant';
      case MountingType.surface:
        return 'Surface';
    }
  }

  static MountingType? fromJson(String? value) {
    switch (value?.toLowerCase()) {
      case 'surface':
        return MountingType.surface;
      case 'pendant':
        return MountingType.pendant;
      case 'ceiling':
        return MountingType.ceiling;
      default:
        return null;
    }
  }
}

enum LowFrequency {
  vocal,
  fullRange,
  extended,
  subwoofer,
}

extension LowFrequencyExtension on LowFrequency {
  String get name {
    switch (this) {
      case LowFrequency.vocal:
        return 'Vocal ';
      case LowFrequency.fullRange:
        return 'Full Range';
      case LowFrequency.extended:
        return 'Extended';
      case LowFrequency.subwoofer:
        return 'Subwoofer';
    }
  }
}

enum WiringType {
  highImpedance,
  lowImpedance,
}

extension WiringTypeExtension on WiringType {
  String get name {
    switch (this) {
      case WiringType.highImpedance:
        return 'Hi-Z';
      case WiringType.lowImpedance:
        return 'Lo-Z';
    }
  }
}

enum SplRange {
  backgroundMusic,
  paging,
  foregroundMusic,
  moderateLiveSound,
  highSplLiveSound,
}

extension SplRangeExtension on SplRange {
  String get name {
    switch (this) {
      case SplRange.backgroundMusic:
        return 'Background Music';
      case SplRange.paging:
        return 'Paging';
      case SplRange.foregroundMusic:
        return 'Foreground Music';
      case SplRange.moderateLiveSound:
        return 'Moderate Live Sound reinforcement';
      case SplRange.highSplLiveSound:
        return 'High SPL Live Sound reinforcement';
    }
  }

  Map<String, double> get splRangeValues {
    switch (this) {
      case SplRange.backgroundMusic:
        return <String, double>{"min": 60.0, "max": 70.0};
      case SplRange.paging:
        return <String, double>{"min": 70.0, "max": 80.0};
      case SplRange.foregroundMusic:
        return <String, double>{"min": 75.0, "max": 90.0};
      case SplRange.moderateLiveSound:
        return <String, double>{"min": 90.0, "max": 100.0};
      case SplRange.highSplLiveSound:
        return <String, double>{"min": 100.0, "max": 120.0};
    }
  }

  static SplRange getSplRange(double minSPL, double maxSPL) {
    if (minSPL == 60.0 && maxSPL == 70.0) {
      return SplRange.backgroundMusic;
    } else if (minSPL == 70.0 && maxSPL == 80.0) {
      return SplRange.paging;
    } else if (minSPL == 75.0 && maxSPL == 90.0) {
      return SplRange.foregroundMusic;
    } else if (minSPL == 90.0 && maxSPL == 100.0) {
      return SplRange.moderateLiveSound;
    } else if (minSPL == 100.0 && maxSPL == 120.0) {
      return SplRange.highSplLiveSound;
    } else {
      return SplRange.backgroundMusic;
    }
  }
}

enum ListeningPreference {
  mono,
  stereo,
}

extension ListeningPreferenceExtension on ListeningPreference {
  String get name {
    switch (this) {
      case ListeningPreference.mono:
        return 'Mono';
      case ListeningPreference.stereo:
        return 'Stereo';
    }
  }
}

class ListeningArea {
  final String id;
  final List<Offset> vertices;
  SplData? splData;
  final String name;
  final VenueType? venuType;
  final double listeningHeight;
  final String ceilingHeight;
  final double minSPL;
  final double maxSPL;
  final double customListeningAreaHeight;
  final bool isDrawn;

  final Color? preferredSpeakerColor;
  final SplRange? splRange;
  final ListeningPreference? listeningPreference;

  /// THESE ARE FILTER OPTIONS
  final Set<MountingType> mountingTypes;
  final Set<LowFrequency> lowFrequencies;
  final WiringType? wiringType;

  ListeningArea({
    String? id,
    required this.vertices,
    this.splData,
    this.name = '',
    this.venuType,
    this.listeningHeight = 3.0, // Default to sitting height (3 ft)
    this.ceilingHeight = '',
    this.minSPL = 60.0,
    this.maxSPL = 70.0,
    this.customListeningAreaHeight = 0.0,
    this.mountingTypes = const <MountingType>{},
    this.lowFrequencies = const <LowFrequency>{},
    this.wiringType,
    this.preferredSpeakerColor,
    this.splRange,
    this.listeningPreference,
    bool? isDrawn,
  }) : id = id ?? "AREA${FusionUtils.shortStringUUID()}",
       isDrawn = isDrawn ?? vertices.isNotEmpty;

  List<Offset> getFieldPointsSet({int cols = 60, int rows = 60}) {
    if (vertices.isEmpty) return <Offset>[];

    // 1) bounding‐box
    final Iterable<double> xs = vertices.map((Offset v) => v.dx);
    final Iterable<double> ys = vertices.map((Offset v) => v.dy);
    final double minX = xs.reduce(min), maxX = xs.reduce(max);
    final double minY = ys.reduce(min), maxY = ys.reduce(max);

    final double dx = (maxX - minX) / cols;
    final double dy = (maxY - minY) / rows;

    // 2) use custom point-in-polygon for hit testing (Path cannot be used in isolates)

    // 3) sample grid and keep only points inside
    final List<Offset> pts = <Offset>[];
    for (int i = 0; i <= cols; i++) {
      for (int j = 0; j <= rows; j++) {
        final Offset p = Offset(minX + dx * i, minY + dy * j);
        if (_polygonContains(vertices, p)) {
          pts.add(p);
        }
      }
    }
    return pts;
  }

  /// Returns all points inside the polygon on a uniform grid where
  /// the distance between adjacent points is approximately [spacing]
  /// world‐units (rather than a fixed cols×rows).
  List<Offset> getFieldPoints(double spacing) {
    if (vertices.isEmpty) return <Offset>[];

    // final double spacing = 20.0;

    // 1) compute axis‐aligned bounding box
    final Iterable<double> xs = vertices.map((Offset v) => v.dx);
    final Iterable<double> ys = vertices.map((Offset v) => v.dy);
    final double minX = xs.reduce(min), maxX = xs.reduce(max);
    final double minY = ys.reduce(min), maxY = ys.reduce(max);

    // 2) determine how many steps in each direction
    final int cols = ((maxX - minX) / spacing).ceil();
    final int rows = ((maxY - minY) / spacing).ceil();

    // 3) use custom point-in-polygon for hit testing (Path cannot be used in isolates)

    // 4) sample grid
    final List<Offset> pts = <Offset>[];
    for (int i = 0; i <= cols; i++) {
      final double x = minX + i * spacing;
      for (int j = 0; j <= rows; j++) {
        final double y = minY + j * spacing;
        final Offset p = Offset(x, y);
        if (_polygonContains(vertices, p)) {
          pts.add(p);
        }
      }
    }

    return pts;
  }

  ListeningArea copyWith({
    String? id,
    List<Offset>? vertices,
    SplData? splData,
    String? name,
    List<String>? hardwareComponentIds,
    VenueType? venuType,
    double? listeningHeight,
    String? ceilingHeight,
    double? customListeningAreaHeight,
    double? minSPL,
    double? maxSPL,
    Set<MountingType>? mountingTypes,
    Set<LowFrequency>? lowFrequencies,
    WiringType? wiringType,
    Color? preferredSpeakerColor,
    SplRange? splRange,
    ListeningPreference? listeningPreference,
  }) {
    return ListeningArea(
      vertices: vertices ?? this.vertices,
      id: id ?? this.id,
      splData: splData ?? this.splData,
      name: name ?? this.name,
      venuType: venuType ?? this.venuType,
      listeningHeight: listeningHeight ?? this.listeningHeight,
      ceilingHeight: ceilingHeight ?? this.ceilingHeight,
      minSPL: minSPL ?? this.minSPL,
      maxSPL: maxSPL ?? this.maxSPL,
      customListeningAreaHeight: customListeningAreaHeight ?? this.customListeningAreaHeight,
      mountingTypes: mountingTypes ?? this.mountingTypes,
      lowFrequencies: lowFrequencies ?? this.lowFrequencies,
      wiringType: wiringType ?? this.wiringType,
      preferredSpeakerColor: preferredSpeakerColor ?? this.preferredSpeakerColor,
      splRange: splRange ?? this.splRange,
      listeningPreference: listeningPreference ?? this.listeningPreference,
    );
  }

  /// Store the given points & values together
  void setSplData(List<Offset> points, List<double> values) {
    splData = SplData(surfaceId: id, fieldPoints: points, splValues: values);
  }

  void clearSplData() {
    splData = null;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'vertices': vertices.map((Offset v) => <String, double>{'dx': v.dx, 'dy': v.dy}).toList(),
    'splData': null,
    'venuType': venuType?.name,
    'listeningHeight': listeningHeight,
    'ceilingHeight': ceilingHeight,
    'minSPL': minSPL,
    'maxSPL': maxSPL,
    'customListeningAreaHeight': customListeningAreaHeight,
    'isDrawn': isDrawn,
    'preferredSpeakerColor': preferredSpeakerColor,
    'splRange': splRange?.name,
    'listeningPreference': listeningPreference?.name,
  };

  /// Parses back from JSON, turning the dynamic list into List<Offset>
  factory ListeningArea.fromJson(Map<String, dynamic> json) {
    // 1) get the raw list
    final List<dynamic> rawVerts = json['vertices'] as List<dynamic>;
    // 2) map each element (a Map) into an Offset
    final List<Offset> verts = rawVerts.map((dynamic e) {
      final Map<String, dynamic> m = e as Map<String, dynamic>;
      return Offset(
        (m['dx'] as num).toDouble(),
        (m['dy'] as num).toDouble(),
      );
    }).toList();

    return ListeningArea(
      id: json['id'] as String?,
      vertices: verts,
      splData: null,
      name: json['name'] as String,
      venuType: json['venuType'] != null
          ? VenueType.values.firstWhere(
              (VenueType vt) => vt.name == (json['venuType'] as String),
              orElse: () => VenueType.indoor,
            )
          : null,
      listeningHeight: (json['listeningHeight'] as num?)?.toDouble() ?? 3.0,
      ceilingHeight: json['ceilingHeight'] as String? ?? '',
      customListeningAreaHeight: (json['customListeningAreaHeight'] as num?)?.toDouble() ?? 0.0,
      minSPL: (json['minSPL'] as num?)?.toDouble() ?? 60.0,
      maxSPL: (json['maxSPL'] as num?)?.toDouble() ?? 70.0,
      isDrawn: json['isDrawn'] as bool? ?? (verts.isNotEmpty),
      preferredSpeakerColor: json['preferredSpeakerColor'] != null ? Color(json['preferredSpeakerColor'] as int) : null,
      splRange: json['splRange'] != null
          ? SplRange.values.firstWhere(
              (SplRange sr) => sr.name == (json['splRange'] as String),
              orElse: () => SplRange.backgroundMusic,
            )
          : null,
      listeningPreference: json['listeningPreference'] != null
          ? ListeningPreference.values.firstWhere(
              (ListeningPreference lp) => lp.name == (json['listeningPreference'] as String),
              orElse: () => ListeningPreference.mono,
            )
          : null,
    );
  }

  /// Compute speaker points on a hex-lattice inside the polygon defined by [vertices],
  /// plus any grid points within [tolerance] of its edges.
  List<Offset> getSpeakerPoints({
    double spacing = 200.0,
    double tolerance = 20.0,
  }) {
    if (vertices.isEmpty) return <Offset>[];

    // 1) bounding box
    final Iterable<double> xs = vertices.map((Offset v) => v.dx);
    final Iterable<double> ys = vertices.map((Offset v) => v.dy);
    final double minX = xs.reduce(min), maxX = xs.reduce(max);
    final double minY = ys.reduce(min), maxY = ys.reduce(max);

    // 2) hex-grid math
    final double rowHeight = spacing * sqrt(3) / 2;
    final int cols = ((maxX - minX) / spacing).ceil() + 1;
    final int rows = ((maxY - minY) / rowHeight).ceil() + 1;

    // 3) extract polygon edges (avoid Path in isolates)
    final List<_Edge> edges = <_Edge>[];
    for (int i = 0; i < vertices.length; i++) {
      final Offset a = vertices[i];
      final Offset b = vertices[(i + 1) % vertices.length];
      edges.add(_Edge(a, b));
    }

    final List<Offset> points = <Offset>[];

    // 4) sweep rows
    for (int row = 0; row <= rows; row++) {
      final double y = minY + row * rowHeight;
      final double xOffset = (row.isEven ? 0.0 : spacing / 2);

      for (int col = 0; col <= cols; col++) {
        final double x = minX + col * spacing + xOffset;
        final Offset p = Offset(x, y);

        // keep if inside polygon or within tolerance of any edge
        if (_polygonContains(vertices, p) || _minDistToEdges(p, edges) <= tolerance) {
          points.add(p);
        }
      }
    }

    return points;
  }

  /// Point-in-polygon using ray casting. Works in isolates without dart:ui Path.
  /// Returns true if [point] lies inside or on the boundary of the polygon [poly].
  bool _polygonContains(List<Offset> poly, Offset point) {
    final int n = poly.length;
    if (n < 3) return false;

    bool inside = false;
    for (int i = 0, j = n - 1; i < n; j = i++) {
      final Offset pi = poly[i];
      final Offset pj = poly[j];

      // Check if point is exactly on the segment pj->pi
      if (_pointOnSegment(point, pj, pi)) return true;

      final bool intersect =
          ((pi.dy > point.dy) != (pj.dy > point.dy)) &&
          (point.dx < (pj.dx - pi.dx) * (point.dy - pi.dy) / ((pj.dy - pi.dy) == 0 ? 1e-12 : (pj.dy - pi.dy)) + pi.dx);
      if (intersect) inside = !inside;
    }
    return inside;
  }

  // Checks if point p lies on segment v->w within a small epsilon tolerance.
  bool _pointOnSegment(Offset p, Offset v, Offset w, {double epsilon = 1e-6}) {
    final double cross = (p.dy - v.dy) * (w.dx - v.dx) - (p.dx - v.dx) * (w.dy - v.dy);
    if (cross.abs() > epsilon) return false; // not colinear

    final double dot = (p.dx - v.dx) * (w.dx - v.dx) + (p.dy - v.dy) * (w.dy - v.dy);
    if (dot < -epsilon) return false; // before v

    final double lenSq = (w.dx - v.dx) * (w.dx - v.dx) + (w.dy - v.dy) * (w.dy - v.dy);
    if (dot - lenSq > epsilon) return false; // beyond w
    return true;
  }

  // helper: compute minimum distance from p to any edge
  double _minDistToEdges(Offset p, List<_Edge> edges) {
    double best = double.infinity;
    for (final _Edge e in edges) {
      final double d = _pointToSegmentDistance(p, e.a, e.b);
      if (d < best) best = d;
    }
    return best;
  }

  // helper: point-to-segment distance
  double _pointToSegmentDistance(Offset p, Offset v, Offset w) {
    final double dx = w.dx - v.dx;
    final double dy = w.dy - v.dy;
    if (dx == 0 && dy == 0) {
      return (p - v).distance;
    }
    final double t = ((p.dx - v.dx) * dx + (p.dy - v.dy) * dy) / (dx * dx + dy * dy);
    if (t <= 0) return (p - v).distance;
    if (t >= 1) return (p - w).distance;
    final Offset proj = Offset(v.dx + t * dx, v.dy + t * dy);
    return (p - proj).distance;
  }
}

/// Holds the SPL results for one surface,
/// pairing each field‐point with its SPL value.
class SplData {
  /// The id of the surface these values belong to.
  final String surfaceId;

  /// The list of points (in world‐coords) where SPL was measured.
  final List<Offset> fieldPoints;

  /// The corresponding SPL values, in the same order as [fieldPoints].
  final List<double> splValues;

  SplData({required this.surfaceId, required this.fieldPoints, required this.splValues})
    : assert(fieldPoints.length == splValues.length, 'fieldPoints(${fieldPoints.length}) and splValues(${splValues.length}) must match');

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SplData && other.surfaceId == surfaceId && listEquals(other.fieldPoints, fieldPoints) && listEquals(other.splValues, splValues);
  }

  @override
  int get hashCode => Object.hash(
    surfaceId,
    Object.hashAll(fieldPoints),
    Object.hashAll(splValues),
  );
}

class _Edge {
  final Offset a, b;

  _Edge(this.a, this.b);
}
