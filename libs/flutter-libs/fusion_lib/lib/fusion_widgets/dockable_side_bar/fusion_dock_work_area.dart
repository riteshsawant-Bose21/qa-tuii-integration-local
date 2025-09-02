import 'package:flutter/material.dart';
import '../../models/dock_item_config.dart';
import '../../models/fusion_dock_item.dart';
import 'fusion_dock_floating_panel.dart';
import 'fusion_dock_side_bar.dart';

class FusionDockWorkspace extends StatefulWidget {
  final String tabKey;
  final bool showLeft;
  final bool showRight;
  final List<DockItemConfig> dockItemList;
  final Widget mainArea;

  const FusionDockWorkspace({
    super.key,
    required this.tabKey,
    required this.showLeft,
    required this.showRight,
    required this.dockItemList,
    required this.mainArea,
  });

  @override
  State<FusionDockWorkspace> createState() => _FusionDockWorkspaceState();
}

class _FusionDockWorkspaceState extends State<FusionDockWorkspace> {
  /// Static map to store dock items globally across all tabs
  static final Map<String, DockItem> _globalDockItems = {};

  @override
  void initState() {
    super.initState();

    /// Initialize items from the provided configs, but preserve existing state
    for (var config in widget.dockItemList) {
      if (!_globalDockItems.containsKey(config.id)) {
        _globalDockItems[config.id] = DockItem(id: config.id, title: config.title, side: config.side);
      }
    }
  }

  @override
  void didUpdateWidget(FusionDockWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);

    /// Add new items if configs changed, but preserve existing state
    for (var config in widget.dockItemList) {
      if (!_globalDockItems.containsKey(config.id)) {
        _globalDockItems[config.id] = DockItem(id: config.id, title: config.title, side: config.side);
      }
    }
  }

  /// Get items that belong to this tab
  List<DockItem> getItemsForTab() {
    /// Return only items that are configured for this tab
    return widget.dockItemList.map((config) => _globalDockItems[config.id]!).where((item) => item != null).toList();
  }

  /// Get config for a specific item
  DockItemConfig? getConfigForItem(String itemId) {
    return widget.dockItemList.firstWhere((config) => config.id == itemId, orElse: () => widget.dockItemList.first);
  }

  /// Handle drag end to determine docking or floating
  void _handleItemDragEnd(DockItem item, DraggableDetails details, double screenWidth) {
    setState(() {
      final dx = details.offset.dx;
      if (widget.showLeft && dx < 120) {
        item.docked = true;
        item.expanded = false;
        item.side = "left";
      } else if (widget.showRight && dx > screenWidth - 220) {
        item.docked = true;
        item.expanded = false;
        item.side = "right";
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

    return Stack(
      children: [
        Row(
          children: [
            if (widget.showLeft)
              FusionDockSidebar(
                side: "left",
                items: items.where((i) => i.docked && i.side == "left").toList(),
                itemConfigs: widget.dockItemList,
                onItemUndock: _handleItemUndock,
                onExpansionChanged: _handleExpansionChanged,
              ),

            Expanded(child: widget.mainArea),

            if (widget.showRight)
              FusionDockSidebar(
                side: "right",
                items: items.where((i) => i.docked && i.side == "right").toList(),
                itemConfigs: widget.dockItemList,
                onItemUndock: _handleItemUndock,
                onExpansionChanged: _handleExpansionChanged,
              ),
          ],
        ),

        // Floating panels
        for (var item in items.where((i) => !i.docked))
          if ((item.side == "left" && widget.showLeft) || (item.side == "right" && widget.showRight))
            Positioned(
              left: item.position.dx,
              top: item.position.dy,
              child: FusionFloatingPanel(
                item: item,
                config: getConfigForItem(item.id),
                onDragEnd: (details) => _handleItemDragEnd(item, details, screenWidth),
                onClose: () => onCloseButtonPressed(item),
                onResize: (deltaX, deltaY) => _handleItemResize(item, deltaX, deltaY),
              ),
            ),
      ],
    );
  }
}
