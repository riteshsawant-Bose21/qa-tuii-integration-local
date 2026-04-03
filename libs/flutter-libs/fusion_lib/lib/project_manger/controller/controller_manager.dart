import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/models/project_entities/controller.dart';
import 'package:fusion_lib/project_manger/controller/controller_service.dart';

/// Extension on [ProjectManager] providing FusionController-specific operations.
///
/// Mirrors the [MessagePlayerManager] pattern:
/// guards against null [projectService], then delegates to [ControllerService].
extension ControllerManager on ProjectManager {
  // ─── Guard helper ──────────────────────────────────────────────────────────

  ProjectService get _service {
    if (projectService == null) throw Exception('No project is currently open');
    return projectService!;
  }

  // ─── Read ─────────────────────────────────────────────────────────────────

  /// All [FusionController] instances in the current project.
  List<FusionController> getAllControllers() => _service.getAllControllers();

  /// Returns the [FusionController] with [controllerId], or null if not found.
  FusionController? getControllerById(String controllerId) => _service.getControllerById(controllerId);

  /// Zone / sub-zone IDs assigned to [controllerId] via [RelationshipType.controllerZones].
  Set<String> getAssignedZoneIds(String controllerId) => _service.getAssignedZoneIds(controllerId);

  /// Returns controllers that have [zoneId] in their assigned zone IDs.
  List<FusionController> getControllersForZone(String zoneId) => _service.getControllersForZone(zoneId);

  // ─── Write ────────────────────────────────────────────────────────────────

  /// Adds [controller] to the hardware repository.
  void addFusionController(FusionController controller) => _service.addController(controller);

  /// Removes the controller with [controllerId] from the hardware repository.
  void removeFusionController(String controllerId) => _service.removeController(controllerId);

  /// Replaces the stored controller record with [controller].
  void updateFusionController(FusionController controller) => _service.updateController(controller);

  // ─── Zone-assignment ──────────────────────────────────────────────────────

  /// Assigns [zoneId] to [controllerId]'s zone list and persists.
  void assignZoneToController({
    required String controllerId,
    required String zoneId,
  }) => _service.assignZoneToController(
    controllerId: controllerId,
    zoneId: zoneId,
  );

  /// Removes [zoneId] from [controllerId]'s zone list and persists.
  void unassignZoneFromController({
    required String controllerId,
    required String zoneId,
  }) => _service.unassignZoneFromController(
    controllerId: controllerId,
    zoneId: zoneId,
  );
}
