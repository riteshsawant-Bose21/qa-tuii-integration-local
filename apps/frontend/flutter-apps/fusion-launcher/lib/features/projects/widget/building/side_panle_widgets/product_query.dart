import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

class ProductQuery extends StatefulWidget {
  const ProductQuery({super.key});

  @override
  State<ProductQuery> createState() => _ProductQueryState();
}

class _ProductQueryState extends State<ProductQuery> {
  final TextEditingController _searchController = TextEditingController();
  List<Product> _filteredProducts = ProductService.getAllProducts();
  String _searchQuery = '';
  ProductType? _selectedProductType; // For filtering by type

  /// Sort and Filter state
  SortOption _selectedSortOption = SortOption.nameAToZ;
  final Set<ProductType> _selectedProductTypes = <ProductType>{};
  final Set<String> _selectedMountTypes = <String>{};
  final Set<String> _selectedVenueTypes = <String>{};
  final Set<String> _selectedColors = <String>{};
  final Set<String> _selectedCoverages = <String>{};
  final Set<String> _selectedImpedances = <String>{};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  /// Handle search input changes
  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _filteredProducts = _performSearch(_searchQuery);
    });
  }

  /// Perform search using the ProductSearchService
  List<Product> _performSearch(String query) {
    final List<Product> searchBase = _getFilteredProducts();

    if (query.isEmpty) {
      return _sortProducts(searchBase);
    }

    /// Using the search method with relevance scoring for better results
    final List<Product> searchResults = ProductSearchService.searchProductsWithRelevance(searchBase, query);
    return _sortProducts(searchResults);
  }

  /// Get filtered products based on advanced filters
  List<Product> _getFilteredProducts() {
    List<Product> products = ProductService.getAllProducts();

    // Apply product type filter from chips
    if (_selectedProductType != null) {
      products = products.where((Product product) => product.type == _selectedProductType).toList();
    }

    // Apply advanced filters
    if (_selectedProductTypes.isNotEmpty) {
      products = products.where((Product product) => _selectedProductTypes.contains(product.type)).toList();
    }

    // Apply speaker-specific filters
    if (_selectedMountTypes.isNotEmpty || _selectedVenueTypes.isNotEmpty || _selectedCoverages.isNotEmpty || _selectedImpedances.isNotEmpty) {
      products =
          products.where((Product product) {
            if (product.type != ProductType.speaker) return true;

            // Here you would check against actual speaker properties
            // This is a simplified example - you'd need to access the actual speaker data
            // from SpeakerDatabase to check mount type, venue type, etc.

            return true; // Placeholder - implement actual filtering logic
          }).toList();
    }

    // Apply color filter (would need to be added to Product model)
    if (_selectedColors.isNotEmpty) {
      // Implement color filtering when color property is added to Product model
    }

    return products;
  }

  /// Sort products based on selected sort option
  List<Product> _sortProducts(List<Product> products) {
    final List<Product> sortedProducts = List<Product>.from(products);

    switch (_selectedSortOption) {
      case SortOption.priceHighToLow:
        sortedProducts.sort((Product a, Product b) => b.price.compareTo(a.price));
        break;
      case SortOption.priceLowToHigh:
        sortedProducts.sort((Product a, Product b) => a.price.compareTo(b.price));
        break;
      case SortOption.nameAToZ:
        sortedProducts.sort((Product a, Product b) => a.name.compareTo(b.name));
        break;
      case SortOption.nameZToA:
        sortedProducts.sort((Product a, Product b) => b.name.compareTo(a.name));
        break;
    }

    return sortedProducts;
  }

  /// Handle product type filter change
  void _onProductTypeChanged(ProductType? type) {
    setState(() {
      _selectedProductType = type;
      _filteredProducts = _performSearch(_searchQuery);
    });
  }

  /// Handle sort option change
  void _onSortOptionChanged(SortOption option) {
    setState(() {
      _selectedSortOption = option;
      _filteredProducts = _performSearch(_searchQuery);
    });
  }

  /// Handle advanced filters change
  void _onFiltersChanged() {
    setState(() {
      _filteredProducts = _performSearch(_searchQuery);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        /// Search and filter section
        ProductSearchWidget(
          searchController: _searchController,
          selectedProductType: _selectedProductType,
          selectedSortOption: _selectedSortOption,
          selectedProductTypes: _selectedProductTypes,
          selectedMountTypes: _selectedMountTypes,
          selectedVenueTypes: _selectedVenueTypes,
          selectedColors: _selectedColors,
          selectedCoverages: _selectedCoverages,
          selectedImpedances: _selectedImpedances,
          onClearSearch: _clearSearch,
          onProductTypeChanged: _onProductTypeChanged,
          onSortOptionChanged: _onSortOptionChanged,
          onFiltersChanged: _onFiltersChanged,
        ),
        const SizedBox(height: 8),

        /// Search results info
        if (_searchQuery.isNotEmpty) ...<Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FusionAppText(
              text: 'Found ${_filteredProducts.length} results for "$_searchQuery"',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],

        /// Product list
        _filteredProducts.isEmpty
            ? _buildEmptyState()
            : ListView.separated(
              separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 16),
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filteredProducts.length,
              itemBuilder: (BuildContext context, int index) {
                return ProductCard(
                  product: _filteredProducts[index],
                  searchQuery: _searchQuery, // Pass search query for highlighting
                );
              },
            ),
      ],
    );
  }

  /// Empty state widget
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: Column(
        children: <Widget>[
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          FusionAppText(
            text: 'No products found',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          FusionAppText(
            text: 'Try adjusting your search terms or filters',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _filteredProducts = _getFilteredProducts();
    });
  }
}

