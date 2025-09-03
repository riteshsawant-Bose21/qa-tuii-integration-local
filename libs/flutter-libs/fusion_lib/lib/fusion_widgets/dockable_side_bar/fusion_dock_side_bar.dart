import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

import '../../models/dock_item_config.dart';
import '../../models/fusion_dock_item.dart';
import '../text_views/fusion_app_text.dart';
import 'fusion_dock_floating_panel.dart';

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
              return config != null
                  ? SidebarPanel(item: item, config: config, onUndock: onItemUndock, onExpansionChanged: onExpansionChanged)
                  : const SizedBox.shrink();
            }).toList(),
          ),
        );
      },
    );
  }
}

class SidebarPanel extends StatelessWidget {
  final DockItem item;
  final DockItemConfig config;
  final void Function(DockItem, DraggableDetails) onUndock;
  final void Function(DockItem, bool) onExpansionChanged;

  const SidebarPanel({super.key, required this.item, required this.config, required this.onUndock, required this.onExpansionChanged});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.white,
          border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.dividerColor, width: 1)),
        ),
        child: ExpansionTile(
          minTileHeight: 24,
          iconColor: Theme.of(context).colorScheme.fusionTextViewColor,
          title: Draggable<DockItem>(
            data: item,
            feedback: FloatingWidget(
              item: item,
              config: config,
              resizing: false,
              onClose: () {}, // No-op for feedback
              onResize: (_, __) {}, // No-op for feedback
            ),

            /// make the original widget semi transparent when dragging
            childWhenDragging: Opacity(
              opacity: 0.3,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
                child: FusionAppText(text: item.title, style: Theme.of(context).textTheme.bodySmall),
              ),
            ),
            onDragEnd: (details) => onUndock(item, details),
            child: FusionAppText(text: item.title, style: Theme.of(context).textTheme.bodySmall),
          ),
          initiallyExpanded: item.expanded,
          onExpansionChanged: (val) => onExpansionChanged(item, val ?? false),
          children: [config.widgetBuilder()],
        ),
      ),
    );
  }
}
