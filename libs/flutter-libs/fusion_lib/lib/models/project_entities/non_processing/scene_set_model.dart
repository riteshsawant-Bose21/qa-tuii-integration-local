class SceneSetModel {
  final String id;
  final String name;

  SceneSetModel({
    String? id,
    required this.name,
  }) : id = id ?? "SCENESET${DateTime.now().millisecondsSinceEpoch}";

  //copy with
  SceneSetModel copyWith({
    String? id,
    String? name,
  }) {
    return SceneSetModel(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  factory SceneSetModel.fromJson(Map<String, dynamic> json) {
    return SceneSetModel(
      id: json['id'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}
