part of '../pb_item_param.dart';

class PBDropdownParam extends PBItemParam {
  final String label;
  PBDropdownParam({
    required this.label,
  });
  factory PBDropdownParam.fromMap(Map<dynamic, dynamic> map) {
    return PBDropdownParam(
      label: (map['label'] ?? '') as String,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'label': label,
    };
  }

  @override
  PBDropdownParam loadMap(Map<String, dynamic> map) {
    return PBDropdownParam.fromMap(map);
  }

  PBDropdownParam copyWith({
    String? label,
  }) {
    return PBDropdownParam(
      label: label ?? this.label,
    );
  }

  String toJson() => json.encode(toMap());

  factory PBDropdownParam.fromJson(String source) => PBDropdownParam.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'PBDropdownParam(label: $label)';

  @override
  bool operator ==(covariant PBDropdownParam other) {
    if (identical(this, other)) return true;

    return other.label == label;
  }

  @override
  int get hashCode => label.hashCode;
}
