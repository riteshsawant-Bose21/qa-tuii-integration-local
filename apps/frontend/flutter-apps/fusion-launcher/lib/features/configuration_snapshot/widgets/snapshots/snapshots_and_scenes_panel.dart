import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration_snapshot/viewModel/snapshot_viewmodel/config_snapshots_viewmodel.dart';
import 'package:fusion_launcher/features/configuration_snapshot/widgets/snapshots/scene_sets_section.dart';
import 'package:fusion_launcher/features/configuration_snapshot/widgets/snapshots/snapshot_section.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

import '../../../../core/widgets/configuration_widgets/drag_divider.dart';

class SnapshotsAndScenesPanel extends StatefulWidget {
  const SnapshotsAndScenesPanel({super.key});

  @override
  State<SnapshotsAndScenesPanel> createState() => _SnapshotsAndScenesPanelState();
}

class _SnapshotsAndScenesPanelState extends State<SnapshotsAndScenesPanel> {
  bool _isInitialized = false;

  ConfigSnapshotsViewmodel get _configSnapshotsViewmodel => context.read<ConfigSnapshotsViewmodel>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final double screenHeight = MediaQuery.of(context).size.height;
      _configSnapshotsViewmodel.initializeSourcesHeight(screenHeight);
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _updateSourcesHeight(double delta) {
    final double screenHeight = MediaQuery.of(context).size.height;
    _configSnapshotsViewmodel.updateSourcesHeight(delta, screenHeight);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.primaryBlack,
      ),
      child: Column(
        children: <Widget>[
          /// Snapshots Section
          const SnapshotSet(),

          /// Draggable divider
          DragDivider(onDragUpdate: _updateSourcesHeight),

          /// Scenes Section
          const Expanded(child: SceneSets()),
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
      color: Theme.of(context).colorScheme.primaryWhite,
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
            semanticFieldId: '${widget.headerText}name',
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
                  accessLabel: 'snapshots_cancel',
                  width: double.infinity,
                  label: "Cancel",
                  textStyle: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontSize: 10),
                  onTap: () {
                    widget.onCancel.call();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: FusionButton(
                  accessLabel: 'snapshot_create',
                  width: double.infinity,
                  textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontSize: 10,
                    color: context.colorScheme.primaryBlack,
                  ),

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
