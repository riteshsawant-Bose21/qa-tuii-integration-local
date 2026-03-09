import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';

/// Extension on ProjectViewModel for managing Message Players
extension MessagePlayerViewModels on ProjectViewModel {
  /// Get all message players from the project
  List<MessagePlayerModel> getAllMessagePlayers() {
    return projectManager.getAllMessagePlayers();
  }

  /// Get a message player by ID
  MessagePlayerModel? getMessagePlayerById(String id) {
    try {
      return projectManager.getMessagePlayerById(id);
    } catch (ex) {
      FusionLogger.log(tag: LogTag.project, message: "Error getting message player by id: $ex");
      return null;
    }
  }

  /// Add a new message player
  Future<void> addMessagePlayer({
    required MessagePlayerModel messagePlayer,
    bool autoSave = true,
  }) async {
    if (autoSave) {
      recordSnapshot();
    }

    projectManager.addMessagePlayer(messagePlayer: messagePlayer);

    if (autoSave) {
      await saveProject();
    }
    updateProject();
  }

  /// Update an existing message player
  Future<void> updateMessagePlayer({
    required MessagePlayerModel messagePlayer,
    bool autoSave = true,
  }) async {
    if (autoSave) {
      recordSnapshot();
    }

    projectManager.updateMessagePlayer(messagePlayer: messagePlayer);

    if (autoSave) {
      await saveProject();
    }
    updateProject();
  }

  /// Remove a message player by ID
  Future<void> removeMessagePlayer({
    required String messagePlayerId,
    bool autoSave = true,
  }) async {
    if (autoSave) {
      recordSnapshot();
    }

    projectManager.removeMessagePlayerById(messagePlayerId);

    if (autoSave) {
      await saveProject();
    }
    updateProject();
  }

  /// Add a message to a specific message player
  Future<void> addMessageToPlayer({
    required String messagePlayerId,
    required MessageModel message,
    bool autoSave = true,
  }) async {
    if (autoSave) {
      recordSnapshot();
    }

    projectManager.addMessageToPlayer(
      messagePlayerId: messagePlayerId,
      message: message,
    );

    if (autoSave) {
      await saveProject();
    }
    updateProject();
  }

  /// Update a message in a specific message player
  Future<void> updateMessageInPlayer({
    required String messagePlayerId,
    required MessageModel message,
    bool autoSave = true,
  }) async {
    if (autoSave) {
      recordSnapshot();
    }

    projectManager.updateMessageInPlayer(
      messagePlayerId: messagePlayerId,
      message: message,
    );

    if (autoSave) {
      await saveProject();
    }
    updateProject();
  }

  /// Remove a message from a specific message player
  Future<void> removeMessageFromPlayer({
    required String messagePlayerId,
    required String messageId,
    bool autoSave = true,
  }) async {
    if (autoSave) {
      recordSnapshot();
    }

    projectManager.removeMessageFromPlayer(
      messagePlayerId: messagePlayerId,
      messageId: messageId,
    );

    if (autoSave) {
      await saveProject();
    }
    updateProject();
  }

  /// Create a new message player with default settings
  MessagePlayerModel createNewMessagePlayer({String? name, bool isZoneSelectType = false}) {
    return projectManager.createNewMessagePlayer(
      name: name,
      isZoneSelectType: isZoneSelectType,
    );
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
