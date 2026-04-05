import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/models/project_entities/controller.dart';
import 'package:fusion_lib/models/project_entities/controller_page_model.dart';
import 'package:fusion_lib/project_manger/controller/controller_service.dart';

/// Extension on [ProjectManager] providing FusionController-specific operations.
extension ControllerManager on ProjectManager {
  // ─── Guard helper ─────────────────────────────────────────────────────────

  ProjectService get _service {
    if (projectService == null) throw Exception('No project is currently open');
    return projectService!;
  }

  // ─── Read ─────────────────────────────────────────────────────────────────

  List<FusionController> getAllControllers() => _service.getAllControllers();

  FusionController? getControllerById(String controllerId) => _service.getControllerById(controllerId);

  Set<String> getAssignedZoneIds(String controllerId) => _service.getAssignedZoneIds(controllerId);

  List<FusionController> getControllersForZone(String zoneId) => _service.getControllersForZone(zoneId);

  // ─── Zone-assignment ──────────────────────────────────────────────────────

  void assignZoneToController({required String controllerId, required String zoneId}) =>
      _service.assignZoneToController(controllerId: controllerId, zoneId: zoneId);

  void unassignZoneFromController({required String controllerId, required String zoneId}) =>
      _service.unassignZoneFromController(controllerId: controllerId, zoneId: zoneId);

  // ─── Snapshot page-assignment (controllerSnapshotPages) ───────────────────

  Set<String> getControllerPageIds(String controllerId) => _service.getControllerPageIds(controllerId);

  void linkPageToController({required String controllerId, required String pageId}) =>
      _service.linkPageToController(controllerId: controllerId, pageId: pageId);

  void unlinkPageFromController({required String controllerId, required String pageId}) =>
      _service.unlinkPageFromController(controllerId: controllerId, pageId: pageId);

  void setControllerPageIds({required String controllerId, required Set<String> pageIds}) =>
      _service.setControllerPageIds(controllerId: controllerId, pageIds: pageIds);

  // ─── Typed snapshot pages data ────────────────────────────────────────────

  /// Returns all [ControllerPageModel] entries stored on the controller model.
  List<ControllerPageModel> getControllerPages(String controllerId) => _service.getControllerPages(controllerId);

  /// Replaces the full [ControllerPageModel] list on the controller model
  /// and keeps [RelationshipType.controllerSnapshotPages] in sync.
  void setControllerPages({required String controllerId, required List<ControllerPageModel> pages}) =>
      _service.setControllerPages(controllerId: controllerId, pages: pages);

  // ─── Typed message pages data ─────────────────────────────────────────────

  /// Source IDs of checked message players for [controllerId].
  Set<String> getControllerMessagePageIds(String controllerId) => _service.getControllerMessagePageIds(controllerId);

  /// Returns all [ControllerMessagePageModel] entries stored on the controller model.
  List<ControllerMessagePageModel> getControllerMessagePages(String controllerId) => _service.getControllerMessagePages(controllerId);

  /// Replaces the full [ControllerMessagePageModel] list on the controller model
  /// and keeps [RelationshipType.controllerMessagePages] in sync.
  void setControllerMessagePages({required String controllerId, required List<ControllerMessagePageModel> messagePages}) =>
      _service.setControllerMessagePages(controllerId: controllerId, messagePages: messagePages);
}
