part of '../equipment_location_dialog.dart';

class _FilterOptions extends StatelessWidget {
  const _FilterOptions({this.equipmentLocationId, this.currentFilter});

  final String? equipmentLocationId;
  final EQLDeviceType? currentFilter;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EqlProductsVm, EQLProductsState>(
      builder: (BuildContext context, EQLProductsState state) {
        final EqlProductsVm vm = BlocProvider.of<EqlProductsVm>(context);
        return Column(
          spacing: 12,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                FusionAppText(
                  text: 'Device',
                  style: context.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.normal,
                    color: context.colorScheme.onSurface,
                  ),
                ),

                const SizedBox(height: 8),

                FusionRadio<EQLDeviceType>(
                  selected: state.filters.deviceType,
                  options: currentFilter != null ? <EQLDeviceType>[currentFilter!] : EQLDeviceType.values,
                  labelBuilder: (EQLDeviceType mountingType) {
                    return FusionAppText(
                      text: mountingType.displayName,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colorScheme.onSurface,
                      ),
                    );
                  },
                  onChanged: (EQLDeviceType value) {
                    vm.updateFilters(
                      state.filters.copyWith(
                        deviceType: value,
                      ),
                    );
                  },
                ),
              ],
            ),
            _buildLAPropertyRow(
              context: context,
              label: "Spare Capacity",
              value: state.filters.spareCapacity.displayName,
              options: SpareCapacity.values.map((SpareCapacity capacity) => capacity.displayName).toList(),
              onOptionSelected: (int selectedIndex) {
                vm.updateFilters(state.filters.copyWith(spareCapacity: SpareCapacity.values[selectedIndex]));
              },
            ),
            _buildLAPropertyRow(
              context: context,
              label: "Monitoring",
              value: state.filters.monitoringType.displayName,
              options: MonitoringType.values.map((MonitoringType type) => type.displayName).toList(),
              onOptionSelected: (int selectedIndex) {
                vm.updateFilters(state.filters.copyWith(monitoringType: MonitoringType.values[selectedIndex]));
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildLAPropertyRow({
    required BuildContext context,
    required String label,
    required String value,
    List<String> options = const <String>[],
    required Function(int selectedIndex) onOptionSelected,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Expanded(
          child: FusionAppText(
            text: label,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.onSurface,
              fontWeight: FontWeight.normal,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: BuildingPageDronDown<String>(
            value: value,
            hintText: "Select type",
            items: options,
            onSelect: (String newValue) {
              final int selectedIndex = options.indexOf(newValue);
              onOptionSelected(selectedIndex);
            },
            labelBuilder: (String option) {
              return FusionAppText(
                text: option,
                style: Theme.of(context).textTheme.labelMedium,
              );
            },
          ),
        ),
      ],
    );
  }
}
