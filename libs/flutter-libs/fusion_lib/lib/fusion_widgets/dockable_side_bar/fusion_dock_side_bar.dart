import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

import '../../constants/test_keys.dart';
import '../../models/dock_item_config.dart';
import '../../models/fusion_dock_item.dart';

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
        return item != null;
      },
      onAccept: (DockItem item) {
        print("Item ${item.title} docked to $side sidebar");
      },
      builder: (BuildContext context, List<DockItem?> candidateItems, List<dynamic> rejectedItems) {
        final bool hasIncomingData = candidateItems.isNotEmpty;
        return SemanticHelper.container(
          testId: SemanticHelper.createTestId(SemanticTypes.container, side == "left" ? FusionTestKeys.dockLeftSideBar : FusionTestKeys.dockRightSideBar),
          child: Container(
            width: 240,
            height: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 1, vertical: 4),

            decoration: BoxDecoration(
              color: hasIncomingData ? const Color(0xFF80C7FF) : context.colorScheme.elevation1,
              border: Border.all(color: context.colorScheme.elevation2, width: 1),
              borderRadius: const BorderRadius.all(Radius.circular(12)),
              // border: Border(
              //   right: side == "left" ? BorderSide(color: Theme.of(context).colorScheme.primaryBlack, width: 1) : BorderSide.none,
              //   left: side == "right" ? BorderSide(color: Theme.of(context).colorScheme.primaryBlack, width: 1) : BorderSide.none,
              // ),
            ),
            child: ListView(
              physics: const ClampingScrollPhysics(),
              children: items.map((item) {
                final config = getConfigForItem(item.id);
                if (config == null || !config.isVisible) {
                  return const SizedBox.shrink();
                }

                // Only show items that are configured for this tab
                final bool isConfiguredForThisTab = itemConfigs.any((c) => c.id == item.id);
                if (!isConfiguredForThisTab) {
                  return const SizedBox.shrink();
                }

                if (config.isCollapsibleSection) {
                  final int index = items.indexOf(item);
                  return SemanticHelper.listItem(
                    testId: SemanticHelper.createTestId(SemanticTypes.listItem, "${config.title}_$index"),
                    index: index,
                    child: FusionExpandableTileWidget(
                      item: item,
                      config: config,
                      onUndock: onItemUndock,
                      onExpansionChanged: onExpansionChanged,
                      controller: config.controller,
                    ),
                  );
                } else {
                  return config.dockItemWidget;
                }
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}
