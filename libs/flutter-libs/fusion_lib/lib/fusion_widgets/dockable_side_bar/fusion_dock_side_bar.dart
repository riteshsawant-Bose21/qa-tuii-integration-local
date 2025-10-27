import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

import '../../models/dock_item_config.dart';
import '../../models/fusion_dock_item.dart';
import '../others/fusion_expandable_tile_widget.dart';

class FusionDockSidebar extends StatelessWidget {
  final String side;
  final List<DockItem> items;
  final List<DockItemConfig> itemConfigs;
  final void Function(DockItem, DraggableDetails) onItemUndock;
  final void Function(DockItem, bool) onExpansionChanged;

  const FusionDockSidebar({
    super.key,
    required this.side,
    required this.items,
    required this.itemConfigs,
    required this.onItemUndock,
    required this.onExpansionChanged,
  });

  DockItemConfig? getConfigForItem(String itemId) {
    try {
      return itemConfigs.firstWhere((config) => config.id == itemId);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DragTarget<DockItem>(
      onWillAccept: (DockItem? item) {
        // Only accept items that can be docked to this side
        return item != null;
      },
      onAccept: (DockItem item) {
        // Handle docking to this sidebar
        print("Item ${item.title} docked to $side sidebar");
        // This will be handled by the main drag end logic
      },
      builder: (BuildContext context, List<DockItem?> candidateItems, List<dynamic> rejectedItems) {
        final bool hasIncomingData = candidateItems.isNotEmpty;
        return Container(
          width: 240,
          height: double.infinity,
          decoration: BoxDecoration(
            color: hasIncomingData ? const Color(0xFF80C7FF) : Theme.of(context).colorScheme.white,
            border: Border(
              /// side == "left" show right border or left border
              right: side == "left" ? BorderSide(color: Theme.of(context).colorScheme.dividerColor, width: 1) : BorderSide.none,
              left: side == "right" ? BorderSide(color: Theme.of(context).colorScheme.dividerColor, width: 1) : BorderSide.none,
            ),
          ),
          child: ListView(
            physics: const ClampingScrollPhysics(),
            children: items.map((item) {
              final config = getConfigForItem(item.id);
              if (config != null && !config.isVisible) {
                return SizedBox.shrink();
              }
              return config != null
                  ? config.isCollapsibleSection
                        ? FusionExpandableTileWidget(
                            item: item,
                            config: config,
                            onUndock: onItemUndock,
                            onExpansionChanged: onExpansionChanged,
                            controller: config.controller,
                          )
                        : config.dockItemWidget()
                  : const SizedBox.shrink();
            }).toList(),
          ),
        );
      },
    );
  }
}
