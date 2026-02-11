import 'package:fusion_lib/fusion_lib.dart';

class EquipLocation {
  final String id;
  final String name;

  EquipLocation({
    String? id,
    required this.name,
  }) : id = id ?? "EQUIP${FusionUtils.shortStringUUID()}";

  EquipLocation copyWith({
    String? id,
    String? name,
  }) {
    return EquipLocation(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
  };

  factory EquipLocation.fromJson(Map<String, dynamic> json) {
    return EquipLocation(
      id: json['id'] as String?,
      name: json['name'] as String,
    );
  }
}
