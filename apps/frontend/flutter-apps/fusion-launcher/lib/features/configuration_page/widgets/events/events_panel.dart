import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration_page/widgets/section_header.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/buttons/fusion_button.dart';
import 'package:fusion_lib/fusion_widgets/buttons/fusion_outlined_button.dart';
import 'package:fusion_lib/fusion_widgets/form_fields/fusion_text_field.dart';
import 'package:fusion_lib/fusion_widgets/others/fusion_toast.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';
import 'package:fusion_lib/models/project_entities/non_processing/fusion_event.dart';

import '../../../configuration/presentation/viewmodel/project_view_model.dart';
import 'events_list.dart';

class EventsPanel extends StatefulWidget {
  const EventsPanel({super.key});

  @override
  State<EventsPanel> createState() => _EventsPanelState();
}

class _EventsPanelState extends State<EventsPanel> {
  ProjectViewModel get _projectViewModel => serviceLocator<ProjectViewModel>();

  void _addNewEvents() {
    final FusionEvent newScene = FusionEvent(
      name: "New Event ${_projectViewModel.getAllEvents().length + 1}",
      isEnabled: true,
    );

    /// Add new scene to project
    _projectViewModel.addNewEvent(event: newScene);

    /// make this snapshot selected
    _projectViewModel.setSelectedEventId(newScene.id);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.white,
      ),
      child: Column(
        children: <Widget>[
          /// Events Section
          SectionHeader(
            title: 'Events',
            trailing: GestureDetector(
              onTap: () {
                _addNewEvents();
              },
              child: Icon(Icons.add_sharp, size: 16, color: Theme.of(context).colorScheme.greyDark),
            ),
          ),

          /// Event list
          Expanded(
            child: BlocBuilder<ProjectViewModel, ProjectViewModelState>(
              builder: (BuildContext context, ProjectViewModelState state) {
                final List<FusionEvent> eventList = _projectViewModel.getAllEvents();
                if (eventList.isEmpty) {
                  return Container(
                    width: double.infinity,
                    alignment: Alignment.center,
                    child: FusionAppText(
                      text: 'No events available',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                      ),
                    ),
                  );
                }
                return EventList(
                  eventList: eventList,
                  onDelete: (String eventId) {
                    _projectViewModel.removeEvent(eventId: eventId);

                    /// clear on selected snapshot to avoid confusion after delete
                    _projectViewModel.setSelectedEventId(null);
                    FusionToast.success(context, message: "Event deleted successfully");
                  },
                  selectedEventId: _projectViewModel.selectedEventId,
                  onSelect: (String eventId) {
                    _projectViewModel.setSelectedEventId(eventId);
                  },
                  onReorder: (int oldIndex, int newIndex) {
                    if (oldIndex < newIndex) newIndex -= 1;
                    final String eventToMove = eventList[oldIndex].id;
                    final String eventAtNewIndex = eventList[newIndex].id;
                    _projectViewModel.reOrderEvents(
                      eventIdToMove: eventToMove,
                      eventAtNewIndex: eventAtNewIndex,
                    );
                    _projectViewModel.setSelectedEventId(eventToMove);
                  },
                  onSwitchChanged: (String eventId) {
                    /// Fetch event, create updated copy and update
                    final FusionEvent event = _projectViewModel.getEventById(eventId);
                    final FusionEvent updatedEvent = event.copyWith(isEnabled: !event.isEnabled);
                    _projectViewModel.updateEvent(event: updatedEvent);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget for creating a new Snapshot or Scene
class CreateSnapshotsOrScenesWidget extends StatefulWidget {
  final String headerText;
  final TextEditingController nameController;

  final VoidCallback onCreate;
  final VoidCallback onCancel;

  const CreateSnapshotsOrScenesWidget({
    super.key,
    required this.nameController,

    required this.onCreate,
    required this.onCancel,
    required this.headerText,
  });

  @override
  State<CreateSnapshotsOrScenesWidget> createState() => CreateSnapshotsOrScenesWidgetState();
}

class CreateSnapshotsOrScenesWidgetState extends State<CreateSnapshotsOrScenesWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.white,
      width: 250,
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          FusionAppText(
            text: "Create ${widget.headerText}",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          FusionAppText(
            text: "${widget.headerText} Name",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),

          /// Enter Name
          FusionTextField(
            controller: widget.nameController,
            hintText: "Enter ${widget.headerText} name",
            decoration: FusionInputDecoration.fusionDense(
              colorScheme: Theme.of(context).colorScheme,
              hintText: 'Enter ${widget.headerText} name',
            ),
            onChanged: (String value) {
              setState(() {});
            },
          ),

          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              Flexible(
                child: FusionOutlinedButton(
                  width: double.infinity,
                  label: "Cancel",
                  textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 10),
                  onTap: () {
                    widget.onCancel.call();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: FusionButton(
                  width: double.infinity,
                  textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 10, color: Theme.of(context).colorScheme.fusionButtonTextColor),

                  label: "Create",
                  isActive: widget.nameController.text.trim().isNotEmpty,
                  onTap: () {
                    widget.onCreate.call();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
