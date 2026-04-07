import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/models/project_entities/controller.dart';
import 'package:fusion_lib/models/project_entities/controller_page_model.dart';

/// Extension on [ProjectViewModel] providing FusionController-specific
/// **write** operations with undo/redo, auto-save, and project-update signals.
extension ControllerViewModel on ProjectViewModel {
  // ─── Read ─────────────────────────────────────────────────────────────────

  FusionController? getControllerById(String controllerId) {
    try {
      return projectManager.getControllerById(controllerId);
    } catch (_) {
      return null;
    }
  }

  Set<String> getAssignedZoneIds(String controllerId) {
    try {
      return projectManager.getAssignedZoneIds(controllerId);
    } catch (_) {
      return <String>{};
    }
  }

  List<FusionController> getControllersForZone(String zoneId) {
    try {
      return projectManager.getControllersForZone(zoneId);
    } catch (_) {
      return <FusionController>[];
    }
  }

  // ─── Write ────────────────────────────────────────────────────────────────

  void assignZoneToController({
    required String controllerId,
    required String zoneId,
    bool autoSave = true,
  }) {
    try {
      if (autoSave) recordSnapshot();
      projectManager.assignZoneToController(controllerId: controllerId, zoneId: zoneId);
      if (autoSave) saveProject();
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: 'ControllerViewModel: failed to assign zone: $e');
      throwError('Failed to assign zone to controller: $e');
    }
  }

  void unassignZoneFromController({
    required String controllerId,
    required String zoneId,
    bool autoSave = true,
  }) {
    try {
      if (autoSave) recordSnapshot();
      projectManager.unassignZoneFromController(controllerId: controllerId, zoneId: zoneId);
      if (autoSave) saveProject();
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: 'ControllerViewModel: failed to unassign zone: $e');
      throwError('Failed to unassign zone from controller: $e');
    }
  }

  // ─── Pages ────────────────────────────────────────────────────────────────

  List<ControllerPageModel> getControllerPages(String controllerId) {
    try {
      return projectManager.getControllerPages(controllerId);
    } catch (_) {
      return <ControllerPageModel>[];
    }
  }

  void setControllerPages({
    required String controllerId,
    required List<ControllerPageModel> pages,
    bool autoSave = true,
  }) {
    try {
      if (autoSave) recordSnapshot();
      projectManager.setControllerPages(controllerId: controllerId, pages: pages);
      if (autoSave) saveProject();
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: 'ControllerViewModel: failed to set controller pages: $e');
      throwError('Failed to set controller pages: $e');
    }
  }

  // ─── Page-item relationships ──────────────────────────────────────────────

  Set<String> getSnapshotIdsForPage(String pageId) {
    try {
      return projectManager.getSnapshotIdsForPage(pageId);
    } catch (_) {
      return <String>{};
    }
  }

  void setSnapshotIdsForPage({
    required String pageId,
    required Set<String> snapshotIds,
    bool autoSave = false,
  }) {
    try {
      projectManager.setSnapshotIdsForPage(pageId: pageId, snapshotIds: snapshotIds);
      if (autoSave) saveProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: 'ControllerViewModel: failed to set snapshot IDs for page: $e');
    }
  }

  Set<String> getMessageIdsForPage(String pageId) {
    try {
      return projectManager.getMessageIdsForPage(pageId);
    } catch (_) {
      return <String>{};
    }
  }

  void setMessageIdsForPage({
    required String pageId,
    required Set<String> messageIds,
    bool autoSave = false,
  }) {
    try {
      projectManager.setMessageIdsForPage(pageId: pageId, messageIds: messageIds);
      if (autoSave) saveProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: 'ControllerViewModel: failed to set message IDs for page: $e');
    }
  }

  // ─── Schedule config ──────────────────────────────────────────────────────

  ControllerSchedulePageConfig getControllerScheduleConfig(String controllerId) {
    try {
      return projectManager.getControllerScheduleConfig(controllerId);
    } catch (_) {
      return const ControllerSchedulePageConfig();
    }
  }

  void setControllerScheduleConfig({
    required String controllerId,
    required ControllerSchedulePageConfig config,
    bool autoSave = true,
  }) {
    try {
      if (autoSave) recordSnapshot();
      projectManager.setControllerScheduleConfig(controllerId: controllerId, config: config);
      if (autoSave) saveProject();
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: 'ControllerViewModel: failed to set schedule config: $e');
      throwError('Failed to set controller schedule config: $e');
    }
  }

  Set<String> getSelectedScheduleIds(String controllerId) {
    try {
      return projectManager.getSelectedScheduleIds(controllerId);
    } catch (_) {
      return <String>{};
    }
  }

  void setSelectedScheduleIds({
    required String controllerId,
    required Set<String> scheduleIds,
    bool autoSave = true,
  }) {
    try {
      projectManager.setSelectedScheduleIds(controllerId: controllerId, scheduleIds: scheduleIds);
      if (autoSave) saveProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: 'ControllerViewModel: failed to set selected schedule IDs: $e');
    }
  }

  // ─── Display config ───────────────────────────────────────────────────────

  ControllerDisplayConfig getControllerDisplayConfig(String controllerId) {
    try {
      return projectManager.getControllerDisplayConfig(controllerId);
    } catch (_) {
      return const ControllerDisplayConfig();
    }
  }

  void setControllerDisplayConfig({
    required String controllerId,
    required ControllerDisplayConfig config,
    bool autoSave = true,
  }) {
    try {
      if (autoSave) recordSnapshot();
      projectManager.setControllerDisplayConfig(controllerId: controllerId, config: config);
      if (autoSave) saveProject();
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: 'ControllerViewModel: failed to set display config: $e');
      throwError('Failed to set controller display config: $e');
    }
  }

  // ─── Wall-controller config ───────────────────────────────────────────────

  WallControllerConfig getWallControllerConfig() {
    try {
      return projectManager.getWallControllerConfig();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: 'ControllerViewModel: failed to get wall controller config: $e');
      rethrow;
    }
  }
}
