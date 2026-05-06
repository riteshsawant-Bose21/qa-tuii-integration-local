import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../configuration/presentation/viewmodel/project_view_model.dart';
import '../repositories/device_registration_repository.dart';

part 'device_registration_state.dart';

class DeviceRegistrationViewModel extends Cubit<DeviceRegistrationState> {
  final DeviceRegistrationRepository repository;
  DeviceRegistrationViewModel(this.repository) : super(const DeviceRegistrationState()) {
    _syncLocalFusionNetworkUnRegisteredDevices();
  }

  final String virtualIP = serviceLocator<ProjectViewModel>().virtualIP ?? '';
  final String projectId = serviceLocator<ProjectViewModel>().projectId;

  String _toUserErrorMessage(Object error, {required String fallback}) {
    String message = error.toString().trim();
    if (message.startsWith('Exception:')) {
      message = message.substring('Exception:'.length).trim();
    }
    if (message.isEmpty) return fallback;
    return message;
  }

  Future<void> _syncLocalFusionNetworkUnRegisteredDevices() async {
    try {
      final List<FusionNetworkDevice> devices = await repository.getFusionNetworkUnRegisteredDevices();
      final Iterable<DeviceSpecificRegistrationState> updated = devices.map((FusionNetworkDevice element) => DeviceSpecificRegistrationState(device: element));
      emit(state.copyWith(devices: updated.toList(), error: null));
    } catch (e) {
      emit(state.copyWith(devices: <DeviceSpecificRegistrationState>[], error: e.toString()));
    }
  }

  Future<void> singleDeviceRegister(DeviceSpecificRegistrationState deviceState) async {
    emit(
      state.copyWith(
        devices: state.updateDevice(
          deviceState.copyWith(
            step: DeviceRegistrationStep.processing,
            error: '',
          ),
        ),
      ),
    );

    final String fusionDeviceId = deviceState.device.id;

    try {
      final String csrCertificate = await repository.getCSRCertificate(fusionDeviceId);

      final CloudDeviceRegisterResult result = await repository.registerSingleDevice(
        projectId: projectId,
        csrCertificate: csrCertificate,
        device: deviceState.device,
      );

      // If any exceptions were thrown in the updateCsrInFusionDevice call, the next lines won't execute and
      // the catch block will handle it, setting the device back to initial step with an error message.
      final bool updateResult = await updateCsrInFusionDevice(fusionDeviceId, result.certificate);

      deviceState = deviceState.copyWith(
        device: deviceState.device.copyWith(isDeviceCertificateValid: updateResult),
        step: updateResult ? DeviceRegistrationStep.completed : DeviceRegistrationStep.initial,
        error: '',
      );

      final List<DeviceSpecificRegistrationState>? updated = state.updateDevice(deviceState);
      emit(state.copyWith(devices: updated));
    } on DeviceAlreadyRegisteredException {
      await resetDeviceCertificateAndRetry(deviceState);
    } catch (e) {
      final String message = _toUserErrorMessage(e, fallback: 'Registration Failed');
      final DeviceRegistrationState updated = state.copyWith(
        devices: state.updateDevice(
          deviceState.copyWith(
            step: DeviceRegistrationStep.initial,
            error: message,
          ),
        ),
      );

      emit(updated);
    }
  }

  Future<void> bulkDeviceRegistration() async {
    emit(state.bulkRetryState);

    // Set the global notifier to true to indicate that registration is in progress,
    // this will hide the close button in the dialog to prevent user from closing it while registration is in progress.
    serviceLocator<ProjectViewModel>().isDevicesRegisteringNotifier.value = true;

    final List<DeviceSpecificRegistrationState> devices = <DeviceSpecificRegistrationState>[...state.devices ?? <DeviceSpecificRegistrationState>[]];
    for (final DeviceSpecificRegistrationState deviceState in devices) {
      await singleDeviceRegister(deviceState);
    }

    emit(
      state.copyWith(
        stepBulk: state.allCompleted ? DeviceRegistrationStep.completed : DeviceRegistrationStep.initial,
      ),
    );

    // After all devices have been processed, set the global notifier back to false to show the close button again.
    serviceLocator<ProjectViewModel>().isDevicesRegisteringNotifier.value = false;
  }

  Future<bool> updateCsrInFusionDevice(String fusionDeviceId, String certificate) async {
    try {
      final bool result = await repository.updateCsrInFusionDevice(
        fusionDeviceId: fusionDeviceId,
        certificate: certificate,
      );
      return result;
    } catch (e) {
      return false;
    }
  }

  Future<void> refreshDevices() async {
    emit(state.copyWith(stepBulk: DeviceRegistrationStep.processing));
    await _syncLocalFusionNetworkUnRegisteredDevices();
    emit(state.copyWith(stepBulk: DeviceRegistrationStep.initial));
  }

  // RESET DEVICE CERTIFICATE
  // & RETRY REGISTRATION AGAIN FOR THAT FAILED DEVICE.
  Future<void> resetDeviceCertificateAndRetry(DeviceSpecificRegistrationState deviceState) async {
    try {
      final bool result = await repository.resetDeviceCertificate(fusionDeviceSerialNumber: deviceState.device.serialNumber);
      if (result) {
      } else {}
      if (!result) throw Exception("Failed to reset device certificate");

      await singleDeviceRegister(deviceState);
    } catch (e) {
      emit(
        state.copyWith(
          devices: state.updateDevice(
            deviceState.copyWith(
              step: DeviceRegistrationStep.initial,
              error: 'Failed to reset device certificate. Please try again.',
            ),
          ),
        ),
      );
    }
  }
}
