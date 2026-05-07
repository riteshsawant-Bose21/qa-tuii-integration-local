import 'dart:developer';
import 'dart:math' show Random;

import 'package:bloc/bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/models/project_entities/controller.dart';
import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';

part 'fusion_network_device_vm_state.dart';

class FusionNetworkDeviceViewModel extends Cubit<FusionNetworkDeviceViewModelState> {
  final FusionDeviceService fusionDeviceService;
  FusionNetworkDeviceViewModel(this.fusionDeviceService) : super(FusionNetworkDeviceViewModelInitial());

  bool get hasUnRegisteredDevices {
    if (state is FusionNetworkDeviceViewModelLoaded) {
      final List<FusionNetworkDevice> devices = (state as FusionNetworkDeviceViewModelLoaded).devices;
      return devices.any((FusionNetworkDevice device) => !device.isDeviceCertificateValid);
    }
    return false;
  }

  /// Fetches both `/devices` and `/controllers` from the Fusion server in parallel
  /// and emits a single combined [FusionNetworkDeviceViewModelLoaded] state.
  Future<void> getFusionNetworkDevice({required String vip}) async {
    emit(FusionNetworkDeviceViewModelLoading());
    try {
      final List<dynamic> responses = await Future.wait<dynamic>(<Future<dynamic>>[
        fusionDeviceService.getAvailableDevicesOnNetwork(ip: vip),
        fusionDeviceService.getAvailableControllersOnNetwork(ip: vip),
      ]);

      final ResponseCallback<List<FusionNetworkDevice>> deviceResponse = responses[0] as ResponseCallback<List<FusionNetworkDevice>>;
      final ResponseCallback<List<FusionNetworkController>> controllerResponse = responses[1] as ResponseCallback<List<FusionNetworkController>>;

      if (!deviceResponse.success) {
        emit(FusionNetworkDeviceViewModelError(message: deviceResponse.message));
        return;
      }

      final List<FusionNetworkDevice> devices = deviceResponse.data ?? <FusionNetworkDevice>[];
      final List<FusionNetworkController> controllers =
          controllerResponse.success ? (controllerResponse.data ?? <FusionNetworkController>[]) : <FusionNetworkController>[];

      log("FUSION DEVICES: ${devices.map((FusionNetworkDevice e) => e.toJson()).toList()}");
      log("FUSION CONTROLLERS: ${controllers.map((FusionNetworkController e) => e.toJson()).toList()}");

      emit(FusionNetworkDeviceViewModelLoaded(devices: devices, controllers: controllers));
    } catch (e) {
      emit(FusionNetworkDeviceViewModelError(message: e.toString()));
    }
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

  // ─── Assignment orchestration ────────────────────────────────────────────
  // The following methods own the full assign/unassign flow for both audio
  // devices and wall-controllers. They were previously inlined in the screen
  // widget; centralising them here keeps the view dumb and makes the flow
  // testable independent of UI.

  /// Returns the most recently loaded list of network devices (empty if not yet loaded).
  List<FusionNetworkDevice> get _currentDevices =>
      state is FusionNetworkDeviceViewModelLoaded ? (state as FusionNetworkDeviceViewModelLoaded).devices : <FusionNetworkDevice>[];

  /// Assigns (or unassigns) a Fusion network audio device to a [HardwareComponent].
  ///
  /// Reuses the previously-loaded `/devices` snapshot to detect any stale assignment
  /// of the same id, rewrites it with a fresh UUID, then assigns the requested
  /// [hardware] (if any) to [device]. Refreshes the network device list at the end.
  /// Throws on failure so the caller can surface a snackbar.
  Future<void> assignHardwareToDevice({
    required HardwareComponent device,
    required FusionNetworkDevice? hardware,
  }) async {
    if (hardware != null && hardware.id == device.id) return;

    // Clear any existing network device whose id collides with this hardware component.
    for (final FusionNetworkDevice hw in _currentDevices.where((FusionNetworkDevice h) => h.id == device.id)) {
      final String newId = const Uuid().v4();
      await updateDeviceDetails(
        currentDeviceId: hw.id,
        newDeviceId: newId,
        name: "Fusion ${FusionUtils.shortStringUUID()}",
        location: "",
      );
    }

    if (hardware != null) {
      final String equipmentLocation = serviceLocator<ProjectViewModel>().getEquipLocationForHardware(hardwareId: device.id)?.name ?? "";
      await updateDeviceDetails(
        currentDeviceId: hardware.id,
        newDeviceId: device.id,
        name: "${device.name} ${Random().nextInt(100)}",
        location: equipmentLocation,
      );
    }

    final String? vip = serviceLocator<ProjectViewModel>().virtualIP;
    if (vip != null) {
      await getFusionNetworkDevice(vip: vip);
    }
  }

  /// Assigns (or unassigns) a [FusionNetworkController] to a [FusionController]
  /// project hardware component.
  ///
  /// Unlike [assignHardwareToDevice], this does **not** rewrite the on-device id;
  /// it only mutates `assignedNetworkDeviceId` on the project model via
  /// [ProjectViewModel.updateHardware]. If [controller] was already bound to a
  /// different [FusionController] in the project, that previous binding is cleared
  /// first using [FusionController.clearNetworkHardwareId].
  ///
  /// Refreshes the network controller list afterwards so the UI reflects current state.
  Future<void> assignControllerToDevice({
    required FusionController device,
    required FusionNetworkController? controller,
  }) async {
    final ProjectViewModel pvm = serviceLocator<ProjectViewModel>();

    if (controller == null) {
      // Unassign: clear `assignedNetworkDeviceId` on the target component.
      if (device.assignedNetworkDeviceId == null) return;
      pvm.updateHardware(hardware: device.clearNetworkHardwareId());
    } else if (device.assignedNetworkDeviceId == controller.id) {
      // No-op if already assigned to the same controller.
      return;
    } else {
      // Clear any previous FusionController binding for this network controller.
      final List<FusionController> existingAssignees =
          pvm.fusionControllers.where((FusionController c) => c.id != device.id && c.assignedNetworkDeviceId == controller.id).toList();
      for (final FusionController previous in existingAssignees) {
        pvm.updateHardware(hardware: previous.clearNetworkHardwareId(), autoSave: false);
      }
      // Bind to the target component.
      pvm.updateHardware(hardware: device.copyWith(assignedNetworkDeviceId: controller.id));
    }

    // Refresh so the local controller list (and assigned status) reflects reality.
    final String? vip = pvm.virtualIP;
    if (vip != null) {
      await getFusionNetworkDevice(vip: vip);
    }
  }
}
