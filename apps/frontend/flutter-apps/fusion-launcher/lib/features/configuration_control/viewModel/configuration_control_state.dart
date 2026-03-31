import 'package:equatable/equatable.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/models/project_entities/controller.dart';

/// Enum representing the available tabs in Configuration Control
enum ConfigControlTab {
  zoneControl,
  snapshotsScenes,
  schedule,
  message,
  settings,
}

/// Base state class for the Configuration Control feature
sealed class ConfigurationControlState extends Equatable {
  const ConfigurationControlState();

  /// Get controllers list (empty for non-loaded states)
  List<FusionController> get controllers => <FusionController>[];

  /// Get zones list (empty for non-loaded states)
  List<Zone> get zones => <Zone>[];

  /// Get sub-zones map for each zone (empty for non-loaded states)
  Map<String, List<SubZone>> get subZonesInZones => <String, List<SubZone>>{};

  /// Get selected controller ID
  String? get selectedControllerId => null;

  /// Get selected zone ID
  String? get selectedZoneId => null;

  /// Get current tab
  ConfigControlTab get currentTab => ConfigControlTab.zoneControl;

  /// Get search query
  String get searchQuery => '';

  @override
  List<Object?> get props => <Object?>[];
}

/// Initial state - no data loaded yet
class ConfigControlInitial extends ConfigurationControlState {
  const ConfigControlInitial();
}

/// Loading state - fetching data
class ConfigControlLoading extends ConfigurationControlState {
  const ConfigControlLoading();
}

/// Empty state - no controllers in project
class ConfigControlEmpty extends ConfigurationControlState {
  const ConfigControlEmpty();
}

/// Loaded state - controllers and zones successfully loaded
class ConfigControlLoaded extends ConfigurationControlState {
  @override
  final List<FusionController> controllers;

  @override
  final List<Zone> zones;

  @override
  final Map<String, List<SubZone>> subZonesInZones;

  @override
  final String? selectedControllerId;

  @override
  final String? selectedZoneId;

  @override
  final ConfigControlTab currentTab;

  @override
  final String searchQuery;

  /// Selected zones for the controller (zone IDs that are checked)
  final Set<String> selectedZoneIds;

  const ConfigControlLoaded({
    required this.controllers,
    required this.zones,
    this.subZonesInZones = const <String, List<SubZone>>{},
    this.selectedControllerId,
    this.selectedZoneId,
    this.currentTab = ConfigControlTab.zoneControl,
    this.searchQuery = '',
    this.selectedZoneIds = const <String>{},
  });

  /// Create a copy with updated values
  ConfigControlLoaded copyWith({
    List<FusionController>? controllers,
    List<Zone>? zones,
    Map<String, List<SubZone>>? subZonesInZones,
    String? selectedControllerId,
    String? selectedZoneId,
    ConfigControlTab? currentTab,
    String? searchQuery,
    Set<String>? selectedZoneIds,
    bool clearSelectedControllerId = false,
    bool clearSelectedZoneId = false,
  }) {
    return ConfigControlLoaded(
      controllers: controllers ?? this.controllers,
      zones: zones ?? this.zones,
      subZonesInZones: subZonesInZones ?? this.subZonesInZones,
      selectedControllerId: clearSelectedControllerId ? null : (selectedControllerId ?? this.selectedControllerId),
      selectedZoneId: clearSelectedZoneId ? null : (selectedZoneId ?? this.selectedZoneId),
      currentTab: currentTab ?? this.currentTab,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedZoneIds: selectedZoneIds ?? this.selectedZoneIds,
    );
  }

  /// Get filtered controllers based on search query
  List<FusionController> get filteredControllers {
    if (searchQuery.isEmpty) {
      return controllers;
    }
    final String query = searchQuery.toLowerCase();
    return controllers.where((FusionController c) => c.name.toLowerCase().contains(query)).toList();
  }

  /// Get the currently selected controller
  FusionController? get selectedController {
    if (selectedControllerId == null) return null;
    try {
      return controllers.firstWhere((FusionController c) => c.id == selectedControllerId);
    } catch (_) {
      return null;
    }
  }

  /// Check if the selected controller is a Pro type
  bool get isProController {
    final FusionController? controller = selectedController;
    if (controller == null) return false;
    final String sku = controller.sku.toLowerCase();
    final String name = controller.name.toLowerCase();
    return sku.contains('pro') || name.contains('pro');
  }

  /// Get zones associated with the selected controller
  List<Zone> get controllerZones {
    // For now, return all zones. In future, this can be filtered based on controller-zone mapping
    return zones;
  }

  @override
  List<Object?> get props => <Object?>[
    controllers,
    zones,
    subZonesInZones,
    selectedControllerId,
    selectedZoneId,
    currentTab,
    searchQuery,
    selectedZoneIds,
  ];
}

/// Error state - failed to load data
class ConfigControlError extends ConfigurationControlState {
  final String message;

  const ConfigControlError({required this.message});

  @override
  List<Object?> get props => <Object?>[message];
}
