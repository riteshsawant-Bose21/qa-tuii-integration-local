import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration_page/widgets/events/event_action_row_data.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';
import 'package:fusion_lib/models/project_entities/non_processing/fusion_event.dart';
import 'package:fusion_lib/models/project_entities/non_processing/snapshot_model.dart';

import '../../../../core/service_locator.dart';
import '../../../configuration/presentation/viewmodel/project_view_model.dart';
import 'event_action_row_header.dart';
import 'event_header_widget.dart';
import 'event_trigger_row_header.dart';

class TriggerPanel extends StatelessWidget {
  ProjectViewModel get _projectViewModel => serviceLocator<ProjectViewModel>();

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
          BlocBuilder<ProjectViewModel, ProjectViewModelState>(
            builder: (BuildContext context, ProjectViewModelState state) {
              final String? selectedEventId = _projectViewModel.selectedEventId;

              if (selectedEventId == null) {
                /// No event selected
                return Expanded(
                  child: Center(
                    child: Container(
                      // 40%
                      width: MediaQuery.of(context).size.width * 0.4,
                      padding: const EdgeInsets.all(100.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          FusionAppText(
                            text: 'Select a event to view and edit its triggers',
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
              final FusionEvent selectedEvent = _projectViewModel.getEventById(selectedEventId);
              final List<SceneActionModel> eventActionsList = _projectViewModel.getEventActionsForEvent(selectedEventId);
              return Expanded(
                child: Column(
                  children: <Widget>[
                    /// Events Header Widget
                    EventHeaderWidget(
                      eventName: selectedEvent.name,
                      onNameChanged: (String newName) {
                        final FusionEvent event = selectedEvent.copyWith(name: newName);
                        _projectViewModel.updateEvent(event: event);
                      },
                    ),

                    /// trigger Row Header
                    EventTriggerRowHeader(eventId: selectedEventId),

                    /// show actions only if the event trigger is complete
                    if (selectedEvent.isComplete) ...<Widget>[
                      const SizedBox(height: 24),

                      /// Action Row Header
                      const EventActionRowHeader(),

                      /// show list of actions for the selected event
                      Expanded(
                        child:
                            eventActionsList.isEmpty
                                ? Center(
                                  child: Container(
                                    // 40%
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
                                  onReorder: (int oldIndex, int newIndex) {},
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
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
