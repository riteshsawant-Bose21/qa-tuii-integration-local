import 'package:fusion_lib/fusion_lib.dart';

/// Extension on ProjectManager for managing Message Players
extension MessagePlayerManager on ProjectManager {
  /// Get all message players
  List<MessagePlayerModel> getAllMessagePlayers() {
    if (projectService == null) {
      throw Exception("ProjectService is not initialized.");
    }
    return projectService!.getAllMessagePlayers();
  }

  /// Get a message player by ID
  MessagePlayerModel? getMessagePlayerById(String id) {
    if (projectService == null) {
      throw Exception("ProjectService is not initialized.");
    }
    return projectService!.getMessagePlayerById(id);
  }

  /// Add a new message player
  void addMessagePlayer({required MessagePlayerModel messagePlayer}) {
    if (projectService == null) {
      throw Exception("ProjectService is not initialized.");
    }
    projectService!.addMessagePlayer(messagePlayer: messagePlayer);
  }

  /// Update an existing message player
  void updateMessagePlayer({required MessagePlayerModel messagePlayer}) {
    if (projectService == null) {
      throw Exception("ProjectService is not initialized.");
    }
    projectService!.updateMessagePlayer(messagePlayer: messagePlayer);
  }

  /// Remove a message player by ID
  void removeMessagePlayerById(String id) {
    if (projectService == null) {
      throw Exception("ProjectService is not initialized.");
    }
    projectService!.removeMessagePlayerById(id);
  }

  /// Add a message to a message player
  void addMessageToPlayer({
    required String messagePlayerId,
    required MessageModel message,
  }) {
    if (projectService == null) {
      throw Exception("ProjectService is not initialized.");
    }
    projectService!.addMessageToPlayer(
      messagePlayerId: messagePlayerId,
      message: message,
    );
  }

  /// Update a message in a message player
  void updateMessageInPlayer({
    required String messagePlayerId,
    required MessageModel message,
  }) {
    if (projectService == null) {
      throw Exception("ProjectService is not initialized.");
    }
    projectService!.updateMessageInPlayer(
      messagePlayerId: messagePlayerId,
      message: message,
    );
  }

  /// Remove a message from a message player
  void removeMessageFromPlayer({
    required String messagePlayerId,
    required String messageId,
  }) {
    if (projectService == null) {
      throw Exception("ProjectService is not initialized.");
    }
    projectService!.removeMessageFromPlayer(
      messagePlayerId: messagePlayerId,
      messageId: messageId,
    );
  }

  /// Create a new message player with default settings
  MessagePlayerModel createNewMessagePlayer({
    String? name,
    bool isZoneSelectType = false,
  }) {
    final List<MessagePlayerModel> existingPlayers = getAllMessagePlayers();
    final String defaultName = name ?? 'Message Player ${existingPlayers.length + 1}';

    return MessagePlayerModel.create(
      name: defaultName,
      isZoneSelectType: isZoneSelectType,
    );
  }

  // ==================== Zone Assignment Methods ====================

  /// Assign a zone to a message
  void assignZoneToMessage({
    required String messageId,
    required String zoneId,
  }) {
    if (projectService == null) {
      throw Exception("ProjectService is not initialized.");
    }
    projectService!.assignZoneToMessage(
      messageId: messageId,
      zoneId: zoneId,
    );
  }

  /// Unassign a zone from a message
  void unassignZoneFromMessage({
    required String messageId,
    required String zoneId,
  }) {
    if (projectService == null) {
      throw Exception("ProjectService is not initialized.");
    }
    projectService!.unassignZoneFromMessage(
      messageId: messageId,
      zoneId: zoneId,
    );
  }

  /// Get all zones assigned to a message
  Set<String> getZonesForMessage(String messageId) {
    if (projectService == null) {
      throw Exception("ProjectService is not initialized.");
    }
    return projectService!.getZonesForMessage(messageId);
  }

  /// Check if a zone is assigned to a message
  bool isZoneAssignedToMessage({
    required String messageId,
    required String zoneId,
  }) {
    if (projectService == null) {
      throw Exception("ProjectService is not initialized.");
    }
    return projectService!.isZoneAssignedToMessage(
      messageId: messageId,
      zoneId: zoneId,
    );
  }

  /// Toggle zone assignment for a message
  void toggleZoneAssignmentForMessage({
    required String messageId,
    required String zoneId,
  }) {
    if (projectService == null) {
      throw Exception("ProjectService is not initialized.");
    }
    projectService!.toggleZoneAssignmentForMessage(
      messageId: messageId,
      zoneId: zoneId,
    );
  }
}
