import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/models/project_entities/controller.dart';

import 'configuration_control_state.dart';

/// ViewModel/Cubit for the Configuration Control feature.
///
/// Responsible only for:
///   • Managing the list of controllers and which one is selected.
///   • Tab switching (LT vs Pro available tabs).
///   • Search query filtering.
///
/// All feature-specific state (zones, snapshots, messages, schedules, settings)
/// is handled by their respective dedicated ViewModels.
class ConfigurationControlViewmodel extends Cubit<ConfigurationControlState> {
  late final StreamSubscription<ProjectViewModelState> _projectSubscription;

  ConfigurationControlViewmodel() : super(const ConfigControlInitial()) {
    _loadData();
    // Re-sync whenever the project changes externally (controllers added / removed / updated)
    _projectSubscription = _projectViewModel.stream.listen((_) => _sync());
  }

  /// Lazy reference — never hold a field copy, always read from the locator.
  ProjectViewModel get _projectViewModel => serviceLocator<ProjectViewModel>();

  // ─── Convenience helper ────────────────────────────────────────────────────

  ConfigControlLoaded? get _loaded {
    final ConfigurationControlState s = state;
    return s is ConfigControlLoaded ? s : null;
  }

  @override
  Future<void> close() {
    _projectSubscription.cancel();
    return super.close();
  }

  // ─── Data loading ──────────────────────────────────────────────────────────

  /// Loads (or reloads) the controller list from the project ViewModel.
  void _loadData({String? preserveControllerId}) {
    if (_loaded == null) emit(const ConfigControlLoading());

    try {
      final List<FusionController> controllers = _projectViewModel.fusionControllers;

      if (controllers.isEmpty) {
        emit(const ConfigControlEmpty());
        return;
      }

      final FusionController selected = _resolveController(controllers, preserveControllerId);
      final ConfigControlTab targetTab = _loaded?.currentTab ?? ConfigControlTab.zoneControl;

      emit(
        ConfigControlLoaded(
          controllers: controllers,
          selectedControllerId: selected.id,
          currentTab: _resolveTab(targetTab, selected),
          searchQuery: _loaded?.searchQuery ?? '',
        ),
      );
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: 'ConfigControl: failed to load data: $e');
      emit(ConfigControlError(message: 'Failed to load data: $e'));
    }
  }

  /// Called by the project subscription — re-loads while keeping current selection.
  void _sync() => _loadData(preserveControllerId: _loaded?.selectedControllerId);

  /// Public refresh — useful when the caller knows data has changed.
  void refresh() => _sync();

  // ─── Controller helpers (used by UI widgets) ───────────────────────────────

  String getControllerLocation(FusionController controller) {
    if (controller.locationEntity.listeningAreaId != null) {
      final String areaId = controller.locationEntity.listeningAreaId!;
      final Zone? zone = _projectViewModel.getZonesForListeningArea(areaId: areaId);
      if (zone != null) return zone.name;

      final SubZone? sub = _projectViewModel.getSubZoneForListeningArea(areaId: areaId);
      if (sub != null) return sub.name;
    }
    return _projectViewModel.getEquipLocationForHardware(hardwareId: controller.id)?.name ?? '--';
  }

  Zone? getZoneForController(FusionController controller) {
    if (controller.locationEntity.listeningAreaId != null) {
      final String areaId = controller.locationEntity.listeningAreaId!;
      final Zone? zone = _projectViewModel.getZonesForListeningArea(areaId: areaId);
      if (zone != null) return zone;

      final SubZone? sub = _projectViewModel.getSubZoneForListeningArea(areaId: areaId);
      if (sub != null) return _projectViewModel.getZoneForSubZone(subZoneId: sub.id);
    }
    return null;
  }

  // ─── Controller actions ────────────────────────────────────────────────────

  void selectController(String controllerId) {
    final ConfigControlLoaded? loaded = _loaded;
    if (loaded == null) return;
    if (loaded.selectedControllerId == controllerId) return; // already selected
    _loadData(preserveControllerId: controllerId);
  }

  void addController(FusionController controller) {
    _projectViewModel.addHardware(hardware: controller);
    _loadData(preserveControllerId: _loaded?.selectedControllerId);
  }

  void deleteController(String controllerId) {
    _projectViewModel.removeHardware(hardwareId: controllerId);

    final ConfigControlLoaded? loaded = _loaded;
    if (loaded == null) return;

    final List<FusionController> remaining = loaded.controllers.where((FusionController c) => c.id != controllerId).toList();

    if (remaining.isEmpty) {
      emit(const ConfigControlEmpty());
      return;
    }

    final String? keepId = loaded.selectedControllerId == controllerId ? null : loaded.selectedControllerId;
    _loadData(preserveControllerId: keepId);
  }

  // ─── Tab / search ──────────────────────────────────────────────────────────

  void changeTab(ConfigControlTab tab) {
    final ConfigControlLoaded? loaded = _loaded;
    if (loaded == null) return;
    emit(loaded.copyWith(currentTab: tab));
  }

  void updateSearchQuery(String query) {
    final ConfigControlLoaded? loaded = _loaded;
    if (loaded == null) return;
    emit(loaded.copyWith(searchQuery: query));
  }

  void clearSearch() => updateSearchQuery('');

  // ─── Private helpers ───────────────────────────────────────────────────────

  FusionController _resolveController(
    List<FusionController> controllers,
    String? preferredId,
  ) {
    if (preferredId != null) {
      final FusionController? match = controllers.where((FusionController c) => c.id == preferredId).firstOrNull;
      if (match != null) return match;
    }
    return controllers.first;
  }

  /// Returns true if [controller] is a Pro type.
  bool _isProController(FusionController controller) {
    final String sku = controller.sku.toLowerCase();
    final String name = controller.name.toLowerCase();
    return sku.contains('pro') || name.contains('pro');
  }

  /// Returns the tabs available for [controller].
  List<ConfigControlTab> _availableTabsFor(FusionController controller) {
    if (_isProController(controller)) return ConfigControlTab.values;
    return <ConfigControlTab>[ConfigControlTab.zoneControl, ConfigControlTab.settings];
  }

  /// Returns [tab] if it is available for [controller], otherwise [ConfigControlTab.zoneControl].
  ConfigControlTab _resolveTab(ConfigControlTab tab, FusionController controller) {
    final List<ConfigControlTab> available = _availableTabsFor(controller);
    return available.contains(tab) ? tab : ConfigControlTab.zoneControl;
  }
}
