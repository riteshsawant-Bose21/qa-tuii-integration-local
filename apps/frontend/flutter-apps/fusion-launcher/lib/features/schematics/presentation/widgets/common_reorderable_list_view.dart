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
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ),
      );
    }

    return ReorderableListView.builder(
      proxyDecorator: proxyDecorator ?? _defaultProxyDecorator,
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: items.length,
      onReorder: onReorder,
      itemBuilder: (BuildContext context, int index) {
        final T item = items[index];
        return ReorderableDragStartListener(
          key: ValueKey<String>(keyExtractor(item)),
          index: index,
          child: itemBuilder(context, item, index),
        );
      },
    );
  }

  Widget _defaultProxyDecorator(Widget child, int index, Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) {
        return Transform.scale(
          scale: 1.05,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
