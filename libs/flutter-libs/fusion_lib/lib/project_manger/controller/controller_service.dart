import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/models/project_entities/controller.dart';
import 'package:fusion_lib/models/project_entities/controller_page_model.dart';

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

  // ─── Page-assignment (via RelationshipManager — controllerSnapshotPages) ──

  /// Page IDs linked to [controllerId] (scene-set IDs + snapshot-page IDs).
  Set<String> getControllerPageIds(String controllerId) => relationships.getChildren(RelationshipType.controllerSnapshotPages, controllerId);

  /// Links [pageId] to [controllerId] in the relationship manager.
  void linkPageToController({
    required String controllerId,
    required String pageId,
  }) {
    relationships.link(RelationshipType.controllerSnapshotPages, controllerId, pageId);
  }

  /// Unlinks [pageId] from [controllerId] in the relationship manager.
  void unlinkPageFromController({
    required String controllerId,
    required String pageId,
  }) {
    relationships.unlink(RelationshipType.controllerSnapshotPages, controllerId, pageId);
  }

  /// Replaces ALL page links for [controllerId] with [pageIds].
  void setControllerPageIds({
    required String controllerId,
    required Set<String> pageIds,
  }) {
    // Remove existing links
    final Set<String> existing = Set<String>.from(getControllerPageIds(controllerId));
    for (final String id in existing) {
      relationships.unlink(RelationshipType.controllerSnapshotPages, controllerId, id);
    }
    // Add new links
    for (final String id in pageIds) {
      relationships.link(RelationshipType.controllerSnapshotPages, controllerId, id);
    }
  }

  // ─── Typed snapshot pages data (persisted on the FusionController model) ──

  /// Returns all [ControllerPageModel] entries stored on the controller model.
  List<ControllerPageModel> getControllerPages(String controllerId) {
    final FusionController? controller = getControllerById(controllerId);
    return controller?.pages ?? <ControllerPageModel>[];
  }

  /// Replaces the full [ControllerPageModel] list on the controller model.
  void setControllerPages({
    required String controllerId,
    required List<ControllerPageModel> pages,
  }) {
    final FusionController? controller = getControllerById(controllerId);
    if (controller == null) return;
    final FusionController updated = controller.copyWith(pages: pages);
    hardware.add(controllerId, updated);

    // Keep the controllerSnapshotPages relationship in sync with the page IDs
    setControllerPageIds(
      controllerId: controllerId,
      pageIds: pages.map((ControllerPageModel p) => p.id).toSet(),
    );
  }

  // ─── Message pages (via RelationshipManager — controllerMessagePages) ──────

  /// Source IDs of checked message players for [controllerId].
  Set<String> getControllerMessagePageIds(String controllerId) => relationships.getChildren(RelationshipType.controllerMessagePages, controllerId);

  /// Replaces ALL message-page source-ID links for [controllerId] with [sourceIds].
  void setControllerMessagePageIds({
    required String controllerId,
    required Set<String> sourceIds,
  }) {
    final Set<String> existing = Set<String>.from(getControllerMessagePageIds(controllerId));
    for (final String id in existing) {
      relationships.unlink(RelationshipType.controllerMessagePages, controllerId, id);
    }
    for (final String id in sourceIds) {
      relationships.link(RelationshipType.controllerMessagePages, controllerId, id);
    }
  }

  // ─── Typed message pages data (persisted on the FusionController model) ────

  /// Returns all [ControllerMessagePageModel] entries stored on the controller model.
  List<ControllerMessagePageModel> getControllerMessagePages(String controllerId) {
    final FusionController? controller = getControllerById(controllerId);
    return controller?.messagePages ?? <ControllerMessagePageModel>[];
  }

  /// Replaces the full [ControllerMessagePageModel] list on the controller model.
  void setControllerMessagePages({
    required String controllerId,
    required List<ControllerMessagePageModel> messagePages,
  }) {
    final FusionController? controller = getControllerById(controllerId);
    if (controller == null) return;
    final FusionController updated = controller.copyWith(messagePages: messagePages);
    hardware.add(controllerId, updated);

    // Keep the controllerMessagePages relationship in sync
    setControllerMessagePageIds(
      controllerId: controllerId,
      sourceIds: messagePages.map((ControllerMessagePageModel p) => p.sourceId).toSet(),
    );
  }
}
