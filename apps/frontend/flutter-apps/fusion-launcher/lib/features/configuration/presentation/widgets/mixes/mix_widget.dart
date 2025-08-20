import 'package:flutter/material.dart';

import '../../../../../core/constants.dart';
import '../../../../../core/models/mix_entity.dart';
import '../../../../../core/models/processing_block_entity.dart';
import '../../../../../core/models/source_entity.dart';
import '../common/processing_block_view.dart';
import 'multi_device_selection_dialog.dart';

class MixWidget extends StatefulWidget {
  final Mix mix;
  final List<Source> availableSources;
  final void Function(Mix) onMixUpdated;
  final void Function() duplicateMix;
  final Function() onDelete;
  final bool isControlMode;

  const MixWidget({
    super.key,
    required this.mix,
    required this.availableSources,
    required this.onMixUpdated,
    required this.onDelete,
    required this.duplicateMix,
    required this.isControlMode,
  });

  @override
  MixWidgetState createState() => MixWidgetState();
}

class MixWidgetState extends State<MixWidget> {
  Future<void> pickInputs(Mix mix) async {
    final List<Source>? picked = await showDialog<List<Source>>(
      context: context,
      builder:
          (_) => MultiDevicePickerDialog(
            title: 'Pick Input Devices',
            devices: widget.availableSources,
            initiallySelected: mix.sourceIds.map((String id) => widget.availableSources.firstWhere((Source s) => s.id == id)).toList(),
          ),
    );
    if (picked != null) {
      final List<String> selectedIds = picked.map((Source s) => s.id).toList();

      //set mix source levels to default if not already set
      final Map<String, double> updatedLevels = <String, double>{};
      for (final String id in selectedIds) {
        if (!mix.sourceMixLevels.containsKey(id)) {
          updatedLevels[id] = 0.0; // Default level
        } else {
          updatedLevels[id] = mix.sourceMixLevels[id]!;
        }
      }

      final Mix updatedMix = mix.copyWith(sourceIds: selectedIds);
      widget.onMixUpdated(updatedMix);
    }
  }

