import 'package:equatable/equatable.dart';
import 'package:fusion_lib/fusion_lib.dart';

/// State for the Message tab panel.
sealed class MessageState extends Equatable {
  const MessageState();

  @override
  List<Object?> get props => <Object?>[];
}

/// Initial state - no data loaded yet.
class MessageInitial extends MessageState {
  const MessageInitial();
}

/// Loading state - fetching data.
class MessageLoading extends MessageState {
  const MessageLoading();
}

/// Loaded state - message players and messages successfully loaded.
class MessageLoaded extends MessageState {
  /// All message-player sources available in the project.
  final List<Source> messagePlayers;

  /// Messages grouped by message-player source ID.
  final Map<String, List<MessageModel>> messagesPerPlayer;

  /// IDs of message players whose checkbox is checked.
  final Set<String> selectedMessagePlayerIds;

  /// The currently active/highlighted page in the PAGES panel.
  final String? selectedMessagePageId;

  /// Selected message IDs per player (checkbox state).
  final Map<String, Set<String>> selectedMessageIdsPerPlayer;

  /// The controller ID this state belongs to.
  final String? controllerId;

  const MessageLoaded({
    required this.messagePlayers,
    required this.messagesPerPlayer,
    this.selectedMessagePlayerIds = const <String>{},
    this.selectedMessagePageId,
    this.selectedMessageIdsPerPlayer = const <String, Set<String>>{},
    this.controllerId,
  });

  /// Filtered message players that are checked.
  List<Source> get checkedPlayers => messagePlayers.where((Source s) => selectedMessagePlayerIds.contains(s.id)).toList();

  /// Get selected message IDs for a specific player.
  Set<String> getSelectedMessagesForPlayer(String playerId) => selectedMessageIdsPerPlayer[playerId] ?? const <String>{};

  /// Get messages for a specific player.
  List<MessageModel> getMessagesForPlayer(String playerId) => messagesPerPlayer[playerId] ?? const <MessageModel>[];

  MessageLoaded copyWith({
    List<Source>? messagePlayers,
    Map<String, List<MessageModel>>? messagesPerPlayer,
    Set<String>? selectedMessagePlayerIds,
    Object? selectedMessagePageId = _sentinel,
    Map<String, Set<String>>? selectedMessageIdsPerPlayer,
    Object? controllerId = _sentinel,
  }) {
    return MessageLoaded(
      messagePlayers: messagePlayers ?? this.messagePlayers,
      messagesPerPlayer: messagesPerPlayer ?? this.messagesPerPlayer,
      selectedMessagePlayerIds: selectedMessagePlayerIds ?? this.selectedMessagePlayerIds,
      selectedMessagePageId: identical(selectedMessagePageId, _sentinel) ? this.selectedMessagePageId : selectedMessagePageId as String?,
      selectedMessageIdsPerPlayer: selectedMessageIdsPerPlayer ?? this.selectedMessageIdsPerPlayer,
      controllerId: identical(controllerId, _sentinel) ? this.controllerId : controllerId as String?,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    messagePlayers,
    messagesPerPlayer,
    selectedMessagePlayerIds,
    selectedMessagePageId,
    selectedMessageIdsPerPlayer,
    controllerId,
  ];
}

/// Error state - failed to load data.
class MessageError extends MessageState {
  final String message;

  const MessageError({required this.message});

  @override
  List<Object?> get props => <Object?>[message];
}

/// Sentinel for nullable copyWith parameters.
const Object _sentinel = Object();
