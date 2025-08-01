import 'package:uuid/uuid.dart';

import 'floor_plan_entity.dart';
import 'listening_area_entity.dart';

class Floor {
  final String id;
  final String name;
  FloorPlanEntity floorPlan;
  final List<ListeningArea> listeningAreas;

  Floor({
    String? id,
    required this.name,
    required this.floorPlan,
    List<ListeningArea>? listeningAreas,
  }) : id = id ?? const Uuid().v4(),
       listeningAreas = listeningAreas ?? <ListeningArea>[];

  Floor copyWith({String? id, String? name, FloorPlanEntity? floorPlan, List<ListeningArea>? listeningAreas}) {
    return Floor(
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

  factory Floor.fromJson(Map<String, dynamic> json) {
    // 1) Floor plan
    final Map<String, dynamic> fpMap = json['floorPlan'] as Map<String, dynamic>;
    final FloorPlanEntity fp = FloorPlanEntity.fromJson(fpMap);

    // 2) Listening Areas
    final List<dynamic> rawListeningAreas = json['listeningAreas'] as List<dynamic>? ?? <dynamic>[];
    final List<ListeningArea> listeningAreas = rawListeningAreas.map((dynamic e) => ListeningArea.fromJson(e as Map<String, dynamic>)).toList();

    return Floor(
      id: json['id'] as String?,
      name: json['name'] as String,
      floorPlan: fp,
      listeningAreas: listeningAreas,
    );
  }
}