  @override
  Widget build(BuildContext ctx) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: AppColors.cardSoft,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: const BorderSide(color: AppColors.borderSoft),
      ),
      margin: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          title: Row(
            children: <Widget>[
              Expanded(
                child: TextFormField(
                  key: ValueKey<String>(widget.mix.id),
                  initialValue: widget.mix.name,
                  enabled: widget.isControlMode ? false : true,
                  decoration: const InputDecoration(
                    hintText: 'Input Mix Name',
                    border: InputBorder.none,
                  ),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: colors.onSurface, fontSize: 13),
                  onChanged: (String v) {
                    final Mix updatedMix = widget.mix.copyWith(name: v);
                    widget.onMixUpdated(updatedMix);
                  },
                ),
              ),
              if (!widget.isControlMode)
                IconButton(
                  icon: const Icon(Icons.copy_outlined, size: 16),
                  tooltip: 'Duplicate Mix',
                  onPressed: () {
                    widget.duplicateMix();
                  },
                ),
              if (!widget.isControlMode)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 16),
                  tooltip: 'Delete Mix',
                  onPressed: () {
                    widget.onDelete();
                  },
                ),
            ],
          ),
          children: <Widget>[
            // Inputs Section
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.cardSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.outline.withOpacity(0.2)),
                ),
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Icon(Icons.input, size: 18, color: colors.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Input Devices',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: colors.primary, fontSize: 12),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: colors.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${widget.mix.sourceIds.length}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: colors.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (!widget.isControlMode)
                          FilledButton.tonalIcon(
                            icon: const Icon(Icons.add, size: 16),
                            label: Text('Add', style: TextStyle(fontSize: 12, color: colors.onPrimaryContainer)),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () => pickInputs(widget.mix),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (widget.mix.sourceIds.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colors.surfaceVariant.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: colors.outline.withOpacity(0.2),
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Row(
                          children: <Widget>[
                            Icon(Icons.info_outline, size: 16, color: colors.onSurfaceVariant),
                            const SizedBox(width: 8),
                            Text(
                              'No input devices selected',
                              style: TextStyle(
                                color: colors.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: widget.mix.sourceIds.length,
                          separatorBuilder: (BuildContext context, int index) {
                            return Divider(
                              height: 1,
                              color: Colors.grey[200],
                            );
                          },
                          itemBuilder: (BuildContext context, int index) {
                            final String id = widget.mix.sourceIds[index];
                            final Source source = widget.availableSources.firstWhere(
                              (Source s) => s.id == id,
                            );
                            final double currentValue =
                                widget.mix.sourceMixLevels.containsKey(source.id) ? double.parse(widget.mix.sourceMixLevels[source.id].toString()) : 0.0;

                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      Expanded(
                                        child: Text(
                                          key: ValueKey<String>(source.id),
                                          source.name,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '${currentValue.toInt()} dB',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      if (!widget.isControlMode)
                                        GestureDetector(
                                          onTap: () {
                                            final Mix updatedMix = widget.mix.copyWith(
                                              sourceIds: List<String>.from(widget.mix.sourceIds)..removeAt(index),
                                            );
                                            widget.onMixUpdated(updatedMix);
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[200],
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              size: 10,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),

                                  // Slider
                                  Row(
                                    children: <Widget>[
                                      Text(
                                        '-80',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      Expanded(
                                        child: SliderTheme(
                                          data: SliderTheme.of(context).copyWith(
                                            trackHeight: 1.5,
                                            thumbShape: const RoundSliderThumbShape(
                                              enabledThumbRadius: 5,
                                            ),
                                            overlayShape: const RoundSliderOverlayShape(
                                              overlayRadius: 16,
                                            ),
                                            activeTrackColor: Colors.black87,
                                            inactiveTrackColor: Colors.grey[300],
                                            thumbColor: Colors.black87,
                                            overlayColor: Colors.black12,
                                          ),
                                          child: Slider(
                                            value: currentValue,
                                            min: -80.0,
                                            max: 0.0,
                                            divisions: 80,
                                            onChanged: (double value) {
                                              final Map<String, double> updatedLevels = Map<String, double>.from(
                                                widget.mix.sourceMixLevels,
                                              );
                                              updatedLevels[source.id] = value;
                                              final Mix updatedMix = widget.mix.copyWith(sourceMixLevels: updatedLevels);
                                              widget.onMixUpdated(updatedMix);
                                            },
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '0',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    // Wrap(
                    //   spacing: 8,
                    //   runSpacing: 8,
                    //   children: widget.mix.sourceIds.asMap().entries.map((MapEntry<int, String> sourceId) {
                    //     final String d = sourceId.value;
                    //     final int deviceIndex = sourceId.key;
                    //     final Source source = widget.availableSources.firstWhere(
                    //       (Source s) => s.id == d,
                    //     );
                    //     return Chip(
                    //       label: Text(source.name),
                    //       avatar: const Icon(Icons.device_hub, size: 16),
                    //       backgroundColor: colors.secondaryContainer,
                    //       labelStyle: TextStyle(color: colors.onSecondaryContainer),
                    //       deleteIcon: const Icon(Icons.close, size: 16),
                    //       onDeleted: () {
                    //         final Mix updatedMix = widget.mix.copyWith(
                    //           sourceIds: List<String>.from(widget.mix.sourceIds)..removeAt(deviceIndex),
                    //         );
                    //         widget.onMixUpdated(updatedMix);
                    //
                    //       },
                    //     );
                    //   }).toList(),
                    // ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 5),
            //Processing blocks
            ProcessingBlockView(
              processingType: ProcessingType.mix,
              selectedBlocks: widget.mix.processingBlocks,
              isControlMode: widget.isControlMode,
              onBlocksUpdated: (List<ProcessingBlockEntity> chain) {
                final Mix updatedMix = widget.mix.copyWith(processingBlocks: chain);
                widget.onMixUpdated(updatedMix);
              },
              onBlockRemoved: (int index) {
                final List<ProcessingBlockEntity> updatedBlocks = List<ProcessingBlockEntity>.from(
                  widget.mix.processingBlocks,
                );
                updatedBlocks.removeAt(index);
                widget.onMixUpdated(widget.mix.copyWith(processingBlocks: updatedBlocks));
              },
              onBlockSelected: (ProcessingBlockEntity block) {
                final List<ProcessingBlockEntity> updatedBlocks = List<ProcessingBlockEntity>.from(
                  widget.mix.processingBlocks,
                );
                updatedBlocks.add(block);
                widget.onMixUpdated(widget.mix.copyWith(processingBlocks: updatedBlocks));
              },
            ),
          ],
        ),
      ),
    );
  }
}
