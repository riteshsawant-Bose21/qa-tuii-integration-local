part of 'fusion_network_device_vm.dart';

@immutable
sealed class FusionNetworkDeviceViewModelState {}

final class FusionNetworkDeviceViewModelInitial extends FusionNetworkDeviceViewModelState {}

final class FusionNetworkDeviceViewModelLoading extends FusionNetworkDeviceViewModelState {}

final class FusionNetworkDeviceViewModelLoaded extends FusionNetworkDeviceViewModelState {
  final List<FusionNetworkDevice> devices;

  FusionNetworkDeviceViewModelLoaded({required this.devices});
}

final class FusionNetworkDeviceViewModelError extends FusionNetworkDeviceViewModelState {
  final String message;

  FusionNetworkDeviceViewModelError({required this.message});
}
