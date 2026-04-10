import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/wiring_design/usecase/connection_usecase.dart';
import 'package:fusion_launcher/features/wiring_design/view/port_connection/port_connection_overlay.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../configuration/presentation/viewmodel/project_view_model.dart';

class WiringConnectionOverlay extends StatelessWidget {
  const WiringConnectionOverlay({
    super.key,
    required this.deviceId,
    required this.fromPortData,
    this.onPortTap,
  });
  final String deviceId;
  final PortData fromPortData;
  final void Function(PortData fromPort, PortData toPort)? onPortTap;
  @override
  Widget build(BuildContext context) {
    final List<HardwareComponent> hardwares =
        context.watch<ProjectViewModel>().hardwareComponents.where((HardwareComponent e) => e is! Speaker && e is! HardwareRack && e.id != deviceId).toList();
    final List<CircuitModel> circuits = context.watch<ProjectViewModel>().circuits;
    final Map<HardwareComponent, List<PortData>> compatibleHardwarePorts = <HardwareComponent, List<PortData>>{};
    final Map<CircuitModel, List<PortData>> compatibleCircuitPorts = <CircuitModel, List<PortData>>{};
    final ConnectionUseCase useCase = ConnectionUseCase();

    for (final HardwareComponent hardware in hardwares) {
      final List<PortData> compatible =
          <PortData>[
            ...hardware.inputPortsData,
            ...hardware.outputPortsData,
            ...hardware.communicationPorts,
          ].where((PortData port) => useCase.isCompatible(fromPortData.type, port.type)).toList();
      if (compatible.isNotEmpty) {
        compatibleHardwarePorts[hardware] = compatible;
      }
    }
    for (final CircuitModel circuit in circuits) {
      final List<PortData> compatible = <PortData>[circuit.inputPort].where((PortData port) => useCase.isCompatible(fromPortData.type, port.type)).toList();
      if (compatible.isNotEmpty) {
        compatibleCircuitPorts[circuit] = compatible;
      }
    }
    return FusionFlatContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            "Connect ${fromPortData.name} to:",
            style: context.textTheme.b3Regular,
          ),
          const Divider(),
          for (final HardwareComponent hardware in compatibleHardwarePorts.keys)
            FusionExpansionPanel(
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  ...compatibleHardwarePorts[hardware]!.map(
                    (PortData port) => Row(
                      spacing: 10,
                      children: <Widget>[
                        WiringPortWidget(
                          portData: port,
                          onTap: () {
                            // context.read<ProjectViewModel>().addWiringConnection(
                            //   fromDeviceId: deviceId,
                            //   fromPort: fromPortData,
                            //   toDeviceId: hardware.id,
                            //   toPort: port,
                            // );
                            // Navigator.of(context).pop();
                          },
                        ),

                        Text(
                          port.type.description,
                          style: context.textTheme.b3Regular,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              titleBuilder:
                  (BuildContext context, bool isExpanded) => Row(
                    children: <Widget>[
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(Icons.arrow_drop_down),
                      ),
                      Text(hardware.name),
                    ],
                  ),
              semanticsId: "compatible_hardware_${hardware.name}",
            ),
          for (final CircuitModel circuit in compatibleCircuitPorts.keys)
            FusionExpansionPanel(
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  ...compatibleCircuitPorts[circuit]!.map(
                    (PortData port) => Row(
                      spacing: 10,
                      children: <Widget>[
                        WiringPortWidget(
                          portData: port,
                          onTap: () {
                            // context.read<ProjectViewModel>().addWiringConnection(
                            //   fromDeviceId: deviceId,
                            //   fromPort: fromPortData,
                            //   toDeviceId: hardware.id,
                            //   toPort: port,
                            // );
                            // Navigator.of(context).pop();
                          },
                        ),

                        Text(
                          port.type.description,
                          style: context.textTheme.b3Regular,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              titleBuilder:
                  (BuildContext context, bool isExpanded) => Row(
                    children: <Widget>[
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(Icons.arrow_drop_down),
                      ),
                      Text(circuit.name),
                    ],
                  ),
              semanticsId: "compatible_circuit_${circuit.name}",
            ),
        ],
      ),
    );
  }
}

class WiringPortWidget extends StatelessWidget {
  const WiringPortWidget({super.key, required this.portData, this.onTap});
  final PortData portData;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: context.colorScheme.inactivePortBG,
            width: 2,
          ),
          shape: BoxShape.circle,
        ),
        padding: const EdgeInsets.all(6),
        child: Text(
          portData.name,
          style: context.textTheme.bodySmall?.copyWith(
            fontSize: 8,
          ),
        ),
      ),
    );
  }
}
