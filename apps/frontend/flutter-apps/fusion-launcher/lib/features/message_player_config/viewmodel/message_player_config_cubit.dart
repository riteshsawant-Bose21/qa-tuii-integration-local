import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';

part 'message_player_config_state.dart';

/// Cubit for managing Message Player Configuration state and business logic
class MessagePlayerConfigCubit extends Cubit<MessagePlayerConfigState> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  MessagePlayerConfigCubit() : super(const MessagePlayerInitial()) {
    _initializeAudioPlayer();
  }

  ProjectViewModel get _projectViewModel => serviceLocator<ProjectViewModel>();

  /// Helper to get current loaded state or null
  MessagePlayerLoaded? get _loadedState {
    final MessagePlayerConfigState currentState = state;
    if (currentState is MessagePlayerLoaded) {
      return currentState;
    }
    return null;
  }

  void _initializeAudioPlayer() {
    _audioPlayer.onPlayerStateChanged.listen((PlayerState playerState) {
      final MessagePlayerLoaded? loaded = _loadedState;
      if (loaded == null) return;

      if (playerState == PlayerState.playing) {
        emit(loaded.copyWith(isPlaying: true));
      } else if (playerState == PlayerState.paused || playerState == PlayerState.stopped || playerState == PlayerState.completed) {
        emit(loaded.copyWith(isPlaying: false));
      }
    });

    _audioPlayer.onPositionChanged.listen((Duration position) {
      final MessagePlayerLoaded? loaded = _loadedState;
      if (loaded == null) return;
      emit(loaded.copyWith(currentPosition: position));
    });

    _audioPlayer.onDurationChanged.listen((Duration duration) {
      final MessagePlayerLoaded? loaded = _loadedState;
      if (loaded == null) return;
      emit(loaded.copyWith(totalDuration: duration));
    });
  }

  /// Initialize the cubit with a message player
  void init({MessagePlayerModel? messagePlayer, String? messagePlayerId}) {
    // Get available zones from project manager
    final List<Zone> availableZones = _projectViewModel.projectManager.getAllZones();

    if (messagePlayer != null) {
      emit(
        MessagePlayerLoaded(
          messagePlayer: messagePlayer,
          availableZones: availableZones,
        ),
      );
    } else {
      // Create a new message player if none provided
      final MessagePlayerModel newPlayer = MessagePlayerModel.create(
        name: 'Message Player',
      );
      emit(
        MessagePlayerLoaded(
          messagePlayer: newPlayer,
          availableZones: availableZones,
        ),
      );
    }
  }

  /// Add a new message to the player
  void addMessage() {
    final MessagePlayerLoaded? loaded = _loadedState;
    if (loaded == null || loaded.messagePlayer == null) return;

    final int messageCount = loaded.messagePlayer!.messages.length;
    final String defaultName = 'Untitled_${(messageCount + 1).toString().padLeft(2, '0')}';

    final MessageModel newMessage = MessageModel.create(name: defaultName);
    final List<MessageModel> updatedMessages = <MessageModel>[
      ...loaded.messagePlayer!.messages,
      newMessage,
    ];

    final MessagePlayerModel updatedPlayer = loaded.messagePlayer!.copyWith(
      messages: updatedMessages,
    );

    emit(
      loaded.copyWith(
        messagePlayer: updatedPlayer,
        selectedMessageId: newMessage.id,
      ),
    );
  }

  /// Select a message for editing
  void selectMessage(String messageId) {
    final MessagePlayerLoaded? loaded = _loadedState;
    if (loaded == null) return;

    _stopPlayback();
    emit(
      loaded.copyWith(
        selectedMessageId: messageId,
        currentPosition: Duration.zero,
        isPlaying: false,
        clearTotalDuration: true,
      ),
    );
  }

  /// Update message name
  void updateMessageName(String name) {
    final MessagePlayerLoaded? loaded = _loadedState;
    if (loaded == null || loaded.selectedMessageId == null || loaded.messagePlayer == null) return;

    final List<MessageModel> updatedMessages =
        loaded.messagePlayer!.messages
            .map(
              (MessageModel m) => m.id == loaded.selectedMessageId ? m.copyWith(name: name) : m,
            )
            .toList();

    emit(
      loaded.copyWith(
        messagePlayer: loaded.messagePlayer!.copyWith(messages: updatedMessages),
      ),
    );
  }

  /// Assign audio file to selected message
  void assignAudioFile(String audioFileId, String audioFileName) {
    final MessagePlayerLoaded? loaded = _loadedState;
    if (loaded == null || loaded.selectedMessageId == null || loaded.messagePlayer == null) return;

    final List<MessageModel> updatedMessages =
        loaded.messagePlayer!.messages
            .map(
              (MessageModel m) => m.id == loaded.selectedMessageId ? m.copyWith(audioFileId: audioFileId, audioFileName: audioFileName) : m,
            )
            .toList();

    emit(
      loaded.copyWith(
        messagePlayer: loaded.messagePlayer!.copyWith(messages: updatedMessages),
      ),
    );

    // Load the audio file for preview
    _loadAudioFile(audioFileId);
  }

  Future<void> _loadAudioFile(String audioFileId) async {
    try {
      final File file = await _projectViewModel.getMediaFileFromProject(
        mediaId: audioFileId,
      );
      await _audioPlayer.setSourceDeviceFile(file.path);
    } catch (e) {
      final MessagePlayerLoaded? loaded = _loadedState;
      if (loaded != null) {
        emit(loaded.copyWith(errorMessage: 'Failed to load audio file'));
      }
    }
  }

  /// Update gain for selected message
  void updateGain(double gain) {
    final MessagePlayerLoaded? loaded = _loadedState;
    if (loaded == null || loaded.selectedMessageId == null || loaded.messagePlayer == null) return;

    final List<MessageModel> updatedMessages =
        loaded.messagePlayer!.messages
            .map(
              (MessageModel m) => m.id == loaded.selectedMessageId ? m.copyWith(gain: gain) : m,
            )
            .toList();

    emit(
      loaded.copyWith(
        messagePlayer: loaded.messagePlayer!.copyWith(messages: updatedMessages),
      ),
    );
  }

  /// Toggle repeat for selected message
  void toggleRepeat(bool repeat) {
    final MessagePlayerLoaded? loaded = _loadedState;
    if (loaded == null || loaded.selectedMessageId == null || loaded.messagePlayer == null) return;

    final List<MessageModel> updatedMessages =
        loaded.messagePlayer!.messages
            .map(
              (MessageModel m) => m.id == loaded.selectedMessageId ? m.copyWith(repeat: repeat) : m,
            )
            .toList();

    emit(
      loaded.copyWith(
        messagePlayer: loaded.messagePlayer!.copyWith(messages: updatedMessages),
      ),
    );
  }

  /// Update repeat count for selected message
  void updateRepeatCount(int count) {
    final MessagePlayerLoaded? loaded = _loadedState;
    if (loaded == null || loaded.selectedMessageId == null || loaded.messagePlayer == null) return;

    final List<MessageModel> updatedMessages =
        loaded.messagePlayer!.messages
            .map(
              (MessageModel m) => m.id == loaded.selectedMessageId ? m.copyWith(repeatCount: count) : m,
            )
            .toList();

    emit(
      loaded.copyWith(
        messagePlayer: loaded.messagePlayer!.copyWith(messages: updatedMessages),
      ),
    );
  }

  /// Update repeat interval for selected message
  void updateRepeatInterval(int seconds) {
    final MessagePlayerLoaded? loaded = _loadedState;
    if (loaded == null || loaded.selectedMessageId == null || loaded.messagePlayer == null) return;

    final List<MessageModel> updatedMessages =
        loaded.messagePlayer!.messages
            .map(
              (MessageModel m) => m.id == loaded.selectedMessageId ? m.copyWith(repeatIntervalSeconds: seconds) : m,
            )
            .toList();

    emit(
      loaded.copyWith(
        messagePlayer: loaded.messagePlayer!.copyWith(messages: updatedMessages),
      ),
    );
  }

  /// Toggle zone assignment for selected message
  void toggleZoneAssignment(String zoneId) {
    final MessagePlayerLoaded? loaded = _loadedState;
    if (loaded == null || loaded.selectedMessageId == null || loaded.messagePlayer == null) return;

    final MessageModel? selectedMessage = loaded.selectedMessage;
    if (selectedMessage == null) return;

    List<String> updatedZoneIds;
    if (selectedMessage.assignedZoneIds.contains(zoneId)) {
      updatedZoneIds = selectedMessage.assignedZoneIds.where((String id) => id != zoneId).toList();
    } else {
      updatedZoneIds = <String>[...selectedMessage.assignedZoneIds, zoneId];
    }

    final List<MessageModel> updatedMessages =
        loaded.messagePlayer!.messages
            .map(
              (MessageModel m) => m.id == loaded.selectedMessageId ? m.copyWith(assignedZoneIds: updatedZoneIds) : m,
            )
            .toList();

    emit(
      loaded.copyWith(
        messagePlayer: loaded.messagePlayer!.copyWith(messages: updatedMessages),
      ),
    );
  }

  /// Delete selected message
  void deleteSelectedMessage() {
    final MessagePlayerLoaded? loaded = _loadedState;
    if (loaded == null || loaded.selectedMessageId == null || loaded.messagePlayer == null) return;

    _stopPlayback();

    final List<MessageModel> updatedMessages = loaded.messagePlayer!.messages.where((MessageModel m) => m.id != loaded.selectedMessageId).toList();

    emit(
      loaded.copyWith(
        messagePlayer: loaded.messagePlayer!.copyWith(messages: updatedMessages),
        clearSelectedMessage: true,
      ),
    );
  }

  /// Play/pause audio
  Future<void> togglePlayPause() async {
    final MessagePlayerLoaded? loaded = _loadedState;
    if (loaded == null || loaded.selectedMessage?.audioFileId == null) return;

    if (loaded.isPlaying) {
      await _audioPlayer.pause();
    } else {
      // Load audio if not already loaded
      if (loaded.totalDuration == null) {
        await _loadAudioFile(loaded.selectedMessage!.audioFileId!);
      }
      await _audioPlayer.resume();
    }
  }

  /// Seek audio to position
  Future<void> seekTo(Duration position) async {
    await _audioPlayer.seek(position);
  }

  void _stopPlayback() {
    _audioPlayer.stop();
    final MessagePlayerLoaded? loaded = _loadedState;
    if (loaded != null) {
      emit(
        loaded.copyWith(
          isPlaying: false,
          currentPosition: Duration.zero,
        ),
      );
    }
  }

  /// Get zone name by ID
  String getZoneName(String zoneId) {
    try {
      return state.availableZones.firstWhere((Zone z) => z.id == zoneId).name;
    } catch (e) {
      return 'Unknown Zone';
    }
  }

  /// Get list of media files for dropdown
  List<MediaFileModel> getAvailableAudioFiles() {
    return _projectViewModel.getAllMediaFiles();
  }

  /// Upload a new audio file
  Future<void> uploadAudioFile(File file, {String? fileName}) async {
    try {
      await _projectViewModel.addMediaFile(file: file, fileName: fileName);
      // Refresh the audio files list - the dropdown will rebuild with new files
    } catch (e) {
      final MessagePlayerLoaded? loaded = _loadedState;
      if (loaded != null) {
        emit(loaded.copyWith(errorMessage: 'Failed to upload audio file: $e'));
      }
    }
  }

  /// Clear error message
  void clearError() {
    final MessagePlayerLoaded? loaded = _loadedState;
    if (loaded != null) {
      emit(loaded.copyWith(clearError: true));
    }
  }

  /// Save the current message player to the project
  Future<void> saveMessagePlayer() async {
    final MessagePlayerLoaded? loaded = _loadedState;
    if (loaded == null || loaded.messagePlayer == null) return;

    try {
      emit(const MessagePlayerLoading());

      // Check if this is a new player or updating existing
      final MessagePlayerModel? existingPlayer = _projectViewModel.getMessagePlayerById(
        loaded.messagePlayer!.id,
      );

      if (existingPlayer != null) {
        await _projectViewModel.updateMessagePlayer(
          messagePlayer: loaded.messagePlayer!,
        );
      } else {
        await _projectViewModel.addMessagePlayer(
          messagePlayer: loaded.messagePlayer!,
        );
      }

      emit(loaded);
    } catch (e) {
      emit(
        loaded.copyWith(
          errorMessage: 'Failed to save message player: $e',
        ),
      );
    }
  }

  /// Load a message player from the project by ID
  void loadMessagePlayer(String messagePlayerId) {
    final MessagePlayerModel? player = _projectViewModel.getMessagePlayerById(messagePlayerId);
    final MessagePlayerLoaded? loaded = _loadedState;
    if (player != null && loaded != null) {
      emit(
        loaded.copyWith(
          messagePlayer: player,
          clearSelectedMessage: true,
        ),
      );
    }
  }

  /// Delete the current message player from the project
  Future<void> deleteMessagePlayer() async {
    final MessagePlayerLoaded? loaded = _loadedState;
    if (loaded == null || loaded.messagePlayer == null) return;

    try {
      emit(const MessagePlayerLoading());
      await _projectViewModel.removeMessagePlayer(
        messagePlayerId: loaded.messagePlayer!.id,
      );
      emit(
        MessagePlayerLoaded(
          availableZones: loaded.availableZones,
        ),
      );
    } catch (e) {
      emit(
        loaded.copyWith(
          errorMessage: 'Failed to delete message player: $e',
        ),
      );
    }
  }

  /// Get current message player (for external access)
  MessagePlayerModel? get currentMessagePlayer => state.messagePlayer;

  @override
  Future<void> close() {
    _audioPlayer.dispose();
    return super.close();
  }
}
