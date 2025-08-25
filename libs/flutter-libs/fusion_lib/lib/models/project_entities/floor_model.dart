import 'package:fusion_lib/models/fusion_models.dart';
import 'package:uuid/uuid.dart';

class FloorModel {
  final String id;
  final String name;
  FloorPlanModel floorPlan;
  final List<ListeningArea> listeningAreas;

  FloorModel({String? id, required this.name, required this.floorPlan, List<ListeningArea>? listeningAreas})
    : id = id ?? const Uuid().v4(),
      listeningAreas = listeningAreas ?? <ListeningArea>[];

  FloorModel copyWith({String? id, String? name, FloorPlanModel? floorPlan, List<ListeningArea>? listeningAreas}) {
    return FloorModel(
      id: id ?? this.id,
      name: name ?? this.name,
      floorPlan: floorPlan ?? this.floorPlan,
      listeningAreas: listeningAreas ?? this.listeningAreas,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'floorPlan': floorPlan.toJson(),
    'listeningAreas': listeningAreas.map((ListeningArea s) => s.toJson()).toList(),
  };

  factory FloorModel.fromJson(Map<String, dynamic> json) {
    // 1) Floor plan
    final Map<String, dynamic> fpMap = json['floorPlan'] as Map<String, dynamic>;
    final FloorPlanModel fp = FloorPlanModel.fromJson(fpMap);

    // 2) Listening Areas
    final List<dynamic> rawListeningAreas = json['listeningAreas'] as List<dynamic>? ?? <dynamic>[];
    final List<ListeningArea> listeningAreas = rawListeningAreas.map((dynamic e) => ListeningArea.fromJson(e as Map<String, dynamic>)).toList();

    return FloorModel(id: json['id'] as String?, name: json['name'] as String, floorPlan: fp, listeningAreas: listeningAreas);
  }
}
