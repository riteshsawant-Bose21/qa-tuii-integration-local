import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/models/project_entities/controller.dart';
import 'package:fusion_lib/models/project_entities/controller_page_model.dart';

/// Extension on [ProjectService] providing FusionController-specific data access.
///
/// Pages are stored in [controllerPages] repository + [RelationshipManager].
/// Display settings and schedule preferences live directly on [FusionController].
/// Selected schedule IDs are stored in the [controllerSchedules] relationship.
extension ControllerService on ProjectService {
  // ─── Read ──────────────────────────────────────────────────────────────────

  List<FusionController> getAllControllers() => hardware.getAll().whereType<FusionController>().toList();

  FusionController? getControllerById(String controllerId) {
    final HardwareComponent? hw = hardware.get(controllerId);
    return hw is FusionController ? hw : null;
  }

  /// Zone / sub-zone IDs assigned to [controllerId] via [controllerAssignedZones].
  Set<String> getAssignedZoneIds(String controllerId) => relationships.getChildren(RelationshipType.controllerAssignedZones, controllerId);

  /// Controllers that have [zoneId] in their assigned zone IDs.
  List<FusionController> getControllersForZone(String zoneId) =>
      getAllControllers().where((FusionController c) => getAssignedZoneIds(c.id).contains(zoneId)).toList();

  // ─── Write ─────────────────────────────────────────────────────────────────

  void addController(FusionController controller) {
    addHardware(hw: controller, addToCircuit: false);
  }

  void removeController(String controllerId) {
    relationships.removeAllRelationships(controllerId);
    // Clean up all pages belonging to this controller
    final Set<String> pageIds = Set<String>.from(
      relationships.getChildren(RelationshipType.controllerPages, controllerId),
    );
    for (final String pageId in pageIds) {
      controllerPages.remove(pageId);
    }
    removeHardware(controllerId);
  }

  void updateController(FusionController controller) {
    if (!hardware.exists(controller.id)) {
      throw Exception('Controller ${controller.id} does not exist');
    }
    hardware.add(controller.id, controller);
  }

  // ─── Zone-assignment (via controllerAssignedZones relationship) ────────────

  void assignZoneToController({required String controllerId, required String zoneId}) =>
      relationships.link(RelationshipType.controllerAssignedZones, controllerId, zoneId);

  void unassignZoneFromController({required String controllerId, required String zoneId}) =>
      relationships.unlink(RelationshipType.controllerAssignedZones, controllerId, zoneId);

  // ─── Pages (controllerPages repo + controllerPages relationship) ───────────

  /// All pages (scene-set, snapshot, message) linked to [controllerId].
  List<ControllerPageModel> getControllerPages(String controllerId) {
    final Set<String> pageIds = relationships.getChildren(RelationshipType.controllerPages, controllerId);
    return pageIds.map((String id) => controllerPages.get(id)).whereType<ControllerPageModel>().toList();
  }

  /// Replaces ALL pages for [controllerId] with [pages].
  void setControllerPages({
    required String controllerId,
    required List<ControllerPageModel> pages,
  }) {
    final Set<String> existingIds = Set<String>.from(
      relationships.getChildren(RelationshipType.controllerPages, controllerId),
    );
    for (final String pageId in existingIds) {
      controllerPages.remove(pageId);
      relationships.unlink(RelationshipType.controllerPages, controllerId, pageId);
    }
    for (final ControllerPageModel p in pages) {
      controllerPages.add(p.id, p);
      relationships.link(RelationshipType.controllerPages, controllerId, p.id);
    }
  }

  // ─── Page-item relationships ───────────────────────────────────────────────

  Set<String> getSnapshotIdsForPage(String pageId) => relationships.getChildren(RelationshipType.controllerPageSnapshots, pageId);

  void setSnapshotIdsForPage({required String pageId, required Set<String> snapshotIds}) {
    final Set<String> existing = Set<String>.from(
      relationships.getChildren(RelationshipType.controllerPageSnapshots, pageId),
    );
    for (final String id in existing) {
      relationships.unlink(RelationshipType.controllerPageSnapshots, pageId, id);
    }
    for (final String id in snapshotIds) {
      relationships.link(RelationshipType.controllerPageSnapshots, pageId, id);
    }
  }

  Set<String> getMessageIdsForPage(String pageId) => relationships.getChildren(RelationshipType.controllerPageMessages, pageId);

  void setMessageIdsForPage({required String pageId, required Set<String> messageIds}) {
    final Set<String> existing = Set<String>.from(
      relationships.getChildren(RelationshipType.controllerPageMessages, pageId),
    );
    for (final String id in existing) {
      relationships.unlink(RelationshipType.controllerPageMessages, pageId, id);
    }
    for (final String id in messageIds) {
      relationships.link(RelationshipType.controllerPageMessages, pageId, id);
    }
  }

  // ─── Schedule config (stored directly on FusionController) ────────────────

  /// Returns schedule preferences from the controller model.
  ControllerSchedulePageConfig getControllerScheduleConfig(String controllerId) {
    final FusionController? c = getControllerById(controllerId);
    return ControllerSchedulePageConfig(
      displayMode: c?.scheduleDisplayMode ?? 'all',
      showUpcoming: c?.showUpcoming ?? false,
    );
  }

