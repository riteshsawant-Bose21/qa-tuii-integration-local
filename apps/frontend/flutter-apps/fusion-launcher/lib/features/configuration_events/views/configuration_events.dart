import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/configuration_events/viewModel/actions_viewmodel/event_actions_cubit.dart';
import 'package:fusion_launcher/features/configuration_events/viewModel/events_viewmodel/events_cubit.dart';
import 'package:fusion_launcher/features/configuration_events/viewModel/events_viewmodel/events_state.dart';
import 'package:fusion_launcher/features/configuration_events/widgets/events/events_panel.dart';
import 'package:fusion_launcher/features/configuration_events/widgets/actions/trigger_panel.dart';
import 'package:fusion_lib/fusion_lib.dart';

class ConfigurationEvents extends StatelessWidget {
  const ConfigurationEvents({super.key});

  @override
  Widget build(BuildContext context) {
    final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();

    return MultiBlocProvider(
      providers: <BlocProvider<dynamic>>[
        BlocProvider<EventsCubit>(
          create:
              (BuildContext context) => EventsCubit(
                projectViewModel: projectViewModel,
              ),
        ),
        BlocProvider<EventActionsCubit>(
          create:
              (BuildContext context) => EventActionsCubit(
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
    return BlocListener<EventsCubit, EventsState>(
      listenWhen: (EventsState previous, EventsState current) => previous.selectedEventId != current.selectedEventId,
      listener: (BuildContext context, EventsState state) {
        // When selected event changes, load actions for the new event
        context.read<EventActionsCubit>().loadActionsForEvent(state.selectedEventId);
      },
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