/// Search, sort and filter section widget
class ProductSearchWidget extends StatelessWidget {
  const ProductSearchWidget({
    super.key,
    required this.searchController,
    required this.selectedProductType,
    required this.selectedSortOption,
    required this.selectedProductTypes,
    required this.selectedMountTypes,
    required this.selectedVenueTypes,
    required this.selectedColors,
    required this.selectedCoverages,
    required this.selectedImpedances,
    this.onClearSearch,
    this.onProductTypeChanged,
    this.onSortOptionChanged,
    this.onFiltersChanged,
  });

  final TextEditingController searchController;
  final ProductType? selectedProductType;
  final SortOption selectedSortOption;
  final Set<ProductType> selectedProductTypes;
  final Set<String> selectedMountTypes;
  final Set<String> selectedVenueTypes;
  final Set<String> selectedColors;
  final Set<String> selectedCoverages;
  final Set<String> selectedImpedances;
  final VoidCallback? onClearSearch;
  final ValueChanged<ProductType?>? onProductTypeChanged;
  final ValueChanged<SortOption>? onSortOptionChanged;
  final VoidCallback? onFiltersChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).colorScheme.dividerColor, width: 1),
          top: BorderSide(color: Theme.of(context).colorScheme.dividerColor, width: 1),
        ),
      ),
      child: Column(
        children: <Widget>[
          /// Search row
          SizedBox(
            height: 40,
            child: Row(
              children: <Widget>[
                Expanded(
                  child: FusionTextField(
                    controller: searchController,
                    hintText: 'Search products...',
                    prefixIcon: Icon(Icons.search, color: Colors.grey[400], size: 16),
                    suffixIcon:
                        searchController.text.isNotEmpty
                            ? IconButton(
                              icon: Icon(Icons.clear, color: Colors.grey[400], size: 16),
                              onPressed: onClearSearch,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            )
                            : null,
                  ),
                ),

                /// Filter Dropdown
                _buildDropdownButton(
                  context: context,
                  image: "assets/images/filter.png",
                  tooltip: 'Filter',
                  hasActiveFilters: _hasActiveFilters(),
                  dropdownBuilder:
                      (BuildContext context) => FilterDropdownContent(
                        selectedProductTypes: selectedProductTypes,
                        selectedMountTypes: selectedMountTypes,
                        selectedVenueTypes: selectedVenueTypes,
                        selectedColors: selectedColors,
                        selectedCoverages: selectedCoverages,
                        selectedImpedances: selectedImpedances,
                        onFiltersChanged: onFiltersChanged ?? () {},
                      ),
                ),

                const SizedBox(width: 8),

                /// Sort Dropdown
                _buildDropdownButton(
                  context: context,
                  image: "assets/images/sort_descending.png",
                  tooltip: 'Sort',
                  hasActiveFilters: false,
                  dropdownBuilder:
                      (BuildContext context) => SortDropdownContent(
                        selectedSortOption: selectedSortOption,
                        onSortOptionChanged: onSortOptionChanged ?? (SortOption option) {},
                      ),
                ),

                const SizedBox(width: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build dropdown button with custom dropdown content
  Widget _buildDropdownButton({
    required BuildContext context,
    required String image,
    required String tooltip,
    required bool hasActiveFilters,
    required Widget Function(BuildContext) dropdownBuilder,
  }) {
    return PopupMenuButton<void>(
      tooltip: tooltip,
      color: Theme.of(context).colorScheme.white,
      offset: const Offset(0, 30),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      itemBuilder:
          (BuildContext context) => <PopupMenuEntry<void>>[
            PopupMenuItem<void>(
              enabled: false,
              padding: EdgeInsets.zero,
              child: dropdownBuilder(context),
            ),
          ],
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration:
            hasActiveFilters
                ? BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                )
                : null,
        child: Image.asset(
          image,
          height: 16,
          width: 16,
        ),
      ),
    );
  }

  /// Check if any advanced filters are active
  bool _hasActiveFilters() {
    return selectedProductTypes.isNotEmpty ||
        selectedMountTypes.isNotEmpty ||
        selectedVenueTypes.isNotEmpty ||
        selectedColors.isNotEmpty ||
        selectedCoverages.isNotEmpty ||
        selectedImpedances.isNotEmpty;
  }
}

/// Product card widget
/// Updated ProductCard with search term highlighting
class ProductCard extends StatelessWidget {
  final Product product;
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

  String _getProductTypeAndSpecs(Product product) {
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

/// Product types enum
enum ProductType {
  speaker,
  amplifier,
  device,
}

/// Sort options enum
enum SortOption {
  priceHighToLow,
  priceLowToHigh,
  nameAToZ,
  nameZToA,
}

/// Sort dropdown content widget
class SortDropdownContent extends StatelessWidget {
  const SortDropdownContent({
    super.key,
    required this.selectedSortOption,
    required this.onSortOptionChanged,
  });

  final SortOption selectedSortOption;
  final ValueChanged<SortOption> onSortOptionChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            height: 32,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.white,
              border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.dividerColor, width: 1)),
            ),
            child: FusionAppText(text: "Sort", style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11)),
          ),
          _buildSortOption(
            context: context,
            option: SortOption.priceHighToLow,
            title: 'Price: High to Low',
            image: "assets/images/low_to_high.png",
          ),
          _buildSortOption(
            context: context,
            option: SortOption.priceLowToHigh,
            title: 'Price: Low to High',
            image: "assets/images/high_to_low.png",
          ),
          _buildSortOption(
            context: context,
            option: SortOption.nameAToZ,
            title: 'Product Name: A-Z',
            image: "assets/images/sort_a_to_z.png",
          ),
          _buildSortOption(
            context: context,
            option: SortOption.nameZToA,
            title: 'Product Name: Z-A',
            image: "assets/images/sort_a_to_z.png",
          ),
        ],
      ),
    );
  }

  /// Build individual sort option
  Widget _buildSortOption({required BuildContext context, required SortOption option, required String title, required String image}) {
    final bool isSelected = selectedSortOption == option;

    return InkWell(
      onTap: () {
        onSortOptionChanged(option);
        Navigator.of(context).pop();
      },
      child: Container(
        color: isSelected ? Theme.of(context).colorScheme.grey : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: <Widget>[
            Image.asset(
              image,
              width: 24,
              height: 24,
            ),
            const SizedBox(width: 12),
            FusionAppText(
              text: title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Filter dropdown content widget
class FilterDropdownContent extends StatefulWidget {
  const FilterDropdownContent({
    super.key,
    required this.selectedProductTypes,
    required this.selectedMountTypes,
    required this.selectedVenueTypes,
    required this.selectedColors,
    required this.selectedCoverages,
    required this.selectedImpedances,
    required this.onFiltersChanged,
  });

  final Set<ProductType> selectedProductTypes;
  final Set<String> selectedMountTypes;
  final Set<String> selectedVenueTypes;
  final Set<String> selectedColors;
  final Set<String> selectedCoverages;
  final Set<String> selectedImpedances;
  final VoidCallback onFiltersChanged;

  @override
  State<FilterDropdownContent> createState() => _FilterDropdownContentState();
}

class _FilterDropdownContentState extends State<FilterDropdownContent> {
  late Set<ProductType> _localProductTypes;
  late Set<String> _localMountTypes;
  late Set<String> _localVenueTypes;
  late Set<String> _localColors;
  late Set<String> _localCoverages;
  late Set<String> _localImpedances;

  @override
  void initState() {
    super.initState();
    _localProductTypes = Set<ProductType>.from(widget.selectedProductTypes);
    _localMountTypes = Set<String>.from(widget.selectedMountTypes);
    _localVenueTypes = Set<String>.from(widget.selectedVenueTypes);
    _localColors = Set<String>.from(widget.selectedColors);
    _localCoverages = Set<String>.from(widget.selectedCoverages);
    _localImpedances = Set<String>.from(widget.selectedImpedances);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.white,
      constraints: const BoxConstraints(maxHeight: 450, minWidth: 200),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.white,
                border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.dividerColor, width: 1)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: FusionAppText(text: "Filter", style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11)),
                  ),
                  if (_hasAnyFilters())
                    TextButton(
                      onPressed: _clearAllFilters,
                      child: Text('Clear All', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11)),
                    ),
                ],
              ),
            ),

            /// Product Type Filter
            _buildFilterSection(
              title: 'Product Type',
              image: "assets/images/coverage.png",
              options: ProductType.values.map((ProductType type) => _getProductTypeDisplayName(type)).toList(),
              selectedOptions: _localProductTypes.map((ProductType type) => _getProductTypeDisplayName(type)).toSet(),
              onChanged: (Set<String> selected) {
                setState(() {
                  _localProductTypes.clear();
                  for (String displayName in selected) {
                    final ProductType? type = _getProductTypeFromDisplayName(displayName);
                    if (type != null) _localProductTypes.add(type);
                  }
                });
                _applyFilters();
              },
            ),

            /// Mount Type Filter (only for speakers)
            if (_localProductTypes.isEmpty || _localProductTypes.contains(ProductType.speaker))
              _buildFilterSection(
                title: 'Mount Type',
                image: "assets/images/mount_type.png",
                options: <String>['Ceiling', 'Surface', 'Pendant'],
                selectedOptions: _localMountTypes,
                onChanged: (Set<String> selected) {
                  setState(() {
                    _localMountTypes = selected;
                  });
                  _applyFilters();
                },
              ),

            /// Venue Type Filter (only for speakers)
            if (_localProductTypes.isEmpty || _localProductTypes.contains(ProductType.speaker))
              _buildFilterSection(
                title: 'Venue Type',
                image: "assets/images/venue_type.png",
                options: <String>['Indoor', 'Outdoor'],
                selectedOptions: _localVenueTypes,
                onChanged: (Set<String> selected) {
                  setState(() {
                    _localVenueTypes = selected;
                  });
                  _applyFilters();
                },
              ),

            /// Color Filter
            _buildFilterSection(
              title: 'Color',
              image: "assets/images/color.png",
              options: <String>['White', 'Black'],
              selectedOptions: _localColors,
              onChanged: (Set<String> selected) {
                setState(() {
                  _localColors = selected;
                });
                _applyFilters();
              },
            ),

            /// Coverage Filter (only for speakers)
            if (_localProductTypes.isEmpty || _localProductTypes.contains(ProductType.speaker))
              _buildFilterSection(
                title: 'Coverage',
                image: "assets/images/coverage.png",
                options: <String>['Low', 'Mid', 'High'],
                selectedOptions: _localCoverages,
                onChanged: (Set<String> selected) {
                  setState(() {
                    _localCoverages = selected;
                  });
                  _applyFilters();
                },
              ),

            /// Impedance Filter (only for speakers)
            if (_localProductTypes.isEmpty || _localProductTypes.contains(ProductType.speaker))
              _buildFilterSection(
                title: 'Impedance',
                image: "assets/images/impedance.png",
                options: <String>['Low', 'High'],
                selectedOptions: _localImpedances,
                onChanged: (Set<String> selected) {
                  setState(() {
                    _localImpedances = selected;
                  });
                  _applyFilters();
                },
              ),
          ],
        ),
      ),
    );
  }

  /// Build individual filter section with checkboxes
  Widget _buildFilterSection({
    required String title,
    required String image,
    required List<String> options,
    required Set<String> selectedOptions,
    required ValueChanged<Set<String>> onChanged,
  }) {
    return ExpansionTile(
      minTileHeight: 24,
      iconColor: Colors.black,
      collapsedIconColor: Colors.black,
      initiallyExpanded: selectedOptions.isNotEmpty,
      childrenPadding: const EdgeInsets.only(left: 34, right: 16, bottom: 8),
      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
      title: Row(
        children: <Widget>[
          Image.asset(
            image,
            width: 24,
            height: 24,
          ),
          const SizedBox(width: 12),
          FusionAppText(
            text: title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      children:
          options.map((String option) {
            final bool isSelected = selectedOptions.contains(option);
            return CheckboxListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: FusionAppText(
                text: option,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 11,
                ),
              ),
              value: isSelected,
              activeColor: Theme.of(context).colorScheme.greyDark,
              onChanged: (bool? value) {
                final Set<String> newSelected = Set<String>.from(selectedOptions);
                if (value == true) {
                  newSelected.add(option);
                } else {
                  newSelected.remove(option);
                }
                onChanged(newSelected);
              },
            );
          }).toList(),
    );
  }

  bool _hasAnyFilters() {
    return _localProductTypes.isNotEmpty ||
        _localMountTypes.isNotEmpty ||
        _localVenueTypes.isNotEmpty ||
        _localColors.isNotEmpty ||
        _localCoverages.isNotEmpty ||
        _localImpedances.isNotEmpty;
  }

  void _clearAllFilters() {
    setState(() {
      _localProductTypes.clear();
      _localMountTypes.clear();
      _localVenueTypes.clear();
      _localColors.clear();
      _localCoverages.clear();
      _localImpedances.clear();
    });
    _applyFilters();
  }

  String _getProductTypeDisplayName(ProductType type) {
    switch (type) {
      case ProductType.speaker:
        return 'Speakers';
      case ProductType.amplifier:
        return 'Amplifiers';
      case ProductType.device:
        return 'Devices';
    }
  }

  ProductType? _getProductTypeFromDisplayName(String displayName) {
    switch (displayName) {
      case 'Speakers':
        return ProductType.speaker;
      case 'Amplifiers':
        return ProductType.amplifier;
      case 'Devices':
        return ProductType.device;
      default:
        return null;
    }
  }

  void _applyFilters() {
    widget.selectedProductTypes.clear();
    widget.selectedProductTypes.addAll(_localProductTypes);

    widget.selectedMountTypes.clear();
    widget.selectedMountTypes.addAll(_localMountTypes);

    widget.selectedVenueTypes.clear();
    widget.selectedVenueTypes.addAll(_localVenueTypes);

    widget.selectedColors.clear();
    widget.selectedColors.addAll(_localColors);

    widget.selectedCoverages.clear();
    widget.selectedCoverages.addAll(_localCoverages);

    widget.selectedImpedances.clear();
    widget.selectedImpedances.addAll(_localImpedances);

    widget.onFiltersChanged();
  }
}

