import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_theme/fusion_sizes.dart';

import '../../models/dock_item_config.dart';
import '../../models/fusion_dock_item.dart';
import '../text_views/fusion_app_text.dart';
import 'fuison_resize_handle.dart';

class FusionFloatingPanel extends StatelessWidget {
  final DockItem item;
  final DockItemConfig? config;
  final void Function(DraggableDetails) onDragEnd;
  final void Function(double, double) onResize;
  final void Function() onClose;
  final void Function()? onTap; // Add tap callback
  final void Function()? onDragStart; // Add drag start callback

  const FusionFloatingPanel({
    super.key,
    required this.item,
    required this.config,
    required this.onDragEnd,
    required this.onResize,
    required this.onClose,
    this.onTap, // Add tap callback
    this.onDragStart, // Add drag start callback
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, // Handle tap to bring to front
      child: Draggable<DockItem>(
        data: item,
        onDragStarted: onDragStart, // Handle drag start to bring to front
        feedback: FloatingWidget(
          item: item,
          config: config,
          onClose: onClose,
          resizing: false,
          onResize: (_, __) {}, // No-op for feedback
        ),
        childWhenDragging: Container(),
        onDragEnd: onDragEnd,
        child: FloatingWidget(item: item, config: config, resizing: true, onResize: onResize, onClose: onClose),
      ),
    );
  }
}

class FloatingWidget extends StatelessWidget {
  final DockItem item;
  final void Function() onClose;
  final DockItemConfig? config;
  final bool resizing;
  final void Function(double, double) onResize;

  const FloatingWidget({super.key, required this.item, required this.config, required this.resizing, required this.onResize, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(FusionSizes.borderRadius16),
      child: Container(
        width: item.width,
        height: item.height,
        decoration: BoxDecoration(
          color: context.colorScheme.elevation1,
          borderRadius: BorderRadius.circular(FusionSizes.borderRadius16),
          border: Border.all(color: Theme.of(context).colorScheme.elevation2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(FusionSizes.borderRadius16),
          child: Stack(
            children: [
              /// floating header with close button
              Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: context.colorScheme.elevation1,
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).colorScheme.elevation2,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: FusionAppText(
                        text: config?.title ?? item.title,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: onClose,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

              /// Content area
              Positioned(
                top: 32,
                left: 0,
                right: 0,
                bottom: resizing ? 0 : 0,
                child: SingleChildScrollView(
                  child:
                      config?.dockItemWidget ??
                      Container(
                        padding: EdgeInsets.all(16),
                        alignment: Alignment.center,
                        child: FusionAppText(
                          text: "${item.title} content",
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: context.colorScheme.elevation5,
                          ),
                        ),
                      ),
                ),
              ),

              if (resizing) Positioned(right: 0, bottom: 0, child: FusionResizeHandle(onResize: onResize)),
            ],
          ),
        ),
      ),
    );
  }
}
