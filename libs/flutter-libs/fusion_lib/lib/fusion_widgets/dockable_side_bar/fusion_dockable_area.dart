import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import '../../models/dock_item_config.dart';
import '../../models/fusion_dock_item.dart';
import '../others/fusion_horizontal_resizable_widget.dart';
import 'fusion_dock_floating_panel.dart';
import 'fusion_dock_side_bar.dart';

class FusionDockableArea extends StatefulWidget {
  final String tabKey;
  final bool showLeft;
  final bool showRight;
  final List<DockItemConfig> dockItemList;
  final Widget mainArea;

  const FusionDockableArea({
    super.key,
    required this.tabKey,
    required this.showLeft,
    required this.showRight,
    required this.dockItemList,
    required this.mainArea,
  });

  @override
  State<FusionDockableArea> createState() => _FusionDockableAreaState();
}

class _FusionDockableAreaState extends State<FusionDockableArea> {
  /// Static map to store dock items globally across ALL tabs and instances
  static final Map<String, DockItem> _globalDockItems = {};

  /// Static callback to notify all instances when global state changes
  static final List<VoidCallback> _stateUpdateCallbacks = [];

  /// Track the highest z-index for bringing items to front
  static int _highestZIndex = 0;

  /// Track the order items were docked to the right side
  static int _rightDockOrder = 0;
  static int _leftDockOrder = 0;

  @override
  void initState() {
    super.initState();

    /// Register this instance for global state updates
    _stateUpdateCallbacks.add(_updateState);

    /// Initialize items from the provided configs, but preserve existing state globally
    for (var config in widget.dockItemList) {
      if (!_globalDockItems.containsKey(config.id)) {
        print("Initializing GLOBAL DockItem: ${config.id} === ${config.title}");
        _globalDockItems[config.id] = DockItem(id: config.id, title: config.title, side: config.side);
        _globalDockItems[config.id]!.zIndex ??= 0;
      } else {
        print("Reusing existing GLOBAL DockItem: ${config.id} === ${config.title}");
      }
    }
  }

  @override
  void dispose() {
    /// Unregister this instance from global state updates
    _stateUpdateCallbacks.remove(_updateState);
    super.dispose();
  }

  /// Update state callback for global state changes
  void _updateState() {
    if (mounted) {
      setState(() {});
    }
  }

  /// Notify all instances about global state changes
  static void _notifyGlobalStateChange() {
    for (final callback in _stateUpdateCallbacks) {
      callback();
    }
  }

  /// Get items that belong to this tab - now checks global state
  List<DockItem> getItemsForTab() {
    /// Return items that are configured for this tab, using global state
    return widget.dockItemList.map((config) => _globalDockItems[config.id]).where((item) => item != null).cast<DockItem>().toList();
  }

  /// Get config for a specific item
  DockItemConfig? getConfigForItem(String itemId) {
    try {
      return widget.dockItemList.firstWhere((config) => config.id == itemId);
    } catch (e) {
      return null;
    }
  }

  /// Bring item to front by giving it the highest z-index
  void _bringItemToFront(DockItem item) {
    _highestZIndex++;
    item.zIndex = _highestZIndex;
    _notifyGlobalStateChange();
  }

  /// Handle item tap to bring to front
  void _handleItemTap(DockItem item) {
    _bringItemToFront(item);
  }

  /// Handle drag start to bring item to front
  void _handleItemDragStart(DockItem item) {
    // _bringItemToFront(item);
  }

  /// Handle drag end to determine docking or floating
  void _handleFloatingItemDragEnd(DockItem item, DraggableDetails details, double screenWidth) {
    final dx = details.offset.dx;
    final dy = details.offset.dy;

    /// Calculate more generous docking zones
    final double leftDockZone = widget.showLeft ? 240 : 0;
    final double rightDockZone = widget.showRight ? screenWidth - 484 : screenWidth;

    if (widget.showLeft && dx < leftDockZone) {
      /// Dock to left side
      print("Docking ${item.title} to left side");
      item.docked = true;
      item.expanded = false;
      item.side = "left";
      _leftDockOrder++;
      item.dockedOrder = _leftDockOrder;
    } else if (widget.showRight && dx > rightDockZone) {
      /// Dock to right side
      print("Docking ${item.title} to right side");
      item.docked = true;
      item.expanded = false;
      item.side = "right";
      _rightDockOrder++;
      item.dockedOrder = _rightDockOrder;
    } else {
      /// Keep floating
      print("Keeping ${item.title} floating at: ${details.offset}");
      item.position = details.offset;
      item.docked = false;
      item.expanded = true;
      _bringItemToFront(item);
    }

    _notifyGlobalStateChange();
  }

