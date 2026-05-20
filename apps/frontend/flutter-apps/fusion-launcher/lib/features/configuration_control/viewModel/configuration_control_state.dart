import 'package:equatable/equatable.dart';
import 'package:fusion_lib/models/project_entities/controller.dart';

const Object _kClear = Object();

/// Enum representing the available tabs in Configuration Control
enum ConfigControlTab {
  zoneControl,
  snapshotsScenes,
  schedule,
  message,
  settings,
}

/// Base state class for the Configuration Control feature.
/// Only holds controller-level and tab-management state.
sealed class ConfigurationControlState extends Equatable {
  const ConfigurationControlState();

  List<FusionController> get controllers => <FusionController>[];
  String? get selectedControllerId => null;
  ConfigControlTab get currentTab => ConfigControlTab.zoneControl;
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

/// Loaded state - controllers successfully loaded.
/// Only contains controller list, selection, tab, and search.
class ConfigControlLoaded extends ConfigurationControlState {
  @override
  final List<FusionController> controllers;

  @override
  final String? selectedControllerId;

  @override
  final ConfigControlTab currentTab;

  @override
  final String searchQuery;

  // ignore: prefer_const_constructors_in_immutables
  ConfigControlLoaded({
    required this.controllers,
    this.selectedControllerId,
    this.currentTab = ConfigControlTab.zoneControl,
    this.searchQuery = '',
  });

  // ── Computed / cached properties ───────────────────────────────────────────

  /// Filtered controllers matching [searchQuery] — computed once per instance.
  late final List<FusionController> filteredControllers =
      searchQuery.isEmpty ? controllers : controllers.where((FusionController c) => c.name.toLowerCase().contains(searchQuery.toLowerCase())).toList();

  /// The currently selected [FusionController], or `null` if not found.
  late final FusionController? selectedController = controllers.where((FusionController c) => c.id == selectedControllerId).firstOrNull;

  /// Whether the selected controller is a Pro type (SKU or name contains "pro").
  late final bool isProController = () {
    final FusionController? c = selectedController;
    if (c == null) return false;
    final String sku = c.sku.toLowerCase();
    final String name = c.name.toLowerCase();
    return sku.contains('pro') || name.contains('pro');
  }();

  /// Whether the selected controller is a Virtual type (SKU or name contains "virtual").
  late final bool isVirtualController = () {
    final FusionController? c = selectedController;
    if (c == null) return false;
    final String sku = c.sku.toLowerCase();
    final String name = c.name.toLowerCase();
    return sku.contains('virtual') || name.contains('virtual');
  }();

  ConfigControlLoaded copyWith({
    List<FusionController>? controllers,
    Object? selectedControllerId = _kClear,
    ConfigControlTab? currentTab,
    String? searchQuery,
  }) {
    return ConfigControlLoaded(
      controllers: controllers ?? this.controllers,
      selectedControllerId: identical(selectedControllerId, _kClear) ? this.selectedControllerId : selectedControllerId as String?,
      currentTab: currentTab ?? this.currentTab,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => <Object?>[controllers, selectedControllerId, currentTab, searchQuery];
}

/// Error state - failed to load data
class ConfigControlError extends ConfigurationControlState {
  final String message;

  const ConfigControlError({required this.message});

  @override
  List<Object?> get props => <Object?>[message];
}
