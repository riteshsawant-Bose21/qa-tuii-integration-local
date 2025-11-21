import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'pb_item.dart';

class PBLayout {
  final num width;
  final num height;

  final List<PBItem> children;
  PBLayout({required this.width, required this.height, required this.children});

  PBLayout copyWith({num? width, num? height, List<PBItem>? children}) {
    return PBLayout(width: width ?? this.width, height: height ?? this.height, children: children ?? this.children);
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{'width': width, 'height': height, 'children': children.map((PBItem x) => x.toMap()).toList()};
  }

  factory PBLayout.fromMap(Map<String, dynamic> map) {
    return PBLayout(
      width: (map['width'] ?? 0) as num,
      height: (map['height'] ?? 0) as num,
      children: List<PBItem>.from(
        (map['children']).map<PBItem>((dynamic x) => PBItem.fromMap(x as Map<String, dynamic>)),
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory PBLayout.fromJson(String source) => PBLayout.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'GridLayout(width: $width, height: $height, children: $children)';

  @override
  bool operator ==(covariant PBLayout other) {
    if (identical(this, other)) return true;

    return other.width == width && other.height == height && listEquals(other.children, children);
  }

  @override
  int get hashCode => width.hashCode ^ height.hashCode ^ children.hashCode;
}
