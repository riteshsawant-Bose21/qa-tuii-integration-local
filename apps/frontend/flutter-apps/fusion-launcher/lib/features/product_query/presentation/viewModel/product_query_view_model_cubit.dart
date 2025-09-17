import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/product_query/presentation/viewModel/product_query_view_model_state.dart';
import 'package:fusion_lib/fusion_utils/app_enums.dart';
import 'package:fusion_lib/models/product_query/product_query_model.dart';
import 'package:fusion_lib/service/product_search_service/product_search_service.dart';

import '../pages/product_query.dart';

class ProductQueryCubit extends Cubit<ProductQueryState> {
  ProductQueryCubit() : super(ProductQueryState.initial()) {
    state.searchController.addListener(_onSearchChanged);
    // Apply initial sort to the products on startup
    _applyInitialSort();
  }

  /// Apply initial sort when cubit is created
  void _applyInitialSort() {
    emit(
      state.copyWith(
        filteredProducts: _performSearch(state.searchQuery),
      ),
    );
  }

  @override
  Future<void> close() {
    state.searchController.removeListener(_onSearchChanged);
    state.searchController.dispose();
    return super.close();
  }

  /// Listener for search input changes
  void _onSearchChanged() {
    final String query = state.searchController.text;

    emit(
      state.copyWith(
        searchQuery: query,
        filteredProducts: _performSearch(query),
      ),
    );
  }

  /// Perform search and return sorted results
  List<ProductQueryModel> _performSearch(String query) {
    final List<ProductQueryModel> searchBase = _getFilteredProducts();

    if (query.isEmpty) {
      return _sortProducts(searchBase);
    }

    final List<ProductQueryModel> searchResults = ProductSearchService.searchProductsWithRelevance(searchBase, query);
    return _sortProducts(searchResults);
  }

  /// Apply all selected filters to the product list
  List<ProductQueryModel> _getFilteredProducts() {
    // If no filters are applied, return all products
    if (state.selectedProductTypes.isEmpty &&
        state.selectedMountTypes.isEmpty &&
        state.selectedVenueTypes.isEmpty &&
        state.selectedColors.isEmpty &&
        state.selectedCoverages.isEmpty &&
        state.selectedImpedances.isEmpty &&
        state.selectedProductType == null) {
      return ProductAPI.getAllProducts();
    }

    /// Start with all products
    List<ProductQueryModel> products = ProductAPI.getAllProducts();

    /// Debug: Print all speaker data
    final List<ProductQueryModel> speakers = products.where((ProductQueryModel p) => p.type == ProductType.speaker).toList();

    /// Filter by multiple product types from filter dropdown (priority)
    if (state.selectedProductTypes.isNotEmpty) {
      products = products.where((ProductQueryModel product) => state.selectedProductTypes.contains(product.type)).toList();
    }
    /// Filter by single product type from main dropdown (fallback)
    else if (state.selectedProductType != null) {
      products = products.where((ProductQueryModel product) => product.type == state.selectedProductType).toList();
    }

    /// Filter by color (only for speakers)
    if (state.selectedColors.isNotEmpty) {
      final int beforeColorFilter = products.length;
      products =
          products.where((ProductQueryModel product) {
            // For speakers, only include if they have a matching color (case insensitive)
            if (product.type == ProductType.speaker) {
              if (product.color == null) {
                return false;
              }
              final bool matches = state.selectedColors.any((String selectedColor) => selectedColor.toLowerCase() == product.color!.toLowerCase());
              return matches;
            }
            // For non-speakers, always include them
            return true;
          }).toList();
    }

    /// Filter by mount type (only for speakers)
    if (state.selectedMountTypes.isNotEmpty) {
      final int beforeMountFilter = products.length;
      products =
          products.where((ProductQueryModel product) {
            // For speakers, only include if they have a matching mounting type (case insensitive)
            if (product.type == ProductType.speaker) {
              if (product.mountingType == null) {
                return false;
              }
              final bool matches = state.selectedMountTypes.any((String selectedMount) => selectedMount.toLowerCase() == product.mountingType!.toLowerCase());
              return matches;
            }
            // For non-speakers, always include them
            return true;
          }).toList();
    }

    /// Filter by venue type (only for speakers based on outdoorRated)
    if (state.selectedVenueTypes.isNotEmpty) {
      final int beforeVenueFilter = products.length;
      products =
          products.where((ProductQueryModel product) {
            // For speakers, filter based on outdoor rating
            if (product.type == ProductType.speaker) {
              if (product.outdoorRated == null) {
                return false;
              }

              final bool matches = state.selectedVenueTypes.any((String selectedVenue) {
                if (selectedVenue == 'Indoor') {
                  // Indoor only matches products that are NOT outdoor rated (false)
                  return product.outdoorRated == false;
                } else if (selectedVenue == 'Indoor + Outdoor') {
                  // Indoor + Outdoor matches products that ARE outdoor rated (true)
                  return product.outdoorRated == true;
                }
                return false;
              });

              return matches;
            }
            // For non-speakers, always include them
            return true;
          }).toList();
    }

    /// Filter by coverage (only for speakers based on maxSpl)
    if (state.selectedCoverages.isNotEmpty) {
      final int beforeCoverageFilter = products.length;

      // Debug: Show all speakers and their maxSpl values
      final List<ProductQueryModel> currentSpeakers = products.where((ProductQueryModel p) => p.type == ProductType.speaker).toList();
      for (final ProductQueryModel speaker in currentSpeakers) {}

      products =
          products.where((ProductQueryModel product) {
            // For speakers, filter based on maxSpl coverage levels
            if (product.type == ProductType.speaker) {
              if (product.maxSpl == null || product.maxSpl == 0.0) {
                return false;
              }

              final String coverageLevel = _getCoverageLevelFromMaxSpl(product.maxSpl!);
              final bool matches = state.selectedCoverages.any((String selectedCoverage) => selectedCoverage.toLowerCase() == coverageLevel.toLowerCase());

              return matches;
            }
            // For non-speakers, always include them
            return true;
          }).toList();
    }

    /// Filter by impedance (only for speakers based on nominalOhms)
    if (state.selectedImpedances.isNotEmpty) {
      final int beforeImpedanceFilter = products.length;

      // Debug: Show all speakers and their nominalOhms values
      final List<ProductQueryModel> currentSpeakers = products.where((ProductQueryModel p) => p.type == ProductType.speaker).toList();
      for (final ProductQueryModel speaker in currentSpeakers) {}

      products =
          products.where((ProductQueryModel product) {
            // For speakers, filter based on nominalOhms impedance levels
            if (product.type == ProductType.speaker) {
              if (product.nominalOhms == null || product.nominalOhms == 0.0) {
                return false;
              }

              final String impedanceLevel = _getImpedanceLevelFromOhms(product.nominalOhms!);
              final bool matches = state.selectedImpedances.any((String selectedImpedance) => selectedImpedance.toLowerCase() == impedanceLevel.toLowerCase());

              return matches;
            }
            // For non-speakers, always include them
            return true;
          }).toList();
    }

    return products;
  }