/// Unified Product model
class Product {
  const Product({
    required this.name,
    required this.price,
    required this.image,
    required this.type,
    this.specifications = '',
  });

  final String name;
  final double price;
  final String image;
  final ProductType type;
  final String specifications;
}

/// Product service to manage different product types
class ProductService {
  /// Get all products from all sources
  static List<Product> getAllProducts() {
    return <Product>[
      ...getSpeakerProducts(),
      ...getAmplifierProducts(),
      ...getDeviceProducts(),
    ];
  }

  /// Get products by type
  static List<Product> getProductsByType(ProductType type) {
    switch (type) {
      case ProductType.speaker:
        return getSpeakerProducts();
      case ProductType.amplifier:
        return getAmplifierProducts();
      case ProductType.device:
        return getDeviceProducts();
    }
  }

  /// Convert speaker models to products
  static List<Product> getSpeakerProducts() {
    return SpeakerDatabase.database.entries.map((MapEntry<String, SpeakerModel> entry) {
      final SpeakerModel speaker = entry.value;
      return Product(
        name: speaker.model,
        price: speaker.price,
        image: speaker.imageUrl,
        type: ProductType.speaker,
        specifications: '${speaker.maxSpl} dB SPL • ${speaker.mountingType}',
      );
    }).toList();
  }

