import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

import '../../models/dock_item_config.dart';
import '../../models/fusion_dock_item.dart';
import '../text_views/fusion_app_text.dart';
import 'fuison_resize_handle.dart';

class FusionFloatingPanel extends StatefulWidget {
  final DockItem item;
  final DockItemConfig? config;
  final void Function(DraggableDetails) onDragEnd;
  final void Function(double, double) onResize;
  final void Function() onClose;
  final void Function()? onTap;
  final void Function()? onDragStart;

  const FusionFloatingPanel({
    super.key,
    required this.item,
    required this.config,
    required this.onDragEnd,
    required this.onResize,
    required this.onClose,
    this.onTap,
    this.onDragStart,
  });

  @override
  State<FusionFloatingPanel> createState() => _FusionFloatingPanelState();
}

class _FusionFloatingPanelState extends State<FusionFloatingPanel> {
  bool highlight = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Draggable<DockItem>(
        data: widget.item,
        onDragStarted: widget.onDragStart,
        feedback: FloatingWidget(
          item: widget.item,
          config: widget.config,
          onClose: widget.onClose,
          resizing: false,
          onResize: (_, __) {},
          highlight: highlight, // pass state
        ),
        childWhenDragging: Container(),
        onDragUpdate: (details) {
          final dx = details.globalPosition.dx;
          final screenWidth = MediaQuery.of(context).size.width;

          bool shouldHighlight = dx < 240 || dx > (screenWidth - 240);

          if (shouldHighlight != highlight) {
            print("Highlight changed: $shouldHighlight, dx: $dx, screenWidth: $screenWidth");
            setState(() {
              highlight = shouldHighlight;
            });
          }
        },
        onDragEnd: (details) {
          print("Drag ended, resetting highlight");
          setState(() {
            highlight = false; // reset after drag
          });
          widget.onDragEnd(details);
        },
        child: FloatingWidget(
          item: widget.item,
          config: widget.config,
          resizing: true,
          onResize: widget.onResize,
          onClose: widget.onClose,
          highlight: highlight,
        ),
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
  final bool highlight;

  const FloatingWidget({
    super.key,
    required this.item,
    required this.config,
    required this.resizing,
    required this.onResize,
    required this.onClose,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: item.width,
        height: item.height,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.white,
          borderRadius: BorderRadius.circular(6),
          // Fixed: More explicit border logic with fallback color
          border: Border.all(color: highlight ? Colors.blue : (Theme.of(context).colorScheme.dividerColor ?? Colors.grey.shade300), width: 2),
        ),
        child: Stack(
          children: [
            // header + close button
            Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.white,
                border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.dividerColor, width: 1)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: FusionAppText(text: item.title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11)),
                  ),
                  IconButton(icon: const Icon(Icons.close, size: 16), onPressed: onClose, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                ],
              ),
            ),

            // Content
            Positioned(
              top: 32,
              left: 0,
              right: 0,
              bottom: resizing ? 0 : 0,
              child: SingleChildScrollView(
                child: config?.widgetBuilder() ?? Container(alignment: Alignment.center, child: Text("${item.title} content")),
              ),
            ),

            if (resizing) Positioned(right: 0, bottom: 0, child: FusionResizeHandle(onResize: onResize)),
          ],
        ),
      ),
    );
  }
}
