import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/schematics/state/device_form_state.dart';

class AddDeviceFormViewModel<T> extends Cubit<DeviceFormState<DeviceFormData<T>>> {
  AddDeviceFormViewModel() : super(DeviceFormState<DeviceFormData<T>>(formData: DeviceFormData<T>()));
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  void selectDevice(T deviceId) => updateFormData(state.formData.copyWith(selectedDevice: deviceId));
  void selectLocation(String locationId) => updateFormData(state.formData.copyWith(selectedLocation: locationId));

  void updateFormData(DeviceFormData<T> formData) => emit(
    state.copyWith(
      formData: formData,
      isComplete: formData.selectedDevice != null && formData.selectedLocation != null,
    ),
  );

  void submit() {}
}
