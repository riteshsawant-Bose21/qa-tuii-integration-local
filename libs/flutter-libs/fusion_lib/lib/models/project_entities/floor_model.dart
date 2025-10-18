import 'package:fusion_lib/models/fusion_models.dart';
import 'package:uuid/uuid.dart';

class FloorModel {
  final String id;
  final String name;
  FloorPlanModel floorPlan;

  FloorModel({
    String? id,
    required this.name,
    required this.floorPlan,
  }) : id = id ?? const Uuid().v4();

  FloorModel copyWith({
    String? id,
    String? name,
    FloorPlanModel? floorPlan,
  }) {
    return FloorModel(
      id: id ?? this.id,
      name: name ?? this.name,
      floorPlan: floorPlan ?? this.floorPlan,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'floorPlan': floorPlan.toJson(),
  };

  factory FloorModel.fromJson(Map<String, dynamic> json) {
    // 1) Floor plan
    final Map<String, dynamic> fpMap = json['floorPlan'] as Map<String, dynamic>;
    final FloorPlanModel fp = FloorPlanModel.fromJson(fpMap);
    return FloorModel(
      id: json['id'] as String?,
      name: json['name'] as String,
      floorPlan: fp,
    );
  }
}
