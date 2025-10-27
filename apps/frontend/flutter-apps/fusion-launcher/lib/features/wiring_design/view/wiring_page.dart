import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/wiring_design/controller/circuit_controller.dart';
import 'package:fusion_launcher/features/wiring_design/controller/helpers/project_manager_methods.dart';
import 'package:fusion_launcher/features/wiring_design/view/circuit_view.dart';

class WiringPage extends StatefulWidget {
  const WiringPage({super.key});

  @override
  State<WiringPage> createState() => _WiringPageState();
}

class _WiringPageState extends State<WiringPage> {
  late CircuitController controller = CircuitController(
    serviceLocator<ProjectViewModel>(),
  );

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProjectViewModel, ProjectViewModelState>(
      listener: (BuildContext context, ProjectViewModelState state) {
        if (state is DeviceSelectionChanged) {
          controller.selectElementFromPM(state.selectedDevice?.id);
        }
      },
      child: CircuitView(controller: controller),
    );
  }
}
