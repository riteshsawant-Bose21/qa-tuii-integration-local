import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration_events/viewModel/actions_viewmodel/config_event_actions_state.dart';
import 'package:fusion_launcher/features/configuration_events/viewModel/actions_viewmodel/config_event_actions_viewmodel.dart';
import 'package:fusion_launcher/features/configuration_events/widgets/actions/event_action_row_data.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';
import 'package:fusion_lib/models/project_entities/non_processing/fusion_event.dart';
import 'package:fusion_lib/models/project_entities/non_processing/snapshot_model.dart';

import '../../viewModel/events_viewmodel/config_events_state.dart';
import '../../viewModel/events_viewmodel/config_events_viewmodel.dart';
import 'event_action_row_header.dart';
import '../events/event_header_widget.dart';
import 'event_trigger_row_header.dart';

class TriggerPanel extends StatelessWidget {
  const TriggerPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: context.colorScheme.primaryBlack,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(width: 1, color: context.colorScheme.elevation2),
      ),
      child: Column(
        children: <Widget>[
          BlocBuilder<ConfigEventActionsViewmodel, ConfigEventActionsState>(
            builder: (BuildContext context, ConfigEventActionsState state) {
              return switch (state) {
                EventActionsInitial() => _buildNoEventSelected(context),
                EventActionsLoading() => _buildLoading(context),
                EventActionsLoaded() => _buildLoaded(context, state),
                EventActionsError() => _buildError(context, state),
              };
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNoEventSelected(BuildContext context) {
    return Expanded(
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.4,
          padding: const EdgeInsets.all(100.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              FusionAppText(
                text: 'Select an event to view and edit its triggers',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              FusionAppText(
                text: "Events allow you to define specific conditions that, when met, will trigger a set of actions within your project.",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  color: context.colorScheme.primaryBlack,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              FusionAppText(
                text:
                    "Triggers are the conditions or events that initiate actions. They can be based on various parameters such as time, user input, or system states.",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  color: context.colorScheme.primaryBlack,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoading(BuildContext context) {
    return const Expanded(
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildError(BuildContext context, EventActionsError state) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.error_outline, size: 48, color: context.colorScheme.error),
            const SizedBox(height: 16),
            FusionAppText(
              text: 'Error loading actions',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoaded(BuildContext context, EventActionsLoaded state) {
    final ConfigEventActionsViewmodel actionsCubit = context.read<ConfigEventActionsViewmodel>();
    final String selectedEventId = state.selectedEventId!;
    final List<SceneActionModel> eventActionsList = state.actions;

    return Expanded(
      child: BlocBuilder<ConfigEventsViewmodel, ConfigEventsState>(
        builder: (BuildContext context, ConfigEventsState eventsState) {
          final bool eventExists = eventsState.events.any((FusionEvent e) => e.id == selectedEventId);
          if (!eventExists) return const SizedBox.shrink();

          final ConfigEventsViewmodel configEventsViewmodel = context.read<ConfigEventsViewmodel>();
          final FusionEvent selectedEvent = configEventsViewmodel.getEventById(selectedEventId);

          return Column(
            children: <Widget>[
              /// Events Header Widget
              EventHeaderWidget(
                eventName: selectedEvent.name,
                onNameChanged: (String newName) {
                  final FusionEvent event = selectedEvent.copyWith(name: newName);
                  configEventsViewmodel.updateEvent(event);
                },
              ),

              /// Trigger Row Header
              EventTriggerRowHeader(eventId: selectedEventId),

              /// Show actions only if the event trigger is complete
              if (selectedEvent.isComplete) ...<Widget>[
                const SizedBox(height: 24),

                /// Action Row Header
                const EventActionRowHeader(),

                /// Show list of actions for the selected event
                Expanded(
                  child:
                      eventActionsList.isEmpty
                          ? Center(
                            child: Container(
                              width: MediaQuery.of(context).size.width * 0.4,
                              padding: const EdgeInsets.all(100.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
                                  FusionAppText(
                                    text: "No actions added to this event yet.",
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          : ReorderableListView.builder(
                            buildDefaultDragHandles: false,
                            physics: const ClampingScrollPhysics(),
                            itemCount: eventActionsList.length,
                            onReorder: (int oldIndex, int newIndex) {
                              actionsCubit.reorderActions(oldIndex, newIndex);
                            },
                            itemBuilder: (BuildContext context, int index) {
                              final SceneActionModel action = eventActionsList[index];
                              return EventActionRowData(
                                key: ValueKey<String>(action.id),
                                action: action,
                                eventId: selectedEventId,
                                index: index,
                              );
                            },
                          ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
