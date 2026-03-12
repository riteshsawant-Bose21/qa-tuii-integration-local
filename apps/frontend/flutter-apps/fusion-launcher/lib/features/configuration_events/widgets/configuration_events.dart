import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
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
