class SceneSetModel {
  final String id;
  final String name;

  SceneSetModel({
    String? id,
    required this.name,
  }) : id = id ?? "SCENESET${DateTime.now().millisecondsSinceEpoch}";

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
