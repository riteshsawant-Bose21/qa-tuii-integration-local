import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../core/models/products_data.dart';
import '../../../core/service_locator.dart';
import '../../configuration/presentation/viewmodel/aes67/aes67_view_model.dart';
import '../../configuration/presentation/viewmodel/project_view_model.dart';

part 'add_source_viewmodel_state.dart';

class AddSourceViewModel extends Cubit<AddSourceViewModelState> {
  AddSourceViewModel() : super(const AddSourceViewModelState(selectedSources: <SourceData?>[null]));

  bool isFromBuildingPage = true;
  void Function()? onSaved;

  void init({
    required bool fromBuildingPage,
    required void Function()? onSaved,
  }) {
    isFromBuildingPage = fromBuildingPage;
    this.onSaved = onSaved;
    if (isFromBuildingPage) {
      final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();
      final ListeningArea? currentSelectedListeningArea = projectViewModel.getCurrentSelectedListeningArea();
      if (currentSelectedListeningArea != null) {
        emit(state.copyWith(selectedListeningArea: currentSelectedListeningArea));
      }
    }
  }

  void setSelectedStream(Aes67Config stream) {
    emit(state.copyWith(selectedStream: stream));
  }

  void setSelectedMonoChannel(int channel) {
    emit(state.copyWith(selectedMonoChannel: channel));
  }

  void setSelectedLeftChannel(int channel) {
    emit(state.copyWith(selectedLeftChannel: channel));
  }

  void setSelectedRightChannel(int channel) {
    emit(state.copyWith(selectedRightChannel: channel));
  }

  void setSourceSectionType(SourceSectionType sourceSectionType) {
    final bool isSrouceSectionTypeSame = state.selectedSourceSectionType == sourceSectionType;
    if (isSrouceSectionTypeSame) return;

    AddSourceViewModelState updated = state.copyWith(
      selectedSourceSectionType: sourceSectionType,
      selectedSources: <SourceData?>[null],
      selectedSignalType: SignalType.mono,
      selectedConnectionType: null,
    );
    updated = updated.resetConnectionType();
    emit(updated);
  }

  void setSelectedListeningArea(ListeningArea listeningArea) => emit(state.copyWith(selectedListeningArea: listeningArea));

  void setSelectedConnectionType(SourceConnectionType type) => emit(state.copyWith(selectedConnectionType: type));

  void setSignalType(SignalType signalType) => emit(state.copyWith(selectedSignalType: signalType));

  void setSelectedSourceName(String sourceName) => emit(state.copyWith(selectedSourceName: sourceName));

  List<SignalType> get signalTypes {
    return switch (state.selectedSourceSectionType) {
      SourceSectionType.microPhone => <SignalType>[SignalType.mono],
      SourceSectionType.mediaSources => <SignalType>[SignalType.mono, SignalType.stereo],
      SourceSectionType.paging => <SignalType>[SignalType.mono],
    };
  }

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

