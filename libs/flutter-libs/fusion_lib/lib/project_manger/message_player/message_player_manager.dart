import 'package:fusion_lib/fusion_lib.dart';

/// Extension on ProjectManager for managing Messages linked to Sources
extension MessagePlayerManager on ProjectManager {
  /// Get all messages for a source (message player)
  List<MessageModel> getMessagesForSource(String sourceId) {
    if (projectService == null) {
      throw Exception("ProjectService is not initialized.");
    }
    return projectService!.getMessagesForSource(sourceId: sourceId);
  }

  /// Add a message and link it to a source
  void addMessageToSource({
    required String sourceId,
    required MessageModel message,
  }) {
    if (projectService == null) {
      throw Exception("ProjectService is not initialized.");
    }
    projectService!.addMessageToSource(sourceId: sourceId, message: message);
  }

  /// Update a message
  void updateMessage({required MessageModel message}) {
    if (projectService == null) {
      throw Exception("ProjectService is not initialized.");
    }
    projectService!.messages.add(message.id, message);
  }

  /// Remove a message from a source
  void removeMessageFromSource({
    required String sourceId,
    required String messageId,
  }) {
    if (projectService == null) {
      throw Exception("ProjectService is not initialized.");
    }
    // Unlink from source
    projectService!.relationships.unlink(
      RelationshipType.sourceMessages,
      sourceId,
      messageId,
    );
    // Remove all zone relationships for this message
    projectService!.relationships.removeAllRelationships(messageId);
    // Remove the message itself
    projectService!.messages.remove(messageId);
  }

  /// Get a message by ID
  MessageModel? getMessageById(String messageId) {
    if (projectService == null) {
      throw Exception("ProjectService is not initialized.");
    }
    return projectService!.messages.get(messageId);
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
