import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'add_output_device_vm_state.dart';

class AddOutputDeviceViewModel extends Cubit<AddOutputDeviceVmState> {
  AddOutputDeviceViewModel() : super(AddOutputDeviceVmState.initial());

  final TextEditingController outputDeviceNameCtrl = TextEditingController();

  void updateOutputType(OutputDeviceType? type) => emit(state.copyWith(outputType: () => type));
  void updateAudioChannel(AudioChannel? channel) => emit(state.copyWith(audioChannel: () => channel));
  void updateConnection(OutputDeviceConnectionType? connection) => emit(state.copyWith(connection: () => connection));

  @override
  Future<void> close() {
    outputDeviceNameCtrl.dispose();
    return super.close();
  }
}
