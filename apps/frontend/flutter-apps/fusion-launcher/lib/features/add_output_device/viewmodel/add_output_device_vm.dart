import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/add_output_device/repository/add_output_device_repo.dart';
import 'package:fusion_launcher/features/speaker_selection_popup/viewmodel/product_query_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/product_data/models/output_product.dart';

part 'add_output_device_vm_state.dart';

class AddOutputDeviceViewModel extends Cubit<AddOutputDeviceVmState> {
  AddOutputDeviceViewModel() : super(AddOutputDeviceVmState.initial());

  final ValueNotifier<bool> isSaveEnabled = ValueNotifier<bool>(false);

  final AddOutputDeviceRepository _repository = AddOutputDeviceRepository();

  void setZoneId(String? id) => emit(state.copyWith(zoneId: () => id));

  List<OutputProduct> get outputProducts => serviceLocator<ProductQueryViewModel>().outputs;

  void updateOutputProductId(int? productId) {
    final OutputProduct? selectedProduct = outputProducts.firstWhereOrNull((OutputProduct p) => p.id == productId);
    emit(state.copyWith(outputProductId: () => productId, connectionType: () => selectedProduct?.primaryConnection));
  }

  List<OutputConnectionType> get supportedConnectionTypes {
    return outputProducts.firstWhereOrNull((OutputProduct p) => p.id == state.outputProductId)?.supportedConnections ?? <OutputConnectionType>[];
  }

  void updateOutputDeviceName(String name) => emit(state.copyWith(outputDeviceName: () => name));
  void updateAudioChannel(AudioChannel channel) => emit(state.copyWith(audioChannel: () => channel));
  void updateConnectionType(OutputConnectionType? connectionType) => emit(state.copyWith(connectionType: () => connectionType));
  void setSelectedStream(Aes67Config stream) => emit(state.copyWith(selectedStream: () => stream));
  void setSelectedMonoChannel(int channel) => emit(state.copyWith(selectedMonoChannel: () => channel));
  void setSelectedLeftChannel(int channel) => emit(state.copyWith(selectedLeftChannel: () => channel));
  void setSelectedRightChannel(int channel) => emit(state.copyWith(selectedRightChannel: () => channel));

  void _updateSaveEnabled(AddOutputDeviceVmState vmState) {
    bool canProceed = false;

    final bool hasName = vmState.outputDeviceName != null && vmState.outputDeviceName!.isNotEmpty;
    canProceed = vmState.zoneId != null && hasName && vmState.outputProductId != null && vmState.connectionType != null;

    final bool isAes67 = vmState.connectionType == OutputConnectionType.aes67output;
    if (isAes67) {
      if (vmState.audioChannel == AudioChannel.mono) {
        canProceed = canProceed && vmState.selectedMonoChannel != null && vmState.selectedStream != null;
      } else if (vmState.audioChannel == AudioChannel.stereo) {
        canProceed = canProceed && vmState.selectedLeftChannel != null && vmState.selectedRightChannel != null && vmState.selectedStream != null;
      }
    }

    isSaveEnabled.value = canProceed;
  }

  void onSaveTap(BuildContext context) {
    final AddOutputDeviceVmState current = state;

    if (current.outputDeviceName == null || current.outputProductId == null || current.connectionType == null) return;

    final OutputDevice device = OutputDevice(
      name: current.outputDeviceName!,
      productId: current.outputProductId!,
      connectionType: current.connectionType!,
      audioChannel: current.audioChannel,
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

    Navigator.of(context).pop();
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
