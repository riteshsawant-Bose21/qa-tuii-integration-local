/// Product asset model for storing image/file references
///
/// Assets are organized by color variants or category keys,
/// each containing a list of asset URLs/filenames.
library;

class ProductAsset {
  /// Map of asset category to list of asset URLs
  /// e.g., {"black": ["front.jpg", "rear.jpg"], "white": ["front.jpg"]}
  final Map<String, List<String>> assets;

  const ProductAsset({
    required this.assets,
  });

  /// Creates from a list of asset maps (API format)
  factory ProductAsset.fromJsonList(List<dynamic>? jsonList) {
    if (jsonList == null || jsonList.isEmpty) {
      return const ProductAsset(assets: {});
    }

    final Map<String, List<String>> allAssets = {};

    for (final assetMap in jsonList) {
      if (assetMap is Map<String, dynamic>) {
        for (final entry in assetMap.entries) {
          final key = entry.key;
          final value = entry.value;

          if (value is List) {
            allAssets[key] = value.map((e) => e.toString()).toList();
          } else if (value == null) {
            // Preserve the color/category key even if there are no assets
            allAssets[key] = <String>[];
          } else if (value is String) {
            // Be defensive: sometimes APIs may send a single string
            allAssets[key] = <String>[value];
          }
        }
      }
    }

    return ProductAsset(assets: allAssets);
  }

  /// Get all asset URLs flattened into a single list
  List<String> get allAssetUrls {
    return assets.values.expand((urls) => urls).toList();
  }

  /// Get assets for a specific category (e.g., "black", "white")
  List<String> getAssetsFor(String category) {
    return assets[category] ?? [];
  }

  /// Get the first available asset URL, or null if none
  String? get firstAssetUrl {
    for (final urls in assets.values) {
      if (urls.isNotEmpty) return urls.first;
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
    'assets': assets,
  };

  @override
  String toString() => 'ProductAsset(assets: $assets)';
}
