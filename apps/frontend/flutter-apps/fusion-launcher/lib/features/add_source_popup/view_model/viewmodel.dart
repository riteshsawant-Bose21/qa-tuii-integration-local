import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../core/models/products_data.dart';
import '../../../core/service_locator.dart';
import '../../configuration/presentation/viewmodel/project_view_model.dart' show ProjectViewModel, SubzoneViewModel;

part 'state.dart';

class AddSourceViewModel extends Cubit<AddSourceViewModelState> {
  AddSourceViewModel() : super(const AddSourceViewModelState(selectedSources: <SourceData?>[null]));

  void setSourceSectionType(SourceSectionType sourceSectionType) {
    final bool isSrouceSectionTypeSame = state.selectedSourceSectionType == sourceSectionType;
    if (isSrouceSectionTypeSame) return;
    emit(state.copyWith(selectedSourceSectionType: sourceSectionType, selectedSources: <SourceData?>[null]));
  }

  void setSelectedZone(Zone zone) {
    final bool isZoneSame = state.selectedZone == zone;
    if (isZoneSame) return;
    emit(state.copyWith(selectedZone: zone, selectedSubZone: null));
  }

  void setSelectedSubZone(SubZone subZone) => emit(state.copyWith(selectedSubZone: subZone));
  void setSelectedConnectionLocation(SourceConnectionLocation location) => emit(state.copyWith(selectedConnectionLocation: location));
  void setSignalType(SignalType signalType) => emit(state.copyWith(selectedSignalType: signalType));
  void setSelectedSourceName(String sourceName) => emit(state.copyWith(selectedSourceName: sourceName));

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

  bool get isZoneHasSubzones {
    final List<SubZone> subZones = serviceLocator<ProjectViewModel>().getSubZonesForZone(parentZoneId: state.selectedZone?.id ?? '');
    return subZones.isNotEmpty;
  }

  void onSaveTap(BuildContext context) {
    // validate inputs
    final List<SourceData?> selectedSources = state.selectedSources.where((SourceData? e) => e != null).toList();

    if (selectedSources.isEmpty) return FusionToast.error(context, message: "Please select at least one source");

    // if zone is not selected
    if (state.selectedZone == null) return FusionToast.error(context, message: "Please select a zone");

    // if subzone is not selected
    if (isZoneHasSubzones && state.selectedSubZone == null) return FusionToast.error(context, message: "Please select a subzone");

    // if connection location is not selected
    if (state.selectedConnectionLocation == null) return FusionToast.error(context, message: "Please select a connection location");

    // if name is not provided
    if (state.selectedSourceName?.trim().isEmpty ?? true) return FusionToast.error(context, message: "Please enter a source name");

    // // Save: add selected sources to chosen listening areas
    // final ProjectViewModel projectViewModel = context.read<ProjectViewModel>();
    // final String? selectedAreaId = state.selectedListeningAreaId;
    // if (selectedAreaId == null) return;
    // final ListeningArea? selectedArea = projectViewModel.getAllListeningAreas().firstWhereOrNull((ListeningArea la) => la.id == selectedAreaId);
    // if (selectedArea == null) return;
    // final FloorModel? floorData = projectViewModel.getFloorForListeningArea(areaId: selectedAreaId);
    // final String? floorId = floorData?.id;

    // for (int i = 0; i < state.selectedSources.length; i++) {
    //   final SourceData selectedItem = state.selectedSources.first;

    //   /// Sources [onTapAddDevice]
    //   final SourceConnectionType connectType = SourceData.getSourceConnectionType(selectedItem.id);
    //   final PortType portType = switch (connectType) {
    //     SourceConnectionType.analogInput || SourceConnectionType.aes67input => PortType.analogOutput,
    //     SourceConnectionType.bluetooth => PortType.bleOut,
    //     SourceConnectionType.usb => PortType.usbOut,
    //   };

    //   final Source source = Source(
    //     name: selectedItem.name,
    //     pos: null,
    //     type: selectedItem.type,
    //     addedFromBuildingPage: false,
    //     connectionType: connectType,
    //     assetImagePath: selectedItem.assetPath,
    //     locationEntity: LocationModel(
    //       listeningAreaId: selectedAreaId,
    //       floorId: floorId,
    //     ),
    //     sku: selectedItem.id,
    //     price: selectedItem.price,
    //     portData: HardwarePortData(
    //       inputPorts: 0,
    //       outputPorts: 1,
    //       inputPortType: PortType.analogInput,
    //       outputPortType: portType,
    //       compatibleInputTypes: <PortType>[],
    //       compatibleOutputTypes: switch (connectType) {
    //         SourceConnectionType.analogInput || SourceConnectionType.aes67input => <PortType>[
    //           PortType.dspAnalogInput,
    //           PortType.endpointInput,
    //         ],
    //         SourceConnectionType.bluetooth => <PortType>[
    //           PortType.bleIn,
    //         ],
    //         SourceConnectionType.usb => <PortType>[PortType.usbIn],
    //       },
    //       portPosition: PortPosition.topLeft,
    //     ),
    //   );
    //   serviceLocator<ProjectViewModel>().addHardware(
    //     hardware: source,
    //   );
    //   FusionToast.success(context, message: "Source \"${selectedItem.name}\" added");
    // }
  }
}
