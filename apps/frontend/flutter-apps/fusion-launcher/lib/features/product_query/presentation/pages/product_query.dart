import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

import '../../../../core/service_locator.dart';
import '../../../configuration/presentation/viewmodel/project_view_model.dart';
import '../../../projects/widget/product_search_widget.dart';
import '../viewModel/product_query_view_model_cubit.dart';
import '../viewModel/product_query_view_model_state.dart';

class ProductQueryView extends StatelessWidget {
  const ProductQueryView({super.key});

  ProductType? getCurrentProductType(int index) {
    if (index == -1) return null;
    if (index == 0) return ProductType.speaker;
    if (index == 2) return ProductType.endpoints;
    if (index == 3) return ProductType.amplifier;
    if (index == 4) return ProductType.dsps;
    if (index == 5) return ProductType.controllers;
    return ProductType.speaker;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProjectViewModel, ProjectViewModelState>(
      listener: (BuildContext context, ProjectViewModelState state) {
        if (state is DeviceTypeIndexChanged) {
          serviceLocator<ProductQueryCubit>().onProductTypeChanged(getCurrentProductType(state.index));
        }
      },
      child: BlocBuilder<ProductQueryCubit, ProductQueryState>(
        builder: (BuildContext context, ProductQueryState state) {
          final ProductQueryCubit cubit = serviceLocator<ProductQueryCubit>();

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
                      final ProductQueryModel product = state.filteredProducts[index];
                      return InkWell(
                        onTap: () {
                          serviceLocator<ProjectViewModel>().setSelectedProductToAdd(product);
                        },
                        child: ProductCard(
                          product: product,
                          searchQuery: state.searchQuery,
                        ),
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
                /// Product information with highlighting
                _buildProductInfo(context, product, searchQuery),
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

  /// Build highlighted product information with series and type
  Widget _buildProductInfo(BuildContext context, ProductQueryModel product, String searchQuery) {
    return Column(
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

        // /// Series with highlighting (if available)
        // if (product.series != null && product.series!.isNotEmpty) ...<Widget>[
        //   _buildHighlightedText(
        //     style: Theme.of(context).textTheme.bodySmall!.copyWith(
        //       fontSize: 10,
        //       fontWeight: FontWeight.w500,
        //       color: Theme.of(context).primaryColor,
        //     ),
        //     text: 'Series: ${product.series!}',
        //     query: searchQuery,
        //   ),
        //   const SizedBox(height: 2),
        // ],

        /// Product type with highlighting
        _buildHighlightedText(
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          text: _getProductTypeAndSpecs(product),
          query: searchQuery,
        ),
      ],
    );
  }

  // Move the methods from ProductQueryView to ProductCard
  String _getDefaultImage(ProductType type) {
    switch (type) {
      case ProductType.speaker:
        return "assets/images/speakers/DM_pendant.png";
      case ProductType.amplifier:
        return "assets/images/amps/default_amp.png";
      case ProductType.dsps:
      case ProductType.endpoints:
        return "assets/images/devices/default_device.png";
      case ProductType.sources:
        return "assets/images/products/mic1.png";
      case ProductType.controllers:
        return "assets/images/products/bose_dsp.png";
    }
  }

  String _getProductTypeAndSpecs(ProductQueryModel product) {
    switch (product.type) {
      case ProductType.speaker:
        return 'Speaker';
      case ProductType.amplifier:
        return 'Amplifier';
      case ProductType.controllers:
        return 'Controller';
      case ProductType.endpoints:
        return 'Endpoint';
      case ProductType.sources:
        return 'Source';
      case ProductType.dsps:
        return 'DSP';
    }
  }

  /// Highlight search terms in text (enhanced for multiple fields)
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
    /// Find all matches in the text
    final String lowerText = text.toLowerCase();
    final String lowerQuery = query.toLowerCase();

    // Find all occurrences of the query in the text
    final List<int> matches = <int>[];
    int startIndex = 0;
    while (true) {
      final int index = lowerText.indexOf(lowerQuery, startIndex);
      if (index == -1) break;
      matches.add(index);
      startIndex = index + 1;
    }

    /// If query not found, return normal text
    if (matches.isEmpty) {
      return FusionAppText(text: text, style: style, maxLine: 1);
    }

    /// Build highlighted text spans
    final List<InlineSpan> spans = <InlineSpan>[];
    int currentIndex = 0;

    for (final int matchIndex in matches) {
      // Add text before the match
      if (matchIndex > currentIndex) {
        spans.add(TextSpan(text: text.substring(currentIndex, matchIndex)));
      }

      // Add highlighted match
      spans.add(
        TextSpan(
          text: text.substring(matchIndex, matchIndex + query.length),
          style: style.copyWith(
            backgroundColor: Colors.yellow.withAlpha(100),
            fontWeight: FontWeight.bold,
          ),
        ),
      );

      currentIndex = matchIndex + query.length;
    }

    // Add remaining text after the last match
    if (currentIndex < text.length) {
      spans.add(TextSpan(text: text.substring(currentIndex)));
    }

    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(style: style, children: spans),
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
      ...getControllers(),
      ...getEndpoints(),
    ];
  }

  /// Get products by type
  static List<ProductQueryModel> getProductsByType(ProductType type) {
    switch (type) {
      case ProductType.speaker:
        return getSpeakerProducts();
      case ProductType.amplifier:
        return getAmplifierProducts();
      case ProductType.controllers:
        return getControllers();
      case ProductType.endpoints:
        return getEndpoints();
      case ProductType.dsps:
        return getDeviceProducts();
      case ProductType.sources:
        return <ProductQueryModel>[
          const ProductQueryModel(
            name: 'Mic',
            price: 123.0,
            image: 'assets/images/products/mic1.png',
            type: ProductType.sources,
            sku: 'MIC123',
            //speakerData['model'] ??
            specifications: 'New Mic',
          ),
        ];
    }
  }

  /// Convert speaker models to products using fusion_lib
  static List<ProductQueryModel> getSpeakerProducts() {
    try {
      final String speakersJson = fusionDevices.getSpeakers();
      final List<dynamic> speakersData = jsonDecode(speakersJson);
      return speakersData.map((dynamic speakerData) {
        return ProductQueryModel(
          name: speakerData['model'] ?? '',
          price: (speakerData['price'] ?? 0.0).toDouble(),
          image: speakerData["image_url"] ?? '',
          type: ProductType.speaker,
          color: speakerData["color"],
          mountingType: speakerData["mounting_type"],
          outdoorRated: speakerData["outdoor_rated"],
          maxSpl: speakerData["max_spl"] != null ? (speakerData["max_spl"] as num).toDouble() : null,
          nominalOhms: speakerData["nominal_ohms"] != null ? (speakerData["nominal_ohms"] as num).toDouble() : null,
          sku: 'MSA12XOHS',
          specifications: '${speakerData['max_spl'] ?? 0} dB SPL • ${speakerData['mounting_type'] ?? 'Unknown'}',
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

      return amplifiersData.map((dynamic ampData) {
        return ProductQueryModel(
          name: ampData['name'] ?? '',
          series: ampData['series'] ?? '',
          price: ampData['price'] != null ? (ampData['price'] as num).toDouble() : 0.0,
          image: ampData['image_url'] ?? '',
          type: ProductType.amplifier,
          sku: ampData['name'] ?? '',
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

      return devicesData.map((dynamic deviceData) {
        return ProductQueryModel(
          name: deviceData['name'] ?? '',
          price: deviceData['price'] != null ? (deviceData['price'] as num).toDouble() : 0.0,
          image: deviceData['image_url'] ?? '',
          type: ProductType.dsps,
          sku: deviceData['name'] ?? '',
          specifications: '${deviceData['analogInputs'] ?? 0}in • ${deviceData['analogOutputs'] ?? 0}out • ${deviceData['networkIO'] ?? 0} network I/O',
        );
      }).toList();
    } catch (e) {
      return <ProductQueryModel>[];
    }
  }

  /// Convert controllers specs to products using fusion_lib
  static List<ProductQueryModel> getControllers() {
    try {
      final String controllersJson = fusionDevices.getControllers();
      final List<dynamic> controllersData = jsonDecode(controllersJson);

      return controllersData.map((dynamic data) {
        return ProductQueryModel(
          name: data['name'] ?? '',
          price: data["price"] != null ? (data['price'] as num).toDouble() : 0.0,
          image: data['imageUrl'] ?? '',
          type: ProductType.controllers,
          sku: data['name'] ?? '',
          specifications: '${data['analogInputs'] ?? 0}in • ${data['analogOutputs'] ?? 0}out • ${data['networkIO'] ?? 0} network I/O',
        );
      }).toList();
    } catch (e) {
      return <ProductQueryModel>[];
    }
  }

  /// Convert endpoints specs to products using fusion_lib
  static List<ProductQueryModel> getEndpoints() {
    try {
      final String controllersJson = fusionDevices.getAllEndpoints();
      final List<dynamic> controllersData = jsonDecode(controllersJson);

      return controllersData.map((dynamic deviceData) {
        return ProductQueryModel(
          name: deviceData['name'] ?? '',
          price: deviceData['price'] != null ? (deviceData['price'] as num).toDouble() : 0.0,
          image: deviceData['imageUrl'] ?? '',
          type: ProductType.endpoints,
          sku: deviceData['name'] ?? '',
          specifications: '${deviceData['analogInputs'] ?? 0}in • ${deviceData['analogOutputs'] ?? 0}out • ${deviceData['networkIO'] ?? 0} network I/O',
        );
      }).toList();
    } catch (e) {
      return <ProductQueryModel>[];
    }
  }
}
