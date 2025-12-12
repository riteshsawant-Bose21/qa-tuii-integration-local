part of '../pb_item_param.dart';

class PBDropdownParam extends PBItemParam {
  final String label;
  final List<String> options;
  PBDropdownParam({
    required this.label,
    required this.options,
  });
  factory PBDropdownParam.fromMap(Map<dynamic, dynamic> map) {
    return PBDropdownParam(
      label: (map['label']?.toString() ?? ''),
      options: (map['options']?.map<String>((dynamic x) => x.toString()).toList() ?? <String>[]),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'label': label,
      'options': options,
    };
  }

  @override
  PBDropdownParam loadMap(Map<String, dynamic> map) {
    return PBDropdownParam.fromMap(map);
  }

  @override
  PBDropdownParam clone() {
    return copyWith();
  }

  PBDropdownParam copyWith({
    String? label,
    List<String>? options,
  }) {
    return PBDropdownParam(
      label: label ?? this.label,
      options: options ?? this.options,
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
