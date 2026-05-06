import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/devices/services/fusion_device_discovery_service.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:meta/meta.dart';

part 'fusion_network_device_vm_state.dart';

class FusionNetworkDeviceViewModel
    extends Cubit<FusionNetworkDeviceViewModelState> {
  final FusionDeviceDiscoveryService fusionDeviceDiscoveryService;
  FusionNetworkDeviceViewModel(this.fusionDeviceDiscoveryService)
    : super(FusionNetworkDeviceViewModelInitial());

  bool get hasUnRegisteredDevices {
    if (state is FusionNetworkDeviceViewModelLoaded) {
      final List<FusionNetworkDevice> devices =
          (state as FusionNetworkDeviceViewModelLoaded).devices;
      return devices.any(
        (FusionNetworkDevice device) => !device.isDeviceCertificateValid,
      );
    }
    return false;
  }

  Future<void> getFusionNetworkDevice({required String vip}) async {
    emit(FusionNetworkDeviceViewModelLoading());
    try {
      final ResponseCallback<List<FusionNetworkDevice>> response =
          await fusionDeviceDiscoveryService.getAvailableDevicesOnNetwork(
            ip: vip,
          );
      if (response.success) {
        log(
          "FUSION DEVICES: ${response.data?.map((FusionNetworkDevice e) => e.toJson()).toList()}",
        );
        emit(
          FusionNetworkDeviceViewModelLoaded(
            devices: response.data ?? <FusionNetworkDevice>[],
          ),
        );
      } else {
        emit(FusionNetworkDeviceViewModelError(message: response.message));
      }
    } catch (e) {
      emit(FusionNetworkDeviceViewModelError(message: e.toString()));
    }
  }

  Future<bool> updateDeviceDetails({
    required String currentDeviceId,
    required String newDeviceId,
    required String name,
    required String location,
  }) async {
    final String vip = serviceLocator<ProjectViewModel>().virtualIP ?? "";
    final ResponseCallback<bool> response =
        await serviceLocator<FusionDeviceService>().updateDeviceDetails(
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
