import 'package:flutter/material.dart';
import 'package:fusion_design_tool_prototype/core/models/location_entity.dart';
import 'package:fusion_design_tool_prototype/core/models/processing_block_entity.dart';

import '../../../../../core/constants.dart';
import '../../../../../core/models/floor_entity.dart';
import '../../../../../core/models/mix_entity.dart';
import '../../../../../core/models/products_data.dart';
import '../../../../../core/models/source_entity.dart';
import '../../../../../core/models/speaker_entity.dart';
import '../../../../../core/models/zone_entity.dart';
import '../../../../../core/service_locator.dart';
import '../../../../../core/services/project_manager.dart';
import '../../../../dynamic_config/data/datasources/panel_datasource.dart';
import '../../../../dynamic_config/domain/entities/audio_widget_entity.dart';
import '../../../../dynamic_config/domain/entities/audio_widget_value.dart';
import '../common/processing_block_view.dart';
import 'multiple_mix_selection_dialog.dart';
import 'output_widget.dart';

class OutputOptions {
  final String name;
  final OutputType type;
  final String assetImagePath;

  OutputOptions({required this.name, required this.type, required this.assetImagePath});
}

class ZoneWidget extends StatefulWidget {
  final Zone zone;
  final List<Mix> availableMixes;
  final List<Speaker> zoneSpeakers;
  final List<Source> sources;
  final void Function(Zone) onZoneUpdated;
  final VoidCallback onDelete;
  final void Function(Zone) duplicateZone;
  final Function(Speaker speakers) onSpeakerUpdated;
  final Function(Speaker speakers) onSpeakerDeleted;
  final Function(Speaker speakers) onSpeakerAdded;
  final Function(Floor) onFloorUpdated;
  final Function(Floor) onFloorAdded;
  final bool isControlMode;

  const ZoneWidget({
    super.key,
    required this.zone,
    required this.availableMixes,
    required this.onZoneUpdated,
    required this.onDelete,
    required this.sources,
    required this.zoneSpeakers,
    required this.duplicateZone,
    required this.onSpeakerUpdated,
    required this.onSpeakerDeleted,
    required this.onSpeakerAdded,
    required this.onFloorUpdated,
    required this.onFloorAdded,
    required this.isControlMode,
  });

  @override
  ZoneWidgetState createState() => ZoneWidgetState();
}

class ZoneWidgetState extends State<ZoneWidget> {
  final TextEditingController _nameController = TextEditingController();

  int? selectedMixIndex;

  Future<void> pickMixes(Zone zone) async {
    final List<Mix>? picked = await showDialog<List<Mix>>(
      context: context,
      builder:
          (_) => MultiMixPickerDialog(
            title: 'Select Mixes',
            devices: widget.availableMixes,
            initiallySelected: widget.availableMixes.where((Mix m) => zone.mixIds.contains(m.id)).toList(),
          ),
    );
    if (picked != null) {
      final List<String> updatedMixIds = picked.map((Mix m) => m.id).toList();
      widget.onZoneUpdated(zone.copyWith(mixIds: updatedMixIds));
    }
  }

  @override
  void initState() {
    super.initState();

    fetchSelectedMixIndex();
  }

  void fetchSelectedMixIndex() async {
    final String? vip = serviceLocator<ProjectManager>().value.virtualIP;
    if (vip != null) {
      final dynamic value = await serviceLocator<PanelDataSource>().getCurrentValueForBlock(
        widget.zone.id,
        "input",
      );
      if (value != null && value is int) {
        debugPrint("Selected Mix Index: $value");
        setState(() {
          selectedMixIndex = value - 1;
        });
      }
    }
  }