  /// Convert amplifier models to products
  static List<Product> getAmplifierProducts() {
    return AmpService.models.map((AmpModel amp) {
      return Product(
        name: amp.name,
        price: 0.0, // Add price if available in your amp model
        image: '', // Add image if available in your amp model
        type: ProductType.amplifier,
        specifications: '${amp.channels}ch • ${amp.peakPerChannel.toInt()}W per ch',
      );
    }).toList();
  }

  /// Convert device specs to products
  static List<Product> getDeviceProducts() {
    return DeviceService.devices.map((DeviceSpec device) {
      return Product(
        name: device.name,
        price: 0.0, // Add price if available in your device model
        image: '', // Add image if available in your device model
        type: ProductType.device,
        specifications: '${device.analogInputs}in • ${device.analogOutputs}out • ${device.networkIO} network I/O',
      );
    }).toList();
  }
}

/// Your existing models (add these to your code)
class AmpModel {
  const AmpModel({
    required this.name,
    required this.channels,
    required this.peakPerChannel,
  });

  final String name;
  final int channels;
  final double peakPerChannel;
}

class DeviceSpec {
  const DeviceSpec({
    required this.name,
    required this.analogInputs,
    required this.analogOutputs,
    required this.networkIO,
  });

  final String name;
  final int analogInputs;
  final int analogOutputs;
  final int networkIO;
}

