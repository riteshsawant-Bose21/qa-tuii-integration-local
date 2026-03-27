part of 'config_sync_view_model.dart';

@immutable
sealed class ConfigSyncState {}

final class ConfigSyncInitial extends ConfigSyncState {}

final class ProcessingDataWithDro extends ConfigSyncState {}

final class DroResponseReceived extends ConfigSyncState {
  final DroResponseData droResponseData;

  DroResponseReceived({required this.droResponseData});
}

final class DroProcessingFailed extends ConfigSyncState {
  final String message;

  DroProcessingFailed({required this.message});
}

final class SyncingConfigWithDsp extends ConfigSyncState {}

final class ConfigSyncedWithDsp extends ConfigSyncState {}

final class ConfigSyncFailure extends ConfigSyncState {
  final String message;

  ConfigSyncFailure({required this.message});
}
