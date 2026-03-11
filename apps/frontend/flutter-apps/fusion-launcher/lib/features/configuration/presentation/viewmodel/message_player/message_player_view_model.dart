import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';

/// Extension on ProjectViewModel for managing Messages linked to Sources
extension MessagePlayerViewModels on ProjectViewModel {
  /// Get all messages for a source (message player)
  List<MessageModel> getMessagesForSource(String sourceId) {
    return projectManager.getMessagesForSource(sourceId);
  }

  /// Add a message to a source
  Future<void> addMessageToSource({
    required String sourceId,
    required MessageModel message,
    bool autoSave = true,
  }) async {
    if (autoSave) {
      recordSnapshot();
    }

    projectManager.addMessageToSource(
      sourceId: sourceId,
      message: message,
    );

    if (autoSave) {
      await saveProject();
    }
    updateProject();
  }

  /// Update a message
  Future<void> updateMessage({
    required MessageModel message,
    bool autoSave = true,
  }) async {
    if (autoSave) {
      recordSnapshot();
    }

    projectManager.updateMessage(message: message);

    if (autoSave) {
      await saveProject();
    }
    updateProject();
  }

  /// Remove a message from a source
  Future<void> removeMessageFromSource({
    required String sourceId,
    required String messageId,
    bool autoSave = true,
  }) async {
    if (autoSave) {
      recordSnapshot();
    }

    projectManager.removeMessageFromSource(
      sourceId: sourceId,
      messageId: messageId,
    );

    if (autoSave) {
      await saveProject();
    }
    updateProject();
  }

  /// Get a message by ID
  MessageModel? getMessageById(String messageId) {
    return projectManager.getMessageById(messageId);
  }

  // ==================== Zone Assignment Methods ====================

  /// Assign a zone to a message
  Future<void> assignZoneToMessage({
    required String messageId,
    required String zoneId,
    bool autoSave = true,
  }) async {
    if (autoSave) {
      recordSnapshot();
    }

    projectManager.assignZoneToMessage(
      messageId: messageId,
      zoneId: zoneId,
    );

    if (autoSave) {
      await saveProject();
    }
    updateProject();
  }

  /// Unassign a zone from a message
  Future<void> unassignZoneFromMessage({
    required String messageId,
    required String zoneId,
    bool autoSave = true,
  }) async {
    if (autoSave) {
      recordSnapshot();
    }

    projectManager.unassignZoneFromMessage(
      messageId: messageId,
      zoneId: zoneId,
    );

    if (autoSave) {
      await saveProject();
    }
    updateProject();
  }

  /// Get all zones assigned to a message
  Set<String> getZonesForMessage(String messageId) {
    return projectManager.getZonesForMessage(messageId);
  }

  /// Check if a zone is assigned to a message
  bool isZoneAssignedToMessage({
    required String messageId,
    required String zoneId,
  }) {
    return projectManager.isZoneAssignedToMessage(
      messageId: messageId,
      zoneId: zoneId,
    );
  }

  /// Toggle zone assignment for a message
  Future<void> toggleZoneAssignmentForMessage({
    required String messageId,
    required String zoneId,
    bool autoSave = true,
  }) async {
    if (autoSave) {
      recordSnapshot();
    }

    projectManager.toggleZoneAssignmentForMessage(
      messageId: messageId,
      zoneId: zoneId,
    );

    if (autoSave) {
      await saveProject();
    }
    updateProject();
  }
}
