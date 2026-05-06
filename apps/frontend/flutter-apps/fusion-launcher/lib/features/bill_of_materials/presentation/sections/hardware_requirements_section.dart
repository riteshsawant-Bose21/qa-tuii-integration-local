part of '../bill_of_materials_page.dart';

class _HardwareRequirementsSection extends StatelessWidget {
  const _HardwareRequirementsSection();

  /// DSP + Amplifier count — represents rack-mounted active devices.
  int _deviceCount(List<HardwareComponent> hw) {
    return hw.where((HardwareComponent c) => c is FusionDsp || c is Amplifier || c is Source).length;
  }

  /// Total ethernet connection ports across all devices in the location.
  int _networkPortCount(List<HardwareComponent> hw) {
    int total = 0;
    for (final HardwareComponent c in hw) {
      for (final PortData port in c.communicationPorts) {
        if (port.type == PortType.networkSwitchIn || port.type == PortType.aes67Input || port.type == PortType.aes67Output || port.type == PortType.ethernet) {
          total++;
        }
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return FusionFlatContainer(
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
      child: BlocBuilder<ProjectViewModel, ProjectViewModelState>(
        builder: (BuildContext context, ProjectViewModelState _) {
          final ProjectViewModel vm = serviceLocator<ProjectViewModel>();
          final List<EquipLocation> locations = vm.equipLocations;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              FusionAppText(
                semanticId: 'bom_hw_title',
                text: 'Hardware Requirements',
                style: context.textTheme.h4Bold,
              ),
              Expanded(
                child:
                    locations.isEmpty
                        ? Center(
                          child: FusionAppText(
                            semanticId: 'bom_hw_empty',
                            text: 'No equipment locations defined.',
                            style: context.textTheme.l1Regular.withColor(context.colorScheme.textBody),
                          ),
                        )
                        : FusionAppTable(
                          semanticId: 'bom_hw_requirements_table',
                          spacing: 16,
                          headers: <FusionTableHeader>[
                            FusionTableHeader(title: 'EQUIPMENT LOCATION', flex: 3),
                            FusionTableHeader(title: 'EQUIPMENT RACK', flex: 2),
                            FusionTableHeader(title: 'NETWORK SWITCHES', flex: 2),
                          ],
                          itemCount: locations.length,
                          itemBuilder: (BuildContext context, int index) {
                            final EquipLocation loc = locations[index];
                            final List<HardwareComponent> hw = vm.getHardwareForEquipLocation(equipLocationId: loc.id);

                            final int deviceCount = _deviceCount(hw);
                            final int portCount = _networkPortCount(hw);

                            return <Widget>[
                              FusionAppText(
                                semanticId: 'bom_hw_location_$index',
                                text: loc.name,
                                maxLine: 1,
                                style: context.textTheme.l1MediumTight.withColor(context.colorScheme.textBody),
                              ),
                              FusionAppText(
                                semanticId: 'bom_hw_rack_$index',
                                text: deviceCount == 0 ? '—' : '$deviceCount ${deviceCount == 1 ? 'Device' : 'Devices'}',
                                style: context.textTheme.l1Regular.withColor(context.colorScheme.textBody),
                              ),
                              FusionAppText(
                                semanticId: 'bom_hw_switch_$index',
                                text: portCount == 0 ? '—' : '$portCount ${portCount == 1 ? 'Port' : 'Ports'}',
                                style: context.textTheme.l1Regular.withColor(context.colorScheme.textBody),
                              ),
                            ];
                          },
                        ),
              ),
            ],
          );
        },
      ),
    );
  }
}