  /// Persists [showUpcoming] and [displayMode] directly onto the controller model.
  void setControllerScheduleConfig({
    required String controllerId,
    required ControllerSchedulePageConfig config,
  }) {
    final FusionController? c = getControllerById(controllerId);
    if (c == null) return;
    hardware.add(
      controllerId,
      c.copyWith(showUpcoming: config.showUpcoming, scheduleDisplayMode: config.displayMode),
    );
  }

  /// Schedule IDs selected for [controllerId] (via [controllerSchedules] relationship).
  Set<String> getSelectedScheduleIds(String controllerId) => relationships.getChildren(RelationshipType.controllerSchedules, controllerId);

  /// Replaces the selected schedule IDs for [controllerId].
  void setSelectedScheduleIds({required String controllerId, required Set<String> scheduleIds}) {
    final Set<String> existing = Set<String>.from(
      relationships.getChildren(RelationshipType.controllerSchedules, controllerId),
    );
    for (final String id in existing) {
      relationships.unlink(RelationshipType.controllerSchedules, controllerId, id);
    }
    for (final String id in scheduleIds) {
      relationships.link(RelationshipType.controllerSchedules, controllerId, id);
    }
  }

  // ─── Display config (stored directly on FusionController) ─────────────────

  ControllerDisplayConfig getControllerDisplayConfig(String controllerId) => getControllerById(controllerId)?.displayConfig ?? const ControllerDisplayConfig();

  void setControllerDisplayConfig({required String controllerId, required ControllerDisplayConfig config}) {
    final FusionController? c = getControllerById(controllerId);
    if (c == null) return;
    hardware.add(controllerId, c.copyWith(displayConfig: config));
  }

  /// Builds a [WallControllerConfig] from the current project state.
  WallControllerConfig getWallControllerConfig() {
    /// Reset so the result is deterministic regardless of call order.
    resetOnoCounter();

    final List<FusionController> allControllers = getAllControllers();

    // Collect all assigned zone IDs in stable insertion order.
    final List<String> orderedZoneIds = <String>[];
    final Set<String> seenZoneIds = <String>{};
    for (final FusionController c in allControllers) {
      for (final String zoneId in getAssignedZoneIds(c.id)) {
        if (seenZoneIds.add(zoneId)) {
          orderedZoneIds.add(zoneId);
        }
      }
    }

    // Build WallZone list.
    final List<WallZone> wallZones = <WallZone>[];
    for (final String zoneId in orderedZoneIds) {
      final Zone? zone = zones.get(zoneId);
      if (zone == null) continue;

      // Sources (direct + source-set sources).
      final List<Source> sources = getSourcesAndSourceSetSourcesInZone(zoneId: zoneId);
      final List<WallZoneSource> wallSources = sources
          .asMap()
          .entries
          .map(
            (MapEntry<int, Source> e) => WallZoneSource(
              index: e.key + 1,
              sourceId: e.value.id,
              sourceName: e.value.name,
            ),
          )
          .toList();

      // Assign zone ONO first, then sub-zone ONOs so numbers are consecutive.
      final WallZoneOno zoneOno = WallZoneOno.autoAssign();

      final List<SubZone> subZonesList = getSubZones(zoneId);

      final List<WallSubZone> wallSubZones = <WallSubZone>[];
      for (final SubZone sz in subZonesList) {
        final List<ProcessingBlockModel> szProcessingBlocks = getProcessingBlockFor(parentId: sz.id, includeUserBlocks: true);
        final ProcessingBlockModel? szProcessingBlockModel = szProcessingBlocks.firstWhereOrNull(
          (ProcessingBlockModel block) => block.algorithmId == "gain" && block.isforUser,
        );
        wallSubZones.add(
          WallSubZone(
            id: sz.id,
            name: sz.name,
            gain: WallGainConfig(gainID: szProcessingBlockModel?.id ?? ""),
            ono: WallSubZoneOno.autoAssign(),
          ),
        );
      }

      final List<ProcessingBlockModel> processingBlocks = getProcessingBlockFor(parentId: zoneId, includeUserBlocks: true);
      ProcessingBlockModel? processingBlockModel = processingBlocks.firstWhereOrNull(
        (ProcessingBlockModel block) => block.algorithmId == "gain" && block.isforUser,
      );

      wallZones.add(
        WallZone(
          id: zone.id,
          name: zone.name,
          gain: WallGainConfig(gainID: processingBlockModel?.id ?? ""),
          ono: zoneOno,
          sources: wallSources,
          subZones: wallSubZones,
        ),
      );
    }

    // Build WallController list.
    final List<WallController> wallControllers = allControllers
        .map(
          (FusionController c) => WallController(
            id: c.id,
            name: c.name,
            zoneIds: getAssignedZoneIds(c.id).toList(),
          ),
        )
        .toList();

    return WallControllerConfig(
      controllers: wallControllers,
      zones: wallZones,
    );
  }
}
