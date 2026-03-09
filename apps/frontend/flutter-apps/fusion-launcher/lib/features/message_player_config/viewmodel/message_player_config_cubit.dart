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

  MessagePlayerConfigCubit() : super(const MessagePlayerConfigState()) {
    _initializeAudioPlayer();
  }

  ProjectViewModel get _projectViewModel => serviceLocator<ProjectViewModel>();

  void _initializeAudioPlayer() {
    _audioPlayer.onPlayerStateChanged.listen((PlayerState playerState) {
      if (playerState == PlayerState.playing) {
        emit(state.copyWith(isPlaying: true));
      } else if (playerState == PlayerState.paused || playerState == PlayerState.stopped || playerState == PlayerState.completed) {
        emit(state.copyWith(isPlaying: false));
      }
    });

    _audioPlayer.onPositionChanged.listen((Duration position) {
      emit(state.copyWith(currentPosition: position));
    });

    _audioPlayer.onDurationChanged.listen((Duration duration) {
      emit(state.copyWith(totalDuration: duration));
    });
  }

  /// Initialize the cubit with a message player
  void init({MessagePlayerModel? messagePlayer, String? messagePlayerId}) {
    // Get available zones from project manager
    final List<Zone> availableZones = _projectViewModel.projectManager.getAllZones();

    if (messagePlayer != null) {
      emit(
        state.copyWith(
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
        state.copyWith(
          messagePlayer: newPlayer,
          availableZones: availableZones,
        ),
      );
    }
  }

  /// Add a new message to the player
  void addMessage() {
    if (state.messagePlayer == null) return;

    final int messageCount = state.messagePlayer!.messages.length;
    final String defaultName = 'Untitled_${(messageCount + 1).toString().padLeft(2, '0')}';

    final MessageModel newMessage = MessageModel.create(name: defaultName);
    final List<MessageModel> updatedMessages = <MessageModel>[
      ...state.messagePlayer!.messages,
      newMessage,
    ];

    final MessagePlayerModel updatedPlayer = state.messagePlayer!.copyWith(
      messages: updatedMessages,
    );

    emit(
      state.copyWith(
        messagePlayer: updatedPlayer,
        selectedMessageId: newMessage.id,
      ),
    );
  }

  /// Select a message for editing
  void selectMessage(String messageId) {
    _stopPlayback();
    emit(
      state.copyWith(
        selectedMessageId: messageId,
        currentPosition: Duration.zero,
        isPlaying: false,
      ),
    );
  }

  /// Update message name
  void updateMessageName(String name) {
    if (state.selectedMessageId == null || state.messagePlayer == null) return;

    final List<MessageModel> updatedMessages =
        state.messagePlayer!.messages
            .map(
              (MessageModel m) => m.id == state.selectedMessageId ? m.copyWith(name: name) : m,
            )
            .toList();

    emit(
      state.copyWith(
        messagePlayer: state.messagePlayer!.copyWith(messages: updatedMessages),
      ),
    );
  }

  /// Assign audio file to selected message
  void assignAudioFile(String audioFileId, String audioFileName) {
    if (state.selectedMessageId == null || state.messagePlayer == null) return;

    final List<MessageModel> updatedMessages =
        state.messagePlayer!.messages
            .map(
              (MessageModel m) => m.id == state.selectedMessageId ? m.copyWith(audioFileId: audioFileId, audioFileName: audioFileName) : m,
            )
            .toList();

    emit(
      state.copyWith(
        messagePlayer: state.messagePlayer!.copyWith(messages: updatedMessages),
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
      emit(state.copyWith(errorMessage: 'Failed to load audio file'));
    }
  }

  /// Update gain for selected message
  void updateGain(double gain) {
    if (state.selectedMessageId == null || state.messagePlayer == null) return;

    final List<MessageModel> updatedMessages =
        state.messagePlayer!.messages
            .map(
              (MessageModel m) => m.id == state.selectedMessageId ? m.copyWith(gain: gain) : m,
            )
            .toList();

    emit(
      state.copyWith(
        messagePlayer: state.messagePlayer!.copyWith(messages: updatedMessages),
      ),
    );
  }

  /// Toggle repeat for selected message
  void toggleRepeat(bool repeat) {
    if (state.selectedMessageId == null || state.messagePlayer == null) return;

    final List<MessageModel> updatedMessages =
        state.messagePlayer!.messages
            .map(
              (MessageModel m) => m.id == state.selectedMessageId ? m.copyWith(repeat: repeat) : m,
            )
            .toList();

    emit(
      state.copyWith(
        messagePlayer: state.messagePlayer!.copyWith(messages: updatedMessages),
      ),
    );
  }

  /// Update repeat count for selected message
  void updateRepeatCount(int count) {
    if (state.selectedMessageId == null || state.messagePlayer == null) return;

    final List<MessageModel> updatedMessages =
        state.messagePlayer!.messages
            .map(
              (MessageModel m) => m.id == state.selectedMessageId ? m.copyWith(repeatCount: count) : m,
            )
            .toList();

    emit(
      state.copyWith(
        messagePlayer: state.messagePlayer!.copyWith(messages: updatedMessages),
      ),
    );
  }

  /// Update repeat interval for selected message
  void updateRepeatInterval(int seconds) {
    if (state.selectedMessageId == null || state.messagePlayer == null) return;

    final List<MessageModel> updatedMessages =
        state.messagePlayer!.messages
            .map(
              (MessageModel m) => m.id == state.selectedMessageId ? m.copyWith(repeatIntervalSeconds: seconds) : m,
            )
            .toList();

    emit(
      state.copyWith(
        messagePlayer: state.messagePlayer!.copyWith(messages: updatedMessages),
      ),
    );
  }

  /// Toggle zone assignment for selected message
  void toggleZoneAssignment(String zoneId) {
    if (state.selectedMessageId == null || state.messagePlayer == null) return;

    final MessageModel? selectedMessage = state.selectedMessage;
    if (selectedMessage == null) return;

    List<String> updatedZoneIds;
    if (selectedMessage.assignedZoneIds.contains(zoneId)) {
      updatedZoneIds = selectedMessage.assignedZoneIds.where((String id) => id != zoneId).toList();
    } else {
      updatedZoneIds = <String>[...selectedMessage.assignedZoneIds, zoneId];
    }

    final List<MessageModel> updatedMessages =
        state.messagePlayer!.messages
            .map(
              (MessageModel m) => m.id == state.selectedMessageId ? m.copyWith(assignedZoneIds: updatedZoneIds) : m,
            )
            .toList();

    emit(
      state.copyWith(
        messagePlayer: state.messagePlayer!.copyWith(messages: updatedMessages),
      ),
    );
  }

  /// Delete selected message
  void deleteSelectedMessage() {
    if (state.selectedMessageId == null || state.messagePlayer == null) return;

    _stopPlayback();

    final List<MessageModel> updatedMessages = state.messagePlayer!.messages.where((MessageModel m) => m.id != state.selectedMessageId).toList();

    emit(
      state.copyWith(
        messagePlayer: state.messagePlayer!.copyWith(messages: updatedMessages),
        clearSelectedMessage: true,
      ),
    );
  }

  /// Play/pause audio
  Future<void> togglePlayPause() async {
    if (state.selectedMessage?.audioFileId == null) return;

    if (state.isPlaying) {
      await _audioPlayer.pause();
    } else {
      // Load audio if not already loaded
      if (state.totalDuration == null) {
        await _loadAudioFile(state.selectedMessage!.audioFileId!);
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
    emit(
      state.copyWith(
        isPlaying: false,
        currentPosition: Duration.zero,
      ),
    );
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

  /// Clear error message
  void clearError() {
    emit(state.copyWith(clearError: true));
  }

  /// Save the current message player to the project
  Future<void> saveMessagePlayer() async {
    if (state.messagePlayer == null) return;

    try {
      emit(state.copyWith(isLoading: true));

      // Check if this is a new player or updating existing
      final MessagePlayerModel? existingPlayer = _projectViewModel.getMessagePlayerById(
        state.messagePlayer!.id,
      );

      if (existingPlayer != null) {
        await _projectViewModel.updateMessagePlayer(
          messagePlayer: state.messagePlayer!,
        );
      } else {
        await _projectViewModel.addMessagePlayer(
          messagePlayer: state.messagePlayer!,
        );
      }

      emit(state.copyWith(isLoading: false));
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to save message player: $e',
        ),
      );
    }
  }

  /// Load a message player from the project by ID
  void loadMessagePlayer(String messagePlayerId) {
    final MessagePlayerModel? player = _projectViewModel.getMessagePlayerById(messagePlayerId);
    if (player != null) {
      emit(
        state.copyWith(
          messagePlayer: player,
          clearSelectedMessage: true,
        ),
      );
    }
  }

  /// Delete the current message player from the project
  Future<void> deleteMessagePlayer() async {
    if (state.messagePlayer == null) return;

    try {
      emit(state.copyWith(isLoading: true));
      await _projectViewModel.removeMessagePlayer(
        messagePlayerId: state.messagePlayer!.id,
      );
      emit(
        state.copyWith(
          isLoading: false,
          messagePlayer: null,
          clearSelectedMessage: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
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
