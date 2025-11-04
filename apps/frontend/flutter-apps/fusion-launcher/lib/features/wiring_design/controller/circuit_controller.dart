import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/image_loader_service.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/wiring_design/controller/helpers/connection_methods_extension.dart';
import 'package:fusion_launcher/features/wiring_design/controller/helpers/project_manager_methods.dart';
import 'package:fusion_launcher/features/wiring_design/controller/state/canvas_state.dart';
import 'package:fusion_launcher/features/wiring_design/controller/state/wiring_state.dart';
import 'package:fusion_lib/di/service_locator.dart';
import 'package:fusion_lib/models/fusion_models.dart';

import '../algorithm/deep_difference.dart';
import '../algorithm/path_finder_algorithm.dart';
import '../dto/component_data.dart';
import '../model/model.dart';
import 'component_db.dart';
import 'helpers/canvas_handler_mixin.dart';
import 'helpers/initialization_handler_mixin.dart';
import 'state_stack.dart';
import 'wiring_state_cache.dart';

part 'helpers/canvas_elements_handler_mixin.dart';

class CircuitController extends ChangeNotifier with CanvasHandlerMixin, _CanvasElementsHandlerMixin {
  final ProjectViewModel projectManager;
  CircuitController(this.projectManager) {
    loadFromPM();
    _loadAllHardwareImages();
    cache.cacheForState(state);
    stack.push(state.toMap());
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

      if (comp.data is CircuitComponentData) {
        final CircuitComponentData data = comp.data as CircuitComponentData;
        for (final ComponentData speaker in data.speakers) {
          if (speaker.image != null) {
            images.add(speaker.image!);
          }
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
    for (final CircuitPort port in component.ports) {
      componentDB.addPort(port);
    }
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
    WiringState currentState = state;
    if (hasConnection(from)) {
      for (final Wire eWire in cache.wireOfPort(from) ?? <Wire>[]) {
        currentState = currentState.deleteElement(eWire);
      }
    }
    if (hasConnection(to)) {
      for (final Wire eWire in cache.wireOfPort(to) ?? <Wire>[]) {
        currentState = currentState.deleteElement(eWire);
      }
    }

    componentDB.addWire(wire);
    setState(currentState.addWire(wire));
    saveState();
    cache.cacheForState(state);
  }

  void addExistingWire(Wire wire) {
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
      for (final CircuitComponent child in component.parent?.children ?? <CircuitComponent>[]) {
        if (component != child) {
          connectedWires.addAll(cache.wiresOfComponent(child));
        }
      }
    }

    for (final CircuitComponent child in component.children) {
      connectedWires.addAll(cache.wiresOfComponent(child));
      for (final CircuitComponent child2 in child.children) {
        connectedWires.addAll(cache.wiresOfComponent(child2));
      }
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
    switch (state) {
      case ElementSelectionState(element: final CanvasElement element):
        selectElementToPM(element.id);
        break;
      case ElementMovingState(element: final CanvasElement element):
        selectElementToPM(element.id);
        break;

      default:
        selectElementToPM(null);
    }
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

  @override
  void saveState() {
    final Map<String, dynamic> currentMap = state.toMap();
    final Map<String, dynamic>? previousMap = stack.current;
    final Map<String, dynamic> changed = DeepDifference().getMapDifference(
      previousMap ?? <String, dynamic>{},
      currentMap,
    );

    if (changed.containsKey('components')) {
      if (changed['components'] is! Map<dynamic, dynamic>) return;
      _saveComponentModification(changed['components'] ?? <dynamic, dynamic>{});
    }
    if (changed.containsKey('wires')) {
      if (changed['wires'] is! Map<dynamic, dynamic>) return;
      _saveWireModification(changed['wires'] ?? <dynamic, dynamic>{});
    }

    stack.push(state.toMap());
    notifyListeners();
  }

  void _saveComponentModification(Map<dynamic, dynamic> diffMap) {
    if (diffMap.containsKey("modified")) {
      final Map<String, dynamic> modified = diffMap["modified"];
      for (final String id in modified.keys) {
        final CircuitComponent? component = componentDB.getComponent(id) as CircuitComponent?;
        if (component != null) {
          switch (component.data) {
            case DeviceSchematicComponentData():
              final HardwareComponent hardware = (component.data as DeviceSchematicComponentData).data;
              projectManager.updateHardware(
                hardware: hardware.copyWith(
                  wiringPos: component.position,
                ),
              );
              break;
            case SourceComponentData():
              final Source source = (component.data as SourceComponentData).source;
              projectManager.updateHardware(
                hardware: source.copyWith(
                  wiringPos: component.position,
                ),
              );
              break;
            case SpeakerComponentData():
              final Speaker speaker = (component.data as SpeakerComponentData).speaker;
              projectManager.updateHardware(
                hardware: speaker.copyWith(
                  wiringPos: component.position,
                ),
              );
              break;
            case ZoneComponentData():
              final Zone zone = (component.data as ZoneComponentData).zone;
              projectManager.updateZone(
                zone: zone.copyWith(
                  wiringPos: component.position,
                ),
              );
              break;
            default:
          }
        }
      }
    }
  }

  void _saveWireModification(Map<dynamic, dynamic> diffMap) {
    if (diffMap.containsKey('added')) {
      final List<dynamic> added = diffMap['added'];
      for (final dynamic map in added) {
        final dynamic fromPortId = map['from'];
        final dynamic toPortId = map['to'];
        final CanvasElement? fromPort = componentDB.getComponent(fromPortId);
        final CanvasElement? toPort = componentDB.getComponent(toPortId);
        if (fromPort is CircuitPort && toPort is CircuitPort) {
          projectManager.addWiringConnection(
            connection: WiringConnectionModel(
              id: map['id'],
              deviceId: fromPort.parent.id,
              portId: fromPort.id,
              targetDeviceId: toPort.parent.id,
              targetPortId: toPort.id,
              type: ConnectionType.data,
            ),
          );
        }
      }
    }

    if (diffMap.containsKey('removed')) {
      final List<dynamic> removed = diffMap['removed'];
      for (final dynamic id in removed) {
        final dynamic connectionId = id['id'];
        projectManager.removeWiringConnection(connectionId: connectionId);

        componentDB.deleteWire(connectionId);
      }
    }
  }

  void deleteSelectedElement() {
    if (state is ElementSelectionState) {
      setState(state.deleteElement((state as ElementSelectionState).element));
      cache.cacheForState(state);
      saveState();
    }
  }
}
