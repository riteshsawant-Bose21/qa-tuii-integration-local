import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/product_query/presentation/viewModel/product_query_view_model_state.dart';
import 'package:fusion_lib/fusion_utils/app_enums.dart';
import 'package:fusion_lib/models/product_query/product_query_model.dart';
import 'package:fusion_lib/service/product_search_service/product_search_service.dart';

import '../pages/product_query.dart';

class ProductQueryCubit extends Cubit<ProductQueryState> {
  ProductQueryCubit() : super(ProductQueryState.initial()) {
    state.searchController.addListener(_onSearchChanged);
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
      print("Mount type filter: $beforeMountFilter -> ${products.length} products");
    }

    /// Filter by venue type (only for speakers based on outdoorRated)
    if (state.selectedVenueTypes.isNotEmpty) {
      print("Filtering by venue types: ${state.selectedVenueTypes}");
      final int beforeVenueFilter = products.length;
      products =
          products.where((ProductQueryModel product) {
            // For speakers, filter based on outdoor rating
            if (product.type == ProductType.speaker) {
              if (product.outdoorRated == null) {
                print("Speaker ${product.name} has no outdoor rating data");
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

              print("Speaker ${product.name} outdoor rated: ${product.outdoorRated}, matches: $matches");
              return matches;
            }
            // For non-speakers, always include them
            return true;
          }).toList();
      print("Venue type filter: $beforeVenueFilter -> ${products.length} products");
    }

    /// Filter by coverage (only for speakers based on maxSpl)
    if (state.selectedCoverages.isNotEmpty) {
      print("Filtering by coverages: ${state.selectedCoverages}");
      final int beforeCoverageFilter = products.length;

      // Debug: Show all speakers and their maxSpl values
      final List<ProductQueryModel> currentSpeakers = products.where((p) => p.type == ProductType.speaker).toList();
      print("Current speakers before coverage filter:");
      for (final ProductQueryModel speaker in currentSpeakers) {
        print("  ${speaker.name}: maxSpl=${speaker.maxSpl}");
      }

      products =
          products.where((ProductQueryModel product) {
            // For speakers, filter based on maxSpl coverage levels
            if (product.type == ProductType.speaker) {
              if (product.maxSpl == null || product.maxSpl == 0.0) {
                print("Speaker ${product.name} has no valid maxSpl data (${product.maxSpl})");
                return false;
              }

              final String coverageLevel = _getCoverageLevelFromMaxSpl(product.maxSpl!);
              final bool matches = state.selectedCoverages.any((String selectedCoverage) => selectedCoverage.toLowerCase() == coverageLevel.toLowerCase());

              print("Speaker ${product.name} maxSpl: ${product.maxSpl}, coverage: $coverageLevel, selected: ${state.selectedCoverages}, matches: $matches");
              return matches;
            }
            // For non-speakers, always include them
            return true;
          }).toList();
      print("Coverage filter: $beforeCoverageFilter -> ${products.length} products");
    }

    /// Filter by impedance (only for speakers based on nominalOhms)
    if (state.selectedImpedances.isNotEmpty) {
      print("Filtering by impedances: ${state.selectedImpedances}");
      final int beforeImpedanceFilter = products.length;

      // Debug: Show all speakers and their nominalOhms values
      final List<ProductQueryModel> currentSpeakers = products.where((p) => p.type == ProductType.speaker).toList();
      print("Current speakers before impedance filter:");
      for (final ProductQueryModel speaker in currentSpeakers) {
        print("  ${speaker.name}: nominalOhms=${speaker.nominalOhms}");
      }

      products =
          products.where((ProductQueryModel product) {
            // For speakers, filter based on nominalOhms impedance levels
            if (product.type == ProductType.speaker) {
              if (product.nominalOhms == null || product.nominalOhms == 0.0) {
                print("Speaker ${product.name} has no valid nominalOhms data (${product.nominalOhms})");
                return false;
              }

              final String impedanceLevel = _getImpedanceLevelFromOhms(product.nominalOhms!);
              final bool matches = state.selectedImpedances.any((String selectedImpedance) => selectedImpedance.toLowerCase() == impedanceLevel.toLowerCase());

              print(
                "Speaker ${product.name} nominalOhms: ${product.nominalOhms}, impedance: $impedanceLevel, selected: ${state.selectedImpedances}, matches: $matches",
              );
              return matches;
            }
            // For non-speakers, always include them
            return true;
          }).toList();
      print("Impedance filter: $beforeImpedanceFilter -> ${products.length} products");
    }

    print("Filtered products count: ${products.length}");
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
    print("Sort option changed to: $option"); // Debug log
    emit(
      state.copyWith(
        selectedSortOption: option,
        filteredProducts: _performSearch(state.searchQuery),
      ),
    );
  }

  void onFiltersChanged() {
    // Sync selectedProductType with selectedProductTypes when filters change
    final ProductType? singleProductType = state.selectedProductTypes.length == 1 ? state.selectedProductTypes.first : null;

    emit(
      state.copyWith(
        selectedProductType: singleProductType,
        filteredProducts: _performSearch(state.searchQuery),
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
