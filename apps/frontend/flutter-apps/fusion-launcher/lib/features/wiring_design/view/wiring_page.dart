import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/fusion_tool_state.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/tools/connection_tool_params.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/elements/wiring/port_painter.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_base_painter.dart' show FusionBasePainter;
import 'package:fusion_launcher/features/wiring_design/algorithm/intersection_manager.dart';
import 'package:fusion_launcher/features/wiring_design/algorithm/path_system_storage.dart';
import 'package:fusion_launcher/features/wiring_design/controller/circuit_controller.dart';
import 'package:fusion_launcher/features/wiring_design/controller/helpers/initialization_handler_mixin.dart';
import 'package:fusion_launcher/features/wiring_design/controller/helpers/project_manager_methods.dart';
import 'package:fusion_launcher/features/wiring_design/usecase/connection_usecase.dart';
import 'package:fusion_launcher/features/wiring_design/view/wiring_toolbar.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../fusion_canvas/view/fusion_canvas.dart';
import '../../fusion_canvas/view/painters/elements/wiring/wiring_connection_painter.dart';
import '../../fusion_canvas/view/painters/elements/wiring/wiring_devices_painter.dart';
import '../../fusion_canvas/view/painters/elements/wiring/wiring_source_painter.dart' show WiringSourcePainter;
import '../../fusion_canvas/view/painters/elements/wiring/wiring_zone_painter.dart';
import '../../fusion_canvas/viewmodel/tools/fusion_canvas_tool.dart';
import '../algorithm/connection_manager.dart';
import '../algorithm/zone_manager.dart';
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
  final PathSystemStorage pathStorage = PathSystemStorage();
  final IntersectionManager intersectionManager = IntersectionManager();
  final WiringZoneManager zoneManager = WiringZoneManager();
  final ConnectionManager connectionManager = ConnectionManager();
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
    return BlocConsumer<ProjectViewModel, ProjectViewModelState>(
      listener: (BuildContext context, ProjectViewModelState state) {
        pathStorage.removeKeysExcept(
          context.read<ProjectViewModel>().getAllWiringConnections().map((WiringConnectionModel c) => c.id).toSet(),
        );
        zoneManager.syncWithProjectManager(context.read<ProjectViewModel>());
        connectionManager.syncWithProjectManager(context.read<ProjectViewModel>());
      },
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
                  if (dest == null) {
                    return;
                  }
                  projectViewModel.addWiringConnection(
                    connection: ConnectionUseCase().createConnection(
                      fromDeviceId: source.deviceId,
                      fromPort: source.port,
                      toDeviceId: dest.deviceId,
                      toPort: dest.port,
                    ),
                  );
                },
              ),
            ),
            FusionCanvasTool.multiSelectionTool,
          ],
          elements: <FusionBasePainter>[
            // FusionDottedBgPainter(color: Colors.grey.withValues(alpha: 0.2)),
            for (HardwareComponent source in projectViewModel.hardwareComponents)
              if (source is Source)
                WiringSourcePainter(source: source, connectionManager: connectionManager)
              else if (source is! Speaker && source is! HardwareRack)
                WiringDevicesPainter(device: source, connectionManager: connectionManager),

            for (Zone zone in projectViewModel.zones) WiringZonePainter(zone: zone, zoneManager: zoneManager, connectionManager: connectionManager),
            for (WiringConnectionModel connection in projectViewModel.getAllWiringConnections())
              // if (connection.sourcePortId != null)
              WiringConnectionPainter(
                connection: connection,
                pathStorage: pathStorage,
                intersectionManager: intersectionManager,
              ),
          ],
          builder:
              (BuildContext context) => Align(
                alignment: Alignment.bottomCenter,
                child: WiringToolBar(
                  onMoveLayer: moveLayer,
                ),
              ),
          toolbarEvents: FusionCanvasEvents(
            onDeleteLayer: (FusionBasePainter painter) {
              if (painter is WiringConnectionPainter) {
                final WiringConnectionModel connection = painter.connection;
                projectViewModel.removeWiringConnection(connectionId: connection.id);
              } else if (painter is WiringDevicesPainter) {
                final HardwareComponent device = painter.device;
                projectViewModel.removeHardware(hardwareId: device.id);
              } else if (painter is WiringSourcePainter) {
                final Source source = painter.source;
                projectViewModel.removeHardware(hardwareId: source.id);
              }
            },
            onMovePoints: (FusionBasePainter painter, List<String> points, Offset delta) {
              if (painter is WiringConnectionPainter) {
                // print(" Moving points for connection ${painter.connection.id}, delta=$delta");
                // final WiringConnectionModel connection = painter.connection;
                // final List<FusionCanvasPoint>? updatedPoints = painter.pathPoints;
                // if (updatedPoints == null) return;
                // final Map<int, FusionCanvasPoint> newPoints = <int, FusionCanvasPoint>{};
                // for (String pointId in points) {
                //   if (updatedPoints.any((FusionCanvasPoint p) => p.id == pointId)) {
                //     final int index = updatedPoints.indexWhere((FusionCanvasPoint p) => p.id == pointId);
                //     // updatedPoints[index] = FusionCanvasPoint(position: updatedPoints[index].position);
                //     newPoints[index] = updatedPoints[index].copyWith(position: updatedPoints[index].position);
                //   }
                // }
                // projectViewModel.updateWiringConnection(
                //   connection: connection.copyWith(
                //     points: newPoints.isEmpty ? <FusionCanvasPoint>[] : newPoints.entries.map((MapEntry<int, FusionCanvasPoint> e) => e.value).toList(),
                //   ),
                // );
                pathStorage.clearPathForLayer(painter.id);
              }
            },
            onMoveLayer: moveLayer,
          ),
        );
      },
    );
  }

  void moveLayer(FusionBasePainter painter, Offset offset) {
    final ProjectViewModel projectViewModel = context.read<ProjectViewModel>();
    if (painter is WiringSourcePainter) {
      final Source source = painter.source;
      projectViewModel.updateHardware(hardware: source.copyWith(wiringPos: (source.wiringPos ?? Offset.zero) + offset));
    }
    if (painter is WiringDevicesPainter) {
      final HardwareComponent device = painter.device;
      projectViewModel.updateHardware(hardware: device.copyWith(wiringPos: (device.wiringPos ?? Offset.zero) + offset));
    }
    if (painter is WiringZonePainter) {
      final Zone zone = painter.zone;
      projectViewModel.updateZone(zone: zone.copyWith(wiringPos: (zone.wiringPos ?? Offset.zero) + offset));
    }
  }
}
