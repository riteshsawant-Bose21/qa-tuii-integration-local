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
        emit(FusionNetworkDeviceViewModelLoaded(devices: response.data ?? <FusionNetworkDevice>[]));
      } else {
        emit(FusionNetworkDeviceViewModelError(message: response.message));
      }
    } catch (e) {
      emit(FusionNetworkDeviceViewModelError(message: e.toString()));
    }
  }

  // This method is returning the list of hardware components that are not registered in the cloud for a given project.
  // It first fetches the status of all devices in the cloud for the specified project,
  // then filters out the hardware components that are already registered based on their IDs.
  Future<List<HardwareComponent>> getUnregisteredHardware({required List<HardwareComponent> hardwares, required String projectId}) async {
    final ResponseCallback<List<CloudDeviceStatus>> response = await fusionDeviceService.getCloudDevicesStatus(projectId: projectId);
    if (!response.success || response.data == null) return hardwares;
    final Set<String> registeredIds = response.data!.where((CloudDeviceStatus s) => s.registered).map((CloudDeviceStatus s) => s.id).toSet();
    return hardwares.where((HardwareComponent hw) => !registeredIds.contains(hw.id)).toList();
  }

  Future<void> registerAndClaimHardwares({required List<HardwareComponent> hardwares, required String projectId}) async {
    if (hardwares.isEmpty) return;

    emit(FusionNetworkDeviceViewModelClaiming());

    final ResponseCallback<List<DeviceBulkRegisterResult>> registerResponse = await fusionDeviceService.registerHardwareDevicesBulk(
      hardwares: hardwares,
      projectId: projectId,
    );

    if (!registerResponse.success) {
      emit(FusionNetworkDeviceViewModelError(message: registerResponse.message));
      throw Exception(registerResponse.message);
    }

    final List<DeviceBulkRegisterResult> bulkResults = registerResponse.data ?? <DeviceBulkRegisterResult>[];
    final List<String> failedDevices = <String>[];

    for (int i = 0; i < hardwares.length; i++) {
      final HardwareComponent hw = hardwares[i];
      final DeviceBulkRegisterResult? bulk = i < bulkResults.length ? bulkResults[i] : null;

      if (bulk != null && !bulk.success) {
        failedDevices.add('${hw.name} (register failed: ${bulk.error.isEmpty ? 'unknown error' : bulk.error})');
        continue;
      }

      final String claimId = (bulk?.deviceId ?? '').isNotEmpty ? bulk!.deviceId : hw.id;

      final ResponseCallback<bool> claimResp = await fusionDeviceService.claimDevice(
        deviceId: claimId,
        projectId: projectId,
        csr: '', // TODO: pass actual CSR.
      );

      if (!claimResp.success) {
        failedDevices.add('${hw.name} (claim failed: ${claimResp.message})');
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
