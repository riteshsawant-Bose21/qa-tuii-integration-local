import 'package:fusion_lib/fusion_utils/fusion_utilities.dart';

import 'canvas/fusion_canvas_point.dart';

class FloorText {
  final String id;
  final String text;
  final FusionCanvasPoint position;
  final double fontSize;

  FloorText({
    String? id,
    required this.text,
    required this.position,
    this.fontSize = 16,
  }) : id = id ?? "TEXT${FusionUtils.shortStringUUID()}";

  FloorText copyWith({
    String? id,
    String? text,
    FusionCanvasPoint? position,
    double? fontSize,
  }) {
    return FloorText(
      id: id ?? this.id,
      text: text ?? this.text,
      position: position ?? this.position,
      fontSize: fontSize ?? this.fontSize,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FloorText && other.id == id && other.text == text && other.position == position && other.fontSize == fontSize;
  }

  @override
  int get hashCode => Object.hash(id, text, position, fontSize);

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'text': text,
      'position': position.toMap(),
      'fontSize': fontSize,
    };
  }

  factory FloorText.fromJson(Map<String, dynamic> json) {
    return FloorText(
      id: json['id'] as String?,
      text: json['text'] as String? ?? 'Text',
      position: FusionCanvasPoint.fromMap(Map<String, dynamic>.from(json['position'] as Map)),
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 16,
    );
  }
}
