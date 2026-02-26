import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';

class EquipmentLocationViewmodel extends Cubit<EquipmentLocationState> {
  final ProjectViewModel viewModel;
  final String? equipLocationId;
  EquipmentLocationViewmodel(this.viewModel, this.equipLocationId) : super(EquipmentLocationLoading()) {
    _initialize();
  }
  void _initialize() {
    if (equipLocationId == null) {
      return;
    }
    final EquipLocation location = viewModel.getEquipLocationById(equipLocationId: equipLocationId!);
    setEquipmentLocation(location);
  }

  void setEquipmentLocation(EquipLocation equipLocation) {
    final List<HardwareComponent> hardwares = viewModel.getHardwareForEquipLocation(equipLocationId: equipLocation.id);
    final Map<int, HardwareComponent> hardwareMap = <int, HardwareComponent>{};

    final List<HardwareComponent> unpositionedHardwares = <HardwareComponent>[];
    int maxPos = 10;
    for (int i = 0; i < hardwares.length; i++) {
      final HardwareComponent hw = hardwares[i];
      final int key = hw.equipmentLocationPosition ?? i;
      maxPos = max(maxPos, key);
      if (hardwareMap[key] != null) {
        unpositionedHardwares.add(hw);
        continue;
      }
      hardwareMap[key] = hw;
    }
    if (unpositionedHardwares.isNotEmpty) {
      for (int i = 0; i < maxPos; i++) {
        if (hardwareMap[i] == null && unpositionedHardwares.isNotEmpty) {
          hardwareMap[i] = unpositionedHardwares.removeAt(0);
        }
      }
    }
    emit(EquipmentLocationLoaded(equipLocation: equipLocation, hardwares: hardwareMap));
  }

  void refresh() {
    if (state is EquipmentLocationLoaded) {
      final EquipmentLocationLoaded currentState = state as EquipmentLocationLoaded;
      setEquipmentLocation(currentState.equipLocation);
    }
  }

  void reorderHardware(int oldIndex, int newIndex) {
    if (state is! EquipmentLocationLoaded) return;
    final EquipmentLocationLoaded currentState = state as EquipmentLocationLoaded;
    final int maxIndex = max(10, currentState.hardwares.keys.length);
    final List<HardwareComponent?> hardwaresAsList = List<HardwareComponent?>.generate(
      maxIndex,
      (int index) => currentState.hardwares[index],
    );

    final HardwareComponent? hw = hardwaresAsList.removeAt(oldIndex);
    hardwaresAsList.insert(newIndex, hw);
    viewModel.recordSnapshot();

    for (int i = 0; i < hardwaresAsList.length; i++) {
      final HardwareComponent? hw = hardwaresAsList[i];
      if (hw == null) continue;
      final HardwareComponent updatedHw = hw.copyWith(equipmentLocationPosition: i);
      viewModel.updateHardware(hardware: updatedHw, autoSave: false);
    }

    viewModel.saveProject();
    refresh();
  }
}

abstract class EquipmentLocationState {}

class EquipmentLocationLoading extends EquipmentLocationState {}

final class EquipmentLocationLoaded extends EquipmentLocationState {
  final EquipLocation equipLocation;
  final Map<int, HardwareComponent> hardwares;

  EquipmentLocationLoaded({required this.equipLocation, required this.hardwares});
}
