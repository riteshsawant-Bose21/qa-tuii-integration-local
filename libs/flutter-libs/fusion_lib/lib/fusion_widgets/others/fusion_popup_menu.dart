import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

class FusionPopupMenu<T> extends StatelessWidget {
  const FusionPopupMenu({
    super.key,
    required this.items,
    required this.onSelected,
    this.itemBuilder,
    this.itemLabels,
    this.matchChildWidth = true,
    required this.child,
    this.tooltip,
    this.popupOffset = const Offset(10, 10),
  });
  final List<T> items;
  final ValueChanged<T> onSelected;
  final Widget Function(BuildContext, T)? itemBuilder;
  final Map<T, String>? itemLabels;
  final bool matchChildWidth;
  final Widget child;
  final String? tooltip;
  final Offset popupOffset;
  @override
  Widget build(BuildContext context) {
    final childKey = GlobalKey();
    return PopupMenuButton<T>(
      tooltip: tooltip,
      position: PopupMenuPosition.under,
      menuPadding: EdgeInsets.zero,
      offset: popupOffset,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: context.colorScheme.strokeLight, width: 2),
      ),
      color: context.colorScheme.elevation2,
      itemBuilder: (context) => List<PopupMenuEntry<T>>.generate(
        items.length,
        (index) {
          final T item = items[index];
          var findRenderObject = (childKey.currentContext?.findRenderObject() as RenderBox?);
          var width2 = matchChildWidth ? findRenderObject?.size.width : null;
          return PopupMenuItem<T>(
            value: item,

            padding: EdgeInsets.all(0),
            child: SizedBox(
              width: width2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: itemBuilder != null
                    ? itemBuilder!(context, item)
                    : FusionAppText(
                        text: itemLabels != null && itemLabels!.containsKey(item) ? itemLabels![item]! : item.toString(),
                        style: context.textTheme.bodySmall,
                      ),
              ),
            ),
          );
        },
      ),
      onSelected: onSelected,
      child: Container(key: childKey, child: child),
    );
  }
}
