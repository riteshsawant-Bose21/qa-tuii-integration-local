part of '../pb_item_param.dart';

class PBTextfieldParam extends PBItemParam {
  final String label;
  final String? unit;
  final num min;
  final num max;
  PBTextfieldParam({required this.label, this.unit, required this.min, required this.max});

  PBTextfieldParam copyWith({String? label, String? unit, num? min, num? max}) {
    return PBTextfieldParam(label: label ?? this.label, unit: unit ?? this.unit, min: min ?? this.min, max: max ?? this.max);
  }

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'label': label,
      'unit': unit,
       //'min': min, 'max': max
    };
  }

  factory PBTextfieldParam.fromMap(Map<dynamic, dynamic> map) {
    return PBTextfieldParam(
      label: map['label'] as String,
      unit: map['unit'] as String?,
      min: WiringSerializationUtil.numDeserializer.deserialize(map['min']) ?? 0,
      max: WiringSerializationUtil.numDeserializer.deserialize(map['max']) ?? 0,
    );
  }

  String toJson() => json.encode(toMap());

  factory PBTextfieldParam.fromJson(String source) => PBTextfieldParam.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'GridSliderParam(label: $label, min: $min, max: $max)';

  @override
  bool operator ==(covariant PBTextfieldParam other) {
    if (identical(this, other)) return true;

    return other.label == label && other.unit == unit && other.min == min && other.max == max;
  }

  @override
  int get hashCode => label.hashCode ^ unit.hashCode ^ min.hashCode ^ max.hashCode;
  @override
  PBItemParam loadMap(Map<String, dynamic> map) {
    return PBTextfieldParam.fromMap(map);
  }

  @override
  PBItemParam clone() {
    return copyWith();
  }
}
