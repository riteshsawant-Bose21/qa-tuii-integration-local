import 'dart:math';
import 'dart:ui';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show RangeValues;
import 'package:fusion_lib/fusion_lib.dart';

import '../../fusion_algorithms/surface_speakers_autolayout/surface_speakers_autolayout.dart';

enum SpeakerEnvironmentType {
  indoor("Indoor"),
  outdoor("Outdoor");

  final String displayName;
  const SpeakerEnvironmentType(this.displayName);

  static SpeakerEnvironmentType? fromJson(String? value) {
    switch (value?.toLowerCase()) {
      case 'indoor':
        return SpeakerEnvironmentType.indoor;
      case 'outdoor':
        return SpeakerEnvironmentType.outdoor;
      default:
        return null;
    }
  }
}

enum MountingType {
  surface,
  pendant,
  ceiling;

  String get displayName {
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
  fullRange,
  extendedBass,
  withSubwoofer;

  String get displayName {
    switch (this) {
      case LowFrequency.fullRange:
        return 'Full Range';
      case LowFrequency.extendedBass:
        return 'Extended Bass';
      case LowFrequency.withSubwoofer:
        return 'Subwoofers';
    }
  }

  static LowFrequency? fromJson(String? value) {
    switch (value?.toLowerCase()) {
      case 'fullrange':
      case 'full_range':
      case 'full-range':
        return LowFrequency.fullRange;
      case 'extendedbass':
      case 'extended_bass':
      case 'extended-bass':
        return LowFrequency.extendedBass;
      case 'withsubwoofer':
      case 'with_subwoofer':
      case 'subwoofer':
      case 'subwoofers':
        return LowFrequency.withSubwoofer;
      default:
        return null;
    }
  }
}

enum WiringType {
  highImpedance,
  lowImpedance;

  String get displayName {
    switch (this) {
      case highImpedance:
        return 'Hi-Z';
      case lowImpedance:
        return 'Lo-Z';
    }
  }

  static WiringType? fromJson(String? value) {
    switch (value?.toLowerCase()) {
      case 'highimpedance':
      case 'hi-z':
        return WiringType.highImpedance;
      case 'lowimpedance':
      case 'lo-z':
        return WiringType.lowImpedance;
      default:
        return null;
    }
  }
}

enum SplRange {
  backgroundMusic,
  paging,
  foregroundMusic,
  moderateLiveSound,
  highSplLiveSound;

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

  static SplRange? fromJson(String? value) {
    switch (value?.toLowerCase()) {
      case 'backgroundmusic':
      case 'background_music':
        return SplRange.backgroundMusic;
      case 'paging':
        return SplRange.paging;
      case 'foregroundmusic':
      case 'foreground_music':
        return SplRange.foregroundMusic;
      case 'moderatelivesound':
      case 'moderate_live_sound':
        return SplRange.moderateLiveSound;
      case 'highspllivesound':
      case 'high_spl_live_sound':
        return SplRange.highSplLiveSound;
      default:
        return null;
    }
  }
}

enum ListeningPreference {
  mono,
  stereo;

  String get name {
    switch (this) {
      case ListeningPreference.mono:
        return 'Mono';
      case ListeningPreference.stereo:
        return 'Stereo';
    }
  }

  static ListeningPreference? fromJson(String? value) {
    switch (value?.toLowerCase()) {
      case 'mono':
        return ListeningPreference.mono;
      case 'stereo':
        return ListeningPreference.stereo;
      default:
        return null;
    }
  }
}

enum BackgroundNoise {
  quiet("Quiet"),
  typical("Typical"),
  loud("Loud");

  const BackgroundNoise(this.displayName);
  final String displayName;

  static BackgroundNoise? fromJson(String? value) {
    switch (value?.toLowerCase()) {
      case 'quiet':
        return BackgroundNoise.quiet;
      case 'typical':
        return BackgroundNoise.typical;
      case 'loud':
        return BackgroundNoise.loud;
      default:
        return null;
    }
  }
}

enum SpeakerSelectionMode {
  select("Select"),
  suggest("Suggest");

