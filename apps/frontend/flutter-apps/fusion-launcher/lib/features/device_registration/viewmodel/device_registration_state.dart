part of 'device_registration_vm.dart';

enum DeviceRegistrationStep { initial, processing, completed }

class DeviceSpecificRegistrationState extends Equatable {
  final DeviceRegistrationStep step;
  final FusionNetworkDevice device;
  final String? error;

  const DeviceSpecificRegistrationState({
    this.step = DeviceRegistrationStep.initial,
    required this.device,
    this.error,
  });

  @override
  List<Object?> get props => <Object?>[step, device, error];

  DeviceSpecificRegistrationState copyWith({DeviceRegistrationStep? step, FusionNetworkDevice? device, String? error}) {
    return DeviceSpecificRegistrationState(
      step: step ?? this.step,
      device: device ?? this.device,
      error: error ?? this.error,
    );
  }
}

class DeviceRegistrationState extends Equatable {
  final DeviceRegistrationStep stepBulk;
  final List<DeviceSpecificRegistrationState>? devices;
  final String? error;

  @override
  List<Object?> get props => <Object?>[stepBulk, devices, error];

  bool get allCompleted => devices?.every((DeviceSpecificRegistrationState element) => element.device.isDeviceCertificateValid) ?? false;

  DeviceRegistrationState get bulkRetryState {
    final Iterable<DeviceSpecificRegistrationState>? updateDevices = devices?.map((DeviceSpecificRegistrationState deviceState) {
      if (deviceState.step == DeviceRegistrationStep.completed || deviceState.device.isDeviceCertificateValid) return deviceState;
      return deviceState.copyWith(step: DeviceRegistrationStep.processing, error: '');
    });

    return copyWith(stepBulk: DeviceRegistrationStep.processing, devices: updateDevices?.toList());
  }

  const DeviceRegistrationState({
    this.stepBulk = DeviceRegistrationStep.initial,
    this.devices,
    this.error,
  });

  DeviceRegistrationState copyWith({
    DeviceRegistrationStep? stepBulk,
    List<DeviceSpecificRegistrationState>? devices,
    String? error,
  }) {
    return DeviceRegistrationState(
      stepBulk: stepBulk ?? this.stepBulk,
      devices: devices ?? this.devices,
      error: error ?? this.error,
    );
  }

  List<DeviceSpecificRegistrationState>? updateDevice(DeviceSpecificRegistrationState device) {
    final Iterable<DeviceSpecificRegistrationState>? updated = devices?.map((DeviceSpecificRegistrationState item) {
      if (item.device.id != device.device.id) return item;
      return device;
    });

    return updated?.toList();
  }

  ({int progressPercent, double progress}) get progressPercent {
    final int completedCount =
        devices?.where((DeviceSpecificRegistrationState d) => d.step == DeviceRegistrationStep.completed || d.device.isDeviceCertificateValid).length ?? 0;
    final double progress = devices == null || devices!.isEmpty ? 0 : completedCount / devices!.length;
    final int progressPercent = (progress * 100).round().clamp(0, 100);
    return (progressPercent: progressPercent, progress: progress);
  }
}
