// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/hardware/product_viewmodel.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/projects/models/eql_product.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/product_data/models/amplifier_product.dart';
import 'package:fusion_lib/product_data/models/dsp_product.dart';
import 'package:fusion_lib/product_data/models/io_endpoint_product.dart';
import 'package:fusion_lib/product_data/models/product_port_data.dart';

import '../widget/building/speaker_selection_section/view_model/product_query_view_model.dart';

class EqlProductsVm extends Cubit<EQLProductsState> {
  final ProjectViewModel projectViewModel;
  EqlProductsVm(this.projectViewModel, this.datasource, {EQLDeviceType? initialFilter})
    : super(
        EQLProductsState(
          filters: EQLProductFilters(
            deviceType: initialFilter ?? EQLDeviceType.processor,
            spareCapacity: SpareCapacity.capacity1,
            monitoringType: MonitoringType.none,
          ),
          data: EQLProductsLoading(),
        ),
      ) {
    loadProducts();
  }
  bool _isInitialized = false;
  Future<void> _initialize() async {
    _isInitialized = true;
    for (final AmplifierProduct element in datasource.amplifiers) {
      final String key = element.assets.assets.keys.firstOrNull ?? '';
      allProducts.add(
        EQLProduct(
          name: element.modelName,
          modelFamily: element.modelFamily ?? '',
          assetPath: datasource.getImagePath(element.assets.assets[key]?.firstOrNull ?? ''),
          description: element.description,
          data: element,
          searchingFields: '${element.modelName} ${element.description}',
          deviceType: EQLDeviceType.amplifier,
          portData: element.numberOfInputsAndOutputs ?? ProductPortData(),
          price: datasource.getPrice(element.productId),
          specifications: <String, String>{
            "Power ": element.power?.at.map((AmplifierMeasurementValue e) => "${e.value} ${e.unit}").join(", ") ?? "",
            "No.Of Loudspeaker Input": element.numberOfLoudspeakerInputs.toString(),
            "Analog input": element.numberOfInputsAndOutputs?.analog?.inputs.toString() ?? "0",
            "Analog output": element.numberOfInputsAndOutputs?.analog?.outputs.toString() ?? "0",
            "FusionConnect input": element.numberOfInputsAndOutputs?.fusionConnect?.maxInputs.toString() ?? "0",
            "FusionConnect output": element.numberOfInputsAndOutputs?.fusionConnect?.maxOutputs.toString() ?? "0",
          },
        ),
      );
    }
    for (final IoEndpointProduct element in datasource.ioEndpoints) {
      final String key = element.assets.assets.keys.firstOrNull ?? '';
      allProducts.add(
        EQLProduct(
          name: element.modelName,
          modelFamily: element.modelFamily ?? '',
          assetPath: datasource.getImagePath(element.assets.assets[key]?.firstOrNull ?? ''),
          data: element,
          //TODO: Check Endpoint Port Data
          portData: element.numberOfInputsAndOutputs,
          searchingFields: '${element.modelName} ${element.description}',
          deviceType: EQLDeviceType.endpoint,
          description: element.shortDescription ?? element.description,
          price: datasource.getPrice(element.productId),
          specifications: <String, String>{
            // "Input Type": element.inputs?.type ?? "-",
            // "no.Of inputs": element.inputs?.quantity.toString() ?? "-",
            // "Output Type": element.outputs?.type ?? "-",
            // "no.Of outputs": element.outputs?.quantity.toString() ?? "-",
            "Network": element.network ? "Yes" : "No",
          },
        ),
      );
    }
    for (final DspProduct element in datasource.dsps) {
      final String key = element.assets.assets.keys.firstOrNull ?? '';

      allProducts.add(
        EQLProduct(
          portData: element.numberOfInputsAndOutputs ?? ProductPortData(),
          name: element.modelName,
          assetPath: datasource.getImagePath(element.assets.assets[key]?.firstOrNull ?? ''),
          modelFamily: element.modelFamily,
          data: element,
          searchingFields: '${element.modelName} ${element.description}',
          deviceType: EQLDeviceType.processor,
          price: datasource.getPrice(element.productId),
          description: element.shortDescription ?? element.description,
          specifications: <String, String>{
            "Max Analog Control": element.maxNumberOfAnalogControl.toString() ?? "0",
            "Max Digital Control": element.maxNumberOfDigitalControl.toString() ?? "0",
            "GPIO Logic Ports":
                element.gpioLogicPorts != null ? "${element.gpioLogicPorts!.inputs} in / ${element.gpioLogicPorts!.outputs} out" : "0 in / 0 out",
            "Analog Inputs": element.numberOfInputsAndOutputs?.analog?.inputs.toString() ?? "0",
            "Analog Outputs": element.numberOfInputsAndOutputs?.analog?.outputs.toString() ?? "0",
            "FusionConnect Inputs": element.numberOfInputsAndOutputs?.fusionConnect?.maxInputs.toString() ?? "0",
            "FusionConnect Outputs": element.numberOfInputsAndOutputs?.fusionConnect?.maxOutputs.toString() ?? "0",
          },
        ),
      );
    }
    loadProducts();
  }

