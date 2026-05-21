import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/authentication/launcher_sign_in_page.dart';
import 'package:fusion_launcher/features/configuration/presentation/usecase/device_suggestion_usecase.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/projects/models/eql_product.dart';
import 'package:fusion_launcher/features/projects/viewmodel/device_suggestion_viewmodel.dart';
import 'package:fusion_launcher/features/projects/viewmodel/eql_products_vm.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/product_data/models/product_port_data.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nested/nested.dart';
import 'package:recase/recase.dart';

import '../../../../../../core/service_locator.dart';
import '../../../../../speaker_selection_popup/viewmodel/product_query_view_model.dart' show ProductQueryViewModel;
import '../../../../viewmodel/equipment_location_selection_viewmodel.dart';
import '../../../../viewmodel/equipment_location_viewmodel.dart';
import '../../widgets/drop_down.dart';
import '../../widgets/grid_view.dart';

part 'parts/_equipment_location_dropdown.dart';
part 'parts/_filter_option.dart';
part 'parts/_product_tile.dart';
part 'parts/_rack_visualization.dart';
part 'parts/_system_requirement_section.dart';

enum _EqlDeviceListMode { select, suggest }

class _EqlDeviceListModeCubit extends Cubit<_EqlDeviceListMode> {
  _EqlDeviceListModeCubit() : super(_EqlDeviceListMode.select);

  void setMode(_EqlDeviceListMode mode) {
    if (state != mode) {
      emit(mode);
    }
  }
}

