part of 'message_player_config_cubit.dart';

/// State for the Message Player Configuration Dialog
class MessagePlayerConfigState extends Equatable {
  /// The message player being configured
  final MessagePlayerModel? messagePlayer;

  /// ID of the currently selected message
  final String? selectedMessageId;

  /// Loading state
  final bool isLoading;

  /// Error message if any
  final String? errorMessage;

  /// Audio playback state
  final bool isPlaying;
  final Duration currentPosition;
  final Duration? totalDuration;

  /// Available zones for assignment
  final List<Zone> availableZones;

  const MessagePlayerConfigState({
    this.messagePlayer,
    this.selectedMessageId,
    this.isLoading = false,
    this.errorMessage,
    this.isPlaying = false,
    this.currentPosition = Duration.zero,
    this.totalDuration,
    this.availableZones = const <Zone>[],
  });

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

  MessagePlayerConfigState copyWith({
    MessagePlayerModel? messagePlayer,
    String? selectedMessageId,
    bool? isLoading,
    String? errorMessage,
    bool? isPlaying,
    Duration? currentPosition,
    Duration? totalDuration,
    List<Zone>? availableZones,
    bool clearSelectedMessage = false,
    bool clearError = false,
  }) {
    return MessagePlayerConfigState(
      messagePlayer: messagePlayer ?? this.messagePlayer,
      selectedMessageId: clearSelectedMessage ? null : (selectedMessageId ?? this.selectedMessageId),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isPlaying: isPlaying ?? this.isPlaying,
      currentPosition: currentPosition ?? this.currentPosition,
      totalDuration: totalDuration ?? this.totalDuration,
      availableZones: availableZones ?? this.availableZones,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    messagePlayer,
    selectedMessageId,
    isLoading,
    errorMessage,
    isPlaying,
    currentPosition,
    totalDuration,
    availableZones,
  ];
}
