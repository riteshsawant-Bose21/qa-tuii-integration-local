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
