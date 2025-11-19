part of '../pb_item_param.dart';

class PBIndicatorParam extends PBItemParam {
  final String label;
  PBIndicatorParam({required this.label});

  PBIndicatorParam copyWith({String? label}) {
    return PBIndicatorParam(label: label ?? this.label);
  }

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{'label': label};
  }

  factory PBIndicatorParam.fromMap(Map<dynamic, dynamic> map) {
    return PBIndicatorParam(label: (map['label'] ?? '') as String);
  }

  String toJson() => json.encode(toMap());

  factory PBIndicatorParam.fromJson(String source) => PBIndicatorParam.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'GridIndicatorParam(label: $label)';

  @override
  bool operator ==(covariant PBIndicatorParam other) {
    if (identical(this, other)) return true;

    return other.label == label;
  }

  @override
  int get hashCode => label.hashCode;
  @override
  PBItemParam loadMap(Map<String, dynamic> map) {
    return PBIndicatorParam.fromMap(map);
  }
    @override
  PBItemParam clone() {
    return copyWith();
  }
}
