import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/models/project_entities/controller.dart';
import 'package:fusion_lib/models/project_entities/controller_page_model.dart';
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

  // ─── Page-assignment (controllerPages) ─────────────────────────────────────

  /// Page IDs linked to [controllerId] (scene-set IDs + snapshot-page IDs).
  Set<String> getControllerPageIds(String controllerId) => _service.getControllerPageIds(controllerId);

  /// Links a single [pageId] to [controllerId].
  void linkPageToController({
    required String controllerId,
    required String pageId,
  }) => _service.linkPageToController(controllerId: controllerId, pageId: pageId);

  /// Unlinks a single [pageId] from [controllerId].
  void unlinkPageFromController({
    required String controllerId,
    required String pageId,
  }) => _service.unlinkPageFromController(controllerId: controllerId, pageId: pageId);

  /// Replaces ALL page links for [controllerId] with [pageIds].
  void setControllerPageIds({
    required String controllerId,
    required Set<String> pageIds,
  }) => _service.setControllerPageIds(controllerId: controllerId, pageIds: pageIds);

  // ─── Typed pages data ──────────────────────────────────────────────────────

  /// Returns all [ControllerPageModel] entries stored on the controller model.
  List<ControllerPageModel> getControllerPages(String controllerId) => _service.getControllerPages(controllerId);

  /// Replaces the full [ControllerPageModel] list on the controller model
  /// and keeps [RelationshipType.controllerPages] in sync.
  void setControllerPages({
    required String controllerId,
    required List<ControllerPageModel> pages,
  }) => _service.setControllerPages(controllerId: controllerId, pages: pages);
}
