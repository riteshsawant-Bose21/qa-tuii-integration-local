// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:fusion_lib/fusion_lib.dart';

class FusionHoverState {
  final String? hoveredPainterId;
  final FusionCanvasElement? hoveredElement;

  FusionHoverState({
    this.hoveredPainterId,
    this.hoveredElement,
  });

  @override
  bool operator ==(covariant FusionHoverState other) {
    if (identical(this, other)) return true;

    return other.hoveredPainterId == hoveredPainterId && other.hoveredElement == hoveredElement;
  }

  @override
  int get hashCode => hoveredPainterId.hashCode ^ hoveredElement.hashCode;

  FusionHoverState copyWith({
    String? hoveredPainterId,
    FusionCanvasElement? hoveredElement,
  }) {
    return FusionHoverState(
      hoveredPainterId: hoveredPainterId ?? this.hoveredPainterId,
      hoveredElement: hoveredElement ?? this.hoveredElement,
    );
  }

  @override
  String toString() => 'FusionHoverState(hoveredPainterId: $hoveredPainterId, hoveredElement: $hoveredElement)';
}
