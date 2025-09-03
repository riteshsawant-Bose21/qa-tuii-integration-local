import 'package:flutter/material.dart';
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
  /// Static map to store dock items globally across all tabs
  static final Map<String, DockItem> _globalDockItems = {};

  /// Track the highest z-index for bringing items to front
  static int _highestZIndex = 0;

  /// Track the order items were docked to the right side
  static int _rightDockOrder = 0;
  static int _leftDockOrder = 0;

  @override
  void initState() {
    super.initState();

    /// Initialize items from the provided configs, but preserve existing state
    for (var config in widget.dockItemList) {
      if (!_globalDockItems.containsKey(config.id)) {
        print("Initializing DockItem: ${config.id}=== ${config.title}");
        _globalDockItems[config.id] = DockItem(id: config.id, title: config.title, side: config.side);
        // Initialize z-index if not set
        _globalDockItems[config.id]!.zIndex ??= 0;
      }
    }
  }

  // @override
  // void didUpdateWidget(FusionDockableArea oldWidget) {
  //   super.didUpdateWidget(oldWidget);
  //
  //   /// Add new items if configs changed, but preserve existing state
  //   for (var config in widget.dockItemList) {
  //     if (!_globalDockItems.containsKey(config.id)) {
  //       print("update DockItem: ${config.id}=== ${config.title}");
  //
  //       _globalDockItems[config.id] = DockItem(id: config.id, title: config.title, side: config.side);
  //       _globalDockItems[config.id]!.zIndex ??= 0;
  //     }
  //   }
  // }

  /// Get items that belong to this tab
  List<DockItem> getItemsForTab() {
    /// Return only items that are configured for this tab
    return widget.dockItemList.map((config) => _globalDockItems[config.id]!).where((item) => item != null).toList();
  }

  /// Get config for a specific item
  DockItemConfig? getConfigForItem(String itemId) {
    return widget.dockItemList.firstWhere((config) => config.id == itemId, orElse: () => widget.dockItemList.first);
  }

  /// Bring item to front by giving it the highest z-index
  void _bringItemToFront(DockItem item) {
    setState(() {
      _highestZIndex++;
      item.zIndex = _highestZIndex;
    });
  }

  /// Handle item tap to bring to front
  void _handleItemTap(DockItem item) {
    _bringItemToFront(item);
  }

  /// Handle drag start to bring item to front
  void _handleItemDragStart(DockItem item) {
    _bringItemToFront(item);
  }

  /// Handle drag end to determine docking or floating
  void _handleItemDragEnd(DockItem item, DraggableDetails details, double screenWidth) {
    setState(() {
      final dx = details.offset.dx;
      if (widget.showLeft && dx < 240) {
        item.docked = true;
        item.expanded = false;
        item.side = "left";
        _leftDockOrder++;
        item.dockedOrder = _leftDockOrder;
      } else if (widget.showRight && dx > screenWidth - 484) {
        item.docked = true;
        item.expanded = false;
        item.side = "right";
        // Assign docked order for right side items
        _rightDockOrder++;
        item.dockedOrder = _rightDockOrder;
      } else {
        item.position = details.offset;
        item.docked = false;
        item.expanded = true;
      }
    });
  }

  /// Undock and reset position if widget side is right then duck to right side or else right side
  void onCloseButtonPressed(DockItem item) {
    setState(() {
      if (item.side == "right" && widget.showRight) {
        item.docked = true;
        item.expanded = false;
        item.side = "right";
      } else if (item.side == "left" && widget.showLeft) {
        item.docked = true;
        item.expanded = false;
        item.side = "left";
      }
      // Reset position
    });
  }

  /// Handle undocking from sidebar
  void _handleItemUndock(DockItem item, DraggableDetails details) {
    setState(() {
      item.docked = false;
      item.position = details.offset;
      item.expanded = true;
    });
    // Bring to front when undocked
    _bringItemToFront(item);
  }

  /// Handle expansion state change
  void _handleExpansionChanged(DockItem item, bool expanded) {
    setState(() {
      item.expanded = expanded;
    });
  }

  /// Handle resizing of floating panel
  void _handleItemResize(DockItem item, double deltaX, double deltaY) {
    setState(() {
      item.width = (item.width + deltaX).clamp(240, 600);
      item.height = (item.height + deltaY).clamp(120, 700);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final items = getItemsForTab();

    // Get floating items and sort them by z-index for proper stacking order
    final floatingItems =
        items.where((i) => !i.docked).where((item) => (item.side == "left" && widget.showLeft) || (item.side == "right" && widget.showRight)).toList()
          ..sort((a, b) => (a.zIndex ?? 0).compareTo(b.zIndex ?? 0));

    return Stack(
      children: [
        Row(
          children: [
            if (widget.showLeft)
              FusionHorizontalResizableWidget(
                minWidth: 240,
                maxWidth: 1000,
                dragLeft: false,
                dragRight: true,
                child: FusionDockSidebar(
                  side: "left",
                  items: items.where((i) => i.docked && i.side == "left").toList()..sort((a, b) => (a.dockedOrder ?? 0).compareTo(b.dockedOrder ?? 0)),
                  itemConfigs: widget.dockItemList,
                  onItemUndock: _handleItemUndock,
                  onExpansionChanged: _handleExpansionChanged,
                ),
              ),

            Expanded(child: widget.mainArea),

            if (widget.showRight)
              FusionHorizontalResizableWidget(
                minWidth: 240,
                maxWidth: 1000,
                dragLeft: true,
                dragRight: false,
                child: FusionDockSidebar(
                  side: "right",
                  items: items.where((i) => i.docked && i.side == "right").toList()..sort((a, b) => (a.dockedOrder ?? 0).compareTo(b.dockedOrder ?? 0)),
                  itemConfigs: widget.dockItemList,
                  onItemUndock: _handleItemUndock,
                  onExpansionChanged: _handleExpansionChanged,
                ),
              ),
          ],
        ),

        /// Floating panels - render in z-index order (lowest to highest)
        for (var item in floatingItems)
          Positioned(
            left: item.position.dx,
            top: item.position.dy,
            child: GestureDetector(
              onTap: () => _handleItemTap(item),
              child: FusionFloatingPanel(
                item: item,
                config: getConfigForItem(item.id),
                onDragStart: () => _handleItemDragStart(item),
                onDragEnd: (details) => _handleItemDragEnd(item, details, screenWidth),
                onClose: () => onCloseButtonPressed(item),
                onResize: (deltaX, deltaY) => _handleItemResize(item, deltaX, deltaY),
              ),
            ),
          ),
      ],
    );
  }
}