class SpeakerModel {
  const SpeakerModel({
    required this.model,
    required this.maxSpl,
    required this.mountingType,
    required this.outdoorRated,
    required this.isSubwoofer,
    required this.nominalOhms,
    required this.hasHiZ,
    required this.hiZTaps,
    required this.taps70V,
    required this.taps100V,
    required this.longTermRms,
    required this.ppk,
    required this.imageUrl,
    required this.price,
  });

  final String model;
  final int maxSpl;
  final String mountingType;
  final bool outdoorRated;
  final bool isSubwoofer;
  final int nominalOhms;
  final bool hasHiZ;
  final List<int> hiZTaps;
  final List<double> taps70V;
  final List<double> taps100V;
  final int longTermRms;
  final int ppk;
  final String imageUrl;
  final double price;
}

/// Your data services
class AmpService {
  static const List<AmpModel> models = <AmpModel>[
    AmpModel(name: 'PSX1204D', channels: 4, peakPerChannel: 600.0),
    AmpModel(name: 'PSX1208D', channels: 8, peakPerChannel: 600.0),
    AmpModel(name: 'PSX2404D', channels: 4, peakPerChannel: 1200.0),
    AmpModel(name: 'PSX2408D', channels: 8, peakPerChannel: 1200.0),
    AmpModel(name: 'PSX4804D', channels: 4, peakPerChannel: 2400.0),
    AmpModel(name: 'PSX4808D', channels: 8, peakPerChannel: 2400.0),
  ];
}

