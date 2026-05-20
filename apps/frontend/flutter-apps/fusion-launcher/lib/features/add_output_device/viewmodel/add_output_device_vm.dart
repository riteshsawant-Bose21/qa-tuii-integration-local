import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/add_output_device/repository/add_output_device_repo.dart';
import 'package:fusion_lib/fusion_lib.dart';

part 'add_output_device_vm_state.dart';

class AddOutputDeviceViewModel extends Cubit<AddOutputDeviceVmState> {
  AddOutputDeviceViewModel() : super(AddOutputDeviceVmState.initial());

  final ValueNotifier<bool> isSaveEnabled = ValueNotifier<bool>(false);

  final AddOutputDeviceRepository _repository = AddOutputDeviceRepository();

  void setZoneId(String? id) => emit(state.copyWith(zoneId: () => id));

  void updateOutputDeviceName(String name) => emit(state.copyWith(outputDeviceName: () => name));
  void updateOutputType(OutputDeviceType? type) => emit(state.copyWith(outputType: () => type));
  void updateAudioChannel(AudioChannel? channel) => emit(state.copyWith(audioChannel: () => channel));
  void updateConnection(OutputDeviceConnectionType? connection) => emit(state.copyWith(connection: () => connection));
  void setSelectedStream(Aes67Config stream) => emit(state.copyWith(selectedStream: () => stream));
  void setSelectedMonoChannel(int channel) => emit(state.copyWith(selectedMonoChannel: () => channel));
  void setSelectedLeftChannel(int channel) => emit(state.copyWith(selectedLeftChannel: () => channel));
  void setSelectedRightChannel(int channel) => emit(state.copyWith(selectedRightChannel: () => channel));

  void _updateSaveEnabled(AddOutputDeviceVmState vmState) {
    bool canProceed = false;

    final bool hasName = vmState.outputDeviceName != null && vmState.outputDeviceName!.isNotEmpty;
    canProceed = vmState.zoneId != null && hasName && vmState.outputType != null && vmState.audioChannel != null && vmState.connection != null;

    final bool isAes67 = vmState.connection == OutputDeviceConnectionType.aes67Stream;
    if (isAes67) {
      if (vmState.audioChannel == AudioChannel.mono) {
        canProceed = canProceed && vmState.selectedMonoChannel != null && vmState.selectedStream != null;
      } else if (vmState.audioChannel == AudioChannel.stereo) {
        canProceed = canProceed && vmState.selectedLeftChannel != null && vmState.selectedRightChannel != null && vmState.selectedStream != null;
      }
    }

    isSaveEnabled.value = canProceed;
  }

  void onSaveTap() {
    final AddOutputDeviceVmState current = state;

    if (current.outputDeviceName == null || current.outputType == null || current.audioChannel == null || current.connection == null) return;

    final OutputDevice device = OutputDevice(
      name: current.outputDeviceName!,
      outputDeviceType: current.outputType!,
      connectionType: current.connection!,
      audioChannel: current.audioChannel!,
      locationEntity: LocationModel(),
      price: 0.0,
      addedFromBuildingPage: false,
    );

    _repository.saveOutputDevice(
      device: device,
      zoneId: current.zoneId,
      selectedStream: current.selectedStream,
      selectedMonoChannel: current.selectedMonoChannel,
      selectedLeftChannel: current.selectedLeftChannel,
      selectedRightChannel: current.selectedRightChannel,
    );
  }

  @override
  void onChange(Change<AddOutputDeviceVmState> change) {
    _updateSaveEnabled(change.nextState);
    super.onChange(change);
  }

  @override
  Future<void> close() {
    isSaveEnabled.dispose();
    return super.close();
  }
}
