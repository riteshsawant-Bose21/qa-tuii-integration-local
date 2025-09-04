import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

import '../../../core/utils/app_enums.dart';

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
