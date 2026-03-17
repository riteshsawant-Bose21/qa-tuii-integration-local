import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

import '../../viewModel/actions_viewmodel/config_event_actions_state.dart';
import '../../viewModel/actions_viewmodel/config_event_actions_viewmodel.dart';
import '../../viewModel/events_viewmodel/config_events_state.dart';
import '../../viewModel/events_viewmodel/config_events_viewmodel.dart';

class EventActionRowHeader extends StatelessWidget {
  const EventActionRowHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double responsivePadding = screenWidth * 0.09;

    return BlocBuilder<ConfigEventActionsViewmodel, ConfigEventActionsState>(
      builder: (BuildContext context, ConfigEventActionsState state) {
        final ConfigEventActionsViewmodel actionsViewModel = context.read<ConfigEventActionsViewmodel>();
        final String? selectedEventId = state.selectedEventId;

        return Column(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: context.colorScheme.elevation2,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  FusionAppText(
                    text: "Actions",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),

                  /// add actions
                  SemanticHelper.button(
                    testId: SemanticHelper.createTestId(SemanticTypes.button, "add_event_action"),
                    child: GestureDetector(
                      onTap: () {
                        if (selectedEventId == null) return;
                        actionsViewModel.addAction();
                      },
                      child: const Icon(Icons.add, size: 16),
                    ),
                  ),
                ],
              ),
            ),

            /// State Selector for 2-state events (above / below).
            /// Uses BlocBuilder<ConfigEventsViewmodel> so that:
            /// - the slider position reflects the latest selectedState
            /// - updateEventSelectedState goes through events viewmodel,
            ///   which always emits a new state and unblocks EventActionRowData.
            if (selectedEventId != null)
              BlocBuilder<ConfigEventsViewmodel, ConfigEventsState>(
                builder: (BuildContext context, ConfigEventsState eventsState) {
                  final ConfigEventsViewmodel configEventsViewmodel = context.read<ConfigEventsViewmodel>();
                  final FusionEvent selectedEvent = configEventsViewmodel.getEventById(selectedEventId);
                  final List<EventStates>? states = selectedEvent.states;

                  /// Hide if null or not exactly 2 states
                  if (states == null || states.length != 2) {
                    return const SizedBox.shrink();
                  }

                  final EventStates left = states.first;
                  final EventStates right = states.last;

                  final Map<bool, Widget> sliderChildren = <bool, Widget>{
                    true: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: FusionAppText(
                        text: left.name,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.textPrimary,
                        ),
                      ),
                    ),
                    false: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: FusionAppText(
                        text: right.name,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.textPrimary,
                        ),
                      ),
                    ),
                  };

                  /// Determine current group value based on event.selectedState
                  final bool groupValue = (selectedEvent.selectedState?.stateType == left.stateType);

                  return Container(
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.only(
                      bottom: 20,
                      right: responsivePadding,
                    ),
                    child: CupertinoSlidingSegmentedControl<bool>(
                      children: sliderChildren,
                      groupValue: groupValue,
                      onValueChanged: (bool? value) {
                        if (value == null) return;
                        final EventStates newSelected = value ? left : right;
                        // Route through ConfigEventsViewmodel so the events state
                        // always emits a fresh object → EventActionRowData rebuilds.
                        configEventsViewmodel.updateEventSelectedState(
                          eventId: selectedEventId,
                          selectedState: newSelected,
                        );
                      },
                    ),
                  );
                },
              ),

            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: context.colorScheme.elevation2.withAlpha(120),
              child: Row(
                spacing: screenWidth * 0.01,
                children: <Widget>[
                  SizedBox(width: screenWidth * 0.01),
                  const _HeaderCell(text: "Action Type"),
                  const _HeaderCell(text: "Action Item"),
                  const _HeaderCell(text: "Param / Action"),
                  const _HeaderCell(text: "Value"),
                  SizedBox(width: screenWidth * 0.046),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Header cell widget
class _HeaderCell extends StatelessWidget {
  final String text;
  const _HeaderCell({required this.text});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: FusionAppText(
        text: text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: Theme.of(context).colorScheme.textPrimary,
        ),
        maxLine: 1,
      ),
    );
  }
}