  const SpeakerSelectionMode(this.displayName);
  final String displayName;

  static SpeakerSelectionMode? fromJson(String? value) {
    switch (value?.toLowerCase()) {
      case 'select':
        return SpeakerSelectionMode.select;
      case 'suggest':
        return SpeakerSelectionMode.suggest;
      default:
        return null;
    }
  }
}

extension ListExtension<T> on List<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (final T element in this) {
      if (test(element)) return element;
    }
    return null;
  }

  // single where or null
  T? singleWhereOrNull(bool Function(T element) test) {
    T? result;
    for (final T element in this) {
      if (test(element)) {
        if (result != null) {
          // More than one match
          return null;
        }
        result = element;
      }
    }
    return result;
  }

  T? elementAtOrNull(int index) {
    if (index < 0 || index >= length) return null;
    return this[index];
  }
}

class SpeakerPlacementAlgorithmResult {
  List<Offset> positions;
  SurfacePlacementResult? surfacePlacementResult;
  PlacementResult? placementResult;
  final double coverageAngle;
  final double listnersHeight;
  final CoveragePreference coveragePreference;
  final double width;
  final double length;
  final CeilingPlacementParams? ceilingPlacementParams;

  SpeakerPlacementAlgorithmResult({
    required this.positions,
    this.surfacePlacementResult,
    this.placementResult,
    required this.coverageAngle,
    required this.listnersHeight,
    required this.coveragePreference,
    required this.width,
    required this.length,
    this.ceilingPlacementParams,
  });
}

class AutoPlacementParam {
  final CoveragePreference autoPlaceCoveragePreference;
  final LayoutPattern autoPlaceLayoutPattern;

  const AutoPlacementParam({
    this.autoPlaceCoveragePreference = CoveragePreference.minimumOverlap,
    this.autoPlaceLayoutPattern = LayoutPattern.hexagonal,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
    'autoPlaceCoveragePreference': autoPlaceCoveragePreference.name,
    'autoPlaceLayoutPattern': autoPlaceLayoutPattern.name,
  };

  factory AutoPlacementParam.fromJson(Map<String, dynamic> json) {
    final autoPlaceCoveragePreference = switch (json['autoPlaceCoveragePreference'] as String?) {
      'minimumOverlap' => CoveragePreference.minimumOverlap,
      'edgeToEdge' => CoveragePreference.edgeToEdge,
      'centerToCenter' => CoveragePreference.centerToCenter,
      _ => CoveragePreference.minimumOverlap,
    };

    final autoPlaceLayoutPattern = switch (json['autoPlaceLayoutPattern'] as String?) {
      'hexagonal' => LayoutPattern.hexagonal,
      'square' => LayoutPattern.square,
      _ => LayoutPattern.hexagonal,
    };

    return AutoPlacementParam(
      autoPlaceCoveragePreference: autoPlaceCoveragePreference,
      autoPlaceLayoutPattern: autoPlaceLayoutPattern,
    );
  }

  AutoPlacementParam copyWith({
    CoveragePreference? autoPlaceCoveragePreference,
    LayoutPattern? autoPlaceLayoutPattern,
  }) {
    return AutoPlacementParam(
      autoPlaceCoveragePreference: autoPlaceCoveragePreference ?? this.autoPlaceCoveragePreference,
      autoPlaceLayoutPattern: autoPlaceLayoutPattern ?? this.autoPlaceLayoutPattern,
    );
  }
}

class ListeningArea {
  final String id;
  final List<FusionCanvasPoint> vertices;
  SplData? splData;
  final String name;
  final ListeningHeightOption listeningHeightOption;
  final SpeakerEnvironmentType environmentType;
  final double listeningHeight;
  final double floorHeight;
  final double ceilingHeight;
  final double minSPL;
  final double maxSPL;
  final bool isDrawn;

  final Color? preferredSpeakerColor;
  final SplRange splRange;
  final ListeningPreference? listeningPreference;

