import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../core/models/products_data.dart';
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
  }

  void setzone(String id) {
    emit(state.copyWith(selectedZone: id, selectedEquipmentLocationId: null));
  }

  void setSelectedEquipmentLocation(String id) {
    emit(state.copyWith(selectedEquipmentLocationId: id, selectedZone: null));
  }

  void clearSelectedListeningArea() {
    emit(
      AddSourceViewModelState(
        selectedSourceSectionType: state.selectedSourceSectionType,
        selectedSourceOption: state.selectedSourceOption,
        selectedSignalType: state.selectedSignalType,
        selectedSources: state.selectedSources,
        selectedConnectionType: state.selectedConnectionType,
        selectedSourceName: state.selectedSourceName,
        selectedListeningArea: null,
        selectedStream: state.selectedStream,
        availableStreams: state.availableStreams,
        selectedMonoChannel: state.selectedMonoChannel,
        selectedLeftChannel: state.selectedLeftChannel,
        selectedRightChannel: state.selectedRightChannel,
        assignedStreamChannels: state.assignedStreamChannels,
      ),
    );
  }

  void setSelectedEquipmentLocation(String id) {
    emit(state.copyWith(selectedEquipmentLocationId: id));
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

    if (state.selectedZone == null && state.selectedEquipmentLocationId == null) {
      return FusionToast.error(context, message: "Please select a location");
    }

    // if connection location is not selected
    if (state.selectedSources.first?.type != SourceType.paging && state.selectedConnectionType == null) {
      return FusionToast.error(context, message: "Please select a connection type");
    }

    final ProjectViewModel projectViewModel = context.read<ProjectViewModel>();

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
      SourceConnectionType.endpoint => PortType.analogOutput,
      SourceConnectionType.messagePlayer => PortType.messagePlayer,
    };

    // ── Zone flow ────────────────────────────────────
    if (state.selectedEquipmentLocationId != null) {
      final Source source = Source(
        name: state.selectedSourceName ?? selectedItem.name,
        pos: null,
        type: selectedItem.type,
        addedFromBuildingPage: false,
        connectionType: connectType,
        image: selectedItem.assetPath,
        locationEntity: LocationModel(),
        sku: selectedItem.id,
        price: selectedItem.price,
        pagingSourceType: selectedItem.pagingSourceType,
        portData: HardwarePortData(
          inputPorts: 0,
          outputPorts: 1,
          inputPortType: PortType.analogInput,
          outputPortType: portType,
          portPosition: PortPosition.topLeft,
        ),
      );

      // 1. Add hardware first
      projectViewModel.addHardware(hardware: source);
      projectViewModel.setCurrentSelectedHardware(source.id);

      // 2. Then link to equipment location
      projectViewModel.addHardwareToEquipLocation(
        equipLocationId: state.selectedEquipmentLocationId!,
        hardwareId: source.id,
      );

      _handleStreamChannelAssignment(projectViewModel, source.id);
    } else if (state.selectedZone != null) {
      final List<ListeningArea> areasInZone = projectViewModel.getListeningAreasForZone(zoneId: state.selectedZone!);
      final ListeningArea? selectedArea = areasInZone.firstOrNull;
      if (selectedArea == null) return;

      final FloorModel? floorData = projectViewModel.getFloorForListeningArea(areaId: selectedArea.id);
      final String? floorId = floorData?.id;

      final Source source = Source(
        name: state.selectedSourceName ?? selectedItem.name,
        pos: selectedArea.getCenterPositionOfVertices(),
        type: selectedItem.type,
        addedFromBuildingPage: false,
        connectionType: connectType,
        image: selectedItem.assetPath,
        locationEntity: LocationModel(listeningAreaId: selectedArea.id, floorId: floorId),
        sku: selectedItem.id,
        price: selectedItem.price,
        pagingSourceType: selectedItem.pagingSourceType,
        portData: HardwarePortData(
          inputPorts: 0,
          outputPorts: 1,
          inputPortType: PortType.analogInput,
          outputPortType: portType,
          portPosition: PortPosition.topLeft,
        ),
      );

      projectViewModel.addHardware(hardware: source);
      projectViewModel.setCurrentSelectedHardware(source.id);
      _handleStreamChannelAssignment(projectViewModel, source.id);

      // ── Equipment Location flow ──────────────────────
    }

    onSaved?.call();
    Navigator.of(context).pop();
  }

  void _handleStreamChannelAssignment(ProjectViewModel projectViewModel, String sourceId) {
    final Aes67Config? selectedStream = state.selectedStream;
    List<AssignedStreamChannel> channelsToAssign = List<AssignedStreamChannel>.from(state.assignedStreamChannels);

    if (selectedStream != null && channelsToAssign.isEmpty) {
      String channelName(int channelNumber) {
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
            channelName: channelName(state.selectedMonoChannel!),
          ),
        ];
      } else if (state.selectedSignalType == SignalType.stereo) {
        channelsToAssign = <AssignedStreamChannel>[
          if (state.selectedLeftChannel != null)
            AssignedStreamChannel(
              streamId: selectedStream.id,
              channelNumber: state.selectedLeftChannel!,
              channelName: channelName(state.selectedLeftChannel!),
            ),
          if (state.selectedRightChannel != null)
            AssignedStreamChannel(
              streamId: selectedStream.id,
              channelNumber: state.selectedRightChannel!,
              channelName: channelName(state.selectedRightChannel!),
            ),
        ];
      }
    }

    if (channelsToAssign.isNotEmpty) {
      projectViewModel.assignStreamChannelsToSource(
        sourceId: sourceId,
        channels: channelsToAssign,
      );
    }
  }
}
