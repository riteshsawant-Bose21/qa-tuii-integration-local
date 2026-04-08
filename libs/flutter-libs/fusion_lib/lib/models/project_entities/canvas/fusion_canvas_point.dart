// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:ui';

import 'package:fusion_lib/fusion_lib.dart';

class FusionCanvasPoint extends FusionCanvasElement {
  final Offset position;

  final Offset? handleIn;
  final Offset? handleOut;

  FusionCanvasPoint({
    required this.position,
    this.handleIn,
    this.handleOut,
    String? id,
  }) : id = id ?? FusionUtils.generateUUID();

  @override
  bool operator ==(covariant FusionCanvasElement other) {
    if (identical(this, other)) return true;

    return other is FusionCanvasPoint && other.position == position && other.handleIn == handleIn && other.handleOut == handleOut;
  }

  @override
  int get hashCode => position.hashCode ^ handleIn.hashCode ^ handleOut.hashCode;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'position': {'x': position.dx, 'y': position.dy},
      'handle_in': handleIn != null ? {'x': handleIn!.dx, 'y': handleIn!.dy} : null,
      'handle_out': handleOut != null ? {'x': handleOut!.dx, 'y': handleOut!.dy} : null,
    };
  }

  factory FusionCanvasPoint.fromMap(Map<String, dynamic> map) {
    return FusionCanvasPoint(
      id: map['id'],
      position: DeserializationUtil.offsetDeserializer.deserialize(map['position'] ?? map)!,
      handleIn: map['handle_in'] != null ? Offset((map['handle_in']['dx'] as num).toDouble(), (map['handle_in']['dy'] as num).toDouble()) : null,
      handleOut: map['handle_out'] != null ? Offset((map['handle_out']['dx'] as num).toDouble(), (map['handle_out']['dy'] as num).toDouble()) : null,
    );
  }

  @override
  final String id;

  FusionCanvasPoint copyWith({
    Offset? position,
    Offset? handleIn,
    Offset? handleOut,
    String? id,
  }) {
    return FusionCanvasPoint(
      position: position ?? this.position,
      handleIn: handleIn ?? this.handleIn,
      handleOut: handleOut ?? this.handleOut,
      id: id ?? this.id,
    );
  }

  @override
  List<String> get pointIds => [id];

  FusionCanvasPoint operator +(Offset other) {
    return copyWith(
      position: position + other,
      handleIn: handleIn != null ? handleIn! + other : null,
      handleOut: handleOut != null ? handleOut! + other : null,
    );
  }

  @override
  String toString() {
    return 'FCP(position: $position, id: $id)';
  }
}
