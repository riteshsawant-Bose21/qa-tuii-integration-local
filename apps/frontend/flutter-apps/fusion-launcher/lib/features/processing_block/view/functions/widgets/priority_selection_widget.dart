import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../../../core/service_locator.dart';
import '../../../../configuration/presentation/viewmodel/project_view_model.dart';
import 'neumorphic_active_blue_button.dart';
import 'neumorphic_text_with_popup_slider_button.dart';

class PrioritySelectionWidget extends StatefulWidget {
  final String zoneId;
  final Function(Widget child)? builder;
  const PrioritySelectionWidget({super.key, required this.zoneId, this.builder});

  @override
  State<PrioritySelectionWidget> createState() => _PrioritySelectionWidgetState();
}

class _PrioritySelectionWidgetState extends State<PrioritySelectionWidget> {
  final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();

  late final List<Source> sources;

  @override
  void initState() {
    super.initState();
    sources = projectViewModel.getSourcesAndSourceSetSourcesInZone(zoneId: widget.zoneId);
  }

  void onReorder(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex -= 1;

    /// Handle the reordering logic - swap sources using reOrderPrioritySourcesInZone
    if (oldIndex != newIndex) {
      /// Get current source IDs directly from view model
      final List<String> prioritySources = projectViewModel.getPrioritySourcesInZone(zoneId: widget.zoneId);
      final String? source1 = prioritySources.isNotEmpty ? prioritySources[0] : null;
      final String? source2 = prioritySources.length > 1 ? prioritySources[1] : null;

      /// Create new order list with swapped sources
      final List<String> newOrder = <String>[];
      if (oldIndex == 0 && newIndex == 1) {
        /// P1 moved to P2 position
        newOrder.add(source2 ?? '');
        newOrder.add(source1 ?? '');
      } else if (oldIndex == 1 && newIndex == 0) {
        /// P2 moved to P1 position
        newOrder.add(source2 ?? '');
        newOrder.add(source1 ?? '');
      }

      /// Use the new reOrderPrioritySourcesInZone method
      projectViewModel.reOrderPrioritySourcesInZone(zoneId: widget.zoneId, newOrder: newOrder);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ZoneFunctions? existingFunction = projectViewModel.getZoneFunctionForZone(zoneId: widget.zoneId);
    if (!(existingFunction?.hasPriority ?? false)) return const SizedBox.shrink();

    final SizedBox child = SizedBox(
      width: 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            height: 28,
            width: double.infinity,
            alignment: Alignment.center,

            child: FusionAppText(
              text: "PRIORITY",
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),

          Divider(color: context.colorScheme.strokeLight, height: 0),

          _buildReorderablePriorityWidgets(),
        ],
      ),
    );

    // Wrap with builder if provided for customizations
    if (widget.builder != null) return widget.builder!(child);

    // Otherwise, return the child directly
    return child;
  }

  Widget _buildReorderablePriorityWidgets() {
    final ZoneFunctions? existingFunction = projectViewModel.getZoneFunctionForZone(zoneId: widget.zoneId);
    if (!(existingFunction?.hasPriority ?? false)) return const SizedBox.shrink();

    return Material(
      color: Colors.transparent,
      child: ReorderableListView.builder(
        proxyDecorator: (Widget child, int index, Animation<double> animation) {
          return FadeTransition(
            opacity: animation.drive(Tween<double>(begin: 0.95, end: 1.0)),
            child: Material(
              color: context.colorScheme.elevation2,
              child: child,
            ),
          );
        },
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        buildDefaultDragHandles: false,
        itemCount: 2,
        onReorder: onReorder,
        itemBuilder: (BuildContext context, int index) {
          final int priorityIndex = index + 1;

          // String? selectedSourceId;
          String? selectedSourceName;

          final List<String> prioritySources = projectViewModel.getPrioritySourcesInZone(zoneId: widget.zoneId);

          /// priority 1
          if (priorityIndex == 1) {
            if (prioritySources.isNotEmpty && prioritySources[0].isNotEmpty) {
              final HardwareComponent? sourceData = projectViewModel.getHardware(hardwareId: prioritySources[0]);
              if (sourceData != null) {
                selectedSourceName = sourceData.name;
                // selectedSourceId = prioritySources[0];
              }
            }
          } else {
            /// priority 2
            if (prioritySources.length > 1 && prioritySources[1].isNotEmpty) {
              final HardwareComponent? sourceData = projectViewModel.getHardware(hardwareId: prioritySources[1]);
              if (sourceData != null) {
                selectedSourceName = sourceData.name;
                // selectedSourceId = prioritySources[1];
              }
            }
          }

          // get zone by id
          final Color? zoneColor = projectViewModel.getZone(zoneId: widget.zoneId)?.color;

          return ReorderableDragStartListener(
            key: ValueKey<String>('priority_widget_$index'),
            index: index,
            child: SemanticHelper.button(
              testId: SemanticHelper.createTestId(SemanticTypes.button, "priority_selection_widget_$priorityIndex"),
              child: Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3))),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    FusionAppText(
                      text: "Priority $priorityIndex",
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                      ),
                    ),
                    Builder(
                      builder: (BuildContext context) {
                        if (selectedSourceName == null) {
                          return FusionAppText(
                            text: "No source selected for priority $priorityIndex",
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontSize: 10,
                              color: const Color(0xFF888888),
                            ),
                          );
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Row(
                              spacing: 8,
                              children: <Widget>[
                                Expanded(
                                  child: Container(
                                    height: 24,
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: context.colorScheme.elevation3,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Row(
                                      spacing: 4,
                                      children: <Widget>[
                                        Container(
                                          height: 16,
                                          width: 16,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: zoneColor,
                                            borderRadius: BorderRadius.circular(3),
                                          ),
                                          child: FusionAppText(
                                            text: "P1",
                                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                              fontSize: 10,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: FusionAppText(
                                            text: selectedSourceName,
                                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                              fontSize: 10,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                Icon(
                                  Icons.circle,
                                  color: context.colorScheme.elevation5,
                                  size: 16,
                                ),

                                SemanticHelper.button(
                                  testId: SemanticHelper.createTestId(SemanticTypes.button, "priority_active_button_$priorityIndex"),
                                  child: NeumorphicActiveBlueButton(
                                    text: "Active",
                                    isActive: false,
                                    width: 72,
                                    onTap: () {
                                      //
                                    },
                                  ),
                                ),
                              ],
                            ),

                            Row(
                              spacing: 8,
                              children: <Widget>[
                                const Expanded(child: SizedBox()),

                                FusionAppText(
                                  text: "Volume",
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    fontSize: 10,
                                  ),
                                ),

                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: SemanticHelper.button(
                                    testId: SemanticHelper.createTestId(SemanticTypes.button, "priority_volume_slider_$priorityIndex"),
                                    child: const NeumorphicTextWithPopupSliderButton(
                                      isActive: false,
                                      width: 72,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
