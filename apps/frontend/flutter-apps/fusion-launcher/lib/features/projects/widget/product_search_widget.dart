import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/projects/widget/sort_drop_down_content.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_utils/app_enums.dart';

import 'filter_drop_down_content.dart';

class ProductSearchWidget extends StatelessWidget {
  const ProductSearchWidget({
    super.key,
    required this.searchController,
    required this.selectedProductType,
    this.selectedSortOption,
    required this.selectedProductTypes,
    required this.selectedMountTypes,
    required this.selectedVenueTypes,
    required this.selectedColors,
    required this.selectedCoverages,
    required this.selectedImpedances,
    this.onClearSearch,
    // this.onProductTypeChanged,
    this.onSortOptionChanged,
    this.onFiltersChanged,
  });

  final TextEditingController searchController;
  final ProductType? selectedProductType;
  final SortOption? selectedSortOption;
  final Set<ProductType> selectedProductTypes;
  final Set<String> selectedMountTypes;
  final Set<String> selectedVenueTypes;
  final Set<String> selectedColors;
  final Set<String> selectedCoverages;
  final Set<String> selectedImpedances;
  final VoidCallback? onClearSearch;
  final ValueChanged<SortOption?>? onSortOptionChanged;
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
                    hintText: 'Search by name, series or type...',
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
                  hasActiveFilters: selectedSortOption != null, // Show active state when sort is selected
                  dropdownBuilder:
                      (BuildContext context) => SortDropdownContent(
                        selectedSortOption: selectedSortOption,
                        onSortOptionChanged: onSortOptionChanged ?? (SortOption? option) {},
                      ),
                ),

                const SizedBox(width: 12),
              ],
            ),
          ),

          /// Active filters chips row
          if (_hasActiveFilters()) _buildActiveFiltersChips(context),
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

  /// Build active filters as chips
  Widget _buildActiveFiltersChips(BuildContext context) {
    final List<Widget> chips = <Widget>[];

    // Product Type chips
    for (final ProductType productType in selectedProductTypes) {
      chips.add(
        _buildFilterChip(
          context: context,
          label: _getProductTypeDisplayName(productType),
          onRemove: () => _removeProductTypeFilter(productType),
        ),
      );
    }

    // Mount Type chips
    if (selectedProductTypes.contains(ProductType.speaker)) {
      for (final String mountType in selectedMountTypes) {
        chips.add(
          _buildFilterChip(
            context: context,
            label: 'Mount: $mountType',
            onRemove: () => _removeMountTypeFilter(mountType),
          ),
        );
      }
    }

    // Venue Type chips
    if (selectedProductTypes.contains(ProductType.speaker)) {
      for (final String venueType in selectedVenueTypes) {
        chips.add(
          _buildFilterChip(
            context: context,
            label: 'Venue: $venueType',
            onRemove: () => _removeVenueTypeFilter(venueType),
          ),
        );
      }
    }

    // Color chips
    if (selectedProductTypes.contains(ProductType.speaker)) {
      for (final String color in selectedColors) {
        chips.add(
          _buildFilterChip(
            context: context,
            label: 'Color: $color',
            onRemove: () => _removeColorFilter(color),
          ),
        );
      }
    }

    // Coverage chips
    if (selectedProductTypes.contains(ProductType.speaker)) {
      for (final String coverage in selectedCoverages) {
        chips.add(
          _buildFilterChip(
            context: context,
            label: 'Coverage: $coverage',
            onRemove: () => _removeCoverageFilter(coverage),
          ),
        );
      }
    }

    // Impedance chips
    if (selectedProductTypes.contains(ProductType.speaker)) {
      for (final String impedance in selectedImpedances) {
        chips.add(
          _buildFilterChip(
            context: context,
            label: 'Impedance: $impedance',
            onRemove: () => _removeImpedanceFilter(impedance),
          ),
        );
      }
    }

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: chips.length,
              separatorBuilder: (BuildContext context, int index) => const SizedBox(width: 8),
              itemBuilder: (BuildContext context, int index) => chips[index],
            ),
          ),

          /// Clear all button
          /// Only show if there are active filters and product type is speaker
          if (chips.isNotEmpty && selectedProductTypes.contains(ProductType.speaker))
            Container(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton(
                onPressed: _clearAllFilters,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: FusionAppText(
                  text: 'Clear',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Build individual filter chip
  Widget _buildFilterChip({
    required BuildContext context,
    required String label,
    required VoidCallback onRemove,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.greyLight,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
          color: Theme.of(context).colorScheme.greyLight,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          FusionAppText(
            text: label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 10,
              color: Theme.of(context).colorScheme.fusionTextViewColor,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Icons.close,
              size: 12,
              color: Theme.of(context).colorScheme.fusionTextViewColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Get product type display name
  String _getProductTypeDisplayName(ProductType type) {
    switch (type) {
      case ProductType.speaker:
        return 'Speakers';
      case ProductType.amplifier:
        return 'Amplifiers';
      case ProductType.controllers:
        return 'Controllers';
      case ProductType.endpoints:
        return 'Endpoints';
      case ProductType.dsps:
        return 'DSPs';
      case ProductType.sources:
        return 'Sources';
      case ProductType.racks:
        return 'Racks';
    }
  }

  /// Remove individual filters
  void _removeProductTypeFilter(ProductType productType) {
    selectedProductTypes.remove(productType);
    onFiltersChanged?.call();
  }

  void _removeMountTypeFilter(String mountType) {
    selectedMountTypes.remove(mountType);
    onFiltersChanged?.call();
  }

  void _removeVenueTypeFilter(String venueType) {
    selectedVenueTypes.remove(venueType);
    onFiltersChanged?.call();
  }

  void _removeColorFilter(String color) {
    selectedColors.remove(color);
    onFiltersChanged?.call();
  }

  void _removeCoverageFilter(String coverage) {
    selectedCoverages.remove(coverage);
    onFiltersChanged?.call();
  }

  void _removeImpedanceFilter(String impedance) {
    selectedImpedances.remove(impedance);
    onFiltersChanged?.call();
  }

  /// Clear all filters
  void _clearAllFilters() {
    selectedProductTypes.clear();
    selectedMountTypes.clear();
    selectedVenueTypes.clear();
    selectedColors.clear();
    selectedCoverages.clear();
    selectedImpedances.clear();
    onFiltersChanged?.call();
  }
}
