import 'package:flutter/material.dart';

/// A global manager for handling cross-sidebar panel docking functionality.
///
/// This manager maintains a registry of dock zones and handles the logic
/// for moving panels between different sidebar containers.
class FusionDockingManager {
  static final FusionDockingManager _instance = FusionDockingManager._internal();
  factory FusionDockingManager() => _instance;
  FusionDockingManager._internal();

  /// Registry of all available dock zones
  final Map<String, DockZone> _dockZones = {};

  /// Registry of all dockable panels
  final Map<String, DockablePanel> _panels = {};

  /// Callback for when a panel is moved between zones
  void Function(String panelId, String fromZone, String toZone)? onPanelMoved;

  /// Register a dock zone
  void registerDockZone(String zoneId, DockZone zone) {
    _dockZones[zoneId] = zone;
  }

  /// Unregister a dock zone
  void unregisterDockZone(String zoneId) {
    _dockZones.remove(zoneId);
  }

  /// Register a dockable panel
  void registerPanel(String panelId, DockablePanel panel) {
    _panels[panelId] = panel;
  }

  /// Unregister a dockable panel
  void unregisterPanel(String panelId) {
    _panels.remove(panelId);
  }

  /// Find the nearest dock zone within the specified distance
  DockZone? findNearestDockZone(Offset position, double maxDistance, {String? excludeZoneId}) {
    DockZone? nearestZone;
    double nearestDistance = double.infinity;

    for (final entry in _dockZones.entries) {
      final String zoneId = entry.key;
      final DockZone zone = entry.value;

      // Skip excluded zones
      if (zoneId == excludeZoneId) continue;

      // Check if zone is available for docking
      if (!zone.isAvailable()) continue;

      final double distance = (position - zone.getCenter()).distance;

      if (distance <= maxDistance && distance < nearestDistance) {
        nearestDistance = distance;
        nearestZone = zone;
      }
    }

    return nearestZone;
  }

  /// Move a panel from one zone to another
  void movePanel(String panelId, String fromZoneId, String toZoneId) {
    final DockablePanel? panel = _panels[panelId];
    final DockZone? fromZone = _dockZones[fromZoneId];
    final DockZone? toZone = _dockZones[toZoneId];

    if (panel == null || fromZone == null || toZone == null) return;

    // Remove panel from source zone
    fromZone.removePanel(panelId);

    // Add panel to target zone
    toZone.addPanel(panelId, panel);

    // Notify listeners
    onPanelMoved?.call(panelId, fromZoneId, toZoneId);
  }

  /// Get all dock zones
  Map<String, DockZone> get dockZones => Map.unmodifiable(_dockZones);

  /// Get all panels
  Map<String, DockablePanel> get panels => Map.unmodifiable(_panels);
}

/// Represents a dock zone that can contain dockable panels
abstract class DockZone {
  final String id;
  final String displayName;

  DockZone({required this.id, required this.displayName});

  /// Get the center position of this dock zone in global coordinates
  Offset getCenter();

  /// Get the bounds of this dock zone
  Rect getBounds();

  /// Check if this zone is available for docking
  bool isAvailable();

  /// Add a panel to this zone
  void addPanel(String panelId, DockablePanel panel);

  /// Remove a panel from this zone
  void removePanel(String panelId);

  /// Get all panels in this zone
  List<String> getPanelIds();
}

/// Represents a dockable panel that can be moved between zones
abstract class DockablePanel {
  final String id;
  final String title;
  final Widget child;

  DockablePanel({required this.id, required this.title, required this.child});

  /// Create a widget representation of this panel
  Widget build(BuildContext context);
}

/// Implementation of DockZone for sidebar containers
class SidebarDockZone extends DockZone {
  final GlobalKey containerKey;
  final List<String> _panelIds = [];
  final void Function(String panelId, DockablePanel panel)? onPanelAdded;
  final void Function(String panelId)? onPanelRemoved;

  SidebarDockZone({required super.id, required super.displayName, required this.containerKey, this.onPanelAdded, this.onPanelRemoved});

  @override
  Offset getCenter() {
    final RenderBox? renderBox = containerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final Offset position = renderBox.localToGlobal(Offset.zero);
      final Size size = renderBox.size;
      return Offset(position.dx + size.width / 2, position.dy + size.height / 2);
    }
    return Offset.zero;
  }

  @override
  Rect getBounds() {
    final RenderBox? renderBox = containerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final Offset position = renderBox.localToGlobal(Offset.zero);
      final Size size = renderBox.size;
      return Rect.fromLTWH(position.dx, position.dy, size.width, size.height);
    }
    return Rect.zero;
  }

  @override
  bool isAvailable() {
    return containerKey.currentContext != null;
  }

  @override
  void addPanel(String panelId, DockablePanel panel) {
    if (!_panelIds.contains(panelId)) {
      _panelIds.add(panelId);
      onPanelAdded?.call(panelId, panel);
    }
  }

  @override
  void removePanel(String panelId) {
    if (_panelIds.remove(panelId)) {
      onPanelRemoved?.call(panelId);
    }
  }

  @override
  List<String> getPanelIds() => List.unmodifiable(_panelIds);
}
