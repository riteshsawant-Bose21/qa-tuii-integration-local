part of '../pb_item_param.dart';

class PBTextParam extends PBItemParam {
  final String label;
  PBTextParam({required this.label});

  PBTextParam copyWith({String? label}) {
    return PBTextParam(label: label ?? this.label);
  }

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{'label': label};
  }

  factory PBTextParam.fromMap(Map<dynamic, dynamic> map) {
    return PBTextParam(label: (map['label'] ?? '') as String);
  }

  String toJson() => json.encode(toMap());

  factory PBTextParam.fromJson(String source) => PBTextParam.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'GridTextParam(label: $label)';

  @override
  bool operator ==(covariant PBTextParam other) {
    if (identical(this, other)) return true;

    return other.label == label;
  }

  @override
  int get hashCode => label.hashCode;

  @override
  PBItemParam loadMap(Map<String, dynamic> map) {
    return PBTextParam.fromMap(map);
  }
}
