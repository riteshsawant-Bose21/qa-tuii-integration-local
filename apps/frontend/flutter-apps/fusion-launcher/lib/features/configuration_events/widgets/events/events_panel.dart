import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration_events/viewModel/events_viewmodel/config_events_state.dart';
import 'package:fusion_launcher/features/configuration_page/widgets/section_header.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/buttons/fusion_button.dart';
import 'package:fusion_lib/fusion_widgets/buttons/fusion_outlined_button.dart';
import 'package:fusion_lib/fusion_widgets/form_fields/fusion_text_field.dart';
import 'package:fusion_lib/fusion_widgets/others/fusion_toast.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';
import 'package:fusion_lib/models/project_entities/non_processing/fusion_event.dart';

import '../../viewModel/events_viewmodel/config_events_viewmodel.dart';
import 'events_list.dart';

class EventsPanel extends StatelessWidget {
  const EventsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConfigEventsViewmodel, ConfigEventsState>(
      builder: (BuildContext context, ConfigEventsState state) {
        final ConfigEventsViewmodel cubit = context.read<ConfigEventsViewmodel>();

        return Column(
          children: <Widget>[
            /// Events Section
            SectionHeader(
              title: 'Events',
              trailing: GestureDetector(
                onTap: () {
                  cubit.addEvent();
                  FusionToast.success(context, message: "Event created");
                },
                child: Icon(Icons.add_sharp, size: 16, color: context.colorScheme.iconWhite),
              ),
            ),

            /// Event list
            Expanded(
              child: Container(
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  border: Border(
                    bottom: BorderSide(color: context.colorScheme.elevation2, width: 1),
                    left: BorderSide(color: context.colorScheme.elevation2, width: 1),
                    right: BorderSide(color: context.colorScheme.elevation2, width: 1),
                  ),
                  color: Theme.of(context).colorScheme.elevation1,
                ),
                child: _buildEventsList(context, state, cubit),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEventsList(BuildContext context, ConfigEventsState state, ConfigEventsViewmodel cubit) {
    return switch (state) {
      EventsInitial() => _buildEmptyState(context),
      EventsLoading() => const Center(child: CircularProgressIndicator()),
      EventsLoaded() => _buildLoadedState(context, state, cubit),
      EventsError() => _buildErrorState(context, state),
    };
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      child: FusionAppText(
        text: 'No events available',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, EventsError state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.error_outline, size: 48, color: context.colorScheme.error),
          const SizedBox(height: 16),
          FusionAppText(
            text: 'Error loading events',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadedState(BuildContext context, EventsLoaded state, ConfigEventsViewmodel cubit) {
    final List<FusionEvent> eventList = state.events;

    if (eventList.isEmpty) {
      return _buildEmptyState(context);
    }

    return EventList(
      eventList: eventList,
      cubit: cubit,
      onDelete: (String eventId) {
        cubit.deleteEvent(eventId);
        FusionToast.success(context, message: "Event deleted successfully");
      },
      selectedEventId: state.selectedEventId,
      onSelect: (String eventId) {
        cubit.selectEvent(eventId);
      },
      onReorder: (int oldIndex, int newIndex) {
        cubit.reorderEvents(oldIndex, newIndex);
      },
      onSwitchChanged: (String eventId) {
        cubit.toggleEventEnabled(eventId);
      },
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
      color: Theme.of(context).colorScheme.elevation1,
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
                  textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 10, color: context.colorScheme.primaryBlack),

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
