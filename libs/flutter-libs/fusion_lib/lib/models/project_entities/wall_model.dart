import 'package:fusion_lib/fusion_utils/fusion_utilities.dart';

import 'canvas/fusion_canvas_point.dart';

class Wall {
  final String id;
  final List<FusionCanvasPoint> vertices;
  Wall({
    String? id,
    required this.vertices,
  }) : id = id ?? "WALL${FusionUtils.shortStringUUID()}";

  Wall copyWith({
    String? id,
    List<FusionCanvasPoint>? vertices,
  }) {
    return Wall(
      id: id ?? this.id,
      vertices: vertices ?? this.vertices,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Wall && other.id == id && _listEquals(other.vertices, vertices);
  }

  @override
  int get hashCode => id.hashCode ^ vertices.hashCode;

  bool _listEquals(List<FusionCanvasPoint> a, List<FusionCanvasPoint> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "vertices": vertices.map((v) => v.toMap()).toList(),
    };
  }

  factory Wall.fromJson(Map<String, dynamic> json) {
    return Wall(
      id: json["id"],
      vertices: (json["vertices"] as List).map((v) => FusionCanvasPoint.fromMap(Map<String, dynamic>.from(v))).toList(),
    );
  }
}
