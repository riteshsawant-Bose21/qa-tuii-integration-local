import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/configuration_page/widgets/snapshots/snapshots_and_scenes_panel.dart';

import '../widgets/snapshots/action_list.dart';

class ConfigurationSnapshots extends StatefulWidget {
  const ConfigurationSnapshots({super.key});

  @override
  State<ConfigurationSnapshots> createState() => _ConfigurationSnapshotsState();
}

class _ConfigurationSnapshotsState extends State<ConfigurationSnapshots> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool isWideScreen = constraints.maxWidth > 600;

          if (isWideScreen) {
            return Row(
              children: <Widget>[
                SizedBox(width: constraints.maxWidth * 0.3, child: const SnapshotsAndScenesPanel()),
                const Expanded(child: ActionList()),
              ],
            );
          } else {
            return const Column(
              children: <Widget>[
                Expanded(flex: 1, child: SnapshotsAndScenesPanel()),
                Expanded(flex: 2, child: ActionList()),
              ],
            );
          }
        },
      ),
    );
  }
}
