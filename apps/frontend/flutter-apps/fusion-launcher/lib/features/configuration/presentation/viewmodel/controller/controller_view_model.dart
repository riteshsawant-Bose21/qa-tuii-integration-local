import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/models/project_entities/controller.dart';
import 'package:fusion_lib/models/project_entities/controller_page_model.dart';

/// Extension on [ProjectViewModel] providing FusionController-specific
/// **write** operations with undo/redo, auto-save, and project-update signals.
///
/// The **read** getter `fusionControllers` intentionally lives in
/// [ProjectPropertiesViewModel] alongside `fusionEndpoints`, `sources`, etc.
/// so all screens share the same single access point.
///
/// Mirrors the [SubzoneViewModel] / [HardwareViewModel] pattern.
extension ControllerViewModel on ProjectViewModel {
  // ─── Read ─────────────────────────────────────────────────────────────────

  /// Returns the [FusionController] with [controllerId], or null if not found.
  FusionController? getControllerById(String controllerId) {
    try {
      return projectManager.getControllerById(controllerId);
    } catch (_) {
      return null;
    }
  }

  /// Zone / sub-zone IDs assigned to [controllerId] via [RelationshipType.controllerZones].
  Set<String> getAssignedZoneIds(String controllerId) {
    try {
      return projectManager.getAssignedZoneIds(controllerId);
    } catch (_) {
      return <String>{};
    }
  }

  /// Returns controllers that have [zoneId] in their assigned zone IDs.
  List<FusionController> getControllersForZone(String zoneId) {
    try {
      return projectManager.getControllersForZone(zoneId);
    } catch (_) {
      return <FusionController>[];
    }
  }

  // ─── Write ────────────────────────────────────────────────────────────────

  // ─── Zone-assignment ──────────────────────────────────────────────────────

  /// Assigns [zoneId] to the controller and persists.
  void assignZoneToController({
    required String controllerId,
    required String zoneId,
    bool autoSave = true,
  }) {
    try {
      if (autoSave) recordSnapshot();
      projectManager.assignZoneToController(
        controllerId: controllerId,
        zoneId: zoneId,
      );
      if (autoSave) saveProject();
      updateProject();
    } catch (e) {
      FusionLogger.log(
        tag: LogTag.project,
        message: 'ControllerViewModel: failed to assign zone: $e',
      );
      throwError('Failed to assign zone to controller: $e');
    }
  }

  /// Removes [zoneId] from the controller's zone list and persists.
  void unassignZoneFromController({
    required String controllerId,
    required String zoneId,
    bool autoSave = true,
  }) {
    try {
      if (autoSave) recordSnapshot();
      projectManager.unassignZoneFromController(
        controllerId: controllerId,
        zoneId: zoneId,
      );
      if (autoSave) saveProject();
      updateProject();
    } catch (e) {
      FusionLogger.log(
        tag: LogTag.project,
        message: 'ControllerViewModel: failed to unassign zone: $e',
      );
      throwError('Failed to unassign zone from controller: $e');
    }
  }

  // ─── Page-assignment (controllerSnapshotPages) ──────────────────────────

  /// Page IDs linked to [controllerId] via [RelationshipType.controllerSnapshotPages].
  Set<String> getControllerPageIds(String controllerId) {
    try {
      return projectManager.getControllerPageIds(controllerId);
    } catch (_) {
      return <String>{};
    }
  }

  /// Links [pageId] to the controller and persists.
  void linkPageToController({
    required String controllerId,
    required String pageId,
    bool autoSave = true,
  }) {
    try {
      if (autoSave) recordSnapshot();
      projectManager.linkPageToController(controllerId: controllerId, pageId: pageId);
      if (autoSave) saveProject();
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: 'ControllerViewModel: failed to link page: $e');
      throwError('Failed to link page to controller: $e');
    }
  }

  /// Unlinks [pageId] from the controller and persists.
  void unlinkPageFromController({
    required String controllerId,
    required String pageId,
    bool autoSave = true,
  }) {
    try {
      if (autoSave) recordSnapshot();
      projectManager.unlinkPageFromController(controllerId: controllerId, pageId: pageId);
      if (autoSave) saveProject();
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: 'ControllerViewModel: failed to unlink page: $e');
      throwError('Failed to unlink page from controller: $e');
    }
  }

  /// Replaces ALL page links for [controllerId] and persists.
  void setControllerPageIds({
    required String controllerId,
    required Set<String> pageIds,
    bool autoSave = true,
  }) {
    try {
      if (autoSave) recordSnapshot();
      projectManager.setControllerPageIds(controllerId: controllerId, pageIds: pageIds);
      if (autoSave) saveProject();
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: 'ControllerViewModel: failed to set page IDs: $e');
      throwError('Failed to set controller page IDs: $e');
    }
  }

  // ─── Typed snapshot pages data ───────────────────────────────────────────

  /// Returns all [ControllerPageModel] entries stored on the controller model.
  List<ControllerPageModel> getControllerPages(String controllerId) {
    try {
      return projectManager.getControllerPages(controllerId);
    } catch (_) {
      return <ControllerPageModel>[];
    }
  }

  /// Replaces the full [ControllerPageModel] list on the controller model and persists.
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

  // ─── Typed message pages data ─────────────────────────────────────────────

  /// Returns all [ControllerMessagePageModel] entries stored on the controller model.
  List<ControllerMessagePageModel> getControllerMessagePages(String controllerId) {
    try {
      return projectManager.getControllerMessagePages(controllerId);
    } catch (_) {
      return <ControllerMessagePageModel>[];
    }
  }

  /// Replaces the full [ControllerMessagePageModel] list on the controller model and persists.
  void setControllerMessagePages({
    required String controllerId,
    required List<ControllerMessagePageModel> messagePages,
    bool autoSave = true,
  }) {
    try {
      if (autoSave) recordSnapshot();
      projectManager.setControllerMessagePages(controllerId: controllerId, messagePages: messagePages);
      if (autoSave) saveProject();
      updateProject();
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: 'ControllerViewModel: failed to set controller message pages: $e');
      throwError('Failed to set controller message pages: $e');
    }
  }

  // ─── Schedule page config ─────────────────────────────────────────────────

  /// Returns the persisted [ControllerSchedulePageConfig] for [controllerId].
  ControllerSchedulePageConfig getControllerScheduleConfig(String controllerId) {
    try {
      return projectManager.getControllerScheduleConfig(controllerId);
    } catch (_) {
      return const ControllerSchedulePageConfig();
    }
  }

  /// Persists updated [ControllerSchedulePageConfig] for [controllerId].
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

  // ─── Display config ───────────────────────────────────────────────────────

  /// Returns the persisted [ControllerDisplayConfig] for [controllerId].
  ControllerDisplayConfig getControllerDisplayConfig(String controllerId) {
    try {
      return projectManager.getControllerDisplayConfig(controllerId);
    } catch (_) {
      return const ControllerDisplayConfig();
    }
  }

  /// Persists updated [ControllerDisplayConfig] for [controllerId].
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
}
