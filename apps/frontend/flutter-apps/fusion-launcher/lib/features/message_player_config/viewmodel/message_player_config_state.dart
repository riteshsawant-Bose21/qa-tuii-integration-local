part of 'message_player_config_cubit.dart';

/// Base state class for the Message Player Configuration Dialog
sealed class MessagePlayerConfigState extends Equatable {
  const MessagePlayerConfigState();

  /// Get the message player being configured
  MessagePlayerModel? get messagePlayer => null;

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

  /// Returns true if there are no messages in the player
  bool get hasNoMessages => messagePlayer?.messages.isEmpty ?? true;

  /// Returns the currently selected message
  MessageModel? get selectedMessage {
    if (selectedMessageId == null || messagePlayer == null) return null;
    try {
      return messagePlayer!.messages.firstWhere(
        (MessageModel m) => m.id == selectedMessageId,
      );
    } catch (e) {
      return null;
    }
  }

  /// Returns all messages in the player
  List<MessageModel> get messages => messagePlayer?.messages ?? <MessageModel>[];

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
  final MessagePlayerModel? messagePlayer;

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

  const MessagePlayerLoaded({
    this.messagePlayer,
    this.selectedMessageId,
    this.errorMessage,
    this.isPlaying = false,
    this.currentPosition = Duration.zero,
    this.totalDuration,
    this.availableZones = const <Zone>[],
  });

  /// Create a copy with updated values
  MessagePlayerLoaded copyWith({
    MessagePlayerModel? messagePlayer,
    String? selectedMessageId,
    String? errorMessage,
    bool? isPlaying,
    Duration? currentPosition,
    Duration? totalDuration,
    List<Zone>? availableZones,
    bool clearSelectedMessage = false,
    bool clearError = false,
    bool clearTotalDuration = false,
  }) {
    return MessagePlayerLoaded(
      messagePlayer: messagePlayer ?? this.messagePlayer,
      selectedMessageId: clearSelectedMessage ? null : (selectedMessageId ?? this.selectedMessageId),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isPlaying: isPlaying ?? this.isPlaying,
      currentPosition: currentPosition ?? this.currentPosition,
      totalDuration: clearTotalDuration ? null : (totalDuration ?? this.totalDuration),
      availableZones: availableZones ?? this.availableZones,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    messagePlayer,
    selectedMessageId,
    errorMessage,
    isPlaying,
    currentPosition,
    totalDuration,
    availableZones,
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