  /// THESE ARE FILTER OPTIONS
  final SpeakerSelectionMode speakerSelectionMode;
  final SpeakerSelectModeArgs speakerSelectModeArgs;
  final SpeakerSuggestModeArgs speakerSuggestModeArgs;

  final SignalType signalType;
  final MountingType mountingType;
  final LowFrequency lowFrequency;
  final WiringType? wiringType;
  final BackgroundNoise? backgroundNoise;
  final bool autoPlacement;
  final AutoPlacementParam? autoPlacementResult;

  ListeningArea({
    String? id,
    required this.vertices,
    this.splData,
    this.name = '',
    this.environmentType = SpeakerEnvironmentType.indoor,
    this.listeningHeightOption = ListeningHeightOption.sitting,
    this.listeningHeight = 1.1, // Default to sitting height (1.1 m)
    this.ceilingHeight = 2.5, // Default to 2.5 meters
    this.floorHeight = 0.0,
    this.minSPL = 60.0,
    this.maxSPL = 70.0,
    this.signalType = SignalType.mono,
    this.mountingType = MountingType.surface,
    this.lowFrequency = LowFrequency.fullRange,
    this.wiringType,
    this.backgroundNoise,
    this.speakerSelectionMode = SpeakerSelectionMode.select,
    this.speakerSelectModeArgs = const SpeakerSelectModeArgs(),
    this.speakerSuggestModeArgs = const SpeakerSuggestModeArgs(),
    this.autoPlacement = false,
    this.autoPlacementResult,
    this.preferredSpeakerColor,
    this.splRange = SplRange.backgroundMusic,
    this.listeningPreference,
    bool? isDrawn,
  }) : id = id ?? "AREA${FusionUtils.shortStringUUID()}",
       isDrawn = isDrawn ?? vertices.isNotEmpty;

