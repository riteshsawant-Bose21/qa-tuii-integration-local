import 'dart:math';
import 'dart:ui';

import 'package:uuid/uuid.dart';

class ListeningArea {
  final String id;
  final List<Offset> vertices;
  SplData? splData;
  final String name;
  final String venuType;
  final String listeningHeight;
  final String ceilingHeight;
  final String splRange;

  ListeningArea({
    String? id,
    required this.vertices,
    this.splData,
    this.name = '',
    this.venuType = '',
    this.listeningHeight = '',
    this.ceilingHeight = '',
    this.splRange = '',
  }) : id = id ?? const Uuid().v4();

  List<Offset> getFieldPointsSet({int cols = 60, int rows = 60}) {
    if (vertices.isEmpty) return <Offset>[];

    // 1) bounding‐box
    final Iterable<double> xs = vertices.map((Offset v) => v.dx);
    final Iterable<double> ys = vertices.map((Offset v) => v.dy);
    final double minX = xs.reduce(min), maxX = xs.reduce(max);
    final double minY = ys.reduce(min), maxY = ys.reduce(max);

    final double dx = (maxX - minX) / cols;
    final double dy = (maxY - minY) / rows;

    // 2) build Path for polygon‐hit testing
    final Path path = Path()..addPolygon(vertices, true);

    // 3) sample grid and keep only points inside
    final List<Offset> pts = <Offset>[];
    for (int i = 0; i <= cols; i++) {
      for (int j = 0; j <= rows; j++) {
        final Offset p = Offset(minX + dx * i, minY + dy * j);
        if (path.contains(p)) {
          pts.add(p);
        }
      }
    }
    return pts;
  }

  /// Returns all points inside the polygon on a uniform grid where
  /// the distance between adjacent points is approximately [spacing]
  /// world‐units (rather than a fixed cols×rows).
  List<Offset> getFieldPoints() {
    if (vertices.isEmpty) return <Offset>[];

    final double spacing = 20.0;

    // 1) compute axis‐aligned bounding box
    final Iterable<double> xs = vertices.map((Offset v) => v.dx);
    final Iterable<double> ys = vertices.map((Offset v) => v.dy);
    final double minX = xs.reduce(min), maxX = xs.reduce(max);
    final double minY = ys.reduce(min), maxY = ys.reduce(max);

    // 2) determine how many steps in each direction
    final int cols = ((maxX - minX) / spacing).ceil();
    final int rows = ((maxY - minY) / spacing).ceil();

    // 3) prepare polygon for hit‐testing
    final Path path = Path()..addPolygon(vertices, true);

    // 4) sample grid
    final List<Offset> pts = <Offset>[];
    for (int i = 0; i <= cols; i++) {
      final double x = minX + i * spacing;
      for (int j = 0; j <= rows; j++) {
        final double y = minY + j * spacing;
        final Offset p = Offset(x, y);
        if (path.contains(p)) {
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
    String? venuType,
    String? listeningHeight,
    String? ceilingHeight,
    String? splRange,
  }) {
    return ListeningArea(
      vertices: vertices ?? this.vertices,
      id: id ?? this.id,
      splData: splData ?? this.splData,
      name: name ?? this.name,
      venuType: venuType ?? this.venuType,
      listeningHeight: listeningHeight ?? this.listeningHeight,
      ceilingHeight: ceilingHeight ?? this.ceilingHeight,
      splRange: splRange ?? this.splRange,
    );
  }

  /// Store the given points & values together
  void setSplData(List<Offset> points, List<double> values) {
    splData = SplData(surfaceId: id, fieldPoints: points, splValues: values);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'vertices': vertices.map((Offset v) => <String, double>{'dx': v.dx, 'dy': v.dy}).toList(),
    'splData': null,
    'venuType': venuType,
    'listeningHeight': listeningHeight,
    'ceilingHeight': ceilingHeight,
    'splRange': splRange,
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
      venuType: json['venuType'] as String? ?? '',
      listeningHeight: json['listeningHeight'] as String? ?? '',
      ceilingHeight: json['ceilingHeight'] as String? ?? '',
      splRange: json['splRange'] as String? ?? '',
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

    // 3) build polygon path & extract edges
    final Path poly = Path()..addPolygon(vertices, true);
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

        // keep if inside or within tolerance of any edge
        if (poly.contains(p) || _minDistToEdges(p, edges) <= tolerance) {
          points.add(p);
        }
      }
    }

    return points;
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
}

class _Edge {
  final Offset a, b;

  _Edge(this.a, this.b);
}