  final ProductQueryViewModel datasource;
  final List<EQLProduct> allProducts = <EQLProduct>[];
  void loadProducts() {
    if (!_isInitialized) {
      _initialize();
      return;
    }

    final EQLProductFilters filters = state.filters;
    final EqlProductsSort? sort = state.sortBy;
    final List<EQLProduct> filteredProducts =
        allProducts
            .where((EQLProduct product) {
              if (product.deviceType != filters.deviceType) {
                return false;
              }
              return true;
            })
            .where((EQLProduct e) => e.searchingFields.toLowerCase().contains(filters.searchQuery?.toLowerCase() ?? ''))
            .toList();

    if (sort != null) {
      switch (sort) {
        case EqlProductsSort.priceLowToHigh:
          filteredProducts.sort((EQLProduct a, EQLProduct b) => a.price.compareTo(b.price));
          break;
        case EqlProductsSort.priceHighToLow:
          filteredProducts.sort((EQLProduct a, EQLProduct b) => b.price.compareTo(a.price));
          break;
        case EqlProductsSort.nameAToZ:
          filteredProducts.sort((EQLProduct a, EQLProduct b) => a.name.compareTo(b.name));
          break;
        case EqlProductsSort.nameZToA:
          filteredProducts.sort((EQLProduct a, EQLProduct b) => b.name.compareTo(a.name));
          break;
      }
    }
    emit(
      EQLProductsState(
        filters: filters,
        sortBy: sort,
        data: EQLProductsLoaded(products: filteredProducts),
      ),
    );
  }

  void updateSort(EqlProductsSort? newSort) {
    emit(
      EQLProductsState(
        filters: state.filters,
        data: state.data,
        sortBy: newSort,
      ),
    );
    loadProducts();
  }

  void updateFilters(EQLProductFilters newFilters) {
    emit(
      EQLProductsState(
        filters: newFilters,
        data: state.data,
      ),
    );
    loadProducts();
  }

  void addProductToLocation({required String equipLocationId, required EQLProduct product}) {
    final HardwareComponent hardware = projectViewModel.assignPortData(
      hardware: _createHardwareFor(product),
      type: _getProductType(product.deviceType),
      portData: product.portData,
      modelFamily: product.modelFamily,
    );

    projectViewModel.addHardware(hardware: hardware);
    projectViewModel.addHardwareToEquipLocation(
      equipLocationId: equipLocationId,
      hardwareId: hardware.id,
    );
  }

  HardwareComponent _createHardwareFor(EQLProduct product) {
    final HardwareComponent hardware = projectViewModel.fromProductQueryModel(
      _createPQMFor(product),
      locationEntity: LocationModel(),
      isFromBuildingPage: true,
    );
    return hardware;
  }

