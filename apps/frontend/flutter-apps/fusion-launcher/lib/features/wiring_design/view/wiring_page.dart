import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/fusion_tool_state.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/tools/connection_tool_params.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/elements/wiring/port_painter.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_base_painter.dart' show FusionBasePainter;
import 'package:fusion_launcher/features/wiring_design/controller/circuit_controller.dart';
import 'package:fusion_launcher/features/wiring_design/controller/helpers/initialization_handler_mixin.dart';
import 'package:fusion_launcher/features/wiring_design/controller/helpers/project_manager_methods.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../fusion_canvas/view/fusion_canvas.dart';
import '../../fusion_canvas/view/painters/elements/wiring/wiring_devices_painter.dart';
import '../../fusion_canvas/view/painters/elements/wiring/wiring_source_painter.dart' show WiringSourcePainter;
import '../../fusion_canvas/viewmodel/tools/fusion_canvas_tool.dart';
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
          tools: <FusionCanvasTool<FusionToolState>>[
            FusionCanvasTool.measureTool,
            FusionCanvasTool.penTool,
            FusionCanvasTool.dragTool,
            FusionCanvasTool.connectionTool(
              connectionParams: ConnectionToolParams(
                onConnectionDrop: (WiringPortData source, Offset pos, WiringPortData? dest) {
                  print("Connection dropped: source=${source.id}, pos=$pos, dest=${dest?.id}");
                  // controller.handleConnectionDrop(source: source, pos: pos, dest: dest);
                },
              ),
            ),
            FusionCanvasTool.multiSelectionTool,
          ],
          elements: <FusionBasePainter>[
            for (HardwareComponent source in projectViewModel.hardwareComponents)
              if (source is Source)
                WiringSourcePainter(source: source)
              else if (source is! Speaker && source is! HardwareRack)
                WiringDevicesPainter(device: source),
          ],
          builder: (BuildContext context) => Container(),
          toolbarEvents: FusionCanvasEvents(
            onMoveLayer: (FusionBasePainter painter, Offset offset) {
              if (painter is WiringSourcePainter) {
                final Source source = painter.source;
                projectViewModel.updateHardware(hardware: source.copyWith(wiringPos: (source.wiringPos ?? Offset.zero) + offset));
              }
              if (painter is WiringDevicesPainter) {
                final HardwareComponent device = painter.device;
                projectViewModel.updateHardware(hardware: device.copyWith(wiringPos: (device.wiringPos ?? Offset.zero) + offset));
              }
            },
          ),
        );
      },
    );
  }
}
