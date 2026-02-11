import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ReorderableRow<T> extends StatelessWidget {
  const ReorderableRow({
    super.key,
    required this.items,
    required this.onReorder,
    required this.itemBuilder,
    this.extractId,
  });
  final List<T> items;
  final String Function(T item)? extractId;

  final void Function(int oldIndex, int newIndex) onReorder;
  final Widget Function(BuildContext context, T item) itemBuilder;
  @override
  Widget build(BuildContext context) {
    return ReorderableFlex<T>(
      direction: Axis.horizontal,
      items: items,
      onReorder: onReorder,
      itemBuilder: itemBuilder,
      extractId: extractId,
    );
  }
}

class ReorderableColumn<T> extends StatelessWidget {
  const ReorderableColumn({
    super.key,
    required this.items,
    required this.onReorder,
    required this.itemBuilder,
    this.extractId,
  });
  final List<T> items;
  final String Function(T item)? extractId;

  final void Function(int oldIndex, int newIndex) onReorder;
  final Widget Function(BuildContext context, T item) itemBuilder;
  @override
  Widget build(BuildContext context) {
    return ReorderableFlex<T>(
      direction: Axis.vertical,
      items: items,
      onReorder: onReorder,
      itemBuilder: itemBuilder,
      extractId: extractId,
    );
  }
}

class ReorderableFlex<T> extends StatefulWidget {
  const ReorderableFlex({
    super.key,
    required this.items,
    required this.onReorder,
    required this.itemBuilder,
    required this.direction,
    this.extractId,
  });
  final List<T> items;

  final void Function(int oldIndex, int newIndex) onReorder;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final String Function(T item)? extractId;
  final Axis direction;
  @override
  State<ReorderableFlex<T>> createState() => _ReorderableFlexState<T>();
}

class _ReorderableFlexState<T> extends State<ReorderableFlex<T>> {
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
      scrollDirection: widget.direction,
      buildDefaultDragHandles: false,
      shrinkWrap: true,
      onReorder: _handleReorder,
      itemCount: widget.items.length,
      itemBuilder: (context, index) {
        return Padding(
          key: ValueKey(widget.extractId != null ? widget.extractId!(widget.items[index]) : index),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
          child: ReorderableDragStartListener(
            index: index,
            child: widget.itemBuilder(context, widget.items[index]),
          ),
        );
      },
    );
  }
}
