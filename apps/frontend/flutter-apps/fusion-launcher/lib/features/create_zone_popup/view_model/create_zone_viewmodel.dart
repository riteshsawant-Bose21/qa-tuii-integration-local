import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/create_zone_popup/view_model/create_zone_viewmodel_state.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../core/service_locator.dart';
import '../../configuration/presentation/viewmodel/project_view_model.dart';

class CreateZoneViewModel extends Cubit<CreateZoneViewModelState> {
  CreateZoneViewModel()
    : super(
        CreateZoneViewModelState(
          zoneName: 'Untitled zone',
          zoneColor: Zone.zoneColors.first,
          zoneListeningAreas: <ListeningArea>[],
        ),
      );

  bool isFromBuildingPage = false;

  void init({required bool isFromBuilding, void Function()? onSaved}) {
    isFromBuildingPage = isFromBuilding;
  }

  void setZoneName(String name) => emit(state.copyWith(zoneName: name));
  void setZoneColor(String color) => emit(state.copyWith(zoneColor: color));
  void setZoneFunctionType(ZoneFunctionsType type) => emit(state.copyWith(zoneFunctionType: type));

  int totalLiseningAreasSelectedForZone() => state.zoneListeningAreas.length;
  int totalLiseningAreasSelectedForSubzone(int subZoneIndex) => state.subzones[subZoneIndex].listeningAreas.length;

  bool get isCreatingSubZonesAlongSide => state.subzones.isNotEmpty;

  void addSubzone() {
    // This will be added on the first subzone creation
    final List<ListeningArea> zoneListeningAreas = <ListeningArea>[...state.zoneListeningAreas];

    final List<AddListeningAreaToSubzoneModel> subzones = <AddListeningAreaToSubzoneModel>[...state.subzones];
    subzones.add(
      AddListeningAreaToSubzoneModel(
        subZoneName: 'Untitled subzone',
        listeningAreas: zoneListeningAreas,
      ),
    );
    emit(state.copyWith(subzones: subzones, zoneListeningAreas: <ListeningArea>[]));
  }

  void removeSubzone(int index) {
    final List<AddListeningAreaToSubzoneModel> subzones = <AddListeningAreaToSubzoneModel>[...state.subzones];
    if (index >= 0 && index < subzones.length) {
      subzones.removeAt(index);
      emit(state.copyWith(subzones: subzones));
    }
  }

  void onSubzoneNameChanged(int index, String name) {
    final List<AddListeningAreaToSubzoneModel> subzones = <AddListeningAreaToSubzoneModel>[...state.subzones];
    final AddListeningAreaToSubzoneModel subzone = subzones[index];
    subzones[index] = subzone.copyWith(subZoneName: name);
    emit(state.copyWith(subzones: subzones));
  }

  bool isListeningAreaSelectedForZone(String listeningAreaId) {
    final List<ListeningArea> zoneListeningAreas = state.zoneListeningAreas;
    return zoneListeningAreas.any((ListeningArea area) => area.id == listeningAreaId);
  }

  bool isListeningAreaSelectedForSubzone(int subZoneIndex, String listeningAreaId) {
    final List<AddListeningAreaToSubzoneModel> subzones = state.subzones;
    final AddListeningAreaToSubzoneModel subzone = subzones[subZoneIndex];
    final List<ListeningArea> listeningAreas = subzone.listeningAreas;
    return listeningAreas.any((ListeningArea area) => area.id == listeningAreaId);
  }

  bool isListeningAreaSelected(String listeningAreaId) {
    final List<ListeningArea> zoneListeningAreas = state.zoneListeningAreas;
    final bool selectedInZone = zoneListeningAreas.any((ListeningArea area) => area.id == listeningAreaId);
    if (selectedInZone) return true;

    for (final AddListeningAreaToSubzoneModel subzone in state.subzones) {
      final List<String> listeningAreaIds = subzone.listeningAreas.map((ListeningArea area) => area.id).toList();
      if (listeningAreaIds.contains(listeningAreaId)) {
        return true;
      }
    }
    return false;
  }

  void updateZoneListeningArea(ListeningArea listeningArea, bool isAlreadySelected) {
    if (isAlreadySelected) {
      _removeListeningAreaFromZone(listeningArea);
    } else {
      _addListeningAreaToZone(listeningArea);
    }
  }

