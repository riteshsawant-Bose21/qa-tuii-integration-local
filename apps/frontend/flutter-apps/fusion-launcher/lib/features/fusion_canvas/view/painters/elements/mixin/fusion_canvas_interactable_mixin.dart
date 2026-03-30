import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../fusion_base_painter.dart';
import '../../fusion_canvas_painter.dart';
enum FusionCanvasLayerInteraction {
  select,
  drag,
}

mixin FusionCanvasInteractibleMixin on FusionBasePainter {
  /// Interactions supported by the layer as a whole (e.g. drag the entire polygon).
  /// Default: select + drag.
  Set<FusionCanvasLayerInteraction> get possibleInteractions => const <FusionCanvasLayerInteraction>{
    FusionCanvasLayerInteraction.select,
    FusionCanvasLayerInteraction.drag,
  };

  bool supportsInteraction(FusionCanvasLayerInteraction interaction) {
    return possibleInteractions.contains(interaction);
  }

  /// Returns element-specific interaction permissions for a sub-element
  /// (e.g. a point or line within this layer).
  ///
  /// Return `null` (the default) to inherit this layer's [possibleInteractions].
  /// Override to have fine-grained control – e.g. make points draggable even
  /// when the layer itself is not draggable.
  Set<FusionCanvasLayerInteraction>? possibleInteractionsForElement(
    FusionCanvasElement element,
  ) => null;

  /// Hit-tests [position] and returns the element only when it supports
  /// [interaction].
  ///
  /// Resolution order:
  ///   1. If an element is hit and it has element-level interaction overrides
  ///      ([possibleInteractionsForElement] returns non-null) → use those.
  ///   2. If none are set for the element → fall back to layer-level
  ///      [possibleInteractions].
  ///   3. If interaction is not allowed under the resolved set → return null.
  FusionCanvasElement? getInteractionElement(
    Offset position,
    FusionCanvasPainter painter,
    FusionCanvasLayerInteraction interaction,
  ) {
    final FusionCanvasElement? hitElement = isHit(position, painter);
    if (hitElement == null) return null;

    // Element-specific overrides take priority; fall back to layer level.
    final Set<FusionCanvasLayerInteraction> effectiveInteractions = possibleInteractionsForElement(hitElement) ?? possibleInteractions;

    return effectiveInteractions.contains(interaction) ? hitElement : null;
  }
}
