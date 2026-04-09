import 'dart:async';
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

  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;

  /// Tracks whether playback has completed so we reload on next play instead of resume
  bool _isCompleted = false;

  MessagePlayerConfigCubit() : super(const MessagePlayerInitial()) {
    _initializeAudioPlayer();
  }

  ProjectViewModel get _projectViewModel => serviceLocator<ProjectViewModel>();

  /// The source ID for this message player
  String? _sourceId;

  /// Helper to get current loaded state or null
  MessagePlayerLoaded? get _loadedState {
    final MessagePlayerConfigState currentState = state;
    if (currentState is MessagePlayerLoaded) {
      return currentState;
    }
    return null;
  }

  void _initializeAudioPlayer() {
    _playerStateSubscription = _audioPlayer.onPlayerStateChanged.listen((PlayerState playerState) {
      final MessagePlayerLoaded? loaded = _loadedState;
      if (loaded == null) return;

      if (playerState == PlayerState.playing) {
        _isCompleted = false;
        emit(loaded.copyWith(isPlaying: true));
      } else if (playerState == PlayerState.paused || playerState == PlayerState.stopped) {
        emit(loaded.copyWith(isPlaying: false));
      } else if (playerState == PlayerState.completed) {
        _isCompleted = true;
        emit(loaded.copyWith(isPlaying: false, currentPosition: Duration.zero));
      }
    });

    _positionSubscription = _audioPlayer.onPositionChanged.listen((Duration position) {
      final MessagePlayerLoaded? loaded = _loadedState;
      if (loaded == null) return;
      emit(loaded.copyWith(currentPosition: position));
    });

    _durationSubscription = _audioPlayer.onDurationChanged.listen((Duration duration) {
      final MessagePlayerLoaded? loaded = _loadedState;
      if (loaded == null) return;
      emit(loaded.copyWith(totalDuration: duration));
    });
  }

  /// Initialize the cubit with a source ID
  void init({required String sourceId}) {
    _sourceId = sourceId;

    // Get available zones - only zones where this source is assigned
    final List<Zone> availableZones = _projectViewModel.projectManager.getZonesWhereSourceIsAssigned(sourceId);

    // Get messages for this source
    final List<MessageModel> messages = _projectViewModel.getMessagesForSource(sourceId);

    // Auto-select first message if available
    final String? firstMessageId = messages.isNotEmpty ? messages.first.id : null;

    emit(
      MessagePlayerLoaded(
        sourceId: sourceId,
        messages: messages,
        availableZones: availableZones,
        selectedMessageId: firstMessageId,
      ),
    );
  }

  /// Add a new message to the source
  Future<void> addMessage() async {
    final MessagePlayerLoaded? loaded = _loadedState;
    if (loaded == null || _sourceId == null) return;

    final int messageCount = loaded.messages.length;
    final String defaultName = 'Untitled_${(messageCount + 1).toString().padLeft(2, '0')}';

    final MessageModel newMessage = MessageModel.create(name: defaultName);

    // Add message to source via relationship
    await _projectViewModel.addMessageToSource(
      sourceId: _sourceId!,
      message: newMessage,
      autoSave: true,
    );

    // Refresh messages from source
    final List<MessageModel> updatedMessages = _projectViewModel.getMessagesForSource(_sourceId!);

    emit(
      loaded.copyWith(
        messages: updatedMessages,
        selectedMessageId: newMessage.id,
      ),
    );
  }

  /// Select a message for editing
  Future<void> selectMessage(String messageId) async {
    final MessagePlayerLoaded? loaded = _loadedState;
    if (loaded == null) return;

    await _stopPlayback();
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
  Future<void> updateMessageName(String name) async {
    final MessagePlayerLoaded? loaded = _loadedState;
    if (loaded == null || loaded.selectedMessageId == null) return;

    final MessageModel? currentMessage = loaded.selectedMessage;
    if (currentMessage == null) return;

    final MessageModel updatedMessage = currentMessage.copyWith(name: name);

    await _projectViewModel.updateMessage(
      message: updatedMessage,
      autoSave: true,
    );

    // Refresh messages from source
    final List<MessageModel> updatedMessages = _projectViewModel.getMessagesForSource(_sourceId!);

    emit(
      loaded.copyWith(
        messages: updatedMessages,
      ),
    );
  }

  /// Assign audio file to selected message
  Future<void> assignAudioFile(String mediaId) async {
    final MessagePlayerLoaded? loaded = _loadedState;
    if (loaded == null || loaded.selectedMessageId == null) return;

    await _projectViewModel.assignMediaToMessage(
      messageId: loaded.selectedMessageId!,
      mediaId: mediaId,
      autoSave: true,
    );

    // Increment mediaAssignmentVersion to force UI rebuild
    emit(loaded.copyWith(mediaAssignmentVersion: loaded.mediaAssignmentVersion + 1));

    // Load the audio file for preview
    _loadAudioFile(mediaId);
  }

  /// Get media file for selected message
  MediaFileModel? getMediaFileForSelectedMessage() {
    final MessagePlayerLoaded? loaded = _loadedState;
    if (loaded == null || loaded.selectedMessageId == null) return null;
    return _projectViewModel.getMediaFileForMessage(loaded.selectedMessageId!);
  }

  /// Check if selected message has media assigned
  bool hasMediaAssignedToSelectedMessage() {
    final MessagePlayerLoaded? loaded = _loadedState;
    if (loaded == null || loaded.selectedMessageId == null) return false;
    return _projectViewModel.hasMediaAssigned(loaded.selectedMessageId!);
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
  Future<void> updateGain(double gain) async {
    final MessagePlayerLoaded? loaded = _loadedState;
    if (loaded == null || loaded.selectedMessageId == null) return;

    final MessageModel? currentMessage = loaded.selectedMessage;
    if (currentMessage == null) return;

    final MessageModel updatedMessage = currentMessage.copyWith(gain: gain);

    await _projectViewModel.updateMessage(
      message: updatedMessage,
      autoSave: true,
    );

    // Refresh messages from source
    final List<MessageModel> updatedMessages = _projectViewModel.getMessagesForSource(_sourceId!);

    emit(
      loaded.copyWith(
        messages: updatedMessages,
      ),
    );
  }

  /// Toggle repeat for selected message
  Future<void> toggleRepeat(bool repeat) async {
    final MessagePlayerLoaded? loaded = _loadedState;
    if (loaded == null || loaded.selectedMessageId == null) return;

    final MessageModel? currentMessage = loaded.selectedMessage;
    if (currentMessage == null) return;

    final MessageModel updatedMessage = currentMessage.copyWith(
      repeat: repeat,
      repeatCount: repeat ? null : 1,
      repeatIntervalSeconds: repeat ? null : 5,
    );

    await _projectViewModel.updateMessage(
      message: updatedMessage,
      autoSave: true,
    );

    // Refresh messages from source
    final List<MessageModel> updatedMessages = _projectViewModel.getMessagesForSource(_sourceId!);

    emit(
      loaded.copyWith(
        messages: updatedMessages,
      ),
    );
  }

  /// Update repeat count for selected message
  Future<void> updateRepeatCount(int count) async {
    final MessagePlayerLoaded? loaded = _loadedState;
    if (loaded == null || loaded.selectedMessageId == null) return;

    final MessageModel? currentMessage = loaded.selectedMessage;
    if (currentMessage == null) return;

    final MessageModel updatedMessage = currentMessage.copyWith(repeatCount: count);

    await _projectViewModel.updateMessage(
      message: updatedMessage,
      autoSave: true,
    );

    // Refresh messages from source
    final List<MessageModel> updatedMessages = _projectViewModel.getMessagesForSource(_sourceId!);

    emit(
      loaded.copyWith(
        messages: updatedMessages,
      ),
    );
  }

  /// Update repeat interval for selected message
  Future<void> updateRepeatInterval(int seconds) async {
    final MessagePlayerLoaded? loaded = _loadedState;
    if (loaded == null || loaded.selectedMessageId == null) return;

    final MessageModel? currentMessage = loaded.selectedMessage;
    if (currentMessage == null) return;

    final MessageModel updatedMessage = currentMessage.copyWith(repeatIntervalSeconds: seconds);

    await _projectViewModel.updateMessage(
      message: updatedMessage,
      autoSave: true,
    );

    // Refresh messages from source
    final List<MessageModel> updatedMessages = _projectViewModel.getMessagesForSource(_sourceId!);

    emit(
      loaded.copyWith(
        messages: updatedMessages,
      ),
    );
  }

  /// Toggle zone assignment for selected message
  Future<void> toggleZoneAssignment(String zoneId) async {
    final MessagePlayerLoaded? loaded = _loadedState;
    if (loaded == null || loaded.selectedMessageId == null) return;

    await _projectViewModel.toggleZoneAssignmentForMessage(
      messageId: loaded.selectedMessageId!,
      zoneId: zoneId,
      autoSave: true,
    );

    // Increment zoneAssignmentVersion to force UI rebuild
    emit(loaded.copyWith(zoneAssignmentVersion: loaded.zoneAssignmentVersion + 1));
  }

  /// Get zones assigned to selected message
  Set<String> getAssignedZonesForSelectedMessage() {
    final MessagePlayerLoaded? loaded = _loadedState;
    if (loaded == null || loaded.selectedMessageId == null) return <String>{};

    return _projectViewModel.getZonesForMessage(loaded.selectedMessageId!);
  }

  /// Get assigned zones as Zone objects for the selected message
  Set<Zone> getAssignedZonesAsSet() {
    final MessagePlayerLoaded? loaded = _loadedState;
    if (loaded == null || loaded.selectedMessageId == null) return <Zone>{};

    final Set<String> assignedZoneIds = getAssignedZonesForSelectedMessage();
    return loaded.availableZones.where((Zone z) => assignedZoneIds.contains(z.id)).toSet();
  }

  /// Update zone assignments for selected message
  /// Compares the new selection with current assignments and toggles accordingly
  Future<void> updateZoneAssignments(Set<Zone> selectedZones) async {
    final MessagePlayerLoaded? loaded = _loadedState;
    if (loaded == null || loaded.selectedMessageId == null) return;

    final Set<String> currentAssignedIds = getAssignedZonesForSelectedMessage();
    final Set<String> selectedIds = selectedZones.map((Zone z) => z.id).toSet();

    // Find zones to add
    final Set<String> zonesToAdd = selectedIds.difference(currentAssignedIds);
    // Find zones to remove
    final Set<String> zonesToRemove = currentAssignedIds.difference(selectedIds);

    for (final String zoneId in zonesToAdd) {
      await toggleZoneAssignment(zoneId);
    }
    for (final String zoneId in zonesToRemove) {
      await toggleZoneAssignment(zoneId);
    }
  }

  /// Check if a zone is assigned to selected message
  bool isZoneAssignedToSelectedMessage(String zoneId) {
    final MessagePlayerLoaded? loaded = _loadedState;
    if (loaded == null || loaded.selectedMessageId == null) return false;

    return _projectViewModel.isZoneAssignedToMessage(
      messageId: loaded.selectedMessageId!,
      zoneId: zoneId,
    );
  }

  /// Delete selected message
  Future<void> deleteSelectedMessage() async {
    final MessagePlayerLoaded? loaded = _loadedState;
    if (loaded == null || loaded.selectedMessageId == null || _sourceId == null) return;

    await _stopPlayback();

    await _projectViewModel.removeMessageFromSource(
      sourceId: _sourceId!,
      messageId: loaded.selectedMessageId!,
      autoSave: true,
    );

    // Refresh messages from source
    final List<MessageModel> updatedMessages = _projectViewModel.getMessagesForSource(_sourceId!);

    // Select first message if available
    final String? newSelectedId = updatedMessages.isNotEmpty ? updatedMessages.first.id : null;

    emit(
      loaded.copyWith(
        messages: updatedMessages,
        selectedMessageId: newSelectedId,
        clearSelectedMessage: newSelectedId == null,
      ),
    );
  }

  /// Play/pause audio
  Future<void> togglePlayPause() async {
    final MessagePlayerLoaded? loaded = _loadedState;
    if (loaded == null || !hasMediaAssignedToSelectedMessage()) return;

    final MediaFileModel? mediaFile = getMediaFileForSelectedMessage();
    if (mediaFile == null) return;

    if (loaded.isPlaying) {
      await _audioPlayer.pause();
    } else {
      // Reload if source not yet set, or if previous playback completed
      // (calling resume() on a completed player causes a TimeoutException)
      if (loaded.totalDuration == null || _isCompleted) {
        await _loadAudioFile(mediaFile.id);
        _isCompleted = false;
        // Restore any seek position the user dragged to before pressing play
        if (loaded.currentPosition > Duration.zero) {
          await _audioPlayer.seek(loaded.currentPosition);
        }
      }
      await _audioPlayer.resume();
    }
  }

  /// Seek audio to position
  Future<void> seekTo(Duration position) async {
    await _audioPlayer.seek(position);
    // Update state immediately — onPositionChanged stream may not fire when paused/stopped
    final MessagePlayerLoaded? loaded = _loadedState;
    if (loaded != null) {
      emit(loaded.copyWith(currentPosition: position));
    }
  }

  Future<void> _stopPlayback() async {
    await _audioPlayer.stop();
    await _audioPlayer.release();
    final MessagePlayerLoaded? loaded = _loadedState;
    if (loaded != null) {
      emit(
        loaded.copyWith(
          isPlaying: false,
          currentPosition: Duration.zero,
          clearTotalDuration: true,
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

  @override
  Future<void> close() async {
    await _playerStateSubscription?.cancel();
    await _positionSubscription?.cancel();
    await _durationSubscription?.cancel();
    await _audioPlayer.dispose();
    return super.close();
  }
}
