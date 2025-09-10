import 'package:fusion_lib/service/product_search_service/product_search_service.dart';

import '../../fusion_utils/app_enums.dart';
import 'package:fusion_lib/models/product_query/product_query_model.dart';

extension ProductListExtensions on List<ProductQueryModel> {
  /// Search products by name
  List<ProductQueryModel> search(String query) {
    return ProductSearchService.searchProducts(this, query);
  }

  /// Advanced search with multiple keywords
  List<ProductQueryModel> searchAdvanced(String query) {
    return ProductSearchService.searchProductsAdvanced(this, query);
  }

  /// Search with relevance scoring
  List<ProductQueryModel> searchWithRelevance(String query) {
    return ProductSearchService.searchProductsWithRelevance(this, query);
  }

  /// Filter by type
  List<ProductQueryModel> filterByType(ProductType type) {
    return ProductSearchService.filterByType(this, type);
  }
}
