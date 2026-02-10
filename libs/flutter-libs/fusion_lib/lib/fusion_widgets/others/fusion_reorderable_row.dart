import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ReorderableRow<T> extends StatefulWidget {
  final List<T> items;

  final void Function(int oldIndex, int newIndex) onReorder;
  final Widget Function(BuildContext context, T item) itemBuilder;

  const ReorderableRow({
    super.key,
    required this.items,
    required this.onReorder,
    required this.itemBuilder,
  });

  @override
  State<ReorderableRow> createState() => _ReorderableRowState<T>();
}

class _ReorderableRowState<T> extends State<ReorderableRow<T>> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  void _handleReorder(int oldIndex, int newIndex) {
    final adjustedNewIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
    // ✅ Return indexes instead of list
    widget.onReorder(oldIndex, adjustedNewIndex);

    // ✅ Haptic on reorder commit
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      scrollController: _scrollController,
      scrollDirection: Axis.horizontal,
      buildDefaultDragHandles: false,
      onReorder: _handleReorder,
      itemCount: widget.items.length,
      itemBuilder: (context, index) {
        return Padding(
          key: ValueKey(index),
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: ReorderableDragStartListener(
            index: index,
            child: widget.itemBuilder(context, widget.items[index]),
          ),
        );
      },
    );
  }
}
