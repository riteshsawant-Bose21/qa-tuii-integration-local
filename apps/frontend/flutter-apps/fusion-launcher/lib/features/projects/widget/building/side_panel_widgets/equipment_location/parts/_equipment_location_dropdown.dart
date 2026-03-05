part of '../equipment_location_dialog.dart';

class _EquipmentLocationDropdown extends StatelessWidget {
  const _EquipmentLocationDropdown({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProjectViewModel, ProjectViewModelState>(
      builder: (BuildContext context, ProjectViewModelState state) {
        final List<EquipLocation> equipmentLocations = BlocProvider.of<ProjectViewModel>(context).equipLocations;

        return BlocBuilder<EquipmentLocationSelectionViewmodel, String?>(
          builder: (BuildContext context, String? selected) {
            return FusionContainer(
              child: BuildingPageDronDown<EquipLocation?>(
                value: selected != null ? equipmentLocations.firstWhere((EquipLocation element) => element.id == selected) : null,
                hintText: "Select Equipment Location",
                items: <EquipLocation?>[...equipmentLocations, null],
                onSelect: (EquipLocation? newValue) {
                  if (newValue != null) {
                    BlocProvider.of<EquipmentLocationSelectionViewmodel>(context).selectEquipmentLocation(newValue.id);
                  } else {
                    BlocProvider.of<ProjectViewModel>(
                      context,
                    ).addEquipLocation(equipLocation: EquipLocation(name: "Equipment Location ${equipmentLocations.length + 1}"));
                  }
                },
                labelBuilder: (EquipLocation? option) {
                  if (option == null) {
                    return Row(
                      children: <Widget>[
                        Icon(Icons.add, color: context.colorScheme.iconDefault),
                        const SizedBox(width: 8),
                        FusionAppText(
                          text: 'Create New Location',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    );
                  }
                  return SizedBox(
                    width: double.infinity,
                    child: FusionAppText(
                      text: option.name,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  );
                },
              ),
            );
          },
        );
        // return FusionDropDown<EquipLocation>(
        //   items: equipmentLocations,
        //   selectedIndex: equipmentLocations.lastIndexWhere((EquipLocation element) => element.id == selected),
        //   onSelected: (int index) {
        //     final EquipLocation selectedLocation = equipmentLocations[index];
        //     BlocProvider.of<EquipmentLocationSelectionViewmodel>(context).selectEquipmentLocation(selectedLocation.id);
        //   },
        //   itemBuilder:
        //       (BuildContext context, EquipLocation item, bool isSelected) => Padding(
        //         padding: const EdgeInsets.all(8.0),
        //         child: Row(
        //           spacing: 12,
        //           children: <Widget>[
        //             Checkbox(value: isSelected, onChanged: (_) {}),
        //             FusionAppText(
        //               text: item.name,
        //               style: context.textTheme.bodyMedium?.copyWith(
        //                 color: context.colorScheme.onSurface,
        //               ),
        //             ),
        //           ],
        //         ),
        //       ),
        //   childBuilder:
        //       (BuildContext context, int index, EquipLocation item) => Padding(
        //         padding: const EdgeInsets.all(8.0),
        //         child: FusionAppText(
        //           text: item.name,
        //           style: context.textTheme.bodyMedium?.copyWith(
        //             color: context.colorScheme.onSurface,
        //           ),
        //         ),
        //       ),
        // );
      },
    );
  }
}
