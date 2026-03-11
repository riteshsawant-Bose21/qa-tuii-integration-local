part of 'message_player_config_cubit.dart';

/// Base state class for the Message Player Configuration Dialog
sealed class MessagePlayerConfigState extends Equatable {
  const MessagePlayerConfigState();

  /// Get the source ID for this message player
  String? get sourceId => null;

  /// Get the messages for this source
  List<MessageModel> get messages => const <MessageModel>[];

  /// Get the ID of the currently selected message
  String? get selectedMessageId => null;

  /// Get the error message if any
  String? get errorMessage => null;

  /// Get audio playback state
  bool get isPlaying => false;
  Duration get currentPosition => Duration.zero;
  Duration? get totalDuration => null;

  /// Get available zones for assignment
  List<Zone> get availableZones => const <Zone>[];

  /// Returns true if there are no messages
  bool get hasNoMessages => messages.isEmpty;

  /// Returns the currently selected message
  MessageModel? get selectedMessage {
    if (selectedMessageId == null) return null;
    try {
      return messages.firstWhere(
        (MessageModel m) => m.id == selectedMessageId,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  List<Object?> get props => <Object?>[];
}

/// Initial state - no data loaded yet
class MessagePlayerInitial extends MessagePlayerConfigState {
  const MessagePlayerInitial();
}

/// Loading state - performing an operation
class MessagePlayerLoading extends MessagePlayerConfigState {
  const MessagePlayerLoading();
}

/// Loaded state - message player successfully loaded
class MessagePlayerLoaded extends MessagePlayerConfigState {
  @override
  final String? sourceId;

  @override
  final List<MessageModel> messages;

  @override
  final String? selectedMessageId;

  @override
  final String? errorMessage;

  @override
  final bool isPlaying;

  @override
  final Duration currentPosition;

  @override
  final Duration? totalDuration;

  @override
  final List<Zone> availableZones;

  /// Version counter to force UI rebuild when zone assignments change
  final int zoneAssignmentVersion;

  /// Version counter to force UI rebuild when media assignments change
  final int mediaAssignmentVersion;

  const MessagePlayerLoaded({
    this.sourceId,
    this.messages = const <MessageModel>[],
    this.selectedMessageId,
    this.errorMessage,
    this.isPlaying = false,
    this.currentPosition = Duration.zero,
    this.totalDuration,
    this.availableZones = const <Zone>[],
    this.zoneAssignmentVersion = 0,
    this.mediaAssignmentVersion = 0,
  });

  /// Create a copy with updated values
  MessagePlayerLoaded copyWith({
    String? sourceId,
    List<MessageModel>? messages,
    String? selectedMessageId,
    String? errorMessage,
    bool? isPlaying,
    Duration? currentPosition,
    Duration? totalDuration,
    List<Zone>? availableZones,
    int? zoneAssignmentVersion,
    int? mediaAssignmentVersion,
    bool clearSelectedMessage = false,
    bool clearError = false,
    bool clearTotalDuration = false,
  }) {
    return MessagePlayerLoaded(
      sourceId: sourceId ?? this.sourceId,
      messages: messages ?? this.messages,
      selectedMessageId: clearSelectedMessage ? null : (selectedMessageId ?? this.selectedMessageId),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isPlaying: isPlaying ?? this.isPlaying,
      currentPosition: currentPosition ?? this.currentPosition,
      totalDuration: clearTotalDuration ? null : (totalDuration ?? this.totalDuration),
      availableZones: availableZones ?? this.availableZones,
      zoneAssignmentVersion: zoneAssignmentVersion ?? this.zoneAssignmentVersion,
      mediaAssignmentVersion: mediaAssignmentVersion ?? this.mediaAssignmentVersion,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    sourceId,
    messages,
    selectedMessageId,
    errorMessage,
    isPlaying,
    currentPosition,
    totalDuration,
    availableZones,
    zoneAssignmentVersion,
    mediaAssignmentVersion,
  ];
}

/// Error state - failed to load or save message player
class MessagePlayerError extends MessagePlayerConfigState {
  final String message;

  const MessagePlayerError({required this.message});

  @override
  String? get errorMessage => message;

  @override
  List<Object?> get props => <Object?>[message];
}
