import 'dart:ui';

import 'package:fusion_launcher/features/wiring_design/controller/state/canvas_state.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/models/project_entities/controller.dart';
import 'package:fusion_lib/models/project_entities/endpoints.dart';

import '../../../configuration/presentation/viewmodel/project_view_model.dart';
import '../../dto/component_data.dart';
import '../../model/canvas_element.dart';
import '../../model/circuit_component.dart';
import '../circuit_controller.dart';
import '../state/wiring_state.dart';

extension ProjectManagerMethods on CircuitController {
  void selectElementFromPM(String? id) {
    if (state is ElementSelectionState &&
        (state as ElementSelectionState).element.id == id) {
      return;
    }
    if (state is ElementMovingState &&
        (state as ElementMovingState).element.id == id) {
      return;
    }
    final CanvasElement? element = componentDB.getComponent(id ?? "");
    if (element != null) {
      final WiringState updateCanvasState = state.updateCanvasState(
        isWithinViewport(element.position)
            ? state.canvasState
            : state.canvasState.recenter(
              element.position,
              ((canvasSize ?? const Size(100, 100)) * 0.25),
            ),
      );
      setState(updateCanvasState.select(element), notifyToPM: false);
    } else {
      setState(state.idle(), notifyToPM: false);
    }
  }

  void selectElementToPM(String? id) {
    final CanvasElement? element = componentDB.getComponent(id ?? "");
    if (element != null) {
      if (projectManager.selectedDevice?.id == id) return;
      projectManager.setSelectedDevice(
        element.id,
        getType(element),
      );
    } else {
      if (projectManager.selectedDevice?.id == null) return;

      projectManager.setSelectedDevice(null, null);
    }
  }

  SelectedItemType? getType(CanvasElement element) {
    if (element is! CircuitComponent) return null;
    final ComponentData data = element.data;
    if (data is DeviceSchematicComponentData) {
      if (data.data is FusionDsp) {
        return SelectedItemType.processor;
      } else if (data.data is Amplifier) {
        return SelectedItemType.amplifier;
      } else if (data.data is NetworkSwitch) {
        return SelectedItemType.switchs;
      } else if (data.data is FusionEndpoints) {
        return SelectedItemType.endpoint;
      } else if (data.data is FusionController) {
        return SelectedItemType.controller;
      }
    } else if (data is SourceComponentData) {
      return SelectedItemType.source;
    } else if (data is SpeakerComponentData) {
      return null;
    } else if (data is ZoneComponentData) {
      return SelectedItemType.zone;
    } else if (data is SubZoneComponentData) {
      return SelectedItemType.subzone;
    } else if (data is CircuitComponentData) {
      return SelectedItemType.circuit;
    }
    return null;
  }
}
