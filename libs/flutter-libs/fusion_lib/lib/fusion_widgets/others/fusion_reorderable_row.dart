import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fusion_lib/fusion_lib.dart';

class ReorderableRow<T> extends StatelessWidget {
  const ReorderableRow({
    super.key,
    required this.items,
    required this.onReorder,
    required this.itemBuilder,
    this.extractId,
    this.semanticId,
    this.childPadding,
  });
  final String? semanticId;
  final List<T> items;
  final String Function(T item)? extractId;
  final EdgeInsetsGeometry? childPadding;

  final void Function(int oldIndex, int newIndex) onReorder;
  final Widget Function(BuildContext context, T item) itemBuilder;
  @override
  Widget build(BuildContext context) {
    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(
        SemanticTypes.section,
        "fusion_reorderable_${semanticId ?? ""}",
      ),
      child: ReorderableFlex<T>(
        direction: Axis.horizontal,
        items: items,
        onReorder: onReorder,
        itemBuilder: itemBuilder,
        extractId: extractId,
        childPadding:
            childPadding ?? EdgeInsets.symmetric(horizontal: 5, vertical: 0),
      ),
    );
  }
}

class ReorderableColumn<T> extends StatelessWidget {
  const ReorderableColumn({
    this.semanticId,
    super.key,
    required this.items,
    required this.onReorder,
    required this.itemBuilder,
    this.extractId,
    this.childPadding,
  });
  final String? semanticId;

  final List<T> items;
  final String Function(T item)? extractId;

  final void Function(int oldIndex, int newIndex) onReorder;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final EdgeInsetsGeometry? childPadding;

  @override
  Widget build(BuildContext context) {
    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(
        SemanticTypes.section,
        "fusion_reorderable_${semanticId ?? ""}",
      ),
      child: ReorderableFlex<T>(
        direction: Axis.vertical,
        items: items,
        onReorder: onReorder,
        itemBuilder: itemBuilder,
        extractId: extractId,
        childPadding:
            childPadding ??
            const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      ),
    );
  }
}

class ReorderableFlex<T> extends StatefulWidget {
  const ReorderableFlex({
    super.key,
    this.semanticId,
    required this.items,
    required this.onReorder,
    required this.itemBuilder,
    required this.direction,
    this.extractId,
    this.childPadding = const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
  });
  final List<T> items;
  final String? semanticId;

  final void Function(int oldIndex, int newIndex) onReorder;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final String Function(T item)? extractId;
  final Axis direction;
  final EdgeInsetsGeometry childPadding;
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
    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(
        SemanticTypes.section,
        "fusion_reorderable_${widget.semanticId ?? ""}",
      ),

      child: ReorderableListView.builder(
        scrollController: _scrollController,
        scrollDirection: widget.direction,
        buildDefaultDragHandles: false,
        shrinkWrap: true,
        onReorder: _handleReorder,
        itemCount: widget.items.length,
        itemBuilder: (context, index) {
          return Padding(
            key: ValueKey(
              widget.extractId != null
                  ? widget.extractId!(widget.items[index])
                  : index,
            ),
            padding: widget.childPadding,
            child: ReorderableDragStartListener(
              index: index,
              child: widget.itemBuilder(context, widget.items[index]),
            ),
          );
        },
      ),
    );
  }
}
