import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

import '../../../projects/widget/product_search_widget.dart';
import '../viewModel/product_query_view_model_cubit.dart';
import '../viewModel/product_query_view_model_state.dart';

class ProductQueryView extends StatelessWidget {
  const ProductQueryView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProductQueryCubit>(
      create: (_) => ProductQueryCubit(),
      child: BlocBuilder<ProductQueryCubit, ProductQueryState>(
        builder: (BuildContext context, ProductQueryState state) {
          final ProductQueryCubit cubit = context.read<ProductQueryCubit>();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ProductSearchWidget(
                searchController: state.searchController,
                selectedProductType: state.selectedProductType,
                selectedSortOption: state.selectedSortOption,
                selectedProductTypes: state.selectedProductTypes,
                selectedMountTypes: state.selectedMountTypes,
                selectedVenueTypes: state.selectedVenueTypes,
                selectedColors: state.selectedColors,
                selectedCoverages: state.selectedCoverages,
                selectedImpedances: state.selectedImpedances,
                onClearSearch: cubit.clearSearch,
                // onProductTypeChanged: cubit.onProductTypeChanged,
                onSortOptionChanged: cubit.onSortOptionChanged,
                onFiltersChanged: cubit.onFiltersChanged,
              ),
              const SizedBox(height: 8),
              if (state.searchQuery.isNotEmpty) ...<Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: FusionAppText(
                    text: 'Found ${state.filteredProducts.length} results for "${state.searchQuery}"',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              state.filteredProducts.isEmpty
                  ? _buildEmptyState(context)
                  : ListView.separated(
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    shrinkWrap: true,
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: state.filteredProducts.length,
                    itemBuilder: (BuildContext context, int index) {
                      return ProductCard(
                        product: state.filteredProducts[index],
                        searchQuery: state.searchQuery,
                      );
                    },
                  ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: Column(
        children: <Widget>[
          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          FusionAppText(
            text: 'No products found',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          FusionAppText(
            text: 'Try adjusting your search terms or filters',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

/// Product card widget
/// Updated ProductCard with search term highlighting
class ProductCard extends StatelessWidget {
  final ProductQueryModel product;
  final String searchQuery;
  const ProductCard({
    super.key,
    required this.product,
    this.searchQuery = '',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          /// Product image
          FusionImage.asset(
            product.image.isNotEmpty ? product.image : _getDefaultImage(product.type),
            width: 58,
            height: 58,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                /// Product name with highlighting
                _buildHighlightedText(
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  text: product.name,
                  query: searchQuery,
                ),

                const SizedBox(height: 2),

                /// Product type and specifications
                FusionAppText(
                  text: _getProductTypeAndSpecs(product),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),

                /// Product price
                FusionCurrencyText(
                  text: product.price.toString(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.greyDark,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getDefaultImage(ProductType type) {
    switch (type) {
      case ProductType.speaker:
        return "assets/images/speakers/DM_pendant.png";
      case ProductType.amplifier:
        return "assets/images/amps/default_amp.png";
      case ProductType.device:
        return "assets/images/devices/default_device.png";
    }
  }

  String _getProductTypeAndSpecs(ProductQueryModel product) {
    switch (product.type) {
      case ProductType.speaker:
        return 'Speaker';
      case ProductType.amplifier:
        return 'Amplifier • ${product.specifications}';
      case ProductType.device:
        return 'Device • ${product.specifications}';
    }
  }

  /// Highlight search terms in product name
  Widget _buildHighlightedText({
    /// If style is null, default to bodyMedium
    required String text,

    /// The search query to highlight
    required String query,

    /// Text style for normal text
    required TextStyle style,
  }) {
    /// If query is empty, return normal text
    if (query.isEmpty) {
      return FusionAppText(text: text, style: style, maxLine: 1);
    }

    /// Case-insensitive search
    /// Convert both text and query to lower case for comparison
    /// Index of the first match
    final String lowerText = text.toLowerCase();
    final String lowerQuery = query.toLowerCase();
    final int index = lowerText.indexOf(lowerQuery);

    /// If query not found, return normal text
    if (index == -1) {
      return FusionAppText(text: text, style: style, maxLine: 1);
    }

    /// Highlight the matched part
    /// Using RichText to style the matched substring
    /// with background color and bold font weight
    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: style,
        children: <InlineSpan>[
          TextSpan(text: text.substring(0, index)),
          TextSpan(
            text: text.substring(index, index + query.length),
            style: style.copyWith(
              backgroundColor: Colors.yellow.withAlpha(100),
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(text: text.substring(index + query.length)),
        ],
      ),
    );
  }
}

/// Product service to manage different product types
class ProductAPI {
  /// Get all products from all sources
  static List<ProductQueryModel> getAllProducts() {
    return <ProductQueryModel>[
      ...getSpeakerProducts(),
      ...getAmplifierProducts(),
      ...getDeviceProducts(),
    ];
  }

  /// Get products by type
  static List<ProductQueryModel> getProductsByType(ProductType type) {
    switch (type) {
      case ProductType.speaker:
        return getSpeakerProducts();
      case ProductType.amplifier:
        return getAmplifierProducts();
      case ProductType.device:
        return getDeviceProducts();
    }
  }

  /// Convert speaker models to products using fusion_lib
  static List<ProductQueryModel> getSpeakerProducts() {
    try {
      final String speakersJson = fusionDevices.getSpeakers();
      final List<dynamic> speakersData = jsonDecode(speakersJson);
      // print("Speakers Data: $speakersData");
      return speakersData.map((dynamic speakerData) {
        return ProductQueryModel(
          name: speakerData['model'] ?? '',
          price: (speakerData['price'] ?? 0.0).toDouble(),
          image: speakerData['imageUrl'] ?? '',
          type: ProductType.speaker,
          specifications: '${speakerData['maxSpl']} dB SPL • ${speakerData['mountingType']}',
        );
      }).toList();
    } catch (e) {
      return <ProductQueryModel>[];
    }
  }

  /// Convert amplifier models to products using fusion_lib
  static List<ProductQueryModel> getAmplifierProducts() {
    try {
      final String amplifiersJson = fusionDevices.getAmplifiers();
      final List<dynamic> amplifiersData = jsonDecode(amplifiersJson);
      print("Amplifiers Data: $amplifiersData");

      return amplifiersData.map((dynamic ampData) {
        return ProductQueryModel(
          name: ampData['name'] ?? '',
          price: 0.0, // Add price if available in fusion_lib amp model
          image: ampData['image_url'] ?? '', // Add image if available in fusion_lib amp model
          type: ProductType.amplifier,
          specifications: '${ampData['channels']}ch • ${(ampData['peakPerChannel'] ?? 0).toInt()}W per ch',
        );
      }).toList();
    } catch (e) {
      return <ProductQueryModel>[];
    }
  }

  /// Convert device specs to products using fusion_lib
  static List<ProductQueryModel> getDeviceProducts() {
    try {
      final String devicesJson = fusionDevices.getDevices();
      final List<dynamic> devicesData = jsonDecode(devicesJson);
      // print("Devices Data: $devicesData");

      return devicesData.map((dynamic deviceData) {
        print("deviceData['imageUrl'] == > ${deviceData['imageUrl']}");
        return ProductQueryModel(
          name: deviceData['name'] ?? '',
          price: 0.0, // Add price if available in fusion_lib device model
          image: deviceData['image_url'] ?? '', // Add image if available in fusion_lib device model
          type: ProductType.device,
          specifications: '${deviceData['analogInputs']}in • ${deviceData['analogOutputs']}out • ${deviceData['networkIO']} network I/O',
        );
      }).toList();
    } catch (e) {
      return <ProductQueryModel>[];
    }
  }
}
