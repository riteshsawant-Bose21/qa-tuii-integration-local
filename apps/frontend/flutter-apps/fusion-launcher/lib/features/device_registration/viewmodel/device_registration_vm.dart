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

      final CloudDeviceRegisterResult result = await repository.registerSingleDevice(virtualIP, csrCertificate, deviceState.device);

      await updateCsrInFusionDevice(fusionDeviceId, csrCertificate);

      deviceState = deviceState.copyWith(
        device: deviceState.device.copyWith(isDeviceCertificateValid: result.success),
        step: result.success ? DeviceRegistrationStep.completed : DeviceRegistrationStep.initial,
        error: '',
      );

      final List<DeviceSpecificRegistrationState>? updated = state.updateDevice(deviceState);
      emit(state.copyWith(devices: updated));
    } on DeviceAlreadyRegisteredException catch (e) {
      try {
        await updateCsrInFusionDevice(e.fusionDeviceId, e.certificate);

        emit(
          state.copyWith(
            devices: state.updateDevice(
              deviceState.copyWith(
                step: DeviceRegistrationStep.completed,
                device: deviceState.device.copyWith(isDeviceCertificateValid: true),
                error: '',
              ),
            ),
          ),
        );
      } catch (syncError) {
        emit(
          state.copyWith(
            devices: state.updateDevice(
              deviceState.copyWith(
                step: DeviceRegistrationStep.initial,
                error: 'Registration Failed',
              ),
            ),
          ),
        );
      }
    } catch (e) {
      final DeviceRegistrationState updated = state.copyWith(
        devices: state.updateDevice(
          deviceState.copyWith(
            step: DeviceRegistrationStep.initial,
            error: 'Registration Failed',
          ),
        ),
      );

      emit(updated);
    } finally {}
  }

  Future<void> bulkDeviceRegistration() async {
    emit(state.bulkRetryState);
    final List<DeviceSpecificRegistrationState> devices = <DeviceSpecificRegistrationState>[...state.devices ?? <DeviceSpecificRegistrationState>[]];
    for (final DeviceSpecificRegistrationState deviceState in devices) {
      await singleDeviceRegister(deviceState);
    }

    emit(
      state.copyWith(
        stepBulk: state.allCompleted ? DeviceRegistrationStep.completed : DeviceRegistrationStep.initial,
      ),
    );
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
}
