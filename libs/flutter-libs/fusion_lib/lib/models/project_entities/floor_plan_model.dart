import 'dart:ui';

import 'package:uuid/uuid.dart';

import '../../fusion_lib.dart';

class FloorPlanModel {
  String id;
  String imagePath;
  Offset position;
  Size size;
  double canvasZoom;
  Offset canvasPan;

  static FloorPlanModel defaultFloorPlan = FloorPlanModel(imagePath: "", position: Offset.zero, size: const Size(1000, 800));

  FloorPlanModel({
    String? id,
    required this.imagePath,
    required this.position,
    required this.size,
    this.canvasZoom = 1.0,
    this.canvasPan = Offset.zero,
  }) : id = id ?? "FLOORPLAN${FusionUtils.shortStringUUID()}";

  FloorPlanModel copyWith({
    String? id,
    String? imagePath,
    Offset? position,
    Size? size,
    double? canvasZoom,
    Offset? canvasPan,
  }) {
    return FloorPlanModel(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      position: position ?? this.position,
      size: size ?? this.size,
      canvasZoom: canvasZoom ?? this.canvasZoom,
      canvasPan: canvasPan ?? this.canvasPan,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'imagePath': imagePath,
    'position': <String, double>{'dx': position.dx, 'dy': position.dy},
    'size': <String, double>{'width': size.width, 'height': size.height},
    'canvasZoom': canvasZoom,
    'canvasPan': <String, double>{'dx': canvasPan.dx, 'dy': canvasPan.dy},
  };

  factory FloorPlanModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> pos = json['position'] as Map<String, dynamic>;
    final Map<String, dynamic> sz = json['size'] as Map<String, dynamic>;
    final Map<String, dynamic> pan = json['canvasPan'] as Map<String, dynamic>;

    return FloorPlanModel(
      id: json['id'] as String?,
      imagePath: json['imagePath'] as String,
      position: Offset((pos['dx'] as num).toDouble(), (pos['dy'] as num).toDouble()),
      size: Size((sz['width'] as num).toDouble(), (sz['height'] as num).toDouble()),
      canvasZoom: (json['canvasZoom'] as num).toDouble(),
      canvasPan: Offset((pan['dx'] as num).toDouble(), (pan['dy'] as num).toDouble()),
    );
  }
}
