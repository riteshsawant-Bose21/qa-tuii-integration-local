import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_utils/app_enums.dart';
import 'package:fusion_lib/models/product_query/product_query_model.dart';
import '../pages/product_query.dart';

class ProductQueryState {
  final TextEditingController searchController;
  final List<ProductQueryModel> filteredProducts;
  final String searchQuery;
  final ProductType? selectedProductType;
  final SortOption? selectedSortOption;

  final Set<ProductType> selectedProductTypes;
  final Set<String> selectedMountTypes;
  final Set<String> selectedVenueTypes;
  final Set<String> selectedColors;
  final Set<String> selectedCoverages;
  final Set<String> selectedImpedances;

  const ProductQueryState({
    required this.searchController,
    required this.filteredProducts,
    required this.searchQuery,
    required this.selectedProductType,
    required this.selectedSortOption,
    required this.selectedProductTypes,
    required this.selectedMountTypes,
    required this.selectedVenueTypes,
    required this.selectedColors,
    required this.selectedCoverages,
    required this.selectedImpedances,
  });

  /// Initial State
  factory ProductQueryState.initial() {
    return ProductQueryState(
      searchController: TextEditingController(),
      filteredProducts: ProductAPI.getAllProducts(),
      searchQuery: '',
      selectedProductType: null,
      selectedSortOption: null,
      selectedProductTypes: <ProductType>{},
      selectedMountTypes: <String>{},
      selectedVenueTypes: <String>{},
      selectedColors: <String>{},
      selectedCoverages: <String>{},
      selectedImpedances: <String>{},
    );
  }

  /// Copy state with modifications
  ProductQueryState copyWith({
    TextEditingController? searchController,
    List<ProductQueryModel>? filteredProducts,
    String? searchQuery,
    ProductType? selectedProductType,
    SortOption? selectedSortOption,
    Set<ProductType>? selectedProductTypes,
    Set<String>? selectedMountTypes,
    Set<String>? selectedVenueTypes,
    Set<String>? selectedColors,
    Set<String>? selectedCoverages,
    Set<String>? selectedImpedances,
  }) {
    return ProductQueryState(
      searchController: searchController ?? this.searchController,
      filteredProducts: filteredProducts ?? this.filteredProducts,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedProductType: selectedProductType ?? this.selectedProductType,
      selectedSortOption: selectedSortOption ?? this.selectedSortOption,
      selectedProductTypes: selectedProductTypes ?? this.selectedProductTypes,
      selectedMountTypes: selectedMountTypes ?? this.selectedMountTypes,
      selectedVenueTypes: selectedVenueTypes ?? this.selectedVenueTypes,
      selectedColors: selectedColors ?? this.selectedColors,
      selectedCoverages: selectedCoverages ?? this.selectedCoverages,
      selectedImpedances: selectedImpedances ?? this.selectedImpedances,
    );
  }
}
