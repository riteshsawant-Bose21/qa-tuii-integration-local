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
    print(
      "all states: ${state.selectedProductType}, ${state.selectedProductTypes}, ${state.selectedMountTypes}, ${state.selectedVenueTypes}, ${state.selectedColors}, ${state.selectedCoverages}, ${state.selectedImpedances}",
    );

    /// Start with all products
    List<ProductQueryModel> products = ProductAPI.getAllProducts();

    /// Filter by product type
    if (state.selectedProductType != null) {
      products = products.where((ProductQueryModel product) => product.type == state.selectedProductType).toList();
    }

    /// Filter by multiple product types
    if (state.selectedProductTypes.isNotEmpty) {
      products = products.where((ProductQueryModel product) => state.selectedProductTypes.contains(product.type)).toList();
    }

    /// Filter by other attributes (mount types, venue types, colors, coverages, impedances)
    if (state.selectedMountTypes.isNotEmpty ||
        state.selectedVenueTypes.isNotEmpty ||
        state.selectedCoverages.isNotEmpty ||
        state.selectedImpedances.isNotEmpty) {
      products =
          products.where((ProductQueryModel product) {
            if (product.type != ProductType.speaker) return true;
            return true;
          }).toList();
    }

    /// Example placeholder for color filtering
    if (state.selectedColors.isNotEmpty) {
      // code for filtering by colors if applicable
    }

    return products;
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
    emit(
      state.copyWith(
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
