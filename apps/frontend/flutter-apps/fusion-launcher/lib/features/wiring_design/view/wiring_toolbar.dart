import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/fusion_tool_state.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/tools/select_tool_state.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_base_painter.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_canvas_painter.dart';
import 'package:fusion_launcher/features/fusion_canvas/viewmodel/fusion_canvas_tool_viewmodel.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../configuration/presentation/viewmodel/project_view_model.dart';
import '../../fusion_canvas/view/fusion_canvas.dart';

class WiringToolBar extends StatelessWidget {
  const WiringToolBar({super.key, this.onMoveLayer});
  final void Function(FusionBasePainter layer, Offset position)? onMoveLayer;

  @override
  Widget build(BuildContext context) {
    final ProjectViewModel projectViewModel = context.watch<ProjectViewModel>();
    final FusionToolState canvasTool = context.watch<FusionCanvasToolViewModel>().state;
    final Set<String> selectedIds = canvasTool is SelectToolState ? canvasTool.selectedLayerIds : <String>{};
    final FusionCanvasPainter? painter = FusionCanvasPainterProvider.of(context)?.value;
    return FusionFlatContainer(
      semanticsId: "wiring_tool_bar",
      child: Row(
        spacing: 10,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _IconButton(
            isActive: true,
            semanticId: "clear_all_connections",
            iconData: Icons.close,
            onTap: () {
              final List<WiringConnectionModel> allConnections = projectViewModel.getAllWiringConnections();
              for (final WiringConnectionModel element in allConnections) {
                projectViewModel.removeWiringConnection(connectionId: element.id);
              }
            },
          ),

          Container(
            height: 30,
            width: 1,
            color: context.colorScheme.elevation5,
          ),
          ...WiringAlignment.values.map(
            (WiringAlignment alignment) => _IconButton(
              isActive: selectedIds.length > 1,
              semanticId: "align_vertically_${alignment.name}",
              iconData: switch (alignment) {
                WiringAlignment.start => LucideIcons.alignVerticalJustifyStart100,
                WiringAlignment.center => LucideIcons.alignVerticalJustifyCenter100,
                WiringAlignment.end => LucideIcons.alignVerticalJustifyEnd100,
              },
              onTap: () {
                if (painter == null) {
                  return;
                }
                final AlignVerticallyUseCase useCase = AlignVerticallyUseCase(
                  painter.layers.map((FusionBasePainter e) => _RectWithId(e.id ?? "", e.getBounds(painter))).toList(),
                );
                final List<(_RectWithId layer, Offset offset)> alignedOffsets = useCase.align(selectedIds.toList(), alignment);
                for (final (_RectWithId layer, Offset offset) in alignedOffsets) {
                  onMoveLayer?.call(painter.getLayerById(layer.id)!, offset);
                }
              },
            ),
          ),
          Container(
            height: 30,
            width: 1,
            color: context.colorScheme.elevation5,
          ),
          ...WiringAlignment.values.map(
            (WiringAlignment alignment) => _IconButton(
              isActive: selectedIds.length > 1,
              semanticId: "align_horizontally_${alignment.name}",
              iconData: switch (alignment) {
                WiringAlignment.start => LucideIcons.alignHorizontalJustifyStart100,
                WiringAlignment.center => LucideIcons.alignHorizontalJustifyCenter100,
                WiringAlignment.end => LucideIcons.alignHorizontalJustifyEnd100,
              },
              onTap: () {
                if (painter == null) {
                  return;
                }
                final AlignHorizontallyUseCase useCase = AlignHorizontallyUseCase(
                  painter.layers.map((FusionBasePainter e) => _RectWithId(e.id ?? "", e.getBounds(painter))).toList(),
                );
                final List<(_RectWithId layer, Offset offset)> alignedOffsets = useCase.align(selectedIds.toList(), alignment);
                for (final (_RectWithId layer, Offset offset) in alignedOffsets) {
                  onMoveLayer?.call(painter.getLayerById(layer.id)!, offset);
                }
              },
            ),
          ),
          Container(
            height: 30,
            width: 1,
            color: context.colorScheme.elevation5,
          ),
          _IconButton(
            semanticId: "space_vertically",
            iconData: LucideIcons.alignVerticalSpaceBetween100,
            onTap: () {
              if (painter == null) {
                return;
              }
              final EvenlySpacingUseCase useCase = EvenlySpacingUseCase(
                painter.layers.map((FusionBasePainter e) => _RectWithId(e.id ?? "", e.getBounds(painter))).toList(),
              );
              final List<(_RectWithId layer, Offset offset)> spacedOffsets = useCase.space(selectedIds.toList(), true);
              for (final (_RectWithId layer, Offset offset) in spacedOffsets) {
                onMoveLayer?.call(painter.getLayerById(layer.id)!, offset);
              }
            },
          ),
          _IconButton(
            semanticId: "space_horizontally",
            iconData: LucideIcons.alignHorizontalSpaceBetween100,
            onTap: () {
              if (painter == null) {
                return;
              }
              final EvenlySpacingUseCase useCase = EvenlySpacingUseCase(
                painter.layers.map((FusionBasePainter e) => _RectWithId(e.id ?? "", e.getBounds(painter))).toList(),
              );
              final List<(_RectWithId layer, Offset offset)> spacedOffsets = useCase.space(selectedIds.toList(), false);
              for (final (_RectWithId layer, Offset offset) in spacedOffsets) {
                onMoveLayer?.call(painter.getLayerById(layer.id)!, offset);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({super.key, required this.semanticId, required this.iconData, required this.onTap, this.isActive = true});
  final String semanticId;
  final IconData iconData;
  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Icon(
        iconData,
        color: isActive ? null : context.colorScheme.elevation4,
      ),
    );
  }
}

enum WiringAlignment {
  start,
  center,
  end,
}

class AlignVerticallyUseCase {
  final List<_RectWithId> layers;

  AlignVerticallyUseCase(this.layers);

  List<(_RectWithId layer, Offset offset)> align(List<String> selectedIds, WiringAlignment alignment) {
    print("Aligning layers with ids $selectedIds to $alignment");
    final List<_RectWithId> selectedLayers = layers.where((_RectWithId layer) => selectedIds.contains(layer.id)).toList();
    if (selectedLayers.length < 2) {
      return <(_RectWithId, Offset)>[];
    }
    // final List<double> yPositions = selectedLayers.map((_RectWithId layer) => layer.rect.center.dy).toList();
    final Rect outlineBound = selectedLayers.map((_RectWithId layer) => layer.rect).reduce((Rect a, Rect b) => a.expandToInclude(b));
    double targetY;
    switch (alignment) {
      case WiringAlignment.start:
        targetY = outlineBound.top;
        break;
      case WiringAlignment.center:
        targetY = outlineBound.center.dy;
        break;
      case WiringAlignment.end:
        targetY = outlineBound.bottom;
        break;
    }
    final List<(_RectWithId, Offset)> result = <(_RectWithId, Offset)>[];
    for (final _RectWithId layer in selectedLayers) {
      final Offset offsetToConsider = switch (alignment) {
        WiringAlignment.start => layer.rect.topLeft,
        WiringAlignment.center => layer.rect.center,
        WiringAlignment.end => layer.rect.bottomRight,
      };
      final Offset offset = Offset(offsetToConsider.dx, targetY);
      result.add((layer, offset - offsetToConsider));
    }
    return result;
  }
}

class AlignHorizontallyUseCase {
  final List<_RectWithId> layers;

  AlignHorizontallyUseCase(this.layers);

  List<(_RectWithId layer, Offset offset)> align(List<String> selectedIds, WiringAlignment alignment) {
    print("Aligning layers with ids $selectedIds to $alignment");
    final List<_RectWithId> selectedLayers = layers.where((_RectWithId layer) => selectedIds.contains(layer.id)).toList();
    if (selectedLayers.length < 2) {
      return <(_RectWithId, Offset)>[];
    }
    // final List<double> yPositions = selectedLayers.map((_RectWithId layer) => layer.rect.center.dy).toList();
    final Rect outlineBound = selectedLayers.map((_RectWithId layer) => layer.rect).reduce((Rect a, Rect b) => a.expandToInclude(b));
    double targetX;
    switch (alignment) {
      case WiringAlignment.start:
        targetX = outlineBound.left;
        break;
      case WiringAlignment.center:
        targetX = outlineBound.center.dx;
        break;
      case WiringAlignment.end:
        targetX = outlineBound.right;
        break;
    }
    final List<(_RectWithId, Offset)> result = <(_RectWithId, Offset)>[];
    for (final _RectWithId layer in selectedLayers) {
      final Offset offsetToConsider = switch (alignment) {
        WiringAlignment.start => layer.rect.topLeft,
        WiringAlignment.center => layer.rect.center,
        WiringAlignment.end => layer.rect.bottomRight,
      };
      final Offset offset = Offset(targetX, offsetToConsider.dy);
      result.add((layer, offset - offsetToConsider));
    }
    return result;
  }
}

class _RectWithId {
  final String id;
  final Rect rect;

  _RectWithId(this.id, this.rect);
}

class EvenlySpacingUseCase {
  final List<_RectWithId> layers;

  EvenlySpacingUseCase(this.layers);

  List<(_RectWithId layer, Offset offset)> space(List<String> selectedIds, bool isVertical) {
    print("Spacing layers with ids $selectedIds evenly, isVertical=$isVertical");
    final List<_RectWithId> selectedLayers = layers.where((_RectWithId layer) => selectedIds.contains(layer.id)).toList();
    if (selectedLayers.length < 3) {
      return <(_RectWithId, Offset)>[];
    }
    final List<_RectWithId> sortedLayers = List<_RectWithId>.from(selectedLayers)
      ..sort((_RectWithId a, _RectWithId b) => isVertical ? a.rect.top.compareTo(b.rect.top) : a.rect.left.compareTo(b.rect.left));
    final double totalSize = sortedLayers.fold(
      0,
      (double previousValue, _RectWithId layer) => previousValue + (isVertical ? layer.rect.height : layer.rect.width),
    );
    final double outlineStart = isVertical ? sortedLayers.first.rect.top : sortedLayers.first.rect.left;
    final double outlineEnd = isVertical ? sortedLayers.last.rect.bottom : sortedLayers.last.rect.right;
    final double totalSpacing = outlineEnd - outlineStart - totalSize;
    final double spacing = totalSpacing / (sortedLayers.length - 1);
    final List<(_RectWithId, Offset)> result = <(_RectWithId, Offset)>[];
    double currentPosition = outlineStart;
    for (final _RectWithId layer in sortedLayers) {
      final Offset offset = isVertical ? Offset(0, currentPosition - layer.rect.top) : Offset(currentPosition - layer.rect.left, 0);
      result.add((layer, offset));
      currentPosition += (isVertical ? layer.rect.height : layer.rect.width) + spacing;
    }
    return result;
  }
}
