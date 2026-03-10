import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

class CommonReorderableListView<T> extends StatelessWidget {
  final List<T> items;
  final String emptyMessage;
  final void Function(int oldIndex, int newIndex) onReorder;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final String Function(T item) keyExtractor;
  final Widget Function(Widget child, int index, Animation<double> animation)? proxyDecorator;

  const CommonReorderableListView({
    super.key,
    required this.items,
    required this.emptyMessage,
    required this.onReorder,
    required this.itemBuilder,
    required this.keyExtractor,
    this.proxyDecorator,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: FusionAppText(
            text: emptyMessage,
            textAlign: TextAlign.center,
            style: context.textTheme.bodySmall?.copyWith(
              fontSize: FusionSizes.fontSize12,
              color: context.colorScheme.textBody,
            ),
          ),
        ),
      );
    }

    return ReorderableListView.builder(
      proxyDecorator: proxyDecorator ?? (Widget child, int index, Animation<double> animation) => child,
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: items.length,
      onReorder: (int oldIndex, int newIndex) {
        final int adjustedNewIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
        onReorder(oldIndex, adjustedNewIndex);
      },
      itemBuilder: (BuildContext context, int index) {
        final T item = items[index];
        return ReorderableDragStartListener(
          key: ValueKey<String>(keyExtractor(item)),
          index: index,
          child: Material(color: Colors.transparent, child: itemBuilder(context, item, index)),
        );
      },
    );
  }
}