class DeviceService {
  static const List<DeviceSpec> devices = <DeviceSpec>[
    DeviceSpec(name: "4ch PowerSmart", analogInputs: 4, analogOutputs: 4, networkIO: 0),
    DeviceSpec(name: "8ch PowerSmart", analogInputs: 8, analogOutputs: 8, networkIO: 0),
    DeviceSpec(name: "FM6", analogInputs: 6, analogOutputs: 0, networkIO: 24),
    DeviceSpec(name: "FM8Y", analogInputs: 8, analogOutputs: 8, networkIO: 24),
  ];
}

class SpeakerDatabase {
  static const Map<String, SpeakerModel> database = <String, SpeakerModel>{
    'DM2C-LP': SpeakerModel(
      model: 'DM2C-LP',
      maxSpl: 97,
      mountingType: 'ceiling',
      outdoorRated: false,
      isSubwoofer: false,
      nominalOhms: 16,
      hasHiZ: true,
      hiZTaps: <int>[9],
      taps70V: <double>[1.2, 2.3, 4.5, 9],
      taps100V: <double>[2.3, 4.5, 9],
      longTermRms: 20,
      ppk: 40,
      imageUrl: '',
      price: 1312.2,
    ),
    'DM3C': SpeakerModel(
      model: 'DM3C',
      maxSpl: 98,
      mountingType: 'ceiling',
      outdoorRated: false,
      isSubwoofer: false,
      nominalOhms: 8,
      hasHiZ: true,
      hiZTaps: <int>[25],
      taps70V: <double>[3, 6, 12, 25],
      taps100V: <double>[6, 12, 25],
      longTermRms: 30,
      ppk: 60,
      imageUrl: '',
      price: 1312.2,
    ),
    'DM3P': SpeakerModel(
      model: 'DM3P',
      maxSpl: 99,
      mountingType: 'pendant',
      outdoorRated: false,
      isSubwoofer: false,
      nominalOhms: 8,
      hasHiZ: true,
      hiZTaps: <int>[25],
      taps70V: <double>[3, 6, 12, 25],
      taps100V: <double>[6, 12, 25],
      longTermRms: 30,
      ppk: 60,
      imageUrl: '',
      price: 1312.2,
    ),
    // Add more speaker models from your database...
  };
}

