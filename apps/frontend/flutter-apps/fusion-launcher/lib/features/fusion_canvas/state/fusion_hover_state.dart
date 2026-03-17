// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/foundation.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../view/painters/elements/mixin/fusion_canvas_interactable_mixin.dart';

class FusionHoverState {
  final String? hoveredPainterId;
  final FusionCanvasElement? hoveredElement;
  final bool isCenterHandleHovered;

  /// Interactions supported by the hovered painter (layer-level).
  final Set<FusionCanvasLayerInteraction> hoveredPainterInteractions;

  /// Interactions supported by the specific hovered element (e.g. a point or
  /// line within the layer).
  ///
  /// `null` means no element-level override – fall back to layer level.
  final Set<FusionCanvasLayerInteraction>? hoveredElementInteractions;

  FusionHoverState({
    this.hoveredPainterId,
    this.hoveredElement,
    this.isCenterHandleHovered = false,
    this.hoveredPainterInteractions = const <FusionCanvasLayerInteraction>{},
    this.hoveredElementInteractions,
  });

  /// Returns true when the hovered target supports [interaction].
  ///
  /// Resolution:
  ///   - If the hovered element has its own override set → check that.
  ///   - Otherwise fall back to the layer-level [hoveredPainterInteractions].
  bool supportsInteraction(FusionCanvasLayerInteraction interaction) {
    if (hoveredElementInteractions != null) {
      return hoveredElementInteractions!.contains(interaction);
    }
    return hoveredPainterInteractions.contains(interaction);
  }

  @override
  bool operator ==(covariant FusionHoverState other) {
    if (identical(this, other)) return true;

    return other.hoveredPainterId == hoveredPainterId &&
        other.hoveredElement == hoveredElement &&
        other.isCenterHandleHovered == isCenterHandleHovered &&
        setEquals(other.hoveredPainterInteractions, hoveredPainterInteractions) &&
        setEquals(other.hoveredElementInteractions, hoveredElementInteractions);
  }

  @override
  int get hashCode =>
      hoveredPainterId.hashCode ^
      hoveredElement.hashCode ^
      isCenterHandleHovered.hashCode ^
      hoveredPainterInteractions.hashCode ^
      hoveredElementInteractions.hashCode;

  FusionHoverState copyWith({
    String? hoveredPainterId,
    FusionCanvasElement? hoveredElement,
    bool? isCenterHandleHovered,
    Set<FusionCanvasLayerInteraction>? hoveredPainterInteractions,
    Set<FusionCanvasLayerInteraction>? hoveredElementInteractions,
  }) {
    return FusionHoverState(
      hoveredPainterId: hoveredPainterId ?? this.hoveredPainterId,
      hoveredElement: hoveredElement ?? this.hoveredElement,
      isCenterHandleHovered: isCenterHandleHovered ?? this.isCenterHandleHovered,
      hoveredPainterInteractions: hoveredPainterInteractions ?? this.hoveredPainterInteractions,
      hoveredElementInteractions: hoveredElementInteractions ?? this.hoveredElementInteractions,
    );
  }

  @override
  String toString() =>
      'FusionHoverState(hoveredPainterId: $hoveredPainterId, hoveredElement: $hoveredElement, '
      'isCenterHandleHovered: $isCenterHandleHovered, hoveredPainterInteractions: $hoveredPainterInteractions, '
      'hoveredElementInteractions: $hoveredElementInteractions)';
}
