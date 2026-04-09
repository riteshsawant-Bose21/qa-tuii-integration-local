import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:meta/meta.dart';

part 'fusion_network_device_vm_state.dart';

class FusionNetworkDeviceViewModel extends Cubit<FusionNetworkDeviceViewModelState> {
  final FusionDeviceService fusionDeviceService;
  FusionNetworkDeviceViewModel(this.fusionDeviceService) : super(FusionNetworkDeviceViewModelInitial());

  Future<void> getFusionNetworkDevice({required String vip}) async {
    emit(FusionNetworkDeviceViewModelLoading());
    try {
      final ResponseCallback<List<FusionNetworkDevice>> response = await fusionDeviceService.getAvailableDevicesOnNetwork(ip: vip);
      if (response.success) {
        log("FUSION DEVICES: ${response.data?.map((FusionNetworkDevice e) => e.toJson()).toList()}");
        emit(FusionNetworkDeviceViewModelLoaded(devices: response.data ?? <FusionNetworkDevice>[]));
      } else {
        emit(FusionNetworkDeviceViewModelError(message: response.message));
      }
    } catch (e) {
      emit(FusionNetworkDeviceViewModelError(message: e.toString()));
    }
  }

  Future<List<FusionNetworkDevice>> getUnregisteredDevices({required String projectId}) async {
    if (state is FusionNetworkDeviceViewModelLoaded) {
      final List<FusionNetworkDevice> networkDevices = (state as FusionNetworkDeviceViewModelLoaded).devices;
      return networkDevices.where((FusionNetworkDevice element) => !element.isDeviceCertificateValid).toList();
    } else {
      return <FusionNetworkDevice>[];
    }
  }

  Future<void> registerAndClaimDevices({required List<FusionNetworkDevice> devices, required String projectId}) async {
    if (devices.isEmpty) return;

    emit(FusionNetworkDeviceViewModelClaiming());

    final ResponseCallback<List<DeviceBulkRegisterResult>> registerResponse = await fusionDeviceService.registerDevicesBulk(
      devices: devices,
      projectId: projectId,
    );

    if (!registerResponse.success) {
      emit(FusionNetworkDeviceViewModelError(message: registerResponse.message));
      throw Exception(registerResponse.message);
    }

    final List<DeviceBulkRegisterResult> bulkResults = registerResponse.data ?? <DeviceBulkRegisterResult>[];
    final List<String> failedDevices = <String>[];

    for (int i = 0; i < devices.length; i++) {
      final FusionNetworkDevice hw = devices[i];
      final DeviceBulkRegisterResult? bulk = i < bulkResults.length ? bulkResults[i] : null;

      if (bulk != null && !bulk.success) {
        failedDevices.add('${hw.name} (register failed: ${bulk.error.isEmpty ? 'unknown error' : bulk.error})');
        continue;
      }
    }

    if (failedDevices.isNotEmpty) {
      final String message = 'Some devices could not be completed: ${failedDevices.join(', ')}';
      emit(FusionNetworkDeviceViewModelError(message: message));
      throw Exception(message);
    }

    emit(FusionNetworkDeviceViewModelClaimSuccess());
  }

  Future<bool> updateDeviceDetails({required String currentDeviceId, required String newDeviceId, required String name, required String location}) async {
    final String vip = serviceLocator<ProjectViewModel>().virtualIP ?? "";
    final ResponseCallback<bool> response = await fusionDeviceService.updateDeviceDetails(
      currentDeviceId: currentDeviceId,
      newDeviceId: newDeviceId,
      name: name,
      location: location,
      vip: vip,
    );
    if (response.success) {
      return true;
    } else {
      throw Exception(response.message);
    }
  }
}