/// Product search service with various search functionalities
class ProductSearchService {
  /// Search products by name (case-insensitive)
  static List<Product> searchProducts(List<Product> products, String query) {
    if (query.isEmpty) {
      return products;
    }

    final String searchQuery = query.toLowerCase().trim();

    return products.where((Product product) {
      return product.name.toLowerCase().contains(searchQuery) || product.specifications.toLowerCase().contains(searchQuery);
    }).toList();
  }

  /// Advanced search - search by name with multiple keywords
  static List<Product> searchProductsAdvanced(List<Product> products, String query) {
    if (query.isEmpty) {
      return products;
    }

    final List<String> keywords = query.toLowerCase().trim().split(' ');

    return products.where((Product product) {
      final String searchText = '${product.name} ${product.specifications}'.toLowerCase();

      /// Check if all keywords exist in the product name or specifications
      return keywords.every((String keyword) => searchText.contains(keyword));
    }).toList();
  }

  /// Search with relevance scoring (returns results sorted by relevance)
  static List<Product> searchProductsWithRelevance(List<Product> products, String query) {
    if (query.isEmpty) {
      return products;
    }

    final String searchQuery = query.toLowerCase().trim();
    final List<ProductWithScore> scoredProducts = <ProductWithScore>[];

    for (final Product product in products) {
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
  static List<Product> filterByType(List<Product> products, ProductType type) {
    return products.where((Product product) => product.type == type).toList();
  }

  /// Combined search and filter
  static List<Product> searchAndFilter(List<Product> products, String searchQuery, ProductType? filterType) {
    List<Product> result = products;

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
  final Product product;
  final int score;

  ProductWithScore(this.product, this.score);
}

/// Extension methods for easier use
extension ProductListExtensions on List<Product> {
  /// Search products by name
  List<Product> search(String query) {
    return ProductSearchService.searchProducts(this, query);
  }

  /// Advanced search with multiple keywords
  List<Product> searchAdvanced(String query) {
    return ProductSearchService.searchProductsAdvanced(this, query);
  }

  /// Search with relevance scoring
  List<Product> searchWithRelevance(String query) {
    return ProductSearchService.searchProductsWithRelevance(this, query);
  }

  /// Filter by type
  List<Product> filterByType(ProductType type) {
    return ProductSearchService.filterByType(this, type);
  }
}
