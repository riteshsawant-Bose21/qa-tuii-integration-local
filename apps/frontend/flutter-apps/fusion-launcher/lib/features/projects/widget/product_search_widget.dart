import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/projects/widget/sort_drop_down_content.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

import '../../../../../core/utils/app_enums.dart';
import 'filter_drop_down_content.dart';

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