  List<Offset> getFieldPointsSet({int cols = 60, int rows = 60}) {
    if (vertices.isEmpty) return <Offset>[];

    // 1) bounding‐box
    final Iterable<double> xs = vertices.map((FusionCanvasPoint v) => v.position.dx);
    final Iterable<double> ys = vertices.map((FusionCanvasPoint v) => v.position.dy);
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
    final Iterable<double> xs = vertices.map((FusionCanvasPoint v) => v.position.dx);
    final Iterable<double> ys = vertices.map((FusionCanvasPoint v) => v.position.dy);
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

  Offset? getCenterPositionOfVertices() {
    if (vertices.isEmpty) return null;

    double sumX = 0.0;
    double sumY = 0.0;

    for (final FusionCanvasPoint vertex in vertices) {
      sumX += vertex.position.dx;
      sumY += vertex.position.dy;
    }

    final double centerX = sumX / vertices.length;
    final double centerY = sumY / vertices.length;

    return Offset(centerX, centerY);
  }

  ListeningArea copyWith({
    String? id,
    List<FusionCanvasPoint>? vertices,
    SplData? splData,
    String? name,
    List<String>? hardwareComponentIds,
    SpeakerEnvironmentType? environmentType,
    ListeningHeightOption? listeningHeightOption,
    double? listeningHeight,
    double? floorHeight,
    double? ceilingHeight,

    double? minSPL,
    double? maxSPL,
    SignalType? signalType,
    MountingType? mountingType,
    LowFrequency? lowFrequency,
    WiringType? wiringType,
    BackgroundNoise? backgroundNoise,
    Color? preferredSpeakerColor,
    SplRange? splRange,
    ListeningPreference? listeningPreference,
    bool? isDrawn,
    SpeakerSelectionMode? speakerSelectionMode,
    SpeakerSelectModeArgs? speakerSelectModeArgs,
    SpeakerSuggestModeArgs? speakerSuggestModeArgs,
    bool? autoPlacement,
    AutoPlacementParam? autoPlacementResult,
  }) {
    return ListeningArea(
      vertices: vertices ?? this.vertices,
      id: id ?? this.id,
      splData: splData ?? this.splData,
      name: name ?? this.name,
      environmentType: environmentType ?? this.environmentType,
      listeningHeight: listeningHeight ?? this.listeningHeight,
      floorHeight: floorHeight ?? this.floorHeight,
      listeningHeightOption: listeningHeightOption ?? this.listeningHeightOption,
      ceilingHeight: ceilingHeight ?? this.ceilingHeight,
      minSPL: minSPL ?? this.minSPL,
      maxSPL: maxSPL ?? this.maxSPL,
      signalType: signalType ?? this.signalType,
      mountingType: mountingType ?? this.mountingType,
      lowFrequency: lowFrequency ?? this.lowFrequency,
      wiringType: wiringType ?? this.wiringType,
      backgroundNoise: backgroundNoise ?? this.backgroundNoise,
      speakerSelectionMode: speakerSelectionMode ?? this.speakerSelectionMode,
      speakerSelectModeArgs: speakerSelectModeArgs ?? this.speakerSelectModeArgs,
      speakerSuggestModeArgs: speakerSuggestModeArgs ?? this.speakerSuggestModeArgs,
      autoPlacement: autoPlacement ?? this.autoPlacement,
      autoPlacementResult: autoPlacementResult ?? this.autoPlacementResult,
      preferredSpeakerColor: preferredSpeakerColor ?? this.preferredSpeakerColor,
      splRange: splRange ?? this.splRange,
      listeningPreference: listeningPreference ?? this.listeningPreference,
      isDrawn: isDrawn ?? this.isDrawn,
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
    'vertices': vertices.map((FusionCanvasPoint v) => v.toMap()).toList(),
    'splData': null,
    'environmentType': environmentType.name,
    'listeningHeight': listeningHeight,
    'ceilingHeight': ceilingHeight,
    'minSPL': minSPL,
    'maxSPL': maxSPL,
    'isDrawn': isDrawn,
    'preferredSpeakerColor': preferredSpeakerColor,
    'splRange': splRange.name,
    'listeningPreference': listeningPreference?.name,
    'signalType': signalType.name,
    'backgroundNoise': backgroundNoise?.name,
    'mountingType': mountingType.name,
    'lowFrequency': lowFrequency.name,
    'wiringType': wiringType?.name,
    'speakerSelectionMode': speakerSelectionMode.name,
    'autoPlacement': autoPlacement,
    'autoPlacementResult': autoPlacementResult?.toJson(),
    'speakerSelectModeArgs': speakerSelectModeArgs.toJson(),
    'speakerSuggestModeArgs': speakerSuggestModeArgs.toJson(),
  };

  /// Parses back from JSON, turning the dynamic list into List<Offset>
  factory ListeningArea.fromJson(Map<String, dynamic> json) {
    // 1) get the raw list
    final List<dynamic> rawVerts = json['vertices'] as List<dynamic>;
    // 2) map each element (a Map) into a FusionCanvasPoint
    final List<FusionCanvasPoint> verts = rawVerts.map((dynamic e) {
      final Map<String, dynamic> m = e as Map<String, dynamic>;
      return FusionCanvasPoint.fromMap(m);
    }).toList();

    return ListeningArea(
      id: json['id'] as String?,
      vertices: verts,
      splData: null,
      name: json['name'] as String,
      environmentType: SpeakerEnvironmentType.fromJson(json['environmentType']) ?? SpeakerEnvironmentType.indoor,
      listeningHeight: (json['listeningHeight'] as num?)?.toDouble() ?? 3.0,
      ceilingHeight: double.tryParse("${json['ceilingHeight']}") ?? 2.5,
      minSPL: (json['minSPL'] as num?)?.toDouble() ?? 60.0,
      maxSPL: (json['maxSPL'] as num?)?.toDouble() ?? 70.0,
      isDrawn: json['isDrawn'] as bool? ?? (verts.isNotEmpty),
      preferredSpeakerColor: json['preferredSpeakerColor'] != null ? Color(json['preferredSpeakerColor'] as int) : null,
      splRange: SplRange.fromJson(json['splRange'] as String?) ?? SplRange.backgroundMusic,
      listeningPreference: ListeningPreference.fromJson(json['listeningPreference']),
      signalType: SignalType.fromJson(json['signalType']) ?? SignalType.mono,
      mountingType: MountingType.fromJson(json['mountingType']) ?? MountingType.surface,
      lowFrequency: LowFrequency.fromJson(json['lowFrequency']) ?? LowFrequency.fullRange,
      wiringType: WiringType.fromJson(json['wiringType']),
      backgroundNoise: BackgroundNoise.fromJson(json['backgroundNoise']),
      speakerSelectionMode: SpeakerSelectionMode.fromJson(json['speakerSelectionMode'] as String?) ?? SpeakerSelectionMode.select,
      autoPlacement: json['autoPlacement'] as bool? ?? false,
      autoPlacementResult: json['autoPlacementResult'] != null ? AutoPlacementParam.fromJson(json['autoPlacementResult'] as Map<String, dynamic>) : null,
      speakerSelectModeArgs: json['speakerSelectModeArgs'] != null
          ? SpeakerSelectModeArgs.fromJson(json['speakerSelectModeArgs'] as Map<String, dynamic>)
          : const SpeakerSelectModeArgs(),
      speakerSuggestModeArgs: json['speakerSuggestModeArgs'] != null
          ? SpeakerSuggestModeArgs.fromJson(json['speakerSuggestModeArgs'] as Map<String, dynamic>)
          : const SpeakerSuggestModeArgs(),
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
    final Iterable<double> xs = vertices.map((FusionCanvasPoint v) => v.position.dx);
    final Iterable<double> ys = vertices.map((FusionCanvasPoint v) => v.position.dy);
    final double minX = xs.reduce(min), maxX = xs.reduce(max);
    final double minY = ys.reduce(min), maxY = ys.reduce(max);

    // 2) hex-grid math
    final double rowHeight = spacing * sqrt(3) / 2;
    final int cols = ((maxX - minX) / spacing).ceil() + 1;
    final int rows = ((maxY - minY) / rowHeight).ceil() + 1;

    // 3) extract polygon edges (avoid Path in isolates)
    final List<_Edge> edges = <_Edge>[];
    for (int i = 0; i < vertices.length; i++) {
      final Offset a = vertices[i].position;
      final Offset b = vertices[(i + 1) % vertices.length].position;
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
  bool _polygonContains(List<FusionCanvasPoint> poly, Offset point) {
    final int n = poly.length;
    if (n < 3) return false;

    bool inside = false;
    for (int i = 0, j = n - 1; i < n; j = i++) {
      final Offset pi = poly[i].position;
      final Offset pj = poly[j].position;

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

  ListeningAreaRoomBounds getBoundsForVertices() {
    double minX = vertices.first.position.dx;
    double maxX = minX;
    double minY = vertices.first.position.dy;
    double maxY = minY;

    for (final FusionCanvasPoint vertex in vertices) {
      if (vertex.position.dx < minX) minX = vertex.position.dx;
      if (vertex.position.dx > maxX) maxX = vertex.position.dx;
      if (vertex.position.dy < minY) minY = vertex.position.dy;
      if (vertex.position.dy > maxY) maxY = vertex.position.dy;
    }

    return ListeningAreaRoomBounds(minX: minX, maxX: maxX, minY: minY, maxY: maxY);
  }
}

class ListeningAreaRoomBounds {
  final double minX, maxX, minY, maxY;

  const ListeningAreaRoomBounds({required this.minX, required this.maxX, required this.minY, required this.maxY});

  double get roomLengthInMeters => (maxX - minX).abs() / 100; // convert from cm to m
  double get roomWidthInMeters => (maxY - minY).abs() / 100; // convert from cm to m
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

class CeilingPlacementParams {
  final Room room;
  final LayoutPattern selectedLayoutPattern;
  final double boundaryOverlapThreshold;
  final CoveragePreference selectedCoveragePreference;
  final SpeakerType selectedSpeakerType;
  final RoomType selectedRoomType;
  final double coverageAngle;
  final List<Point2D>? customGeometry;
  CeilingPlacementParams({
    required this.room,
    required this.selectedLayoutPattern,
    required this.boundaryOverlapThreshold,
    required this.selectedCoveragePreference,
    required this.selectedSpeakerType,
    required this.selectedRoomType,
    required this.coverageAngle,
    this.customGeometry,
  });
}

enum ListeningHeightOption {
  sitting("Seated (1.1m)"),
  standing("Standing (1.7m)"),
  custom("Custom");

  const ListeningHeightOption(this.displayName);
  final String displayName;

  static double maxListeningHeight = 2.4; // in meters

  static double? getValue(ListeningHeightOption option) {
    switch (option) {
      case ListeningHeightOption.sitting:
        return 1.1;
      case ListeningHeightOption.standing:
        return 1.7;
      case ListeningHeightOption.custom:
        return null;
    }
  }

  static ListeningHeightOption getOptionByValue(double height) {
    switch (height) {
      case 1.1:
        return ListeningHeightOption.sitting;
      case 1.7:
        return ListeningHeightOption.standing;
      default:
        return ListeningHeightOption.custom;
    }
  }
}

class SpeakerSelectModeArgs extends Equatable {
  final List<MountingType> mountingTypes;
  final SpeakerMaxSplRange? maxSplRange;
  final SpeakerColorOption speakerColorOption;
  final double lowFrequencyInHz;
  final AudioChannel audioChannel;
  final WiringType wiringType;
  final bool useSubwoofer;
  final bool monoSubwoofer;

  const SpeakerSelectModeArgs({
    this.mountingTypes = const <MountingType>[],
    this.maxSplRange,
    this.speakerColorOption = SpeakerColorOption.black,
    this.lowFrequencyInHz = 70.0, // in Hz
    this.audioChannel = AudioChannel.stereo,
    this.wiringType = WiringType.highImpedance,
    this.useSubwoofer = false,
    this.monoSubwoofer = false,
  });

  @override
  List<Object?> get props => <Object?>[
    mountingTypes,
    maxSplRange,
    speakerColorOption,
    lowFrequencyInHz,
    audioChannel,
    wiringType,
    useSubwoofer,
    monoSubwoofer,
  ];

  SpeakerSelectModeArgs copyWith({
    ValueGetter<List<MountingType>>? mountingTypes,
    ValueGetter<SpeakerMaxSplRange?>? maxSplRange,
    ValueGetter<SpeakerColorOption>? speakerColorOption,
    ValueGetter<double>? lowFrequencyInHz,
    ValueGetter<AudioChannel>? audioChannel,
    ValueGetter<WiringType>? wiringType,
    ValueGetter<bool>? useSubwoofer,
    ValueGetter<bool>? monoSubwoofer,
  }) {
    return SpeakerSelectModeArgs(
      mountingTypes: mountingTypes != null ? mountingTypes() : this.mountingTypes,
      maxSplRange: maxSplRange != null ? maxSplRange() : this.maxSplRange,
      speakerColorOption: speakerColorOption != null ? speakerColorOption() : this.speakerColorOption,
      lowFrequencyInHz: lowFrequencyInHz != null ? lowFrequencyInHz() : this.lowFrequencyInHz,
      audioChannel: audioChannel != null ? audioChannel() : this.audioChannel,
      wiringType: wiringType != null ? wiringType() : this.wiringType,
      useSubwoofer: useSubwoofer != null ? useSubwoofer() : this.useSubwoofer,
      monoSubwoofer: monoSubwoofer != null ? monoSubwoofer() : this.monoSubwoofer,
    );
  }

  factory SpeakerSelectModeArgs.fromJson(Map<String, dynamic> json) {
    final mountingTypes = List.from(json['mountingTypes'] ?? []).map((e) => MountingType.fromJson(e as String) ?? MountingType.surface);

    return SpeakerSelectModeArgs(
      mountingTypes: mountingTypes.toList(),
      maxSplRange: SpeakerMaxSplRange.fromJson(json['maxSplRange'] as String?),
      speakerColorOption: SpeakerColorOption.values.firstWhere((e) => e.name == json['speakerColorOption'], orElse: () => SpeakerColorOption.black),
      lowFrequencyInHz: (json['lowFrequencyInHz'] as num?)?.toDouble() ?? 70.0,
      audioChannel: AudioChannel.values.firstWhere((e) => e.name == json['audioChannel'], orElse: () => AudioChannel.stereo),
      wiringType: WiringType.values.firstWhere((e) => e.name == json['wiringType'], orElse: () => WiringType.highImpedance),
      useSubwoofer: json['useSubwoofer'] as bool? ?? false,
      monoSubwoofer: json['monoSubwoofer'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'mountingTypes': mountingTypes.map((e) => e.name).toList(),
    'maxSplRange': maxSplRange?.name,
    'speakerColorOption': speakerColorOption.name,
    'lowFrequencyInHz': lowFrequencyInHz,
    'audioChannel': audioChannel.name,
    'wiringType': wiringType.name,
    'useSubwoofer': useSubwoofer,
    'monoSubwoofer': monoSubwoofer,
  };
}

class SpeakerSuggestModeArgs extends Equatable {
  final MountingType mountingType;
  final RangeValues splRange;
  final LowFrequency lowFrequency;

  const SpeakerSuggestModeArgs({
    this.mountingType = MountingType.surface,
    this.splRange = const RangeValues(60.0, 70.0),
    this.lowFrequency = LowFrequency.fullRange,
  });

  @override
  List<Object?> get props => <Object?>[mountingType, splRange, lowFrequency];

  SpeakerSuggestModeArgs copyWith({
    ValueGetter<MountingType>? mountingType,
    ValueGetter<RangeValues>? splRange,
    ValueGetter<LowFrequency>? lowFrequency,
  }) {
    return SpeakerSuggestModeArgs(
      mountingType: mountingType != null ? mountingType() : this.mountingType,
      splRange: splRange != null ? splRange() : this.splRange,
      lowFrequency: lowFrequency != null ? lowFrequency() : this.lowFrequency,
    );
  }

  factory SpeakerSuggestModeArgs.fromJson(Map<String, dynamic> json) {
    return SpeakerSuggestModeArgs(
      mountingType: MountingType.fromJson(json['mountingType'] as String?) ?? MountingType.surface,
      splRange: json['splRange'] != null
          ? RangeValues(
              (json['splRange']['min'] as num).toDouble(),
              (json['splRange']['max'] as num).toDouble(),
            )
          : const RangeValues(60.0, 70.0),
      lowFrequency: LowFrequency.fromJson(json['lowFrequency'] as String?) ?? LowFrequency.fullRange,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'mountingType': mountingType.name,
    'splRange': {'min': splRange.start, 'max': splRange.end},
    'lowFrequency': lowFrequency.name,
  };
}

enum SpeakerColorOption {
  black,
  white;

  String get displayName {
    switch (this) {
      case SpeakerColorOption.black:
        return 'Black';
      case SpeakerColorOption.white:
        return 'White';
    }
  }
}

enum AudioChannel {
  mono,
  stereo;

  String get displayName => switch (this) {
    AudioChannel.mono => 'Mono',
    AudioChannel.stereo => 'Stereo',
  };

  static AudioChannel? fromJson(String? value) {
    switch (value?.toLowerCase()) {
      case 'mono':
        return AudioChannel.mono;
      case 'stereo':
        return AudioChannel.stereo;
      default:
        return null;
    }
  }
}

enum SpeakerMaxSplRange {
  lessThan105db,
  range105to115db,
  greaterThan115db;

  String get displayName {
    switch (this) {
      case SpeakerMaxSplRange.lessThan105db:
        return '< 105dB';
      case SpeakerMaxSplRange.range105to115db:
        return '105 - 115 dB';
      case SpeakerMaxSplRange.greaterThan115db:
        return '> 115dB';
    }
  }

  static SpeakerMaxSplRange? fromJson(String? value) {
    if (value == "lessThan105db") return SpeakerMaxSplRange.lessThan105db;
    if (value == "range105to115db") return SpeakerMaxSplRange.range105to115db;
    if (value == "greaterThan115db") return SpeakerMaxSplRange.greaterThan115db;
    return null;
  }
}
