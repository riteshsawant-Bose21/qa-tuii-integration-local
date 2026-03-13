import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/configuration_events/viewModel/actions_viewmodel/config_event_actions_state.dart';
import 'package:fusion_launcher/features/configuration_events/viewModel/actions_viewmodel/config_event_actions_viewmodel.dart';
import 'package:fusion_launcher/features/configuration_events/viewModel/events_viewmodel/config_events_state.dart';
import 'package:fusion_launcher/features/configuration_events/widgets/events/events_panel.dart';
import 'package:fusion_launcher/features/configuration_events/widgets/actions/trigger_panel.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../viewModel/events_viewmodel/config_events_viewmodel.dart';

class ConfigurationEvents extends StatelessWidget {
  const ConfigurationEvents({super.key});

  @override
  Widget build(BuildContext context) {
    final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();

    return MultiBlocProvider(
      providers: <BlocProvider<dynamic>>[
        BlocProvider<ConfigEventsViewmodel>(
          create:
              (BuildContext context) => ConfigEventsViewmodel(
                projectViewModel: projectViewModel,
              ),
        ),
        BlocProvider<ConfigEventActionsViewmodel>(
          create:
              (BuildContext context) => ConfigEventActionsViewmodel(
                projectViewModel: projectViewModel,
              ),
        ),
      ],
      child: const _ConfigurationEventsBody(),
    );
  }
}

class _ConfigurationEventsBody extends StatefulWidget {
  const _ConfigurationEventsBody();

  @override
  State<_ConfigurationEventsBody> createState() => _ConfigurationEventsBodyState();
}

class _ConfigurationEventsBodyState extends State<_ConfigurationEventsBody> {
  @override
  void initState() {
    super.initState();
    // The BlocProvider creates ConfigEventsViewmodel eagerly and _loadEvents()
    // fires before the BlocListeners below have subscribed to the stream.
    // As a result, if an event is already pre-selected (e.g. from addEventForGPI),
    // Listener 1 misses the null→newEventId transition and loadActionsForEvent
    // is never called.  We recover here: after the first frame all listeners are
    // live, so we check if there is already a selected event and bootstrap the
    // actions load if the actions cubit is still in its initial state.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ConfigEventsViewmodel eventsVm = context.read<ConfigEventsViewmodel>();
      final ConfigEventActionsViewmodel actionsVm = context.read<ConfigEventActionsViewmodel>();
      final String? selectedId = eventsVm.state.selectedEventId;
      if (selectedId != null && actionsVm.state is EventActionsInitial) {
        actionsVm.loadActionsForEvent(selectedId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: <BlocListener<dynamic, dynamic>>[
        // Listener 1: selected event changed → load its actions from scratch.
        BlocListener<ConfigEventsViewmodel, ConfigEventsState>(
          listenWhen: (ConfigEventsState previous, ConfigEventsState current) => previous.selectedEventId != current.selectedEventId,
          listener: (BuildContext context, ConfigEventsState state) {
            context.read<ConfigEventActionsViewmodel>().loadActionsForEvent(state.selectedEventId);
          },
        ),

        // Listener 2: same event selected but its configuration changed
        // (e.g. trigger type switched Schedule→GPI).
        // Refresh ConfigEventActionsViewmodel so it discards any stale scene
        // actions that were removed from the project model by updateEventTrigger
        // / updateEventTriggerItem / updateEventAction / updateEventConditionType.
        BlocListener<ConfigEventsViewmodel, ConfigEventsState>(
          listenWhen:
              (ConfigEventsState previous, ConfigEventsState current) =>
                  current.selectedEventId != null && previous.selectedEventId == current.selectedEventId && !identical(previous.events, current.events),
          listener: (BuildContext context, ConfigEventsState state) {
            context.read<ConfigEventActionsViewmodel>().refresh();
          },
        ),

        // Listener 3: project was updated externally (e.g. addEventForGPI from
        // the GPIO page calls setSelectedEventId which emits ProjectUpdated).
        // Sync ConfigEventsViewmodel so the new event and its pre-set trigger
        // (triggerType + item) are reflected in the UI immediately.
        BlocListener<ProjectViewModel, ProjectViewModelState>(
          listenWhen: (ProjectViewModelState previous, ProjectViewModelState current) => current is ProjectUpdated,
          listener: (BuildContext context, ProjectViewModelState state) {
            context.read<ConfigEventsViewmodel>().syncWithProjectViewModel();
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: context.colorScheme.primaryBlack,
        body: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool isWideScreen = constraints.maxWidth > 600;

            if (isWideScreen) {
              return Row(
                children: <Widget>[
                  SizedBox(width: constraints.maxWidth * 0.2, child: const EventsPanel()),
                  const SizedBox(width: 4),
                  const Expanded(child: TriggerPanel()),
                ],
              );
            } else {
              return const Column(
                children: <Widget>[
                  Expanded(flex: 1, child: EventsPanel()),
                  Expanded(flex: 2, child: TriggerPanel()),
                ],
              );
            }
          },
        ),
      ),
    );
  }
}