  void updateSubzoneListeningArea(int subZoneInde, ListeningArea listeningArea, bool isSelected) {
    if (isSelected) {
      _removeListeningAreaFromSubzone(subZoneInde, listeningArea);
    } else {
      _addListeningAreaToSubzone(subZoneInde, listeningArea);
    }
  }

  void _addListeningAreaToZone(ListeningArea listeningArea) {
    final List<ListeningArea> selectedListeningAreas = List<ListeningArea>.from(state.zoneListeningAreas);
    selectedListeningAreas.add(listeningArea);
    emit(state.copyWith(zoneListeningAreas: selectedListeningAreas));
  }

  void _removeListeningAreaFromZone(ListeningArea listeningArea) {
    final List<ListeningArea> selectedListeningAreas = List<ListeningArea>.from(state.zoneListeningAreas);
    selectedListeningAreas.remove(listeningArea);
    emit(state.copyWith(zoneListeningAreas: selectedListeningAreas));
  }

  void _addListeningAreaToSubzone(int subzoneIndex, ListeningArea listeningArea) {
    final List<AddListeningAreaToSubzoneModel> subzones = List<AddListeningAreaToSubzoneModel>.from(state.subzones);
    final AddListeningAreaToSubzoneModel subzone = subzones[subzoneIndex];
    final List<ListeningArea> updatedListeningAreas = List<ListeningArea>.from(subzone.listeningAreas);
    updatedListeningAreas.add(listeningArea);
    subzones[subzoneIndex] = subzone.copyWith(listeningAreas: updatedListeningAreas);
    emit(state.copyWith(subzones: subzones));
  }

  void _removeListeningAreaFromSubzone(int subzoneIndex, ListeningArea listeningArea) {
    final List<AddListeningAreaToSubzoneModel> subzones = List<AddListeningAreaToSubzoneModel>.from(state.subzones);
    final AddListeningAreaToSubzoneModel subzone = subzones[subzoneIndex];
    final List<ListeningArea> updatedListeningAreas = List<ListeningArea>.from(subzone.listeningAreas);
    updatedListeningAreas.remove(listeningArea);
    subzones[subzoneIndex] = subzone.copyWith(listeningAreas: updatedListeningAreas);
    emit(state.copyWith(subzones: subzones));
  }

  void createZone(BuildContext context) {
    // Check is subzones are created
    if (isCreatingSubZonesAlongSide) {
      // check any of the subzones,listening areas are empty
      for (final AddListeningAreaToSubzoneModel subzone in state.subzones) {
        if (subzone.listeningAreas.isEmpty) {
          return FusionToast.error(context, message: 'Cannot create zone. One of the subzones has no listening areas assigned.');
        }
      }
    }

    if (state.zoneFunctionType == null) return FusionToast.error(context, message: 'Please select a function type for the zone.');

    final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();

    final Zone zone = Zone(name: state.zoneName, zoneColor: state.zoneColor);
    serviceLocator<ProjectViewModel>().addZone(zone: zone);

    serviceLocator<ProjectViewModel>().addFunctionToZone(function: getNewZoneFunction(type: state.zoneFunctionType!), zoneId: zone.id);

    /// Create new zone
    projectViewModel.addZone(zone: zone);

    if (!isCreatingSubZonesAlongSide && state.zoneListeningAreas.isNotEmpty) {
      projectViewModel.updateListeningAreasInZone(
        listeningAreaIds: state.zoneListeningAreas.map((ListeningArea area) => area.id).toList(),
        zoneId: zone.id,
      );
    } else {
      for (final AddListeningAreaToSubzoneModel subzone in state.subzones) {
        final SubZone newSubZone = SubZone(name: subzone.subZoneName);

        projectViewModel.addSubZone(subZone: newSubZone, autoSave: false);
        projectViewModel.addSubZoneToZone(subZoneId: newSubZone.id, parentZoneId: zone.id, autoSave: false);

        projectViewModel.updateListeningAreasInSubZone(
          listeningAreaIds: subzone.listeningAreas.map((ListeningArea area) => area.id).toList(),
          subZoneId: newSubZone.id,
        );
      }
    }

    // CLose popup
    Navigator.of(context).pop();
  }
}
