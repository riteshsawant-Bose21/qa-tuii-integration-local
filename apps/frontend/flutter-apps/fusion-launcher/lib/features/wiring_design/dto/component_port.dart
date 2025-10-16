part of 'component_data.dart';

class ComponentPort {
  final String? image;
  final String? label;
  final String type;
  final List<String> compatibleTypes;
  final String data;
  final PortPosition? position;
  final int index;
  ComponentPort({
    required this.data,
    this.image,
    this.label,
    required this.type,
    required this.compatibleTypes,
    this.position,
    this.index = 0,
  });

  static ComponentPort input({
    required String data,
    String? image,
    String? label,
  }) {
    return ComponentPort(
      data: data,
      image: image,
      label: label,
      type: 'input',
      compatibleTypes: const <String>['output'],
    );
  }

  static ComponentPort output({
    required String data,
    String? image,
    String? label,
  }) {
    return ComponentPort(
      data: data,
      image: image,
      label: label,
      type: 'output',
      compatibleTypes: const <String>['input'],
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'image': image,
      'label': label,
      'type': type,
      'compatibleTypes': compatibleTypes,
      'data': data,
    };
  }

  factory ComponentPort.fromMap(Map<String, dynamic> map) {
    return ComponentPort(
      image: map['image'] != null ? map['image'] as String : null,
      label: map['label'] != null ? map['label'] as String : null,
      type: map['type'] as String,
      compatibleTypes: List<String>.from(
        (map['compatibleTypes'] as List<String>),
      ),
      data: map['data'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory ComponentPort.fromJson(String source) =>
      ComponentPort.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool operator ==(covariant ComponentPort other) {
    if (identical(this, other)) return true;

    return other.image == image &&
        other.label == label &&
        other.type == type &&
        listEquals(other.compatibleTypes, compatibleTypes) &&
        other.data == data;
  }

  @override
  int get hashCode {
    return image.hashCode ^
        label.hashCode ^
        type.hashCode ^
        compatibleTypes.hashCode ^
        data.hashCode;
  }
}
