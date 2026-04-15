import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/fusion_tool_state.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/tools/select_tool_state.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/elements/fusion_canvas_element_painter.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_base_painter.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_canvas_painter.dart';
import 'package:fusion_launcher/features/fusion_canvas/viewmodel/fusion_canvas_tool_viewmodel.dart';
import 'package:fusion_launcher/features/wiring_design/usecase/auto_wiring.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../configuration/presentation/viewmodel/project_view_model.dart';
import '../../fusion_canvas/view/fusion_canvas.dart';
import '../../fusion_canvas/viewmodel/fusion_canvas_state_viewmodel.dart';
import '../../projects/presentation/project_work_area.dart';
import '../algorithm/zone_manager.dart';
import '../usecase/auto_layout_usecase.dart';

class WiringToolBar extends StatelessWidget {
  const WiringToolBar({super.key, this.onMoveLayer});
  final void Function(FusionBasePainter layer, Offset position)? onMoveLayer;

  @override
  Widget build(BuildContext context) {
    final ProjectViewModel projectViewModel = context.watch<ProjectViewModel>();
    final FusionToolState canvasTool = context.watch<FusionCanvasToolViewModel>().state;
    final Set<String> selectedIds = canvasTool is SelectToolState ? canvasTool.selectedLayerIds : <String>{};
    final FusionCanvasPainter? painter = FusionCanvasPainterProvider.of(context)?.value;
    final Set<String> validIds = selectedIds.where((String id) => painter?.getLayerById(id) is FusionCanvasElementPainter).toSet();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 10,
      children: <Widget>[
        FusionFlatContainer(
          semanticsId: "wiring_spacing_tool_bar",
          child: Row(
            spacing: 20,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ...WiringAlignment.values.map(
                (WiringAlignment alignment) => _IconButton(
                  isActive: validIds.length > 1,
                  semanticId: "align_vertically_${alignment.name}",
                  icon: switch (alignment) {
                    WiringAlignment.start => 'assets/icons/wiring_page/align_top_vertical.png',
                    WiringAlignment.center => 'assets/icons/wiring_page/align_center_vertical.png',
                    WiringAlignment.end => 'assets/icons/wiring_page/align_bottom_vertical.png',
                  },
                  tooltip: switch (alignment) {
                    WiringAlignment.start => "Align Top",
                    WiringAlignment.center => "Align Center Vertically",
                    WiringAlignment.end => "Align Bottom",
                  },
                  onTap: () {
                    if (painter == null) {
                      return;
                    }
                    final AlignVerticallyUseCase useCase = AlignVerticallyUseCase(
                      painter.layers.map((FusionBasePainter e) => _RectWithId(e.id ?? "", e.getBounds(painter))).toList(),
                    );
                    final List<(_RectWithId layer, Offset offset)> alignedOffsets = useCase.align(validIds.toList(), alignment);
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
                  isActive: validIds.length > 1,
                  semanticId: "align_horizontally_${alignment.name}",
                  icon: switch (alignment) {
                    WiringAlignment.start => 'assets/icons/wiring_page/align_left_horizontal.png',
                    WiringAlignment.center => 'assets/icons/wiring_page/align_center_horizontal.png',
                    WiringAlignment.end => 'assets/icons/wiring_page/align_right_horizontal.png',
                  },
                  tooltip: switch (alignment) {
                    WiringAlignment.start => "Align Left",
                    WiringAlignment.center => "Align Center Horizontally",
                    WiringAlignment.end => "Align Right",
                  },
                  onTap: () {
                    if (painter == null) {
                      return;
                    }
                    final AlignHorizontallyUseCase useCase = AlignHorizontallyUseCase(
                      painter.layers.map((FusionBasePainter e) => _RectWithId(e.id ?? "", e.getBounds(painter))).toList(),
                    );
                    final List<(_RectWithId layer, Offset offset)> alignedOffsets = useCase.align(validIds.toList(), alignment);
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
                icon: 'assets/icons/wiring_page/space_vertically.png',
                isActive: validIds.length > 1,
                tooltip: "Space Vertically",
                onTap: () {
                  if (painter == null) {
                    return;
                  }
                  final EvenlySpacingUseCase useCase = EvenlySpacingUseCase(
                    painter.layers.map((FusionBasePainter e) => _RectWithId(e.id ?? "", e.getBounds(painter))).toList(),
                  );
                  final List<(_RectWithId layer, Offset offset)> spacedOffsets = useCase.space(validIds.toList(), true);
                  for (final (_RectWithId layer, Offset offset) in spacedOffsets) {
                    onMoveLayer?.call(painter.getLayerById(layer.id)!, offset);
                  }
                },
              ),
              _IconButton(
                semanticId: "space_horizontally",
                isActive: validIds.length > 1,
                icon: 'assets/icons/wiring_page/space_horizontally.png',
                tooltip: "Space Horizontally",
                onTap: () {
                  if (painter == null) {
                    return;
                  }
                  final EvenlySpacingUseCase useCase = EvenlySpacingUseCase(
                    painter.layers.map((FusionBasePainter e) => _RectWithId(e.id ?? "", e.getBounds(painter))).toList(),
                  );
                  final List<(_RectWithId layer, Offset offset)> spacedOffsets = useCase.space(validIds.toList(), false);
                  for (final (_RectWithId layer, Offset offset) in spacedOffsets) {
                    onMoveLayer?.call(painter.getLayerById(layer.id)!, offset);
                  }
                },
              ),
            ],
          ),
        ),
        FusionFlatContainer(
          semanticsId: "wiring_action_tool_bar",
          child: Row(
            spacing: 20,
            children: <Widget>[
              _IconButton(
                isActive: true,
                semanticId: "fit_to_screen",
                tooltip: "Fit to screen",
                icon: 'assets/icons/building_page/fit_to_screen.png',
                onTap: () {
                  context.read<FusionCanvasStateViewModel>().fitToScreen(
                    padding: EdgeInsets.only(top: WorkAreaScope.of(context).appBarHeight + 20, bottom: 20 + 60, left: 50, right: 50),
                  );
                },
              ),

              _IconButton(
                isActive: true,
                semanticId: "auto_layout",
                tooltip: "Auto Arrange",
                icon: 'assets/icons/wiring_page/auto_layout.png',
                onTap: () {
                  final WiringZoneManager zoneManager = WiringZoneManager()..syncWithProjectManager(projectViewModel);
                  final List<WiringLayoutResult> layouts =
                      WiringAutoLayoutUseCase(
                        devices: projectViewModel.getAllHardware(),
                        connections: projectViewModel.getAllWiringConnections(),
                        zones: projectViewModel.getAllZones(),
                        zoneManager: zoneManager,
                      ).execute();
                  for (final WiringConnectionModel element in projectViewModel.getAllWiringConnections()) {
                    projectViewModel.updateWiringConnection(connection: element.copyWith(axisLocks: <AxisLock>[]));
                  }
                  for (final WiringLayoutResult layout in layouts) {
                    final FusionBasePainter? layer = painter?.getLayerById(layout.hardwareComponent?.id ?? layout.zone?.id);
                    if (layer != null) {
                      onMoveLayer?.call(layer, (layout.position - layer.getBounds(painter!).topLeft));
                    }
                  }
                },
              ),
              _IconButton(
                isActive: true,
                semanticId: "auto_connect",
                tooltip: "Auto Connect",
                icon: 'assets/icons/wiring_page/auto_connect.png',
                onTap: () {
                  final List<WiringConnectionModel> connections = AutoWiringUseCase().autoWire(
                    components: projectViewModel.hardwareComponents,
                    circuits: projectViewModel.circuits,
                    existingConnections: projectViewModel.getAllWiringConnections(),
                  );
                  for (final WiringConnectionModel connection in connections) {
                    projectViewModel.addWiringConnection(connection: connection);
                  }
                },
              ),
              _IconButton(
                isActive: true,
                semanticId: "clear_connections",
                tooltip: "Clear Connections",
                icon: 'assets/icons/wiring_page/clear_connections.png',
                onTap: () {
                  for (final WiringConnectionModel connection in projectViewModel.getAllWiringConnections()) {
                    projectViewModel.removeWiringConnection(connectionId: connection.id);
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({super.key, required this.semanticId, required this.icon, required this.tooltip, required this.onTap, this.isActive = true});
  final String semanticId;
  final String tooltip;
  final String icon;
  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return SemanticHelper.button(
      testId: semanticId,

      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          child: FusionImageAuto(
            path: icon,
            color: isActive ? context.colorScheme.primaryWhite : context.colorScheme.elevation4,
            height: 20,
          ),
        ),
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