  /// Get coverage level from maxSpl value
  String _getCoverageLevelFromMaxSpl(double maxSpl) {
    if (maxSpl < 100) return 'Low';
    if (maxSpl < 110) return 'Mid';
    return 'High';
  }

  /// Get impedance level from nominalOhms value
  String _getImpedanceLevelFromOhms(double ohms) {
    return ohms <= 4 ? 'Low' : 'High';
  }

  /// Sort products based on selected sort option
  List<ProductQueryModel> _sortProducts(List<ProductQueryModel> products) {
    /// If no sort option is selected, return products as-is
    if (state.selectedSortOption == null) {
      return products;
    }

    final List<ProductQueryModel> sortedProducts = List<ProductQueryModel>.from(products);

    switch (state.selectedSortOption!) {
      case SortOption.priceHighToLow:
        sortedProducts.sort((ProductQueryModel a, ProductQueryModel b) => b.price.compareTo(a.price));
        break;
      case SortOption.priceLowToHigh:
        sortedProducts.sort((ProductQueryModel a, ProductQueryModel b) => a.price.compareTo(b.price));
        break;
      case SortOption.nameAToZ:
        sortedProducts.sort((ProductQueryModel a, ProductQueryModel b) => a.name.compareTo(b.name));
        break;
      case SortOption.nameZToA:
        sortedProducts.sort((ProductQueryModel a, ProductQueryModel b) => b.name.compareTo(a.name));
        break;
    }

    return sortedProducts;
  }

  void onProductTypeChanged(ProductType? type) {
    emit(
      state.copyWith(
        selectedProductType: type,
        selectedProductTypes: type != null ? <ProductType>{type} : <ProductType>{},
        filteredProducts: type != null ? ProductAPI.getProductsByType(type) : ProductAPI.getAllProducts(),
      ),
    );
  }

  void onSortOptionChanged(SortOption? option) {
    // First emit the new state with the updated sort option
    emit(
      state.copyWith(
        selectedSortOption: option,
      ),
    );

    // Then create sorted products using the updated state
    final List<ProductQueryModel> newFilteredProducts = _performSearch(state.searchQuery);

    // Emit the final state with sorted products
    emit(
      state.copyWith(
        selectedSortOption: option,
        filteredProducts: newFilteredProducts,
      ),
    );
  }

  void onFiltersChanged() {
    // Sync selectedProductType with selectedProductTypes when filters change
    final ProductType? singleProductType = state.selectedProductTypes.length == 1 ? state.selectedProductTypes.first : null;

    // If no filters are selected, show all products
    final List<ProductQueryModel> newFilteredProducts =
        state.selectedProductTypes.isEmpty &&
                state.selectedMountTypes.isEmpty &&
                state.selectedVenueTypes.isEmpty &&
                state.selectedColors.isEmpty &&
                state.selectedCoverages.isEmpty &&
                state.selectedImpedances.isEmpty
            ? ProductAPI.getAllProducts()
            : _performSearch(state.searchQuery);

    emit(
      state.copyWith(
        selectedProductType: singleProductType,
        filteredProducts: newFilteredProducts,
      ),
    );
  }

  void clearSearch() {
    state.searchController.clear();
    emit(
      state.copyWith(
        searchQuery: '',
        filteredProducts: _getFilteredProducts(),
      ),
    );
  }
}
