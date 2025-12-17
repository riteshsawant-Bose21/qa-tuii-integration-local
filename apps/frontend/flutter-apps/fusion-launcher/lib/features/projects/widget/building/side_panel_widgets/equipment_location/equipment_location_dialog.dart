import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/authentication/launcher_sign_in_page.dart';
import 'package:fusion_launcher/features/projects/viewmodel/eql_products_vm.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../widgets/drop_down.dart';
import '../../widgets/grid_view.dart';

class EquipmentLocationDialog extends StatelessWidget {
  const EquipmentLocationDialog({super.key, required this.equipmentLocationId});
  final String equipmentLocationId;
  @override
  Widget build(BuildContext context) {
    return BlocProvider<EqlProductsVm>(
      create: (BuildContext context) => EqlProductsVm(),
      child: Container(
        width: 640,
        // constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: BlocBuilder<EqlProductsVm, EQLProductsState>(
          builder: (BuildContext context, EQLProductsState state) {
            final EqlProductsVm vm = BlocProvider.of<EqlProductsVm>(context);
            return Row(
              spacing: 12,
              children: <Widget>[
                ///********************************************************************** */
                ///
                /// ------- LEFT PANEL -------
                ///
                ///********************************************************************** */
                Expanded(
                  child: Column(
                    children: <Widget>[
                      NeumorphicDarkTextField(
                        prefix: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(
                            LucideIcons.search200,
                            color: Colors.grey[500],
                          ),
                        ),
                        borderRadius: 8,
                        contentPadding: const EdgeInsets.all(10),
                        hintText: "Search devices...",
                        hintStyle: context.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.normal),
                        onChanged: (String value) {
                          vm.updateFilters(state.filters.copyWith(searchQuery: value));
                        },
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: FusionAppText(
                              text: "Recently Viewed",
                              style: context.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.normal,
                                color: context.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () {},
                              child: FusionSvgIcon(
                                icon: "assets/svg/sort.svg",
                                color: context.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () {},
                              child: FusionSvgIcon(
                                icon: "assets/svg/filter.svg",
                                color: context.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Divider(
                        thickness: 0.5,
                        height: 0,
                      ),

                      Expanded(
                        child: switch (state.data) {
                          EQLProductsLoading() => const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CupertinoActivityIndicator(),
                            ),
                          ),
                          EQLProductsError(:final String message) => Center(
                            child: FusionAppText(
                              text: 'Error: $message',
                              style: context.textTheme.bodyMedium?.copyWith(color: context.colorScheme.error),
                            ),
                          ),
                          EQLProductsLoaded(:final List<EQLProduct> products) => ListView.builder(
                            itemCount: products.length,
                            itemBuilder: (BuildContext context, int index) {
                              final EQLProduct product = products[index];

                              return _ProductTile(product: product);
                            },
                          ),
                          _ => const SizedBox.shrink(),
                        },
                      ),
                    ],
                  ),
                ),

                ///********************************************************************** */
                ///
                /// ------- RIGHT PANEL -------
                ///
                ///********************************************************************** */
                ///
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF292826),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: FusionAppText(
                                  text: "Select Devices",
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: context.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: () => Navigator.of(context).pop(),
                                  child: const Padding(
                                    padding: EdgeInsets.all(2.0),
                                    child: Icon(LucideIcons.x200, size: 16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(thickness: 0.5, height: 0),
                        const SizedBox(height: 16),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: context.colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              spacing: 10,
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                ...<String>["Select", "Suggest"].map((String mode) {
                                  final bool isSelected = "Select" == mode;

                                  return Container(
                                    width: 89,
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isSelected ? context.colorScheme.surfaceBright : null,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: FusionAppText(
                                        text: mode,
                                        style: context.textTheme.bodySmall?.copyWith(
                                          color: context.colorScheme.onSurface,
                                          fontWeight: FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        ///
                        ///
                        ///
                        ///
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0),
                            child: Column(
                              spacing: 12,
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
                                      options: EQLDeviceType.values,
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
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
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
          child: BuildingPageDronDown(
            value: value,
            hintText: "Select type",
            options: options,
            onSelect: (String newValue) {
              final int selectedIndex = options.indexOf(newValue);
              onOptionSelected(selectedIndex);
            },
          ),
        ),
      ],
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({
    required this.product,
  });

  final EQLProduct product;

  @override
  Widget build(BuildContext context) {
    final String? assetImagePath = product.assetPath;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            spacing: 10,
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Builder(
                  builder: (BuildContext context) {
                    if (assetImagePath == null || assetImagePath.isEmpty) {
                      return const SizedBox();
                    }

                    return Image.file(
                      File(assetImagePath),
                      fit: BoxFit.contain,
                    );
                  },
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: FusionAppText(
                            text: product.name,
                            style: context.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: context.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        // info
                        FusionArrowPopup(
                          content: SizedBox(
                            width: 300,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                FusionAppText(
                                  text: product.description, //"L 22.4cm | W 14.7cm | H 8.3cm | 9kg", // TODO: hardcoded
                                  style: context.textTheme.bodySmall?.copyWith(
                                    color: context.colorScheme.onSurface,
                                  ),
                                ),

                                // GRID VIEW
                                Divider(color: context.colorScheme.onSurface.withValues(alpha: 0.2)),
                                Builder(
                                  builder: (BuildContext context) {
                                    // TODO: hardcoded
                                    final Map<String, String> details = product.specifications;
                                    // <String, String>{
                                    //   "Mounting": "Surface",
                                    //   "Frequency Response": "speaker",
                                    //   "Environment": "speaker",
                                    //   "HF Size": "speaker",
                                    //   "Power Handling": "speaker",
                                    //   "LF Size": "speaker",
                                    //   "Sensitivity": "speaker",
                                    //   "Max. SPL": "speaker",
                                    //   "Peak Power": "speaker",
                                    //   "Long Term Power": "speaker",
                                    // };

                                    final List<Widget> children = <Widget>[
                                      ...details.keys.map((String key) {
                                        return GestureDetector(
                                          onTap: () {
                                            // selectedSpeaker = selectedSpeaker == speaker ? null : speaker;
                                            // setState(() {});
                                          },
                                          behavior: HitTestBehavior.translucent,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: <Widget>[
                                              FusionAppText(
                                                text: key,
                                                style: context.textTheme.bodySmall?.copyWith(
                                                  fontWeight: FontWeight.normal,
                                                ),
                                              ),
                                              FusionAppText(
                                                text: details[key]!,
                                                style: context.textTheme.bodySmall?.copyWith(
                                                  fontWeight: FontWeight.normal,
                                                  color: context.colorScheme.onSurface.withAlpha(128),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                    ];

                                    return BuildingPageGridView(children: children);
                                  },
                                ),
                              ],
                            ),
                          ),
                          child: Icon(
                            LucideIcons.info200,
                            size: 12,
                            color: context.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),

                    FusionAppText(
                      text: "\$290.00", // TODO: hardcoded
                      style: context.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.normal,
                        color: context.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              NeumorphicDarkButton(
                height: 24,
                width: 24,
                borderRadius: 6,
                backgroundColor: null, //isSelected ? FusionDarkColorPallette.green20 : null,
                child: Icon(
                  LucideIcons.plus,
                  size: 12,
                  color: context.colorScheme.onSurface,
                ),
                onTap: () async {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}