    emit(
      state.copyWith(
        selectedSources: sources.toList(),
        // selectedConnectionType: source.connectionType,
      ),
    );
  }

  void onSaveTap(BuildContext context) {
    // validate inputs
    final List<SourceData?> selectedSources = state.selectedSources.where((SourceData? e) => e != null).toList();

    if (selectedSources.isEmpty) return FusionToast.error(context, message: "Please select at least one source");

    // if listening area is not selected
    if (state.selectedListeningArea == null) return FusionToast.error(context, message: "Please select a location");

    // if connection location is not selected
    if (state.selectedSources.first?.type != SourceType.paging && state.selectedConnectionType == null) {
      return FusionToast.error(context, message: "Please select a connection type");
    }

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
    final SourceConnectionType connectType = state.selectedConnectionType ?? SourceData.getSourceConnectionType(selectedItem.id);

    final PortType portType = switch (connectType) {
      SourceConnectionType.analogInput => PortType.analogOutput,
      SourceConnectionType.aes67input => PortType.networkSwitchOut,
      SourceConnectionType.bluetooth => PortType.bleOut,
      SourceConnectionType.usb => PortType.usbOut,
      SourceConnectionType.audioJack => PortType.audioJackOutput,
      SourceConnectionType.xlr => PortType.xlrOutput,
      SourceConnectionType.hdmi => PortType.hdmiOut,
      SourceConnectionType.rca => PortType.rcaOutput,
      SourceConnectionType.endpoint => PortType.analogOutput, // TODO: Consider it like a wired connection
      SourceConnectionType.messagePlayer => PortType.messagePlayer,
    };

    final Source source = Source(
      name: state.selectedSourceName ?? selectedItem.name,
      pos: selectedArea.getCenterPositionOfVertices(),
      type: selectedItem.type,
      addedFromBuildingPage: false,
      connectionType: connectType,
      image: selectedItem.assetPath,
      locationEntity: LocationModel(listeningAreaId: selectedAreaId, floorId: floorId),
      sku: selectedItem.id,
      price: selectedItem.price,
      pagingSourceType: selectedItem.pagingSourceType,
      portData: HardwarePortData(
        inputPorts: 0,
        outputPorts: 1,
        inputPortType: PortType.analogInput,
        outputPortType: portType,
        // compatibleInputTypes: <PortType>[],
        // compatibleOutputTypes: switch (connectType) {
        //   SourceConnectionType.analogInput || SourceConnectionType.aes67input => <PortType>[
        //     PortType.dspAnalogInput,
        //     PortType.endpointInput,
        //   ],
        //   SourceConnectionType.bluetooth => <PortType>[PortType.bleIn],
        //   SourceConnectionType.usb => <PortType>[PortType.usbIn],
        //   SourceConnectionType.audioJack => <PortType>[PortType.audioJackInput],
        //   SourceConnectionType.xlr => <PortType>[PortType.xlrInput],
        //   SourceConnectionType.hdmi => <PortType>[PortType.hdmiIn],
        //   SourceConnectionType.rca => <PortType>[PortType.rcaInput],
        // },
        portPosition: PortPosition.topLeft,
      ),
    );
    projectViewModel.addHardware(hardware: source);
    projectViewModel.setCurrentSelectedHardware(source.id);

    // Build AssignedStreamChannel list from the selected stream + channel dropdowns.
    final Aes67Config? selectedStream = state.selectedStream;
    List<AssignedStreamChannel> channelsToAssign = List<AssignedStreamChannel>.from(state.assignedStreamChannels);

    if (selectedStream != null && channelsToAssign.isEmpty) {
      String _channelName(int channelNumber) {
        final List<Aes67ChannelConfig> configs = selectedStream.channelConfigs;
        if (channelNumber >= 1 && channelNumber <= configs.length) {
          return configs[channelNumber - 1].label ?? 'Channel $channelNumber';
        }
        return 'Channel $channelNumber';
      }

      if (state.selectedSignalType == SignalType.mono && state.selectedMonoChannel != null) {
        channelsToAssign = <AssignedStreamChannel>[
          AssignedStreamChannel(
            streamId: selectedStream.id,
            channelNumber: state.selectedMonoChannel!,
            channelName: _channelName(state.selectedMonoChannel!),
          ),
        ];
      } else if (state.selectedSignalType == SignalType.stereo) {
        channelsToAssign = <AssignedStreamChannel>[
          if (state.selectedLeftChannel != null)
            AssignedStreamChannel(
              streamId: selectedStream.id,
              channelNumber: state.selectedLeftChannel!,
              channelName: _channelName(state.selectedLeftChannel!),
            ),
          if (state.selectedRightChannel != null)
            AssignedStreamChannel(
              streamId: selectedStream.id,
              channelNumber: state.selectedRightChannel!,
              channelName: _channelName(state.selectedRightChannel!),
            ),
        ];
      }
    }

    // Assign stream-channel mappings if any are set
    if (channelsToAssign.isNotEmpty) {
      print('[AddSource] Saving ${channelsToAssign.length} stream-channel mappings for source ${source.id}');
      projectViewModel.assignStreamChannelsToSource(
        sourceId: source.id,
        channels: channelsToAssign,
      );
    }

    // if this is a building page, add the source to the circuit
    // if (isFromBuildingPage) {
    //   // Set device type index first
    //   serviceLocator<ProjectViewModel>().changeDeviceTypeIndex(1); // Sources index
    //
    //   // Create product and set for addition
    //   final ProductQueryModel product = ProductQueryModel(
    //     name: selectedItem.name,
    //     price: 0.0,
    //     image: selectedItem.assetPath,
    //     type: ProductType.sources,
    //     sku: selectedItem.id,
    //   );
    //   serviceLocator<ProjectViewModel>().setSelectedProductToAdd(product);
    // }

    // place this source in the selected listening area
    onSaved?.call();
    Navigator.of(context).pop();
  }
}
