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

                SemanticHelper.container(
                  testId: SemanticHelper.createTestId(SemanticTypes.container, "equipment_location_dialog_filter_option_device_type"),
                  child: FusionRadio<EQLDeviceType>(
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
          child: FusionPopupMenu<String>(
            // value: value,
            // hintText: "Select $label",
            items: options,
            onSelected: (String newValue) {
              final int selectedIndex = options.indexOf(newValue);
              onOptionSelected(selectedIndex);
            },
            popupOffset: const Offset(5, 0),
            child: FusionContainer(
              raised: true,
              color: context.colorScheme.elevation2,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Flexible(
                      child: FusionAppText(
                        text: value,
                        style: context.textTheme.bodySmall,
                      ),
                    ),
                    Icon(LucideIcons.chevronDown200, size: 16, color: context.colorScheme.iconDefault),
                  ],
                ),
              ),
            ),
            itemBuilder: (BuildContext context, String option) {
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
