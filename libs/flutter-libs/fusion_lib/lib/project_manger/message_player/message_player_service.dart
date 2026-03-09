import 'package:fusion_lib/fusion_lib.dart';

/// Extension on ProjectService for managing Message Players
extension MessagePlayerService on ProjectService {
  /// Get all message players
  List<MessagePlayerModel> getAllMessagePlayers() {
    return messagePlayers.getAll();
  }

  /// Get a message player by ID
  MessagePlayerModel? getMessagePlayerById(String id) {
    return messagePlayers.get(id);
  }

  /// Add a new message player
  void addMessagePlayer({required MessagePlayerModel messagePlayer}) {
    messagePlayers.add(messagePlayer.id, messagePlayer);
  }

  /// Update an existing message player
  void updateMessagePlayer({required MessagePlayerModel messagePlayer}) {
    if (!messagePlayers.exists(messagePlayer.id)) {
      throw Exception("Message player with id ${messagePlayer.id} does not exist.");
    }
    messagePlayers.add(messagePlayer.id, messagePlayer);
  }

  /// Remove a message player by ID
  void removeMessagePlayerById(String id) {
    if (!messagePlayers.exists(id)) {
      throw Exception("Message player with id $id does not exist.");
    }
    messagePlayers.remove(id);
  }

  /// Add a message to a message player
  void addMessageToPlayer({
    required String messagePlayerId,
    required MessageModel message,
  }) {
    final MessagePlayerModel? player = getMessagePlayerById(messagePlayerId);
    if (player == null) {
      throw Exception("Message player with id $messagePlayerId does not exist.");
    }

    final List<MessageModel> updatedMessages = <MessageModel>[...player.messages, message];
    final MessagePlayerModel updatedPlayer = player.copyWith(messages: updatedMessages);
    updateMessagePlayer(messagePlayer: updatedPlayer);
  }

  /// Update a message in a message player
  void updateMessageInPlayer({
    required String messagePlayerId,
    required MessageModel message,
  }) {
    final MessagePlayerModel? player = getMessagePlayerById(messagePlayerId);
    if (player == null) {
      throw Exception("Message player with id $messagePlayerId does not exist.");
    }

    final List<MessageModel> updatedMessages = player.messages.map((MessageModel m) => m.id == message.id ? message : m).toList();
    final MessagePlayerModel updatedPlayer = player.copyWith(messages: updatedMessages);
    updateMessagePlayer(messagePlayer: updatedPlayer);
  }

  /// Remove a message from a message player
  void removeMessageFromPlayer({
    required String messagePlayerId,
    required String messageId,
  }) {
    final MessagePlayerModel? player = getMessagePlayerById(messagePlayerId);
    if (player == null) {
      throw Exception("Message player with id $messagePlayerId does not exist.");
    }

    final List<MessageModel> updatedMessages = player.messages.where((MessageModel m) => m.id != messageId).toList();
    final MessagePlayerModel updatedPlayer = player.copyWith(messages: updatedMessages);
    updateMessagePlayer(messagePlayer: updatedPlayer);
  }
}
