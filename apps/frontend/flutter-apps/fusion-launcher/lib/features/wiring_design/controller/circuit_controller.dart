import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/image_loader_service.dart';
import 'package:fusion_launcher/features/wiring_design/controller/helpers/connection_methods_extension.dart';
import 'package:fusion_launcher/features/wiring_design/controller/state/canvas_state.dart';
import 'package:fusion_launcher/features/wiring_design/controller/state/wiring_state.dart';
import 'package:fusion_lib/di/service_locator.dart';
import 'package:fusion_lib/project_manger/project/project_manager.dart';

import '../algorithm/path_finder_algorithm.dart';
import '../model/model.dart';
import 'component_db.dart';
import 'helpers/canvas_handler_mixin.dart';
import 'helpers/initialization_handler_mixin.dart';
import 'state_stack.dart';
import 'wiring_state_cache.dart';

part 'helpers/canvas_elements_handler_mixin.dart';

class CircuitController extends ChangeNotifier
    with CanvasHandlerMixin, _CanvasElementsHandlerMixin {
  final ProjectManager projectManager;
  CircuitController(this.projectManager) {
    initialize();
    _loadAllHardwareImages();
    cache.cacheForState(state);
  }
  @override
  WiringState state = IdleWiringState(
    components: <CircuitComponent>[],
    wires: <Wire>[],
    canvasState: IdleCanvasState(offset: Offset.zero, scale: 1),
  );

  Map<String, ui.Image> imagesCache = <String, ui.Image>{};
  void _loadAllHardwareImages() {
    final ImageLoaderService loader = fusionLibLocator<ImageLoaderService>();
    for (final CircuitComponent comp in state.components) {
      final String? path = comp.data.image;
      // if (path == null) continue;
      final List<String> images = <String>[
        if (path != null) path,
      ];
      for (final CircuitPort port in comp.ports) {
        if (port.data.image != null) {
          images.add(port.data.image!);
        }
      }
      for (final String imgPth in images) {
        if (!imagesCache.containsKey(imgPth)) {
          loader.loadImage(imgPth).then((ui.Image img) {
            imagesCache[imgPth] = img;
            notifyListeners();
          });
        }
      }
    }
  }

  void addComponent(CircuitComponent component) {
    setState(state.addComponent(component));
  }

  final ComponentDb componentDB = ComponentDb();
  final WiringStateCache cache = WiringStateCache();
  OrthogonalRouter get pathFinder => OrthogonalRouter(<Rect>[
    ...state.components.map(
      (CircuitComponent e) => Obstacle(e.position & e.size).expanded,
    ),
  ]);

  void addWire(CircuitPort from, CircuitPort to) {
    if (!canHaveConnection(from, to)) {
      setState(state.idle());
      return;
    }

    final List<ui.Offset> path = pathFinder.findPath(
      from.absolutePositionWithOffset,
      to.absolutePositionWithOffset,
    );
    final Wire wire = Wire(
      id: "${from.id}_${to.id}",
      from: from,
      to: to,
      joints: path,
    );

    componentDB.addWire(wire);
    setState(state.addWire(wire));
    saveState();
    cache.cacheForState(state);
  }

  bool hasConnection(CircuitPort port) {
    return (cache.wireOfPort(port))?.isNotEmpty ?? false;
  }

  final StateStack stack = StateStack();

  @override
  void saveState() {
    stack.push(state.toMap());
    notifyListeners();
  }

  @override
  void onMoveUpdate(Offset delta) {
    super.onMoveUpdate(delta);
    if (state is ElementMovingState) {
      _updateWirePath(
        (state as ElementMovingState).element,
      );
    }
  }

  void _updateWirePath(CircuitComponent component) {
    final List<Wire> connectedWires = cache.wiresOfComponent(component);
    if (component.parent != null) {
      connectedWires.addAll(
        cache.wiresOfComponent(component.parent!),
      );
      for (final CircuitComponent child
          in component.parent?.children ?? <CircuitComponent>[]) {
        if (component != child) {
          connectedWires.addAll(cache.wiresOfComponent(child));
        }
      }
    }

    for (final CircuitComponent child in component.children) {
      connectedWires.addAll(cache.wiresOfComponent(child));
    }

    for (final Wire wire in connectedWires) {
      wire.setPath(
        pathFinder.findPath(
          wire.from.absolutePositionWithOffset,
          wire.to.absolutePositionWithOffset,
        ),
      );
    }
  }

  @override
  CircuitController get self => this;

  @override
  void setCanvasState(CanvasState canvasState) {
    setState(state.updateCanvasState(canvasState));
  }

  void setState(WiringState state) {
    this.state = state;
    notifyListeners();
  }

  void restoreState(Map<String, dynamic> map) {
    setState(state.fromMap(map: map, db: componentDB));
    cache.cacheForState(state);
  }

  void undo() {
    final Map<String, dynamic>? map = stack.undo();
    if (map != null) {
      restoreState(map);
    }
  }

  void redo() {
    final Map<String, dynamic>? map = stack.redo();
    if (map != null) {
      restoreState(map);
    }
  }
}
