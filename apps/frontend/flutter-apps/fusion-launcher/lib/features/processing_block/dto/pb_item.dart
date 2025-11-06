// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'dart:math';

import 'pb_item_param.dart';
import 'pb_param_factory.dart';

class PBItem {
  final String id;
  final num x;
  final num y;
  final num width;
  final num height;
  final String field;
  final String type;
  final PBItemParam param;
  PBItem({
    required this.id,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.field,
    required this.type,
    required this.param,
  });

  PBItem copyWith({
    String? id,
    num? x,
    num? y,
    num? width,
    num? height,
    String? field,
    String? type,
    PBItemParam? param,
  }) {
    return PBItem(
      id: id ?? this.id,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      field: field ?? this.field,
      type: type ?? this.type,
      param: param ?? this.param,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'field': field,
      'type': type,
      'param': param.toMap(),
    };
  }

  factory PBItem.fromMap(Map<String, dynamic> map) {
    return PBItem(
      id: (map['id'] ?? Random().nextInt(9999999).toString()) as String,
      x: (map['x'] ?? 0) as num,
      y: (map['y'] ?? 0) as num,
      width: (map['width'] ?? 0) as num,
      height: (map['height'] ?? 0) as num,
      field: (map['field'] ?? '') as String,
      type: (map['type'] ?? '') as String,
      param: PBParamFactory.build(map['param'] as Map<String, dynamic>, (map['type'] ?? '') as String),
    );
  }

  String toJson() => json.encode(toMap());

  factory PBItem.fromJson(String source) => PBItem.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'PBItem(id: $id, x: $x, y: $y, width: $width, height: $height, field: $field, type: $type, param: $param)';
  }

  @override
  bool operator ==(covariant PBItem other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.x == x &&
        other.y == y &&
        other.width == width &&
        other.height == height &&
        other.field == field &&
        other.type == type &&
        other.param == param;
  }

  @override
  int get hashCode {
    return id.hashCode ^ x.hashCode ^ y.hashCode ^ width.hashCode ^ height.hashCode ^ field.hashCode ^ type.hashCode ^ param.hashCode;
  }
}
