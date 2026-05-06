part of 'reboot_viewmodel.dart';

sealed class RebootViewmodelState {}

final class RebootViewmodelInitial extends RebootViewmodelState {}

final class RebootViewmodelLoading extends RebootViewmodelState {
  final String deviceId;
  RebootViewmodelLoading({required this.deviceId});
}

final class RebootViewmodelSuccess extends RebootViewmodelState {
  final String deviceId;
  RebootViewmodelSuccess({required this.deviceId});
}

final class RebootViewmodelFailure extends RebootViewmodelState {
  final String deviceId;
  final String message;
  RebootViewmodelFailure({required this.deviceId, required this.message});
}
