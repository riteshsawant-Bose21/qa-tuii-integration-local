// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:fusion_lib/fusion_lib.dart';

class FusionHoverState {
  final String? hoveredPainterId;
  final FusionCanvasElement? hoveredElement;
  final bool isCenterHandleHovered;

  FusionHoverState({
    this.hoveredPainterId,
    this.hoveredElement,
    this.isCenterHandleHovered = false,
  });

  @override
  bool operator ==(covariant FusionHoverState other) {
    if (identical(this, other)) return true;

    return other.hoveredPainterId == hoveredPainterId && other.hoveredElement == hoveredElement && other.isCenterHandleHovered == isCenterHandleHovered;
  }

  @override
  int get hashCode => hoveredPainterId.hashCode ^ hoveredElement.hashCode ^ isCenterHandleHovered.hashCode;

  FusionHoverState copyWith({
    String? hoveredPainterId,
    FusionCanvasElement? hoveredElement,
    bool? isCenterHandleHovered,
  }) {
    return FusionHoverState(
      hoveredPainterId: hoveredPainterId ?? this.hoveredPainterId,
      hoveredElement: hoveredElement ?? this.hoveredElement,
      isCenterHandleHovered: isCenterHandleHovered ?? this.isCenterHandleHovered,
    );
  }

  @override
  String toString() => 'FusionHoverState(hoveredPainterId: $hoveredPainterId, hoveredElement: $hoveredElement, isCenterHandleHovered: $isCenterHandleHovered)';
}