class EquipmentLocationDialog extends StatelessWidget {
  const EquipmentLocationDialog({
    super.key,
    this.equipmentLocationId,
    this.currentFilter,
  });
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
        BlocProvider<_EqlDeviceListModeCubit>(
          create: (_) => _EqlDeviceListModeCubit(),
        ),
        BlocProvider<DeviceSuggestionViewModel>(
          create:
              (BuildContext context) => DeviceSuggestionViewModel(
                productQueryModel: BlocProvider.of<ProductQueryViewModel>(context),
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

      child: MultiBlocListener(
        listeners: <SingleChildWidget>[
          BlocListener<ProjectViewModel, ProjectViewModelState>(
            listener: (BuildContext context, ProjectViewModelState state) {
              context.read<DeviceSuggestionViewModel>().refresh();
            },
          ),
        ],
        child: SemanticHelper.container(
          testId: SemanticHelper.createTestId(
            SemanticTypes.container,
            "equipment_location_dialog",
          ),
          child: Container(
            width: 720,
            height: MediaQuery.of(context).size.height * 0.8,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.colorScheme.elevation1,
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
                        testId: SemanticHelper.createTestId(
                          SemanticTypes.container,
                          "left_dialog",
                        ),
                        child: Column(
                          children: <Widget>[
                            if (equipmentLocationId == null) const _EquipmentLocationDropdown(),
                            Expanded(
                              child: BlocBuilder<EquipmentLocationSelectionViewmodel, String?>(
                                builder: (
                                  BuildContext context,
                                  String? equipmentId,
                                ) {
                                  return _EQLRackPreview(
                                    equipmentLocationId: equipmentId,
                                  );
                                },
                              ),
                            ),
                            Expanded(
                              child: SemanticHelper.formControl(
                                testId: SemanticHelper.createTestId(
                                  SemanticTypes.container,
                                  "available_devices",
                                ),
                                child: Column(
                                  children: <Widget>[
                                    SemanticHelper.formControl(
                                      testId: SemanticHelper.createTestId(
                                        SemanticTypes.textInput,
                                        "equipment_location_dialog_search_input",
                                      ),
                                      child: NeumorphicDarkTextField(
                                        prefix: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                          ),
                                          child: Icon(
                                            LucideIcons.search200,
                                            color: context.colorScheme.iconDefault,
                                          ),
                                        ),
                                        borderRadius: 8,
                                        contentPadding: const EdgeInsets.all(10),
                                        hintText: "Search devices...",
                                        hintStyle: context.textTheme.labelSmall?.copyWith(
                                          fontWeight: FontWeight.normal,
                                        ),
                                        onChanged: (String value) {
                                          vm.updateFilters(
                                            state.filters.copyWith(
                                              searchQuery: value,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: <Widget>[
                                        Expanded(
                                          child: BlocBuilder<_EqlDeviceListModeCubit, _EqlDeviceListMode>(
                                            builder: (BuildContext context, _EqlDeviceListMode mode) {
                                              return FusionAppText(
                                                text: mode == _EqlDeviceListMode.suggest ? "Suggested Devices" : "Recently Viewed",
                                                style: context.textTheme.bodySmall?.copyWith(
                                                  fontWeight: FontWeight.normal,
                                                  color: context.colorScheme.onSurface,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        InkWell(
                                          onTap: () {
                                            if (context.read<_EqlDeviceListModeCubit>().state == _EqlDeviceListMode.suggest) {
                                              context.read<DeviceSuggestionViewModel>().refresh();
                                            } else {
                                              vm.refresh();
                                            }
                                          },
                                          child: Tooltip(
                                            message: "Refresh",
                                            child: Icon(
                                              LucideIcons.refreshCw200,
                                              size: 16,
                                              color: context.colorScheme.textPrimary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        FusionArrowPopup(
                                          semanticId: 'equipment_location_sort_products',
                                          blurAmount: 1,
                                          content: SizedBox(
                                            width: 220,
                                            child: Padding(
                                              padding: const EdgeInsets.all(16.0),

                                              child: BlocProvider<EqlProductsVm>.value(
                                                value: vm,
                                                child: BlocBuilder<EqlProductsVm, EQLProductsState>(
                                                  builder: (
                                                    BuildContext context,
                                                    EQLProductsState state,
                                                  ) {
                                                    final EqlProductsSort? sort = state.sortBy;
                                                    return Column(
                                                      mainAxisSize: MainAxisSize.min,
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: <Widget>[
                                                        FusionAppText(
                                                          text: 'Sort by',
                                                          style: context.textTheme.bodySmall?.copyWith(
                                                            color: context.colorScheme.onSurface,
                                                          ),
                                                        ),
                                                        const SizedBox(height: 8),

                                                        ...EqlProductsSort.values.map(
                                                          (
                                                            EqlProductsSort sortOption,
                                                          ) {
                                                            final bool isSelected = sortOption == sort;
                                                            return InkWell(
                                                              onTap: () {
                                                                vm.updateSort(
                                                                  sortOption,
                                                                );
                                                                Navigator.of(
                                                                  context,
                                                                ).pop();
                                                              },
                                                              child: Padding(
                                                                padding: const EdgeInsets.symmetric(
                                                                  vertical: 8.0,
                                                                ),
                                                                child: Row(
                                                                  children: <Widget>[
                                                                    SemanticHelper.toggle(
                                                                      testId: SemanticHelper.createTestId(
                                                                        SemanticTypes.toggle,
                                                                        "eql_sort_option_toggle_${sortOption.index}",
                                                                      ),
                                                                      value: isSelected,
                                                                      child: Icon(
                                                                        isSelected ? Icons.circle : Icons.radio_button_unchecked,
                                                                        size: 14,
                                                                        color:
                                                                            isSelected
                                                                                ? context.colorScheme.primary
                                                                                : context.colorScheme.onSurface.withValues(
                                                                                  alpha: 0.5,
                                                                                ),
                                                                      ),
                                                                    ),
                                                                    const SizedBox(
                                                                      width: 8,
                                                                    ),
                                                                    const SizedBox(
                                                                      width: 8,
                                                                    ),
                                                                    FusionAppText(
                                                                      text: sortOption.label,
                                                                      style: context.textTheme.bodySmall?.copyWith(
                                                                        color: context.colorScheme.onSurface,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                          ),

                                          child: Tooltip(
                                            message: "Sort",

                                            child: FusionIcon.svg(
                                              semanticId: "equipment_location_dialog_sort_button",
                                              "assets/svg/sort.svg",
                                              color: context.colorScheme.textPrimary,
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
                                      child: BlocBuilder<_EqlDeviceListModeCubit, _EqlDeviceListMode>(
                                        builder: (BuildContext context, _EqlDeviceListMode mode) {
                                          if (mode == _EqlDeviceListMode.suggest) {
                                            return BlocBuilder<DeviceSuggestionViewModel, DeviceSuggestionResult?>(
                                              builder: (BuildContext context, DeviceSuggestionResult? suggestionResult) {
                                                if (suggestionResult == null) {
                                                  return const Center(
                                                    child: Padding(
                                                      padding: EdgeInsets.all(16.0),
                                                      child: CupertinoActivityIndicator(),
                                                    ),
                                                  );
                                                }

                                                final List<({EQLProduct product, int quantity})> suggestedProducts = _mapSuggestedProducts(
                                                  result: suggestionResult,
                                                  state: state,
                                                  productQueryModel: context.read<ProductQueryViewModel>(),
                                                );

                                                if (suggestedProducts.isEmpty) {
                                                  return Center(
                                                    child: FusionAppText(
                                                      text: 'No suggested devices for current system.',
                                                      style: context.textTheme.bodySmall?.copyWith(
                                                        color: context.colorScheme.onSurface.withValues(alpha: 0.7),
                                                      ),
                                                    ),
                                                  );
                                                }

                                                return ListView.builder(
                                                  itemCount: suggestedProducts.length,
                                                  itemBuilder: (BuildContext context, int index) {
                                                    final ({EQLProduct product, int quantity}) suggestedProduct = suggestedProducts[index];
                                                    return _ProductTile(
                                                      index: index,
                                                      product: suggestedProduct.product,
                                                      suggestedQuantity: suggestedProduct.quantity,
                                                      addProduct: () {
                                                        final String? state2 = BlocProvider.of<EquipmentLocationSelectionViewmodel>(context).state;
                                                        if (state2 == null) {
                                                          FusionToast.error(
                                                            context,
                                                            message: "Please select an equipment location to add devices.",
                                                          );
                                                          return;
                                                        }
                                                        for (int i = 0; i < suggestedProduct.quantity; i++) {
                                                          vm.addProductToLocation(
                                                            equipLocationId: state2,
                                                            product: suggestedProduct.product,
                                                          );
                                                        }
                                                      },
                                                    );
                                                  },
                                                );
                                              },
                                            );
                                          }

                                          return switch (state.data) {
                                            EQLProductsLoading() => const Center(
                                              child: Padding(
                                                padding: EdgeInsets.all(16.0),
                                                child: CupertinoActivityIndicator(),
                                              ),
                                            ),
                                            EQLProductsError(:final String message) => Center(
                                              child: FusionAppText(
                                                text: 'Error: $message',
                                                style: context.textTheme.bodyMedium?.copyWith(
                                                  color: context.colorScheme.error,
                                                ),
                                              ),
                                            ),
                                            EQLProductsLoaded(
                                              :final List<EQLProduct> products,
                                            ) =>
                                              ListView.builder(
                                                itemCount: products.length,
                                                itemBuilder: (
                                                  BuildContext context,
                                                  int index,
                                                ) {
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
                                          };
                                        },
                                      ),
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
                        testId: SemanticHelper.createTestId(
                          SemanticTypes.container,
                          "right_dialog",
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: context.colorScheme.elevation2,
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
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium?.copyWith(
                                          color: context.colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                        onTap: () => Navigator.of(context).pop(),
                                        child: SemanticHelper.button(
                                          testId: SemanticHelper.createTestId(
                                            SemanticTypes.button,
                                            "equipment_location_dialog_close_button",
                                          ),
                                          child: const Padding(
                                            padding: EdgeInsets.all(2.0),
                                            child: Icon(
                                              LucideIcons.x200,
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Divider(
                                thickness: 0.5,
                                height: 0,
                                color: context.colorScheme.strokeDark,
                              ),
                              const SizedBox(height: 16),
                              BlocBuilder<_EqlDeviceListModeCubit, _EqlDeviceListMode>(
                                builder: (BuildContext context, _EqlDeviceListMode selectedMode) {
                                  return Center(
                                    child: Container(
                                      padding: const EdgeInsets.all(8.0),
                                      decoration: BoxDecoration(
                                        color: context.colorScheme.elevation1,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        spacing: 10,
                                        mainAxisSize: MainAxisSize.min,
                                        children:
                                            <(_EqlDeviceListMode mode, String label)>[
                                              (_EqlDeviceListMode.select, "Select"),
                                              (_EqlDeviceListMode.suggest, "Suggest"),
                                            ].map(((_EqlDeviceListMode, String) item) {
                                              final _EqlDeviceListMode mode = item.$1;
                                              final String label = item.$2;
                                              final bool isSelected = selectedMode == mode;

                                              return MouseRegion(
                                                cursor: SystemMouseCursors.click,
                                                child: GestureDetector(
                                                  onTap: () {
                                                    context.read<_EqlDeviceListModeCubit>().setMode(mode);
                                                  },
                                                  child: SemanticHelper.container(
                                                    testId: SemanticHelper.createTestId(
                                                      SemanticTypes.container,
                                                      "equipment_location_dialog_filter_option_$label",
                                                    ),
                                                    child: Container(
                                                      width: 89,
                                                      padding: const EdgeInsets.all(8),
                                                      decoration: BoxDecoration(
                                                        color: isSelected ? context.colorScheme.elevation3 : null,
                                                        borderRadius: BorderRadius.circular(
                                                          8,
                                                        ),
                                                      ),
                                                      child: Center(
                                                        child: FusionAppText(
                                                          text: label,
                                                          style: context.textTheme.bodySmall,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 24),

                              ///
                              ///
                              ///
                              ///
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0,
                                ),
                                child: _FilterOptions(
                                  equipmentLocationId: equipmentLocationId,
                                  currentFilter: currentFilter,
                                ),
                              ),
                              const SizedBox(height: 24),

                              Divider(
                                thickness: 0.5,
                                height: 0,
                                color: context.colorScheme.strokeDark,
                              ),

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
      ),
    );
  }
}

List<({EQLProduct product, int quantity})> _mapSuggestedProducts({
  required DeviceSuggestionResult result,
  required EQLProductsState state,
  required ProductQueryViewModel productQueryModel,
}) {
  final EQLDeviceType type = state.filters.deviceType;

  List<({EQLProduct product, int quantity})> products;
  if (type == EQLDeviceType.processor) {
    products =
        result.dsps.map((({dynamic product, int quantity}) item) {
          final dynamic dsp = item.product;
          return (
            product: EQLProduct(
              productId: dsp.productId,
              portData: dsp.numberOfInputsAndOutputs ?? ProductPortData(),
              name: dsp.modelName,
              image: productQueryModel.getDspImage(dsp.productId),
              modelFamily: dsp.modelFamily,
              data: dsp,
              searchingFields: '${dsp.modelName} ${dsp.modelFamily}',
              deviceType: EQLDeviceType.processor,
              price: productQueryModel.getPrice(dsp.productId),
              description: dsp.modelFamily,
              specifications: <String, String>{
                "Analog Inputs": dsp.numberOfInputsAndOutputs?.analog?.inputs.toString() ?? "0",
                "Analog Outputs": dsp.numberOfInputsAndOutputs?.analog?.outputs.toString() ?? "0",
                "FusionConnect Inputs": dsp.numberOfInputsAndOutputs?.fusionConnect?.maxInputs.toString() ?? "0",
                "FusionConnect Outputs": dsp.numberOfInputsAndOutputs?.fusionConnect?.maxOutputs.toString() ?? "0",
              },
            ),
            quantity: item.quantity,
          );
        }).toList();
  } else if (type == EQLDeviceType.amplifier) {
    products =
        result.amplifiers.map((({dynamic product, int quantity}) item) {
          final dynamic amp = item.product;
          return (
            product: EQLProduct(
              productId: amp.productId,
              name: amp.modelName,
              modelFamily: amp.modelFamily ?? '',
              image: productQueryModel.getAmplifierImage(amp.productId),
              description: amp.modelFamily,
              data: amp,
              searchingFields: '${amp.modelName} ${amp.modelFamily}',
              deviceType: EQLDeviceType.amplifier,
              portData: amp.numberOfInputsAndOutputs ?? ProductPortData(),
              price: productQueryModel.getPrice(amp.productId),
              specifications: <String, String>{
                "Analog input": amp.numberOfInputsAndOutputs?.analog?.inputs.toString() ?? "0",
                "Analog output": amp.numberOfInputsAndOutputs?.analog?.outputs.toString() ?? "0",
                "FusionConnect input": amp.numberOfInputsAndOutputs?.fusionConnect?.maxInputs.toString() ?? "0",
                "FusionConnect output": amp.numberOfInputsAndOutputs?.fusionConnect?.maxOutputs.toString() ?? "0",
              },
            ),
            quantity: item.quantity,
          );
        }).toList();
  } else {
    products = <({EQLProduct product, int quantity})>[];
  }

  final String searchQuery = state.filters.searchQuery?.trim().toLowerCase() ?? '';
  if (searchQuery.isNotEmpty) {
    products = products.where((({EQLProduct product, int quantity}) item) => item.product.searchingFields.toLowerCase().contains(searchQuery)).toList();
  }

  final EqlProductsSort? sort = state.sortBy;
  if (sort != null) {
    switch (sort) {
      case EqlProductsSort.priceLowToHigh:
        products.sort((({EQLProduct product, int quantity}) a, ({EQLProduct product, int quantity}) b) => a.product.price.compareTo(b.product.price));
        break;
      case EqlProductsSort.priceHighToLow:
        products.sort((({EQLProduct product, int quantity}) a, ({EQLProduct product, int quantity}) b) => b.product.price.compareTo(a.product.price));
        break;
      case EqlProductsSort.nameAToZ:
        products.sort((({EQLProduct product, int quantity}) a, ({EQLProduct product, int quantity}) b) => a.product.name.compareTo(b.product.name));
        break;
      case EqlProductsSort.nameZToA:
        products.sort((({EQLProduct product, int quantity}) a, ({EQLProduct product, int quantity}) b) => b.product.name.compareTo(a.product.name));
        break;
    }
  }

  return products;
}
