import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/models/project_entities/controller.dart';

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

  /// Adds [controller] to the project hardware repository.
  void addFusionController({
    required FusionController controller,
    bool autoSave = true,
  }) {
    try {
      if (autoSave) recordSnapshot();
      projectManager.addFusionController(controller);
      if (autoSave) saveProject();
      updateProject();
    } catch (e) {
      FusionLogger.log(
        tag: LogTag.project,
        message: 'ControllerViewModel: failed to add controller: $e',
      );
      throwError('Failed to add controller: $e');
    }
  }

  /// Removes the controller with [controllerId] from the project.
  void removeFusionController({
    required String controllerId,
    bool autoSave = true,
  }) {
    try {
      if (autoSave) recordSnapshot();
      projectManager.removeFusionController(controllerId);
      if (autoSave) saveProject();
      updateProject();
    } catch (e) {
      FusionLogger.log(
        tag: LogTag.project,
        message: 'ControllerViewModel: failed to remove controller: $e',
      );
      throwError('Failed to remove controller: $e');
    }
  }

  /// Replaces the stored controller record with [controller].
  void updateFusionController({
    required FusionController controller,
    bool autoSave = true,
  }) {
    try {
      if (autoSave) recordSnapshot();
      projectManager.updateFusionController(controller);
      if (autoSave) saveProject();
      updateProject();
    } catch (e) {
      FusionLogger.log(
        tag: LogTag.project,
        message: 'ControllerViewModel: failed to update controller: $e',
      );
      throwError('Failed to update controller: $e');
    }
  }

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
}
