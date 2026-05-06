import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/models/project_entities/non_processing/aes67_config.dart';

part 'add_output_device_vm_state.dart';

class AddOutputDeviceViewModel extends Cubit<AddOutputDeviceVmState> {
  AddOutputDeviceViewModel() : super(AddOutputDeviceVmState.initial());

  final ValueNotifier<bool> isSaveEnabled = ValueNotifier<bool>(false);

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
    canProceed = hasName && vmState.outputType != null && vmState.audioChannel != null && vmState.connection != null;

    final bool isAes67 = vmState.connection == OutputDeviceConnectionType.aes67;
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
    // Handle the save action, e.g., by sending the data to a repository or service.
    // You can access the current state using `state` and perform necessary actions.
  }

  @override
  void onChange(Change<AddOutputDeviceVmState> change) {
    _updateSaveEnabled(change.nextState);
    super.onChange(change);
  }

  @override
  Future<void> close() {
    // Dispose the ValueNotifier when the ViewModel is closed to prevent memory leaks.
    isSaveEnabled.dispose();
    return super.close();
  }
}
