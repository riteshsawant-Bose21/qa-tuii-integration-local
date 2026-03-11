import 'package:fusion_lib/fusion_lib.dart';

/// Extension on ProjectService for managing Messages linked to Sources
extension MessagePlayerService on ProjectService {
  /// Add a message to the messages repository
  void addMessage({required MessageModel message}) {
    messages.add(message.id, message);
  }

  /// Link a message to a source
  void linkMessageToSource({required String sourceId, required String messageId}) {
    relationships.link(
      RelationshipType.sourceMessages,
      sourceId,
      messageId,
    );
  }

  /// Add a message and link it to a source
  void addMessageToSource({required String sourceId, required MessageModel message}) {
    addMessage(message: message);
    linkMessageToSource(sourceId: sourceId, messageId: message.id);
  }

  /// Get all messages for a source
  List<MessageModel> getMessagesForSource({required String sourceId}) {
    final Set<String> messageIds = relationships.getChildren(
      RelationshipType.sourceMessages,
      sourceId,
    );
    return messageIds.map((String id) => messages.get(id)).whereType<MessageModel>().toList();
  }

  /// Link a message to a zone
  void linkMessageToZone({required String zoneId, required String messageId}) {
    relationships.link(
      RelationshipType.messageZones,
      messageId,
      zoneId,
    );
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
