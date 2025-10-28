import 'dart:async';

import 'package:flutter/material.dart';

import '../models/project_entities/hardware_component_model.dart';
import '../models/project_entities/listening_area_model.dart';
import '../models/project_entities/zone_model.dart';

class FloorCanvasController {
  VoidCallback? _toggleDraw;
  VoidCallback? _fitToView;
  VoidCallback? _deselectAll;
  Future<void> Function()? _loadPlan;
  Function()? _updateFloorView;
  Function(HardwareComponent)? _setSelectedHardwareComponent;
  Function(HardwareComponent)? _setHardwareComponentListeningAreaId;
  VoidCallback? _toggleSpl;
  Completer<List<Offset>?>? autoPlaceCompleter;

  Completer<List<ListeningArea>?>? _listeningAreaSelectionCompleter;
  final List<ListeningArea> _selectedListeningAreas = <ListeningArea>[];
  Zone? currentlySelectingZone;

  final ValueNotifier<bool> isDrawing = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isShowingSpl = ValueNotifier<bool>(false);

  // valueNotifier for isListeningAreaSelectionActive
  final ValueNotifier<bool> isListeningAreaSelectionActive = ValueNotifier<bool>(false);

  List<ListeningArea> get selectedListeningAreas => List<ListeningArea>.unmodifiable(_selectedListeningAreas);

  /// Called by the Canvas State in initState
  void bind({
    required VoidCallback toggleDraw,
    required VoidCallback fitToView,
    required VoidCallback deselectAll,
    required Future<void> Function() loadFloorPlanImage,
    required VoidCallback toggleSpl,
    required Function(HardwareComponent) setSelectedHardwareComponent,
    required Function(HardwareComponent)? setHardwareComponentListeningAreaId,
    required Function()? updateView,
  }) {
    _toggleDraw = toggleDraw;
    _fitToView = fitToView;
    _loadPlan = loadFloorPlanImage;
    _toggleSpl = toggleSpl;
    _deselectAll = deselectAll;
    _setSelectedHardwareComponent = setSelectedHardwareComponent;
    _setHardwareComponentListeningAreaId = setHardwareComponentListeningAreaId;
    _updateFloorView = updateView;
  }

  void updateFloorView() {
    _updateFloorView?.call();
  }

  // update hardware component's listing area id
  setHardwareComponentListeningAreaId(HardwareComponent hardwareComponent) {
    print("called setHardwareComponentListeningAreaId for ${hardwareComponent.name}");
    _setHardwareComponentListeningAreaId?.call(hardwareComponent);
  }

  /// Called by the parent to set the selected hardware component.
  void setSelectedHardwareComponent(HardwareComponent hardwareComponent) {
    _setSelectedHardwareComponent?.call(hardwareComponent);
  }

  void toggleDraw() {
    isDrawing.value = !isDrawing.value;
    _toggleDraw?.call();
  }

  void toggleSpl() {
    isShowingSpl.value = !isShowingSpl.value;
    _toggleSpl?.call();
  }

  void setSpl(bool showSpl) {
    if (isShowingSpl.value != showSpl) {
      isShowingSpl.value = showSpl;
      _toggleSpl?.call();
    }
  }

  void setDraw(bool isDraw) {
    if (isDrawing.value != isDraw) {
      isDrawing.value = isDraw;
      _toggleDraw?.call();
    }
  }

  void deselectAll() {
    _deselectAll?.call();
  }

  void fitToView() => _fitToView?.call();
  Future<void> loadFloorPlanImage() => _loadPlan?.call() ?? Future<void>.value();

  /// Called by the parent to kick off an "auto-place" gesture.
  /// Returns a Future that completes with the speaker points, or null if cancelled.
  Future<List<Offset>?> requestAutoPlace() {
    // if there's already one pending, cancel it first
    autoPlaceCompleter?.complete(null);

    autoPlaceCompleter = Completer<List<Offset>?>();
    return autoPlaceCompleter!.future;
  }

  /// Called by the canvas when the user clicks on a surface (or cancels).
  void completeAutoPlace(List<Offset>? points) {
    if (autoPlaceCompleter != null && !autoPlaceCompleter!.isCompleted) {
      autoPlaceCompleter!.complete(points);
      autoPlaceCompleter = null;
    }
  }

  /// Start listening area selection and return a Future that completes when selection is done
  Future<List<ListeningArea>?> requestListeningAreaSelection(List<ListeningArea> existingListeningAreas, Zone selectingZone) {
    // If there's already one pending, cancel it first
    if (_listeningAreaSelectionCompleter != null && !_listeningAreaSelectionCompleter!.isCompleted) {
      _listeningAreaSelectionCompleter!.complete(null);
      isListeningAreaSelectionActive.value = false;
    }

    _listeningAreaSelectionCompleter = Completer<List<ListeningArea>?>();
    _selectedListeningAreas.clear();
    _selectedListeningAreas.addAll(existingListeningAreas);
    isListeningAreaSelectionActive.value = true;
    currentlySelectingZone = selectingZone;

    updateFloorView();

    return _listeningAreaSelectionCompleter!.future;
  }

  /// Called internally when a listening area is clicked during selection mode
  void selectListeningArea(ListeningArea area) {
    if (!isListeningAreaSelectionActive.value) return;

    // Toggle selection in multiselect mode
    final int index = _selectedListeningAreas.indexWhere((ListeningArea a) => a.id == area.id);
    if (index >= 0) {
      _selectedListeningAreas.removeAt(index);
    } else {
      _selectedListeningAreas.add(area);
    }
  }

  /// Stop listening area selection and complete the Future with selected areas
  void completeListeningAreaSelection() {
    if (_listeningAreaSelectionCompleter != null && !_listeningAreaSelectionCompleter!.isCompleted) {
      final List<ListeningArea> result = List<ListeningArea>.from(_selectedListeningAreas);
      _listeningAreaSelectionCompleter!.complete(result);
      _listeningAreaSelectionCompleter = null;
    }

    isListeningAreaSelectionActive.value = false;
    currentlySelectingZone = null;
    _selectedListeningAreas.clear();
    deselectAll();
  }

  /// Cancel listening area selection and complete the Future with null
  void cancelListeningAreaSelection() {
    if (_listeningAreaSelectionCompleter != null && !_listeningAreaSelectionCompleter!.isCompleted) {
      _listeningAreaSelectionCompleter!.complete(null);
      _listeningAreaSelectionCompleter = null;
    }

    isListeningAreaSelectionActive.value = false;
    currentlySelectingZone = null;
    _selectedListeningAreas.clear();
    deselectAll();
  }

  ///dispose the controller
  void dispose() {
    isDrawing.dispose();
    isShowingSpl.dispose();
    isListeningAreaSelectionActive.dispose();
  }
}
