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

  /// Creates a default ProductAsset with placeholder images for a given product type
  factory ProductAsset.defaultFor(String productType) {
    // Different product types have different standard color variants
    switch (productType.toLowerCase()) {
      case 'speaker':
        return ProductAsset(assets: {
          'black': ['packages/fusion_lib/lib/assets/images/default_speaker_black.png'],
          'white': ['packages/fusion_lib/lib/assets/images/default_speaker_white.png']
        });
      case 'amplifier':
        return ProductAsset(assets: {
          '_flat': ['packages/fusion_lib/lib/assets/images/default_amplifier_image.png']
        });
      case 'controller':
        return ProductAsset(assets: {
          '_flat': ['packages/fusion_lib/lib/assets/images/default_controller_image.png']
        });
      case 'dsp':
        return ProductAsset(assets: {
          '_flat': ['packages/fusion_lib/lib/assets/images/default_dsp_image.png']
        });
      case 'io_endpoint':
        return ProductAsset(assets: {
          '_flat': ['packages/fusion_lib/lib/assets/images/default_io_endpoint_image.png']
        });
      case 'accessory':
        return ProductAsset(assets: {
          '_flat': ['packages/fusion_lib/lib/assets/images/default_accessory_image.png']
        });
      default:
        // For non-speaker products, store in a way that can be extracted as flat list
        return ProductAsset(assets: {
          '_flat': ['packages/fusion_lib/lib/assets/images/default_${productType.toLowerCase()}.png']
        });
    }
  }

  /// Creates from a list of asset maps (API format)
  factory ProductAsset.fromJsonList(List<dynamic>? jsonList, {String? productType}) {
    if (jsonList == null || jsonList.isEmpty) {
      if (productType != null) {
        return ProductAsset.defaultFor(productType);
      }
      return const ProductAsset(assets: {});
    }

    final Map<String, List<String>> allAssets = {};

    for (final assetMap in jsonList) {
      if (assetMap is Map<String, dynamic>) {
        for (final entry in assetMap.entries) {
          final key = entry.key;
          final value = entry.value;

          if (value is List) {
            // Filter out empty strings and convert to strings
            final filteredAssets = value
                .map((e) => e.toString().trim())
                .where((str) => str.isNotEmpty)
                .toList();
            
            // Only add the key if there are actual assets or if it's a speaker with standard colors
            if (filteredAssets.isNotEmpty) {
              allAssets[key] = filteredAssets;
            } else if (productType?.toLowerCase() == 'speaker' && 
                      (key == 'black' || key == 'white')) {
              // For speakers, add default images for standard colors even if empty
              final defaultSpeaker = ProductAsset.defaultFor('speaker');
              allAssets[key] = defaultSpeaker.assets[key] ?? [];
            }
          } else if (value == null) {
            // For speakers with standard colors, add defaults for null values
            if (productType?.toLowerCase() == 'speaker' && 
                (key == 'black' || key == 'white')) {
              final defaultSpeaker = ProductAsset.defaultFor('speaker');
              allAssets[key] = defaultSpeaker.assets[key] ?? [];
            }
          } else if (value is String && value.trim().isNotEmpty) {
            // Only add non-empty strings
            allAssets[key] = <String>[value.trim()];
          }
        }
      }
    }

    // Check if we ended up with any non-empty assets after processing
    final hasAnyNonEmptyAssets = allAssets.values
        .any((list) => list.isNotEmpty);
    if (!hasAnyNonEmptyAssets && productType != null) {
      return ProductAsset.defaultFor(productType);
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

  /// Returns a flat list of asset URLs for non-speaker products
  List<String> toAssetList() {
    // If this is a default asset with _flat key, return just the URLs
    if (assets.containsKey('_flat')) {
      return assets['_flat'] ?? [];
    }
    // Otherwise return all asset URLs flattened
    return allAssetUrls;
  }

  @override
  String toString() => 'ProductAsset(assets: $assets)';
}
