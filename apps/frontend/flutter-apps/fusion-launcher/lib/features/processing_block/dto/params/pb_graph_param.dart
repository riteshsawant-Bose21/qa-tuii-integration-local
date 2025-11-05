part of '../pb_item_param.dart';

class PBGraphParam extends PBItemParam {
  final String label;
  PBGraphParam({required this.label});

  PBGraphParam copyWith({String? label}) {
    return PBGraphParam(label: label ?? this.label);
  }

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{'label': label};
  }

  factory PBGraphParam.fromMap(Map<String, dynamic> map) {
    return PBGraphParam(label: (map['label'] ?? '') as String);
  }

  String toJson() => json.encode(toMap());

  factory PBGraphParam.fromJson(String source) => PBGraphParam.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'GridGraphParam(label: $label)';

  @override
  bool operator ==(covariant PBGraphParam other) {
    if (identical(this, other)) return true;

    return other.label == label;
  }

  @override
  int get hashCode => label.hashCode;
}
