import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/authentication/launcher_sign_in_page.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/projects/viewmodel/eql_products_vm.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nested/nested.dart';

import '../../../../viewmodel/equipment_location_selection_viewmodel.dart';
import '../../../../viewmodel/equipment_location_viewmodel.dart';
import '../../speaker_selection_section/view_model/product_query_view_model.dart' show ProductQueryViewModel;
import '../../widgets/drop_down.dart';
import '../../widgets/grid_view.dart';

part 'parts/_equipment_location_dropdown.dart';
part 'parts/_filter_option.dart';
part 'parts/_product_tile.dart';
part 'parts/_rack_visualization.dart';
part 'parts/_system_requirement_section.dart';

class EquipmentLocationDialog extends StatelessWidget {
  const EquipmentLocationDialog({super.key, this.equipmentLocationId, this.currentFilter});
  final String? equipmentLocationId;
  final EQLDeviceType? currentFilter;
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: <SingleChildWidget>[
        BlocProvider<EqlProductsVm>(
          create:
              (BuildContext context) => EqlProductsVm(
                BlocProvider.of<ProjectViewModel>(context),
                BlocProvider.of<ProductQueryViewModel>(context),
                initialFilter: currentFilter,
              ),
        ),
        BlocProvider<EquipmentLocationSelectionViewmodel>(
          create:
              (BuildContext context) => EquipmentLocationSelectionViewmodel(
                equipmentLocationId,
              ),
        ),
        // BlocProvider<EquipmentLocationViewmodel>(
        //   create:
        //       (BuildContext context) => EquipmentLocationViewmodel(
        //         BlocProvider.of<ProjectViewModel>(context),
        //         equipmentLocationId,
        //       ),
        // ),
      ],

      child: SemanticHelper.container(
        testId: SemanticHelper.createTestId(SemanticTypes.container, "equipment_location_dialog"),
        child: Container(
          width: 720,
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
                    child: SemanticHelper.container(
                    testId: SemanticHelper.createTestId(SemanticTypes.container, "left_dialog"),
                    child: Column(
                      children: <Widget>[
                        if (equipmentLocationId == null) const _EquipmentLocationDropdown(),
                        Expanded(
                          child: BlocBuilder<EquipmentLocationSelectionViewmodel, String?>(
                            builder: (BuildContext context, String? equipmentId) {
                              return _EQLRackPreview(
                                equipmentLocationId: equipmentId,
                              );
                            },
                          ),
                        ),
                        Expanded(
                          child: SemanticHelper.formControl(
                                testId: SemanticHelper.createTestId(SemanticTypes.container, "available_devices"),
                                child: Column(
                            children: <Widget>[
                              SemanticHelper.formControl(
                                testId: SemanticHelper.createTestId(SemanticTypes.textInput, "equipment_location_dialog_search_input"),
                                child: NeumorphicDarkTextField(
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
                                      child: SemanticHelper.button(
                                        testId: SemanticHelper.createTestId(SemanticTypes.button, "equipment_location_dialog_sort_button"),
                                        child: FusionSvgIcon(
                                          icon: "assets/svg/sort.svg",
                                          color: context.colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: GestureDetector(
                                      onTap: () {},
                                      child: SemanticHelper.button(
                                        testId: SemanticHelper.createTestId(SemanticTypes.button, "equipment_location_dialog_filter_button"),
                                        child: FusionSvgIcon(
                                          icon: "assets/svg/filter.svg",
                                          color: context.colorScheme.onSurface,
                                        ),
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

                                      return _ProductTile(
                                        index: index,
                                        product: product,
                                        addProduct: () {
                                          final String? state2 = BlocProvider.of<EquipmentLocationSelectionViewmodel>(context).state;
                                          if (state2 == null) {
                                            FusionToast.error(
                                              context,
                                              message: "Please select an equipment location to add devices.",
                                            );
                                            return;
                                          }
                                          vm.addProductToLocation(
                                            equipLocationId: state2,
                                            product: product,
                                          );
                                        },
                                      );
                                    },
                                  ),
                                  _ => const SizedBox.shrink(),
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

                  ///********************************************************************** */
                  ///
                  /// ------- RIGHT PANEL -------
                  ///
                  ///********************************************************************** */
                  ///
                  Expanded(
                    child: SemanticHelper.container(
                    testId: SemanticHelper.createTestId(SemanticTypes.container, "right_dialog"),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF292826),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListView(
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
                                    child: SemanticHelper.button(
                                      testId: SemanticHelper.createTestId(SemanticTypes.button, "equipment_location_dialog_close_button"),
                                      child: const Padding(
                                        padding: EdgeInsets.all(2.0),
                                        child: Icon(LucideIcons.x200, size: 16),
                                      ),
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

                                    return SemanticHelper.container(
                                      testId: SemanticHelper.createTestId(SemanticTypes.container, "equipment_location_dialog_filter_option_$mode"),
                                      child: Container(
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
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0),
                            child: _FilterOptions(equipmentLocationId: equipmentLocationId, currentFilter: currentFilter),
                          ),
                          const SizedBox(height: 24),

                          const Divider(thickness: 0.5, height: 0),
                          const SizedBox(height: 16),
                          const SizedBox(height: 16),
                          const _EqlSystemRequirementSection(),
                        ],
                      ),
                    ),
                  ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
