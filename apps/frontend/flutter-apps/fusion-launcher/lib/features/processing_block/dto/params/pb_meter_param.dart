part of '../pb_item_param.dart';

class PBMeterParam extends PBItemParam {
  final String label;
  final num min;
  final num max;
  PBMeterParam({required this.label, required this.min, required this.max});

  PBMeterParam copyWith({String? label, num? min, num? max}) {
    return PBMeterParam(label: label ?? this.label, min: min ?? this.min, max: max ?? this.max);
  }

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{'label': label, 'min': min, 'max': max};
  }

  factory PBMeterParam.fromMap(Map<dynamic, dynamic> map) {
    return PBMeterParam(label: map['label'] as String, min: map['min'] as num, max: map['max'] as num);
  }

  String toJson() => json.encode(toMap());

  factory PBMeterParam.fromJson(String source) => PBMeterParam.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'PBMeterParam(label: $label, min: $min, max: $max)';

  @override
  bool operator ==(covariant PBMeterParam other) {
    if (identical(this, other)) return true;

    return other.label == label && other.min == min && other.max == max;
  }

  @override
  int get hashCode => label.hashCode ^ min.hashCode ^ max.hashCode;

  @override
  PBItemParam loadMap(Map<String, dynamic> map) {
    return PBMeterParam.fromMap(map);
  }
}
