import 'package:equatable/equatable.dart';

sealed class AudioMessageSyncState extends Equatable {
  @override
  List<Object?> get props => <Object?>[];
}

final class AudioMessageSyncInitial extends AudioMessageSyncState {}

final class AudioMessageSyncing extends AudioMessageSyncState {}

final class AudioMessageSyncSuccess extends AudioMessageSyncState {}

final class AudioMessageSyncFailure extends AudioMessageSyncState {
  final String message;
  AudioMessageSyncFailure(this.message);

  @override
  List<Object?> get props => <Object?>[message];
}
