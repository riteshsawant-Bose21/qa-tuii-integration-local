part of '../pb_item_param.dart';

class PBSliderParam extends PBItemParam {
  final String label;
  final num min;
  final num max;
  PBSliderParam({required this.label, required this.min, required this.max});

  PBSliderParam copyWith({String? label, num? min, num? max}) {
    return PBSliderParam(label: label ?? this.label, min: min ?? this.min, max: max ?? this.max);
  }

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{'label': label, 'min': min, 'max': max};
  }

  factory PBSliderParam.fromMap(Map<dynamic, dynamic> map) {
    return PBSliderParam(
      label: map['label'] as String,
      min: WiringSerializationUtil.numDeserializer.deserialize(map['min']) ?? 0,
      max: WiringSerializationUtil.numDeserializer.deserialize(map['max']) ?? 0,
    );
  }

  String toJson() => json.encode(toMap());

  factory PBSliderParam.fromJson(String source) => PBSliderParam.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'GridSliderParam(label: $label, min: $min, max: $max)';

  @override
  bool operator ==(covariant PBSliderParam other) {
    if (identical(this, other)) return true;

    return other.label == label && other.min == min && other.max == max;
  }

  @override
  int get hashCode => label.hashCode ^ min.hashCode ^ max.hashCode;
  @override
  PBItemParam loadMap(Map<String, dynamic> map) {
    return PBSliderParam.fromMap(map);
  }
}
