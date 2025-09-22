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
    if (query.isEmpty) return products;

    final String lowerQuery = query.toLowerCase();
    final List<ProductWithScore> scoredProducts = <ProductWithScore>[];

    for (final ProductQueryModel product in products) {
      double score = 0.0;

      // Name matching (highest priority)
      final String lowerName = product.name.toLowerCase();
      if (lowerName.contains(lowerQuery)) {
        if (lowerName.startsWith(lowerQuery)) {
          score += 100.0; // Exact name prefix match
        } else {
          score += 50.0; // Name contains query
        }
      }

      // Series matching (high priority)
      if (product.series != null) {
        final String lowerSeries = product.series!.toLowerCase();
        if (lowerSeries.contains(lowerQuery)) {
          if (lowerSeries.startsWith(lowerQuery)) {
            score += 80.0; // Exact series prefix match
          } else {
            score += 40.0; // Series contains query
          }
        }
      }

      // Product type matching (medium priority)
      final String productTypeName = _getProductTypeSearchName(product.type).toLowerCase();
      if (productTypeName.contains(lowerQuery)) {
        if (productTypeName.startsWith(lowerQuery)) {
          score += 60.0; // Exact type prefix match
        } else {
          score += 30.0; // Type contains query
        }
      }

      // SKU matching (lower priority)
      final String lowerSku = product.sku.toLowerCase();
      if (lowerSku.contains(lowerQuery)) {
        if (lowerSku.startsWith(lowerQuery)) {
          score += 40.0; // Exact SKU prefix match
        } else {
          score += 20.0; // SKU contains query
        }
      }

      // Color matching (for speakers)
      if (product.color != null) {
        final String lowerColor = product.color!.toLowerCase();
        if (lowerColor.contains(lowerQuery)) {
          score += 25.0; // Color contains query
        }
      }

      // Mounting type matching (for speakers)
      if (product.mountingType != null) {
        final String lowerMountingType = product.mountingType!.toLowerCase();
        if (lowerMountingType.contains(lowerQuery)) {
          score += 15.0; // Mounting type contains query
        }
      }

      // Only include products with a score > 0
      if (score > 0) {
        scoredProducts.add(ProductWithScore(product, score));
      }
    }

    // Sort by score (descending) and return products
    scoredProducts.sort((ProductWithScore a, ProductWithScore b) => b.score.compareTo(a.score));
    return scoredProducts.map((ProductWithScore scored) => scored.product).toList();
  }

  /// Get searchable name for product type
  static String _getProductTypeSearchName(ProductType type) {
    switch (type) {
      case ProductType.speaker:
        return 'speaker';
      case ProductType.amplifier:
        return 'amplifier';
      case ProductType.controllers:
        return 'controller';
      case ProductType.endpoints:
        return 'endpoint';
      case ProductType.dsps:
        return 'dsp';
      case ProductType.sources:
        return 'source';
      case ProductType.racks:
        return 'rack';
    }
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
  final double score;

  ProductWithScore(this.product, this.score);
}
