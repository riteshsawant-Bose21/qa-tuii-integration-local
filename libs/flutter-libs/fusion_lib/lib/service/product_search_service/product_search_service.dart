import 'package:fusion_lib/models/product_query/product_query_model.dart';

import '../../fusion_utils/app_enums.dart';

/// Product search service with various search functionalities
class ProductSearchService {
  /// Search products by name (case-insensitive)
  static List<ProductQueryModel> searchProducts(List<ProductQueryModel> products, String query) {
    if (query.isEmpty) {
      return products;
    }

    final String searchQuery = query.toLowerCase().trim();

    return products.where((ProductQueryModel product) {
      return product.name.toLowerCase().contains(searchQuery) || product.specifications.toLowerCase().contains(searchQuery);
    }).toList();
  }

  /// Advanced search - search by name with multiple keywords
  static List<ProductQueryModel> searchProductsAdvanced(List<ProductQueryModel> products, String query) {
    if (query.isEmpty) {
      return products;
    }

    final List<String> keywords = query.toLowerCase().trim().split(' ');

    return products.where((ProductQueryModel product) {
      final String searchText = '${product.name} ${product.specifications}'.toLowerCase();

      /// Check if all keywords exist in the product name or specifications
      return keywords.every((String keyword) => searchText.contains(keyword));
    }).toList();
  }

  /// Search with relevance scoring (returns results sorted by relevance)
  static List<ProductQueryModel> searchProductsWithRelevance(List<ProductQueryModel> products, String query) {
    if (query.isEmpty) {
      return products;
    }

    final String searchQuery = query.toLowerCase().trim();
    final List<ProductWithScore> scoredProducts = <ProductWithScore>[];

    for (final ProductQueryModel product in products) {
      final String productName = product.name.toLowerCase();
      final String productSpecs = product.specifications.toLowerCase();
      final String combinedText = '$productName $productSpecs';
      int score = 0;

      /// Exact match in name gets highest score
      if (productName == searchQuery) {
        score = 100;
      }
      /// Starts with query gets high score
      else if (productName.startsWith(searchQuery)) {
        score = 80;
      }
      /// Contains query in name gets medium score
      else if (productName.contains(searchQuery)) {
        score = 60;

        /// Bonus points for word boundary matches
        final RegExp wordBoundary = RegExp(r'\b' + RegExp.escape(searchQuery) + r'\b');
        if (wordBoundary.hasMatch(productName)) {
          score += 20;
        }
      }
      /// Contains query in specifications gets lower score
      else if (productSpecs.contains(searchQuery)) {
        score = 40;
      }
      /// Contains query in combined text gets lowest score
      else if (combinedText.contains(searchQuery)) {
        score = 20;
      }

      if (score > 0) {
        scoredProducts.add(ProductWithScore(product, score));
      }
    }

    /// Sort by score (highest first)
    scoredProducts.sort((ProductWithScore a, ProductWithScore b) => b.score.compareTo(a.score));

    return scoredProducts.map((ProductWithScore item) => item.product).toList();
  }

  /// Filter products by type
  static List<ProductQueryModel> filterByType(List<ProductQueryModel> products, ProductType type) {
    return products.where((ProductQueryModel product) => product.type == type).toList();
  }

  /// Combined search and filter
  static List<ProductQueryModel> searchAndFilter(List<ProductQueryModel> products, String searchQuery, ProductType? filterType) {
    List<ProductQueryModel> result = products;

    /// Apply type filter
    if (filterType != null) {
      result = filterByType(result, filterType);
    }

    /// Apply search filter
    if (searchQuery.isNotEmpty) {
      result = searchProducts(result, searchQuery);
    }

    return result;
  }
}

/// Helper class for relevance scoring
class ProductWithScore {
  final ProductQueryModel product;
  final int score;

  ProductWithScore(this.product, this.score);
}
