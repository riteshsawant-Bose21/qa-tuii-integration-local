import '../../fusion_utils/fusion_utilities.dart';

class SourceSet {
  final String id;
  final String name;
  final bool isLinked;

  SourceSet({
    String? id,
    required this.name,
    this.isLinked = false,
  }) : id = id ?? "SET${FusionUtils.shortStringUUID()}";

  SourceSet copyWith({
    String? id,
    String? name,
    bool? isLinked,
  }) {
    return SourceSet(
      id: id ?? this.id,
      name: name ?? this.name,
      isLinked: isLinked ?? this.isLinked,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SourceSet && other.id == id && other.name == name && other.isLinked == isLinked;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ isLinked.hashCode;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'isLinked': isLinked,
  };

  factory SourceSet.fromJson(Map<String, dynamic> json) {
    return SourceSet(
      id: json['id'] as String,
      name: json['name'] as String,
      isLinked: json['isLinked'] as bool? ?? false,
    );
  }
}
