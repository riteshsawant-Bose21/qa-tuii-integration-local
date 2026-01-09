import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../core/models/products_data.dart';
import '../../../core/service_locator.dart';
import '../../configuration/presentation/viewmodel/project_view_model.dart';

part 'state.dart';

class AddSourceViewModel extends Cubit<AddSourceViewModelState> {
  AddSourceViewModel() : super(const AddSourceViewModelState(selectedSources: <SourceData?>[null]));

  void setSourceSectionType(SourceSectionType sourceSectionType) {
    final bool isSrouceSectionTypeSame = state.selectedSourceSectionType == sourceSectionType;
    if (isSrouceSectionTypeSame) return;
    emit(state.copyWith(selectedSourceSectionType: sourceSectionType, selectedSources: <SourceData?>[null]));
  }

  void setSelectedListeningArea(ListeningArea listeningArea) => emit(state.copyWith(selectedListeningArea: listeningArea));

  void setSelectedConnectionType(AddSourceConnectionType type) => emit(state.copyWith(selectedConnectionType: type));
  void setSignalType(SignalType signalType) => emit(state.copyWith(selectedSignalType: signalType));
  void setSelectedSourceName(String sourceName) => emit(state.copyWith(selectedSourceName: sourceName));

  (String? zoneName, String? subZoneName) get getZonesForListeningArea {
    final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();
    final String? areaId = state.selectedListeningArea?.id;

    if (areaId == null) return (null, null);
    String? zoneName, subZoneName;

    final SubZone? subZone = projectViewModel.getSubZoneForListeningArea(areaId: areaId);
    if (subZone != null) {
      zoneName = projectViewModel.getZoneForSubZone(subZoneId: subZone.id)?.name;
      subZoneName = subZone.name;
    } else {
      zoneName = projectViewModel.getZonesForListeningArea(areaId: areaId)?.name;
    }
    return (zoneName, subZoneName);
  }

  String? get getCurrentListeningAreaSubZoneName {
    final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();
    final String? listeningAreaId = state.selectedListeningArea?.id;
    if (listeningAreaId == null) return null;
    return projectViewModel.getSubZoneForListeningArea(areaId: listeningAreaId)?.name;
  }

  void setSourceOption(SourceSelectionOption sourceOption) {
    if (sourceOption == state.selectedSourceOption) return;

    final List<SourceData?> sources = List<SourceData?>.from(state.selectedSources);

    if (sourceOption == SourceSelectionOption.singleSource) {
      final List<SourceData?> selectedSources = sources.isNotEmpty ? <SourceData?>[sources.first] : <SourceData?>[];
      emit(state.copyWith(selectedSourceOption: sourceOption, selectedSources: selectedSources));
    } else {
      emit(state.copyWith(selectedSourceOption: sourceOption, selectedSources: sources));
    }
  }

  void addEmptySource() {
    final List<SourceData?> selectedSources = List<SourceData?>.from(state.selectedSources);
    selectedSources.add(null);
    emit(state.copyWith(selectedSources: selectedSources));
  }

  void updateSource(int index, SourceData source) {
    final List<SourceData?> sources = List<SourceData?>.from(state.selectedSources);
    if (sources.length <= index) {
      sources.add(source);
    } else {
      sources[index] = source;
    }
    emit(state.copyWith(selectedSources: sources.toList()));
  }

  void onSaveTap(BuildContext context) {
    // validate inputs
    final List<SourceData?> selectedSources = state.selectedSources.where((SourceData? e) => e != null).toList();

    if (selectedSources.isEmpty) return FusionToast.error(context, message: "Please select at least one source");

    // if listening area is not selected
    if (state.selectedListeningArea == null) return FusionToast.error(context, message: "Please select a listening area");

    // if connection location is not selected
    if (state.selectedConnectionType == null) return FusionToast.error(context, message: "Please select a connection type");

    // Save: add selected sources to chosen listening areas
    final ProjectViewModel projectViewModel = context.read<ProjectViewModel>();
    final String? selectedAreaId = state.selectedListeningArea?.id;

    if (selectedAreaId == null) return;
    final ListeningArea? selectedArea = projectViewModel.getAllListeningAreas().firstWhereOrNull((ListeningArea la) => la.id == selectedAreaId);
    if (selectedArea == null) return;
    final FloorModel? floorData = projectViewModel.getFloorForListeningArea(areaId: selectedAreaId);
    final String? floorId = floorData?.id;

    // Currently only single source selection is supported.
    final SourceData? selectedItem = selectedSources.first;
    if (selectedItem == null) return;

    /// Sources [onTapAddDevice]
    final SourceConnectionType connectType = SourceData.getSourceConnectionType(selectedItem.id);
    final PortType portType = switch (connectType) {
      SourceConnectionType.analogInput || SourceConnectionType.aes67input => PortType.analogOutput,
      SourceConnectionType.bluetooth => PortType.bleOut,
      SourceConnectionType.usb => PortType.usbOut,
    };

    final Source source = Source(
      name: state.selectedSourceName ?? selectedItem.name,
      pos: null,
      type: selectedItem.type,
      addedFromBuildingPage: false,
      connectionType: connectType,
      assetImagePath: selectedItem.assetPath,
      locationEntity: LocationModel(listeningAreaId: selectedAreaId, floorId: floorId),
      sku: selectedItem.id,
      price: selectedItem.price,
      portData: HardwarePortData(
        inputPorts: 0,
        outputPorts: 1,
        inputPortType: PortType.analogInput,
        outputPortType: portType,
        compatibleInputTypes: <PortType>[],
        compatibleOutputTypes: switch (connectType) {
          SourceConnectionType.analogInput || SourceConnectionType.aes67input => <PortType>[
            PortType.dspAnalogInput,
            PortType.endpointInput,
          ],
          SourceConnectionType.bluetooth => <PortType>[PortType.bleIn],
          SourceConnectionType.usb => <PortType>[PortType.usbIn],
        },
        portPosition: PortPosition.topLeft,
      ),
    );
    serviceLocator<ProjectViewModel>().addHardware(
      hardware: source,
    );
    FusionToast.success(context, message: "Source \"${selectedItem.name}\" added");
  }
}