  /// Handle undocking from sidebar
  void _handleSidebarUndock(DockItem item, DraggableDetails details) {
    print("Undocking ${item.title} from ${item.side} sidebar at: ${details.offset}");

    // First handle the undocking with the main drag end logic
    _handleFloatingItemDragEnd(item, details, MediaQuery.of(context).size.width);

    // If it didn't dock to a sidebar, make it floating
    if (!item.docked) {
      item.position = details.offset;
      item.expanded = true;

      /// Bring to front when undocked
      _bringItemToFront(item);
    }

    _notifyGlobalStateChange();
  }

  /// Undock and reset position if widget side is right then duck to right side or else right side
  void onCloseButtonPressed(DockItem item) {
    if (item.side == "right" && widget.showRight) {
      item.docked = true;
      item.expanded = true;
      item.side = "right";
    } else if (item.side == "left" && widget.showLeft) {
      item.docked = true;
      item.expanded = true;
      item.side = "left";
    }

    _notifyGlobalStateChange();
  }

  /// Handle expansion state change
  void _handleExpansionChanged(DockItem item, bool expanded) {
    item.expanded = expanded;
    _notifyGlobalStateChange();
  }

  /// Handle resizing of floating panel
  void _handleItemResize(DockItem item, double deltaX, double deltaY) {
    item.width = (item.width + deltaX).clamp(240, 600);
    item.height = (item.height + deltaY).clamp(120, 700);
    _notifyGlobalStateChange();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final items = getItemsForTab();

    /// Get only floating items that are configured for this tab
    final floatingItems = items.where((item) => !item.docked).toList()..sort((a, b) => (a.zIndex ?? 0).compareTo(b.zIndex ?? 0));

    return Stack(
      children: [
        Row(
          children: [
            /// Left Sidebar
            if (widget.showLeft)
              FusionHorizontalResizableWidget(
                minWidth: 240,
                maxWidth: screenWidth * 0.3,
                dragLeft: false,
                dragRight: true,
                child: FusionDockSidebar(
                  side: "left",
                  items: items.where((i) => i.docked && i.side == "left").toList()..sort((a, b) => (a.dockedOrder ?? 0).compareTo(b.dockedOrder ?? 0)),
                  itemConfigs: widget.dockItemList,
                  onItemUndock: _handleSidebarUndock,
                  onExpansionChanged: _handleExpansionChanged,
                ),
              ),

            /// Main Area
            Expanded(
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  return Container(
                    color: Theme.of(context).colorScheme.white,
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    child: widget.mainArea,
                  );
                },
              ),
            ),

            /// Right Sidebar
            if (widget.showRight)
              FusionHorizontalResizableWidget(
                minWidth: 240,
                maxWidth: screenWidth * 0.3,
                dragLeft: true,
                dragRight: false,
                child: FusionDockSidebar(
                  side: "right",
                  items: items.where((i) => i.docked && i.side == "right").toList()..sort((a, b) => (a.dockedOrder ?? 0).compareTo(b.dockedOrder ?? 0)),
                  itemConfigs: widget.dockItemList,
                  onItemUndock: _handleSidebarUndock,
                  onExpansionChanged: _handleExpansionChanged,
                ),
              ),
          ],
        ),

        /// Floating panels - render only floating items configured for this tab
        for (var item in floatingItems)
          Positioned(
            left: item.position.dx,
            top: item.position.dy - kToolbarHeight - 48,
            child: GestureDetector(
              onTap: () => _handleItemTap(item),
              child: FusionFloatingPanel(
                item: item,
                config: getConfigForItem(item.id)!,
                onDragStart: () => _handleItemDragStart(item),
                onDragEnd: (details) => _handleFloatingItemDragEnd(item, details, screenWidth),
                onClose: () => onCloseButtonPressed(item),
                onResize: (deltaX, deltaY) => _handleItemResize(item, deltaX, deltaY),
              ),
            ),
          ),
      ],
    );
  }
}
