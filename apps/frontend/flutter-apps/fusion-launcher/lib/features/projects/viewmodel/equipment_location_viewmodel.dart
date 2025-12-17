import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';

class EquipmentLocationViewmodel extends Cubit<EquipmentLocationState> {
  final ProjectViewModel viewModel;
  final String equipLocationId;
  EquipmentLocationViewmodel(this.viewModel, this.equipLocationId) : super(EquipmentLocationLoading()) {
    _initialize();
  }
  void _initialize() {
    final EquipLocation location = viewModel.getEquipLocationById(equipLocationId: equipLocationId);
    setEquipmentLocation(location);
  }

  void setEquipmentLocation(EquipLocation equipLocation) {
    final List<HardwareComponent> hardwares = viewModel.getHardwareForEquipLocation(equipLocationId: equipLocation.id);
    emit(EquipmentLocationLoaded(equipLocation: equipLocation, hardwares: hardwares));
  }

  void refresh() {
    if (state is EquipmentLocationLoaded) {
      final EquipmentLocationLoaded currentState = state as EquipmentLocationLoaded;
      setEquipmentLocation(currentState.equipLocation);
    }
  }
}

abstract class EquipmentLocationState {}

class EquipmentLocationLoading extends EquipmentLocationState {}

final class EquipmentLocationLoaded extends EquipmentLocationState {
  final EquipLocation equipLocation;
  final List<HardwareComponent> hardwares;

  EquipmentLocationLoaded({required this.equipLocation, required this.hardwares});
}
