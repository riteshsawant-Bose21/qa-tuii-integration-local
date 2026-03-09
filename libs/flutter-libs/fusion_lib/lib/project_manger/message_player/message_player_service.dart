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

    // Link player to messages using RelationshipManager
    for (final MessageModel message in messagePlayer.messages) {
      relationships.link(
        RelationshipType.playerMessages,
        messagePlayer.id,
        message.id,
      );
    }
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

    // Remove all relationships for this player
    final MessagePlayerModel? player = getMessagePlayerById(id);
    if (player != null) {
      for (final MessageModel message in player.messages) {
        // Remove message-zone relationships
        relationships.removeAllRelationships(message.id);
      }
    }
    relationships.removeAllRelationships(id);

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

    // Link message to player
    relationships.link(
      RelationshipType.playerMessages,
      messagePlayerId,
      message.id,
    );
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

    // Remove all relationships for this message
    relationships.removeAllRelationships(messageId);

    final List<MessageModel> updatedMessages = player.messages.where((MessageModel m) => m.id != messageId).toList();
    final MessagePlayerModel updatedPlayer = player.copyWith(messages: updatedMessages);
    updateMessagePlayer(messagePlayer: updatedPlayer);
  }

  // ==================== Zone Assignment Methods ====================

  /// Assign a zone to a message
  void assignZoneToMessage({
    required String messageId,
    required String zoneId,
  }) {
    relationships.link(
      RelationshipType.messageZones,
      messageId,
      zoneId,
    );
  }

  /// Unassign a zone from a message
  void unassignZoneFromMessage({
    required String messageId,
    required String zoneId,
  }) {
    relationships.unlink(
      RelationshipType.messageZones,
      messageId,
      zoneId,
    );
  }

  /// Get all zones assigned to a message
  Set<String> getZonesForMessage(String messageId) {
    return relationships.getChildren(
      RelationshipType.messageZones,
      messageId,
    );
  }

  /// Check if a zone is assigned to a message
  bool isZoneAssignedToMessage({
    required String messageId,
    required String zoneId,
  }) {
    return getZonesForMessage(messageId).contains(zoneId);
  }

  /// Toggle zone assignment for a message
  void toggleZoneAssignmentForMessage({
    required String messageId,
    required String zoneId,
  }) {
    if (isZoneAssignedToMessage(messageId: messageId, zoneId: zoneId)) {
      unassignZoneFromMessage(messageId: messageId, zoneId: zoneId);
    } else {
      assignZoneToMessage(messageId: messageId, zoneId: zoneId);
    }
  }
}