  @override
  void didUpdateWidget(covariant ZoneWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // fetchSelectedMixIndex();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    _nameController.text = widget.zone.name;

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
                  controller: _nameController,
                  key: ValueKey<String>(widget.zone.id),
                  enabled: widget.isControlMode ? false : true,
                  decoration: const InputDecoration(
                    hintText: 'Zone Name',
                    border: InputBorder.none,
                  ),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  onFieldSubmitted: (String v) {
                    widget.onZoneUpdated(widget.zone.copyWith(name: v));
                  },
                ),
              ),
              // IconButton(
              //   icon: const Icon(Icons.copy_outlined, size: 16),
              //   tooltip: 'Duplicate Zone',
              //   onPressed: () {
              //     widget.duplicateZone(widget.zone);
              //   },
              // ),
              if (!widget.isControlMode)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 16),
                  tooltip: 'Delete Zone',
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
                            Icon(Icons.device_hub, size: 16, color: colors.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Mixes ',
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
                                '${widget.zone.mixIds.length}',
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
                            onPressed: () => pickMixes(widget.zone),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (widget.zone.mixIds.isEmpty)
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
                              'No Mixes selected',
                              style: TextStyle(
                                color: colors.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            widget.zone.mixIds.asMap().entries.map((MapEntry<int, String> sourceId) {
                              final String d = sourceId.value;
                              final int deviceIndex = sourceId.key;
                              final Mix mix = widget.availableMixes.firstWhere(
                                (Mix s) => s.id == d,
                              );
                              return InkWell(
                                onTap: () async {

                                  if(!widget.isControlMode) {
                                    return;
                                  }

                                  final String? vip = serviceLocator<ProjectManager>().value.virtualIP;
                                  if (vip != null) {
                                    final AudioWidgetEntity audioWidgetEntity = AudioWidgetEntity(
                                      id: widget.zone.id,
                                      // blockName_parameterName
                                      name: "input",
                                      parentPanelBlockName: "source_selector",
                                      audioWidgetType: AudioWidgetType.toggleButton,
                                      audioWidgetOrientation: AudioWidgetOrientation.vertical,
                                      isWidgetDependentOnDimensions: false,
                                      dimensionIndex: 0,
                                      value: AudioWidgetValue.from(0, "integer"),
                                      minValue: AudioWidgetValue.from(1, "integer"),
                                      maxValue: AudioWidgetValue.from(widget.zone.mixIds.length, "integer"),
                                    );

                                    final AudioWidgetValue widgetValue = AudioWidgetValue.from(deviceIndex + 1, "integer");

                                    final AudioWidgetEntity updatedEntity = await serviceLocator<PanelDataSource>().sendWidgetData(
                                      audioWidgetEntity,
                                      widgetValue,
                                    );

                                    if (updatedEntity.value.value == deviceIndex + 1) {
                                      setState(() {
                                        selectedMixIndex = deviceIndex;
                                      });
                                    }

                                  }else{
                                    //show toast
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Virtual IP not set. Please configure it in settings.'),
                                      ),
                                    );
                                  }
                                },
                                child: Chip(
                                  label: Text(mix.name),

                                  backgroundColor: selectedMixIndex == deviceIndex ? Theme.of(context).colorScheme.primaryContainer : AppColors.cardSoft,

                                  side: selectedMixIndex == deviceIndex ? BorderSide(color: colors.primary, width: 1.5) : null,

                                  labelStyle: TextStyle(color: colors.onSecondaryContainer, fontSize: 10),
                                  deleteIcon:
                                      (widget.isControlMode)
                                          ? null
                                          : Icon(
                                            Icons.close,
                                            size: 12,
                                            color: Colors.red[600],
                                          ),
                                  onDeleted:
                                      (widget.isControlMode)
                                          ? null
                                          : () {
                                            final List<String> updatedMixIds = List<String>.from(widget.zone.mixIds);
                                            updatedMixIds.removeAt(deviceIndex);
                                            widget.onZoneUpdated(widget.zone.copyWith(mixIds: updatedMixIds));
                                          },
                                ),
                              );
                            }).toList(),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 5),
            //Processing blocks
            ProcessingBlockView(
              processingType: ProcessingType.zone,
              selectedBlocks: widget.zone.processingBlocks,
              onBlocksUpdated: (List<ProcessingBlockEntity> chain) {
                widget.onZoneUpdated(widget.zone.copyWith(processingBlocks: chain));
              },
              isControlMode: widget.isControlMode,
              onBlockRemoved: (int index) {
                final List<ProcessingBlockEntity> updatedBlocks = List<ProcessingBlockEntity>.from(
                  widget.zone.processingBlocks,
                );
                updatedBlocks.removeAt(index);
                widget.onZoneUpdated(widget.zone.copyWith(processingBlocks: updatedBlocks));
              },
              onBlockSelected: (ProcessingBlockEntity block) {
                final List<ProcessingBlockEntity> updatedBlocks = List<ProcessingBlockEntity>.from(
                  widget.zone.processingBlocks,
                );
                updatedBlocks.add(block);
                widget.onZoneUpdated(widget.zone.copyWith(processingBlocks: updatedBlocks));
              },
            ),

            // ── Circuits header + Add button ──
            if (!widget.isControlMode)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    //todo: add localized ids from the listening area
                    Text('Outputs: ${widget.zoneSpeakers.length}', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12)),
                    PopupMenuButton<SpeakerData>(
                      tooltip: 'Add Output',
                      onSelected: (SpeakerData speakerData) {
                        print('Selected: ${speakerData.name}');
                        final Speaker newSpeaker = Speaker(
                          name: speakerData.name,
                          type: speakerData.type,
                          assetImagePath: speakerData.assetPath,
                          speakerSKU: speakerData.sku,
                          locationEntity: LocationEntity(
                            zoneId: widget.zone.id,
                          ),
                          pos: const Offset(0, 0),
                          gain: 0.0,
                          blocks: <ProcessingBlockEntity>[],
                          price: speakerData.price,
                        );
                        widget.onSpeakerAdded(newSpeaker);
                      },
                      color: Colors.white,
                      itemBuilder: (BuildContext context) {
                        return SpeakerData.demoSpeakers.map((SpeakerData speakerData) {
                          return PopupMenuItem<SpeakerData>(
                            value: speakerData,
                            child: Row(
                              children: <Widget>[
                                Image.asset(
                                  speakerData.assetPath,
                                  height: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(speakerData.name),
                              ],
                            ),
                          );
                        }).toList();
                      },
                      child: ElevatedButton.icon(
                        onPressed: null,
                        icon: const Icon(Icons.add, size: 14),
                        label: Text(
                          'Add Outputs',
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.primary,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFB8956A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: const Size(0, 28),
                          disabledBackgroundColor: colors.primaryContainer,
                          disabledForegroundColor: colors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 6),

            // ── Render each circuit with your CircuitWidget ──
            Column(
              children:
                  widget.zoneSpeakers.asMap().entries.map((MapEntry<int, Speaker> entry) {
                    final int idx = entry.key;
                    final Speaker speaker = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: OutputWidget(
                        speaker: speaker,
                        isControlMode: widget.isControlMode,
                        onOutputChanged: (Speaker updated) {
                          widget.onSpeakerUpdated(updated);
                        },
                        onDelete: () {
                          widget.onSpeakerDeleted(speaker);
                        },
                        onFloorUpdated: (Floor updatedFloor) {
                          widget.onFloorUpdated(updatedFloor);
                        },
                        onFloorAdded: (Floor newFloor) {
                          widget.onFloorAdded(newFloor);
                        },
                      ),
                    );
                  }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
