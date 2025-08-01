import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fusion_design_tool_prototype/core/constants.dart';
import 'package:fusion_design_tool_prototype/features/dynamic_config/presentation/pages/panel_page.dart';

import '../../../../../core/models/processing_block_entity.dart';

enum ProcessingType { input, zone, mix, output }

class ProcessingBlockView extends StatefulWidget {
  final List<ProcessingBlockEntity> selectedBlocks;
  final Function(ProcessingBlockEntity) onBlockSelected;
  final Function(int index) onBlockRemoved;
  final Function(List<ProcessingBlockEntity>) onBlocksUpdated;
  final ProcessingType processingType;
  final bool isControlMode;

  const ProcessingBlockView({
    super.key,
    required this.selectedBlocks,
    required this.onBlockSelected,
    required this.onBlockRemoved,
    required this.onBlocksUpdated,
    required this.processingType,
     required this.isControlMode,
  });

  @override
  State<ProcessingBlockView> createState() => _ProcessingBlockViewState();
}

class _ProcessingBlockViewState extends State<ProcessingBlockView> {
  final ScrollController _horizontalScrollController = ScrollController();

  void _removeBlock(int index) {
    widget.onBlockRemoved(index);
  }

  void _reorderBlocks(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final ProcessingBlockEntity block = widget.selectedBlocks.removeAt(
      oldIndex,
    );
    widget.selectedBlocks.insert(newIndex, block);
    widget.onBlocksUpdated(widget.selectedBlocks);
  }

  List<ProcessingBlockEntity> get _availableBlocks {
    switch (widget.processingType) {
      case ProcessingType.input:
        return ProcessingBlockEntity.inputBlocks;
      case ProcessingType.zone:
        return ProcessingBlockEntity.zoneBlocks;
      case ProcessingType.mix:
        return ProcessingBlockEntity.mixBlocks;
      case ProcessingType.output:
        return ProcessingBlockEntity.outputBlocks;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardSoft,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colors.outline.withAlpha((0.2 * 255).toInt()),
              ),
            ),
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(Icons.memory, size: 18, color: colors.tertiary),
                        const SizedBox(width: 8),
                        Text(
                          'Processing Blocks',
                          style: Theme.of(
                            context,
                          ).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.tertiary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colors.tertiaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${widget.selectedBlocks.length}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: colors.onTertiaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (!widget.isControlMode)
                      PopupMenuButton<ProcessingBlockEntity>(
                        tooltip: 'Add processing block',
                        onSelected: (ProcessingBlockEntity selectedBlock) {
                          // Handle selection
                          // print('Selected: ${selectedBlock.name}');

                          //update the id with copyWith
                          selectedBlock = selectedBlock.copyWith(
                            id: '${selectedBlock.name.toLowerCase().replaceAll(' ', '')}${DateTime.now().millisecondsSinceEpoch}',
                          );
                          // Your logic here
                          widget.onBlockSelected(selectedBlock);
                        },
                        color: Colors.white,
                        itemBuilder: (BuildContext context) {
                          return _availableBlocks.map((
                            ProcessingBlockEntity block,
                          ) {
                            return PopupMenuItem<ProcessingBlockEntity>(
                              value: block,
                              child: Row(
                                children: <Widget>[
                                  Icon(block.icon, size: 20),
                                  const SizedBox(width: 8),
                                  Text(block.name),
                                ],
                              ),
                            );
                          }).toList();
                        },
                        child: FilledButton.tonalIcon(
                          icon: const Icon(Icons.add, size: 14),
                          label: Text(
                            'Add',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: colors.primary,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            disabledBackgroundColor: colors.primaryContainer,
                            disabledForegroundColor: colors.primary,
                          ),
                          onPressed: null,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (widget.selectedBlocks.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest.withAlpha(
                        (0.3 * 255).toInt(),
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: colors.outline.withAlpha((0.2 * 255).toInt()),
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Row(
                      children: <Widget>[
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: colors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'No processing blocks selected',
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  // Processing Chain Layout
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(left: 5, right: 5),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[50],
                    ),
                    child: Scrollbar(
                      controller: _horizontalScrollController,
                      thumbVisibility: true,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 5),
                        height: 50,
                        child: ReorderableListView(
                          scrollController: _horizontalScrollController,
                          scrollDirection: Axis.horizontal,
                          buildDefaultDragHandles: false,
                          onReorder: _reorderBlocks,
                          children:
                              widget.selectedBlocks.asMap().entries.map((
                                MapEntry<int, ProcessingBlockEntity> entry,
                              ) {
                                final int index = entry.key;
                                final ProcessingBlockEntity block = entry.value;
                                final bool isLast = index == widget.selectedBlocks.length - 1;

                                return Container(
                                  key: ValueKey<String>("${block.id}$index"),
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      // Processing Block with drag handle
                                      ReorderableDragStartListener(
                                        index: index,
                                        child: GestureDetector(
                                          onLongPress: () {
                                            // Visual feedback for drag start
                                            HapticFeedback.lightImpact();
                                          },
                                          onTap: () {
                                            if(!widget.isControlMode) return;

                                            //navigate to the PanelPage()

                                            //show dialog for PanelPage

                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  backgroundColor: AppColors.cardSoft,
                                                  title: Row(
                                                    children: <Widget>[
                                                      Expanded(
                                                        child: Center(
                                                          child: Text(
                                                            block.name,
                                                          ),
                                                        ),
                                                      ),

                                                      //close Text button with x icon
                                                      IconButton(
                                                        icon: const Icon(
                                                          Icons.close,
                                                          size: 25,
                                                          color: Colors.red,
                                                        ),
                                                        onPressed: () {
                                                          Navigator.of(
                                                            context,
                                                          ).pop();
                                                        },
                                                        tooltip: 'Close',
                                                        padding: EdgeInsets.zero,
                                                        constraints: const BoxConstraints(),
                                                      ),
                                                    ],
                                                  ),
                                                  content: SizedBox(
                                                    width: min(
                                                      700,
                                                      MediaQuery.of(
                                                            context,
                                                          ).size.width *
                                                          0.9,
                                                    ),
                                                    height:
                                                        MediaQuery.of(
                                                          context,
                                                        ).size.height *
                                                        0.9,
                                                    child: PanelPage(
                                                      processingBlockEntity: block,
                                                    ),
                                                  ),
                                                );
                                              },
                                            );
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(
                                                color: Colors.grey[400]!,
                                              ),
                                              boxShadow: <BoxShadow>[
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.05),
                                                  blurRadius: 2,
                                                  offset: const Offset(0, 1),
                                                ),
                                              ],
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: <Widget>[
                                                Icon(
                                                  block.icon,
                                                  size: 14,
                                                  color: Colors.black87,
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  block.name,
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                if (!widget.isControlMode)
                                                  GestureDetector(
                                                    onTap: () => _removeBlock(index),
                                                    child: Container(
                                                      padding: const EdgeInsets.all(2),
                                                      child: Icon(
                                                        Icons.close,
                                                        size: 12,
                                                        color: Colors.red[600],
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),

                                      // Arrow indicator (except for last item)
                                      if (!isLast) ...<Widget>[
                                        const SizedBox(width: 8),
                                        Icon(
                                          Icons.arrow_forward,
                                          size: 14,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                    ],
                                  ),
                                );
                              }).toList(),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (widget.selectedBlocks.isNotEmpty) const SizedBox(height: 12.0),
        ],
      ),
    );
  }
}
