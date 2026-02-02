import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/wiring_design/view/port_connection/port_connection_overlay.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../core/assets/asset_svg.dart';

class WiringDeviceListView extends StatelessWidget {
  const WiringDeviceListView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProjectViewModel, ProjectViewModelState>(
      builder: (BuildContext context, ProjectViewModelState state) {
        final ProjectViewModel vm = serviceLocator<ProjectViewModel>();

        final List<WiringConnectionModel> wires = vm.getAllWiringConnections();
        final List<HardwareComponent> sources = vm.sources;
        final List<HardwareComponent> endPoints = vm.fusionEndpoints;
        // final List<HardwareComponent> controllers = vm.fusionControllers;
        final _ComponentDB db = _ComponentDB();
        for (final HardwareComponent element in vm.hardwareComponents) {
          db.addHardwareComponent(element);
        }

        return Column(
          // shrinkWrap: true,
          // padding: const EdgeInsets.symmetric(horizontal: 10),
          children: <Widget>[
            _DeviceListSection(
              db: db,
              sources: sources,
              label: "Sources",
              wires: wires,
            ),
            _DeviceListSection(
              db: db,
              sources: endPoints,
              label: "Endpoints",
              wires: wires,
            ),
          ],
        );
      },
    );
  }
}

class _DeviceListSection extends StatelessWidget {
  const _DeviceListSection({
    required this.sources,
    required this.label,
    required this.db,
    required this.wires,
  });
  final List<HardwareComponent> sources;
  final String label;
  final _ComponentDB db;
  final List<WiringConnectionModel> wires;
  @override
  Widget build(BuildContext context) {
    return FusionExpansionPanel(
      initiallyExpanded: true,
      titleBuilder:
          (BuildContext context, bool isExpanded) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
            child: Row(
              spacing: 8,
              children: <Widget>[
                AnimatedRotation(
                  duration: const Duration(milliseconds: 250),
                  turns: isExpanded ? 0.5 : 0.25,
                  child: FusionSvgIcon(
                    icon: AssetSvg.expandUp,
                    size: 12,
                    color: context.colorScheme.iconWhite,
                  ),
                ),
                Expanded(
                  child: FusionAppText(
                    text: "$label (${sources.length})",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.colorScheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
      content: Column(
        spacing: 0,
        children: <Widget>[
          for (final HardwareComponent device in sources)
            Builder(
              builder: (BuildContext context) {
                final List<_PortData> portData = <_PortData>[];
                for (final PortData port in <PortData>[
                  ...device.inputPortsData,
                  ...device.outputPortsData,
                ]) {
                  final WiringConnectionModel? connections = wires.firstWhereOrNull(
                    (WiringConnectionModel e) => e.portId == port.id || e.targetPortId == port.id,
                  );
                  final String? otherPortId = (connections?.portId == port.id) ? connections?.targetPortId : connections?.portId;
                  if (connections != null) {
                    portData.add(
                      _PortData(
                        data: port,
                        connectedTo: db.getPortDetail(
                          otherPortId ?? "",
                        ),
                        connectedDeviceName: db.getDeviceLabel(
                          otherPortId ?? "",
                        ),
                      ),
                    );
                  }
                }
                return _DeviceCard(
                  id: device.id,
                  type: SelectedItemType.source,
                  image: device.assetImagePath,
                  title: device.name,
                  ports: portData,
                );
              },
            ),
        ],
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({
    this.image,
    required this.title,
    required this.id,
    required this.type,
    required this.ports,
  });
  final String? image;
  final String title;
  final String id;
  final SelectedItemType type;
  final List<_PortData> ports;
  @override
  Widget build(BuildContext context) {
    final bool isSelected = serviceLocator<ProjectViewModel>().selectedDevice?.id == id;
    return InkWell(
      onTap: () {
        serviceLocator<ProjectViewModel>().setSelectedDevice(
          id,
          type,
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration:
            isSelected
                ? BoxDecoration(
                  // color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                )
                : BoxDecoration(
                  border: Border.all(
                    color: Colors.transparent,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                if (image != null)
                  Image.asset(
                    image!,
                    width: 20,
                    height: 20,
                  ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 8),
              ],
            ),
            for (final _PortData port in ports)
              Row(
                spacing: 8,
                children: <Widget>[
                  const SizedBox(
                    width: 10,
                  ),
                  Icon(
                    Icons.link,
                    color: context.colorScheme.primaryBlack,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: context.colorScheme.activePortBG,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(5),
                    child: Text(
                      port.connectedTo?.name ?? "",
                      style: TextStyle(
                        color: context.colorScheme.activePortFG,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  Flexible(
                    child: Text(
                      port.connectedDeviceName ?? "",
                      style: context.textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                      ),
                      maxLines: 3,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _PortData {
  final PortData data;
  final PortData? connectedTo;
  final String? connectedDeviceName;

  _PortData({
    required this.data,
    required this.connectedTo,
    required this.connectedDeviceName,
  });
}

class _ComponentDB {
  final Map<String, PortData> _portData = <String, PortData>{};
  final Map<String, String> _componentLabel = <String, String>{};
  final Map<String, String> _portDeviceMapping = <String, String>{};

  void addHardwareComponent(HardwareComponent hardware) {
    _componentLabel[hardware.id] = hardware.name;
    for (final PortData port in <PortData>[
      ...hardware.inputPortsData,
      ...hardware.outputPortsData,
      ...hardware.communicationPorts,
    ]) {
      _portData[port.id] = port;
      _portDeviceMapping[port.id] = hardware.id;
    }
  }

  String? getDeviceLabel(String portId) {
    return _componentLabel[_portDeviceMapping[portId]];
  }

  PortData? getPortDetail(String portId) {
    return _portData[portId];
  }
}