  ProductQueryModel _createPQMFor(EQLProduct product) {
    return ProductQueryModel(
      name: product.name,
      price: product.price,
      image: product.assetPath ?? '',
      type: switch (product.deviceType) {
        EQLDeviceType.amplifier => ProductType.amplifier,
        EQLDeviceType.endpoint => ProductType.endpoints,
        EQLDeviceType.processor => ProductType.dsps,
        // EQLDeviceType.mixerAmp => ProductType.amplifier,
      },
      sku: product.name,
      // sku: switch (product.data) {
      //   final AmplifierProduct a => a.skus.isNotEmpty ? a.skus.first.toString() : 'UNKNOWN',
      //   final IoEndpointProduct i => i.skus.isNotEmpty ? i.skus.first.toString() : 'UNKNOWN',
      //   final DspProduct d => d.skus.isNotEmpty ? d.skus.first.toString() : 'UNKNOWN',
      //   _ => 'UNKNOWN',
      // },
    );
  }

  ProductType _getProductType(EQLDeviceType deviceType) {
    switch (deviceType) {
      case EQLDeviceType.amplifier:
        return ProductType.amplifier;
      case EQLDeviceType.endpoint:
        return ProductType.endpoints;
      case EQLDeviceType.processor:
        return ProductType.dsps;
      // case EQLDeviceType.mixerAmp:
      //   return ProductType.amplifier;
    }
  }

  Future<void> refresh() async {
    emit(
      EQLProductsState(
        filters: state.filters,
        data: EQLProductsLoading(),
        sortBy: state.sortBy,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 500));
    loadProducts();
  }
}

enum EqlProductsSort {
  nameAToZ("Name: A to Z"),
  nameZToA("Name: Z to A"),
  priceLowToHigh("Price: Low to High"),
  priceHighToLow("Price: High to Low");

  const EqlProductsSort(this.label);
  final String label;
}

enum EQLDeviceType {
  processor("Processor"),
  amplifier("Amplifier"),
  // mixerAmp("Mixer-Amp"),
  endpoint("Endpoint");

  const EQLDeviceType(this.displayName);
  final String displayName;
}

enum SpareCapacity {
  capacity1("Capacity 1"),
  capacity2("Capacity 2");

  const SpareCapacity(this.displayName);
  final String displayName;
}

enum MonitoringType {
  none("None"),
  local("Local"),
  cloud("Cloud");

  const MonitoringType(this.displayName);
  final String displayName;
}

class EQLProductFilters {
  EQLProductFilters({required this.deviceType, required this.spareCapacity, required this.monitoringType, this.searchQuery});
  final EQLDeviceType deviceType;
  final SpareCapacity spareCapacity;
  final MonitoringType monitoringType;
  final String? searchQuery;

  EQLProductFilters copyWith({
    EQLDeviceType? deviceType,
    SpareCapacity? spareCapacity,
    MonitoringType? monitoringType,
    String? searchQuery,
  }) {
    return EQLProductFilters(
      deviceType: deviceType ?? this.deviceType,
      spareCapacity: spareCapacity ?? this.spareCapacity,
      monitoringType: monitoringType ?? this.monitoringType,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class EQLProductsState {
  final EQLProductFilters filters;
  final EQLProductDataState data;
  final EqlProductsSort? sortBy;
  EQLProductsState({
    required this.filters,
    required this.data,
    this.sortBy,
  });
}

abstract class EQLProductDataState {}

class EQLProductsLoading extends EQLProductDataState {}

class EQLProductsLoaded extends EQLProductDataState {
  final List<EQLProduct> products;
  EQLProductsLoaded({required this.products});
}

class EQLProductsError extends EQLProductDataState {
  final String message;
  EQLProductsError({required this.message});
}
