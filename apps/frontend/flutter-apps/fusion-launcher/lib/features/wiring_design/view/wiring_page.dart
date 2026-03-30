import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_base_painter.dart' show FusionBasePainter;
import 'package:fusion_launcher/features/wiring_design/controller/circuit_controller.dart';
import 'package:fusion_launcher/features/wiring_design/controller/helpers/initialization_handler_mixin.dart';
import 'package:fusion_launcher/features/wiring_design/controller/helpers/project_manager_methods.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../fusion_canvas/view/fusion_canvas.dart';
import '../../fusion_canvas/view/painters/elements/wiring/wiring_source_painter.dart' show WiringSourcePainter;
import 'circuit_view.dart';

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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fitToViewPort();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return BlocListener<ProjectViewModel, ProjectViewModelState>(
        listener: (BuildContext context, ProjectViewModelState state) {
          if (state is DeviceSelectionChanged) {
            controller.selectElementFromPM(state.selectedDevice?.id);
          }
          if (state is ProjectUpdated) {
            controller.loadFromPM();
          }
        },
        child: CircuitView(controller: controller),
      );
    }
    return BlocBuilder<ProjectViewModel, ProjectViewModelState>(
      builder: (BuildContext context, ProjectViewModelState state) {
        final ProjectViewModel projectViewModel = context.watch<ProjectViewModel>();
        return FusionCanvas(
          elements: <FusionBasePainter>[
            for (Source source in projectViewModel.sources) WiringSourcePainter(source: source),
          ],
          builder: (BuildContext context) => Container(),
          toolbarEvents: FusionCanvasEvents(
            onMoveLayer: (FusionBasePainter painter, Offset offset) {
              if (painter is WiringSourcePainter) {
                final Source source = painter.source;
                projectViewModel.updateHardware(hardware: source.copyWith(wiringPos: (source.wiringPos ?? Offset.zero) + offset));
              }
            },
            
          ),
        );
        // if (state is DeviceSelectionChanged) {
        //   controller.selectElementFromPM(state.selectedDevice?.id);
        // }
        // if (state is ProjectUpdated) {
        //   controller.loadFromPM();
        // }
      },

      // child: //CircuitView(controller: controller),
    );
  }
}
