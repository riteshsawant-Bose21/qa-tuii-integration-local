import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/models/project_entities/controller.dart';

/// Extension on [ProjectService] providing FusionController-specific data access.
///
/// Zone assignments are stored exclusively in the [RelationshipManager] under
/// [RelationshipType.controllerZones] — mirrors the [MessagePlayerService]
/// pattern for [RelationshipType.messageZones].
///
/// [FusionController.assignedZoneIds] (model field) is used only for
/// backwards-compatible JSON deserialization; on first add, those IDs are
/// migrated into the relationship manager automatically.
extension ControllerService on ProjectService {
  // ─── Read ──────────────────────────────────────────────────────────────────

  List<FusionController> getAllControllers() => hardware.getAll().whereType<FusionController>().toList();

  FusionController? getControllerById(String controllerId) {
    final HardwareComponent? hw = hardware.get(controllerId);
    return hw is FusionController ? hw : null;
  }

  /// Zone / sub-zone IDs assigned to [controllerId] via the relationship manager.
  Set<String> getAssignedZoneIds(String controllerId) => relationships.getChildren(RelationshipType.controllerZones, controllerId);

  /// Controllers that have [zoneId] in their [RelationshipType.controllerZones] set.
  List<FusionController> getControllersForZone(String zoneId) {
    return getAllControllers().where((FusionController c) => getAssignedZoneIds(c.id).contains(zoneId)).toList();
  }

  // ─── Write ─────────────────────────────────────────────────────────────────

  /// Adds [controller] to the hardware repository and migrates any zone IDs
  /// already present in [FusionController.assignedZoneIds] into the
  /// [RelationshipManager] so the relationship layer is always authoritative.
  void addController(FusionController controller) {
    addHardware(hw: controller, addToCircuit: false);

    // Migrate model-level zone IDs → relationship manager (backward compat)
    for (final String zoneId in controller.assignedZoneIds) {
      relationships.link(RelationshipType.controllerZones, controller.id, zoneId);
    }
  }

  /// Removes [controller] and cleans up all its [controllerZones] relationships.
  void removeController(String controllerId) {
    relationships.removeAllRelationships(controllerId);
    removeHardware(controllerId);
  }

  /// Replaces the stored record with [controller] (model data only).
  void updateController(FusionController controller) {
    if (!hardware.exists(controller.id)) {
      throw Exception('Controller ${controller.id} does not exist');
    }
    hardware.add(controller.id, controller);
  }

  // ─── Zone-assignment (via RelationshipManager) ─────────────────────────────

  /// Links [zoneId] to [controllerId] in the relationship manager.
  void assignZoneToController({
    required String controllerId,
    required String zoneId,
  }) {
    relationships.link(RelationshipType.controllerZones, controllerId, zoneId);
  }

  /// Unlinks [zoneId] from [controllerId] in the relationship manager.
  void unassignZoneFromController({
    required String controllerId,
    required String zoneId,
  }) {
    relationships.unlink(RelationshipType.controllerZones, controllerId, zoneId);
  }
}
