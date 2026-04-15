import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/fusion_tool_state.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/tools/connection_tool_params.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/elements/wiring/port_painter.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_base_painter.dart' show FusionBasePainter;
import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_canvas_painter.dart';
import 'package:fusion_launcher/features/projects/presentation/project_work_area.dart';
import 'package:fusion_launcher/features/wiring_design/algorithm/intersection_manager.dart';
import 'package:fusion_launcher/features/wiring_design/algorithm/path_system_storage.dart';
import 'package:fusion_launcher/features/wiring_design/usecase/connection_usecase.dart';
import 'package:fusion_launcher/features/wiring_design/view/wiring_toolbar.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/models/project_entities/controller.dart';
import 'package:fusion_lib/models/project_entities/endpoints.dart';

import '../../fusion_canvas/view/fusion_canvas.dart';
import '../../fusion_canvas/view/painters/elements/wiring/wiring_connection_painter.dart';
import '../../fusion_canvas/view/painters/elements/wiring/wiring_controller_painter.dart' show WiringControllerPainter;
import '../../fusion_canvas/view/painters/elements/wiring/wiring_devices_painter.dart';
import '../../fusion_canvas/view/painters/elements/wiring/wiring_source_painter.dart' show WiringSourcePainter;
import '../../fusion_canvas/view/painters/elements/wiring/wiring_zone_painter.dart';
import '../../fusion_canvas/viewmodel/fusion_canvas_state_viewmodel.dart';
import '../../fusion_canvas/viewmodel/tools/fusion_canvas_tool.dart';
import '../algorithm/connection_manager.dart';
import '../algorithm/zone_manager.dart';
import 'port_connection/wiring_connection_overlay.dart';
import 'widgets/overlay_container.dart';
import 'wiring_legend.dart';

class WiringPage extends StatefulWidget {
  const WiringPage({super.key});

  @override
  State<WiringPage> createState() => _WiringPageState();
}

class _WiringPageState extends State<WiringPage> {
  final PathSystemStorage pathStorage = PathSystemStorage();
  final IntersectionManager intersectionManager = IntersectionManager();
  final WiringZoneManager zoneManager = WiringZoneManager();
  final ConnectionManager connectionManager = ConnectionManager();

  WiringPortData? portId;
  String? layerId;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _correctPositionOfNewHardware();
    });
  }

  void _correctPositionOfNewHardware() {
    for (final HardwareComponent hardware in context.read<ProjectViewModel>().hardwareComponents) {
      if (hardware.wiringPos == null) {
        context.read<ProjectViewModel>().updateHardware(
          hardware: hardware.copyWith(),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                onConnectionDrop: (WiringConnectionModel connection) {
                  // showDialog(context: context, builder: builder)
                  projectViewModel.removeWiringConnection(connectionId: connection.id);
                },
                getExistingConnectionsForPort: (String deviceId, String portId) {
                  return projectViewModel.getAllWiringConnections().where((WiringConnectionModel connection) {
                    return (connection.deviceId == deviceId && connection.portId == portId) ||
                        (connection.targetDeviceId == deviceId && connection.targetPortId == portId);
                  }).toList();
                },
                onConnectionCreate: (WiringPortData source, Offset pos, WiringPortData dest) {
                  final ConnectionUseCase connectionUseCase = ConnectionUseCase();
                  final WiringConnectionModel? existingConnection = projectViewModel.getAllWiringConnections().firstWhereOrNull(
                    (WiringConnectionModel connection) =>
                        (connection.deviceId == source.deviceId && connection.portId == source.port.id) ||
                        (connection.targetDeviceId == source.deviceId && connection.targetPortId == source.port.id),
                  );
                  if (existingConnection != null) {
                    return;
                  }
                  if (connectionUseCase.isCompatible(source.port.type, dest.port.type)) {
                    projectViewModel.addWiringConnection(
                      connection: connectionUseCase.createConnection(
                        fromDeviceId: source.deviceId,
                        fromPort: source.port,
                        toDeviceId: dest.deviceId,
                        toPort: dest.port,
                      ),
                    );
                  }
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
              else if (source is FusionController || source is FusionEndpoints)
                WiringControllerPainter(device: source, connectionManager: connectionManager)
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
          builder: (BuildContext context) {
            return LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final FusionCanvasPainter? painter = FusionCanvasPainterProvider.of(context)?.value;
                Offset? position;
                if (painter != null && layerId != null && portId != null) {
                  final FusionBasePainter? layer = painter.getLayerById(layerId!);
                  if (layer != null && layer is PortPainter) {
                    position = context.read<FusionCanvasStateViewModel>().transformPosition(
                      layer.getPortPositionWithPadding(portId!.id, painter) ?? Offset.zero,
                    );
                  }
                }
                final Offset resultedPosition = position ?? Offset.zero;
                final double width = 250; //* controller.canvasScale;
                // final double padding = 30 * controller.canvasState.scale;
                // if (port.relativePosition.dx < port.parent.size.width * 0.1) {
                //   resultedPosition = position! + Offset(-width - padding, 0);
                // } else if (port.relativePosition.dx > port.parent.size.width * 0.7) {
                //   resultedPosition = position! + Offset(padding, 0);
                // }
                final Rect currentViewPortRect = context.read<FusionCanvasStateViewModel>().state.offset & (constraints.biggest);

                return Stack(
                  children: <Widget>[
                    if (position != null)
                      Positioned.fill(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              portId = null;
                              layerId = null;
                            });
                          },
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.1),
                            child: const Center(),
                          ),
                        ),
                      ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: WiringToolBar(
                        onMoveLayer: moveLayer,
                      ),
                    ),
                    if (position != null)
                      OverlayContainer(
                        viewPort: currentViewPortRect,
                        position: resultedPosition,
                        tipPosition: position,
                        width: width,
                        child: WiringConnectionOverlay(
                          deviceId: portId!.deviceId,
                          fromPortData: portId!.port,
                          onPortTap: (PortData fromPort, PortData toPort, String toDeviceId) {
                            projectViewModel.addWiringConnection(
                              connection: ConnectionUseCase().createConnection(
                                fromDeviceId: portId!.deviceId,
                                fromPort: fromPort,
                                toDeviceId: toDeviceId,
                                toPort: toPort,
                              ),
                            );
                            setState(() {
                              portId = null;
                              layerId = null;
                            });
                          },
                        ),
                      ),

                    const Align(alignment: Alignment.topRight, child: WorkSafeAreaContent(child: WiringLegend())),
                  ],
                );
              },
            );
          },
          toolbarEvents: FusionCanvasEvents(
            inputEvents: FusionCanvasInputEvents(
              onKeyEvent: (KeyEvent event) {
                if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
                  setState(() {
                    portId = null;
                    layerId = null;
                  });
                }
                return false;
              },
            ),
            onElementClicked: (FusionBasePainter painter, FusionCanvasElement? element) {
              if (element is! WiringPortData) {
                return false;
              }
              setState(() {
                portId = element;
                layerId = painter.id;
              });
              return false;
            },
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
                final WiringConnectionModel connection = painter.connection;
                final List<AxisLock> axisLocks = painter.axisLocks ?? <AxisLock>[];

                projectViewModel.updateWiringConnection(
                  connection: connection.copyWith(
                    axisLocks: axisLocks,
                  ),
                );
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
