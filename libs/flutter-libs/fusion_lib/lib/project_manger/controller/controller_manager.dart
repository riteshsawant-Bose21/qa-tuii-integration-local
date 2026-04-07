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

  // ─── Pages ────────────────────────────────────────────────────────────────

  List<ControllerPageModel> getControllerPages(String controllerId) => _service.getControllerPages(controllerId);

  void setControllerPages({required String controllerId, required List<ControllerPageModel> pages}) =>
      _service.setControllerPages(controllerId: controllerId, pages: pages);

  // ─── Page-item relationships ──────────────────────────────────────────────

  Set<String> getSnapshotIdsForPage(String pageId) => _service.getSnapshotIdsForPage(pageId);

  void setSnapshotIdsForPage({required String pageId, required Set<String> snapshotIds}) =>
      _service.setSnapshotIdsForPage(pageId: pageId, snapshotIds: snapshotIds);

  Set<String> getMessageIdsForPage(String pageId) => _service.getMessageIdsForPage(pageId);

  void setMessageIdsForPage({required String pageId, required Set<String> messageIds}) => _service.setMessageIdsForPage(pageId: pageId, messageIds: messageIds);

  // ─── Schedule config ──────────────────────────────────────────────────────

  ControllerSchedulePageConfig getControllerScheduleConfig(String controllerId) => _service.getControllerScheduleConfig(controllerId);

  void setControllerScheduleConfig({
    required String controllerId,
    required ControllerSchedulePageConfig config,
  }) => _service.setControllerScheduleConfig(controllerId: controllerId, config: config);

  Set<String> getSelectedScheduleIds(String controllerId) => _service.getSelectedScheduleIds(controllerId);

  void setSelectedScheduleIds({required String controllerId, required Set<String> scheduleIds}) =>
      _service.setSelectedScheduleIds(controllerId: controllerId, scheduleIds: scheduleIds);

  // ─── Display config ───────────────────────────────────────────────────────

  ControllerDisplayConfig getControllerDisplayConfig(String controllerId) => _service.getControllerDisplayConfig(controllerId);

  void setControllerDisplayConfig({
    required String controllerId,
    required ControllerDisplayConfig config,
  }) => _service.setControllerDisplayConfig(controllerId: controllerId, config: config);

  // wallcontrollerconfig

  WallControllerConfig getWallControllerConfig() => _service.getWallControllerConfig();
}
