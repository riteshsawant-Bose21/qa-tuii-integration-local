import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/projects/widget/building/side_panle_widgets/floor_properties.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../../../core/service_locator.dart';
import '../../../../configuration/presentation/viewmodel/project_view_model.dart';
import 'hardware_properties.dart';
import 'listening_area_properties.dart';

class PropertiesPanel extends StatefulWidget {
  const PropertiesPanel({super.key, this.onSpeakerUpdated});
  final VoidCallback? onSpeakerUpdated;

  @override
  State<PropertiesPanel> createState() => _PropertiesPanelState();
}

class _PropertiesPanelState extends State<PropertiesPanel> with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;
  late final Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(duration: const Duration(milliseconds: 200), vsync: this, value: 1.0);
    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.5).animate(CurvedAnimation(parent: _rotationController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  /// Handles expansion state changes and triggers icon rotation animation.
  ///
  /// Called by the [ExpansionTile] when the user taps to expand or collapse.
  /// Animates the trailing icon to provide visual feedback.
  ///
  /// [expanded] - `true` if the tile is being expanded, `false` if collapsing.
  void _handleExpansionChanged(bool expanded) {
    if (expanded) {
      _rotationController.forward();
    } else {
      _rotationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();

    return BlocBuilder<ProjectViewModel, ProjectViewModelState>(
      builder: (BuildContext context, ProjectViewModelState state) {
        final HardwareComponent? selectedHardware = projectViewModel.getCurrentSelectedHardware();
        final ListeningArea? selectedListeningArea = projectViewModel.getCurrentSelectedListeningArea();
        final FloorModel currentFloor = projectViewModel.currentFloor;

        if (selectedHardware != null) {
          return HardwareComponentProperties(
            selectedHardware: selectedHardware,
            onSpeakerParametersChanged: widget.onSpeakerUpdated,
          );
        } else if (selectedListeningArea != null) {
          return ListeningAreaProperties(selectedListeningArea: selectedListeningArea);
        } else {
          return FloorProperties(selectedFloor: currentFloor);
        }
      },
    );
  }
}
