part of '../pb_item_param.dart';

class PBTextParam extends PBItemParam {
  final String label;
  final num? fontSize;
  PBTextParam({
    required this.label,
    this.fontSize,
  });

  PBTextParam copyWith({
    String? label,
    num? fontSize,
  }) {
    return PBTextParam(
      label: label ?? this.label,
      fontSize: fontSize ?? this.fontSize,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'label': label,
      'fontSize': fontSize,
    };
  }

  factory PBTextParam.fromMap(Map<dynamic, dynamic> map) {
    return PBTextParam(
      label: (map['label'] ?? '') as String,
      fontSize: map['fontSize'] != null ? map['fontSize'] as num : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory PBTextParam.fromJson(String source) => PBTextParam.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'PBTextParam(label: $label, fontSize: $fontSize)';

  @override
  bool operator ==(covariant PBTextParam other) {
    if (identical(this, other)) return true;

    return other.label == label && other.fontSize == fontSize;
  }

  @override
  int get hashCode => label.hashCode ^ fontSize.hashCode;

  @override
  PBItemParam loadMap(Map<String, dynamic> map) {
    return PBTextParam.fromMap(map);
  }

  @override
  PBItemParam clone() {
    return copyWith();
  }
}
