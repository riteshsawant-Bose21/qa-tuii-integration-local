import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration_page/widgets/source_item.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/others/fusion_image.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';
import 'package:fusion_lib/models/project_entities/source_model.dart';
import 'package:fusion_lib/models/project_entities/source_set_model.dart';

import '../../../core/constants/assets_constants.dart';
import '../../../core/service_locator.dart';
import '../../configuration/presentation/viewmodel/project_view_model.dart';

class SourceSetItem extends StatefulWidget {
  final SourceSet sourceSet;

  const SourceSetItem({required this.sourceSet, super.key});

  @override
  State<SourceSetItem> createState() => _SourceSetItemState();
}

class _SourceSetItemState extends State<SourceSetItem> {
  late ValueNotifier<bool> _isSourcesSetExpanded;
  ProjectViewModel get _projectViewModel => serviceLocator<ProjectViewModel>();
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _isSourcesSetExpanded = ValueNotifier<bool>(false);
  }

  @override
  void dispose() {
    _isSourcesSetExpanded.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _isSourcesSetExpanded,
      builder: (BuildContext context, bool subZoneExpanded, Widget? child) {
        return BlocBuilder<ProjectViewModel, ProjectViewModelState>(
          builder: (BuildContext context, ProjectViewModelState state) {
            /// Check if this Source set is selected
            final SelectedItem? selectedDevice = _projectViewModel.selectedDevice;
            final bool isSelected = selectedDevice?.id == widget.sourceSet.id && selectedDevice?.type == SelectedItemType.sourceSet;

            return Column(
              children: <Widget>[
                MouseRegion(
                  onEnter: (_) => setState(() => _isHovered = true),
                  onExit: (_) => setState(() => _isHovered = false),

                  child: GestureDetector(
                    onTap: () {
                      /// Select source set on tap
                      _isSourcesSetExpanded.value = !_isSourcesSetExpanded.value;
                      _projectViewModel.setSelectedDevice(widget.sourceSet.id, SelectedItemType.sourceSet);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.only(left: 12, right: 12),
                      height: 36,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected ? Theme.of(context).colorScheme.greyDark : Colors.transparent,
                        ),
                        color: _isHovered ? Theme.of(context).colorScheme.grey.withAlpha(200) : Theme.of(context).colorScheme.greyLight,
                      ),
                      child: Row(
                        children: <Widget>[
                          /// Expand/collapse icon
                          Icon(
                            _isSourcesSetExpanded.value ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded,
                            color: Theme.of(context).colorScheme.fusionTextViewColor.withAlpha(90),
                          ),
                          const SizedBox(width: 4),

                          /// Source set name
                          Expanded(
                            child: FusionAppText(
                              text: widget.sourceSet.name,
                              maxLine: 1,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          const FusionImage.asset(
                            Assets.linkIcon,
                            width: 22,
                            height: 22,
                            fit: BoxFit.contain,
                          ),

                          const SizedBox(width: 8),
                          const FusionImage.asset(
                            Assets.processingBlocksIcon,
                            width: 18,
                            height: 12,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(width: 8),
                          const FusionImage.asset(
                            Assets.addSourceIcon,
                            width: 22,
                            height: 22,
                            fit: BoxFit.contain,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (subZoneExpanded) _buildSourcesList(),
              ],
            );
          },
        );
      },
    );
  }

  /// Build the list of sources within the source set
  Widget _buildSourcesList() {
    return BlocBuilder<ProjectViewModel, ProjectViewModelState>(
      builder: (BuildContext context, ProjectViewModelState state) {
        final List<Source> sourceList = _projectViewModel.getSourcesInSourceSet(sourceSetId: widget.sourceSet.id);
        return Container(
          color: Theme.of(context).colorScheme.greyLight.withAlpha(50),
          child: ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: sourceList.length,
            onReorder: (int oldIndex, int newIndex) {},
            itemBuilder: (BuildContext context, int index) {
              return DragTarget<Source>(
                key: ValueKey<String>(sourceList[index].id),
                // onWillAccept: (Source? incoming) {
                //   return incomingSpeakers.first.speakerSKU == currentData.first.speakerSKU && incoming.id != circuitData.id;
                // },
                // onAccept: (Source incoming) {
                //   /// Add speaker to target circuit
                //   final List<Speaker> incomingSpeakers = _projectViewModel.getHardwareForCircuit(circuitId: incoming.id).whereType<Speaker>().toList();
                //
                //   if (incomingSpeakers.isNotEmpty) {
                //     for (final Speaker speaker in incomingSpeakers) {
                //       // serviceLocator<ProjectViewModel>().addHardware(hardware: speaker, autoSave: false);
                //       serviceLocator<ProjectViewModel>().addHardwareToCircuit(hwId: speaker.id, circuitId: circuitData.id);
                //     }
                //   }
                //
                //   /// Remove the dragged circuit from the zone
                //   _projectViewModel.removeCircuitFromSubZone(circuitId: incoming.id, subZoneId: widget.subZoneId);
                //   setState(() {});
                // },
                builder: (BuildContext context, List<Source?> candidateData, List<dynamic> rejectedData) {
                  return Draggable<Source>(
                    data: sourceList[index],
                    feedback: Material(
                      color: Colors.transparent,
                      child: Opacity(
                        opacity: 0.8,
                        child: SizedBox(width: 220, child: SourceItem(source: sourceList[index])),
                      ),
                    ),
                    childWhenDragging: Material(
                      color: Colors.transparent,
                      child: Opacity(
                        opacity: 0.8,
                        child: SizedBox(width: 220, child: SourceItem(source: sourceList[index])),
                      ),
                    ),
                    child: SourceItem(source: sourceList[index]),
                  );
                },
              );

              // return Container(
              //   key: ValueKey<String>(deviceId),
              //   child:
              // );
            },
          ),
        );
      },
    );
  }
}
