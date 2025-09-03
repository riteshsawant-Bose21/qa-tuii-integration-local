import 'package:fusion_lib/models/fusion_models.dart';
import 'package:uuid/uuid.dart';

class FloorModel {
  final String id;
  final String name;
  FloorPlanModel floorPlan;
  final List<String> listeningAreaIds;

  FloorModel({String? id, required this.name, required this.floorPlan, List<String>? listeningAreaIds})
    : id = id ?? const Uuid().v4(),
      listeningAreaIds = listeningAreaIds ?? <String>[];

  FloorModel copyWith({String? id, String? name, FloorPlanModel? floorPlan, List<String>? listeningAreaIds}) {
    return FloorModel(
      id: id ?? this.id,
      name: name ?? this.name,
      floorPlan: floorPlan ?? this.floorPlan,
      listeningAreaIds: listeningAreaIds ?? this.listeningAreaIds,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'floorPlan': floorPlan.toJson(),
    'listeningAreaIds': listeningAreaIds.map((String e) => e).toList(),
  };

  factory FloorModel.fromJson(Map<String, dynamic> json) {
    // 1) Floor plan
    final Map<String, dynamic> fpMap = json['floorPlan'] as Map<String, dynamic>;
    final FloorPlanModel fp = FloorPlanModel.fromJson(fpMap);

    // 2) Listening Areas
    final List<String> listeningAreas = (json['listeningAreaIds'] as List<dynamic>?)?.map((dynamic e) => e as String).toList() ?? <String>[];

    return FloorModel(id: json['id'] as String?, name: json['name'] as String, floorPlan: fp, listeningAreaIds: listeningAreas);
  }
}
