import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../widgets/events/events_panel.dart';
import '../widgets/events/trigger_panel.dart';

class ConfigurationEvents extends StatefulWidget {
  const ConfigurationEvents({super.key});

  @override
  State<ConfigurationEvents> createState() => _ConfigurationEventsState();
}

class _ConfigurationEventsState extends State<ConfigurationEvents> {
  ProjectViewModel get _projectViewModel => serviceLocator<ProjectViewModel>();

  @override
  void dispose() {
    /// Clear selected snapshot when screen is disposed
    _projectViewModel.setSelectedEventId(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
    );
  }
}
