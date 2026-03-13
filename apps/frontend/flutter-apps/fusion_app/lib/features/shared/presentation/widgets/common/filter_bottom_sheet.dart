import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

/// A reusable filter bottom sheet widget that displays filter options
/// with categories and checkboxes.
///
/// The widget supports:
/// - Multiple filter categories (e.g., Zones, Type, Alerts)
/// - Search functionality across filters
/// - Select All / Deselect functionality per category
/// - Custom actions (Clear Filters, Apply)
/// - Dark theme styling matching the app theme
class FilterBottomSheet extends StatefulWidget {
  /// Categories for the filters
  /// Each category contains a name and list of filter options
  final List<FilterCategory> categories;

  /// Callback when Apply button is pressed
  /// Passes back the selected filters
  final Function(Map<String, List<String>>) onApply;

  /// Callback when Clear Filters button is pressed
  final VoidCallback? onClearFilters;

  /// Initial selected filters
  /// Format: {'categoryName': ['option1', 'option2']}
  final Map<String, List<String>>? initialSelectedFilters;

  /// Title of the bottom sheet
  final String title;

  const FilterBottomSheet({
    Key? key,
    required this.categories,
    required this.onApply,
    this.onClearFilters,
    this.initialSelectedFilters,
    this.title = 'FILTERS',
  }) : super(key: key);

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late Map<String, List<String>> selectedFilters;
  late List<FilterCategory> categories;
  String searchQuery = '';
  late String activeCategoryName;

  @override
  void initState() {
    super.initState();
    selectedFilters = widget.initialSelectedFilters ?? {};
    // Initialize empty lists for categories not in initial selection
    for (var category in widget.categories) {
      selectedFilters.putIfAbsent(category.name, () => []);
    }
    categories = widget.categories;
    activeCategoryName = categories.isNotEmpty ? categories[0].name : '';
  }

  void _toggleFilter(String categoryName, String optionName) {
    setState(() {
      if (selectedFilters[categoryName]?.contains(optionName) ?? false) {
        selectedFilters[categoryName]?.remove(optionName);
      } else {
        selectedFilters[categoryName]?.add(optionName);
      }
    });
  }

  void _selectAllInCategory(String categoryName) {
    setState(() {
      final category = categories.firstWhere((c) => c.name == categoryName);
      selectedFilters[categoryName] = List.from(
        category.options.map((e) => e.name),
      );
    });
  }

  void _deselectAllInCategory(String categoryName) {
    setState(() {
      selectedFilters[categoryName]?.clear();
    });
  }

  void _clearAllFilters() {
    setState(() {
      for (var category in categories) {
        selectedFilters[category.name]?.clear();
      }
    });
    if (widget.onClearFilters != null) {
      widget.onClearFilters!();
    }
  }

  List<FilterOption> _getFilteredOptions(String categoryName) {
    final category = categories.firstWhere((c) => c.name == categoryName);
    if (searchQuery.isEmpty) {
      return category.options;
    }
    return category.options
        .where((option) =>
            option.name.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: colorScheme.elevation2,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Header with title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.title,
                      style: textTheme.l1SemiBold.copyWith(
                        color: colorScheme.textPrimary,
                      ),
                    ),
                    // Divider line
                    Container(
                      width: 2,
                      height: 24,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryWhite,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Search field
                _buildSearchField(context, colorScheme, textTheme),
              ],
            ),
          ),
          // Filter content
          Expanded(
            child: Row(
              children: [
                // Left sidebar - Category labels
                _buildCategorySidebar(colorScheme, textTheme),
                // Right side - Filter options
                Expanded(
                  child: _buildFilterOptions(colorScheme, textTheme),
                ),
              ],
            ),
          ),
          // Bottom action buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildActionButtons(context, colorScheme, textTheme),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colorScheme.elevation3,
        border: Border.all(color: colorScheme.strokeLight),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            color: colorScheme.textPrimary,
            size: 24,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
              style: textTheme.b2Regular.copyWith(
                color: colorScheme.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Search across filters...',
                hintStyle: textTheme.b2Regular.copyWith(
                  color: colorScheme.textBody,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySidebar(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      width: 120,
      color: colorScheme.elevation2,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < categories.length; i++)
            Padding(
              padding: EdgeInsets.only(
                bottom: i < categories.length - 1 ? 20 : 0,
              ),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    activeCategoryName = categories[i].name;
                  });
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            categories[i].name,
                            style: textTheme.b3SemiBold.copyWith(
                              color: activeCategoryName == categories[i].name
                                  ? colorScheme.primaryWhite
                                  : colorScheme.textBody,
                            ),
                          ),
                        ),
                        if (activeCategoryName == categories[i].name)
                          Container(
                            width: 2,
                            height: 24,
                            decoration: BoxDecoration(
                              color: colorScheme.primaryWhite,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterOptions(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      color: colorScheme.elevation3,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Only show options for active category
              if (activeCategoryName.isNotEmpty)
                ..._buildActiveCategoryOptions(
                  colorScheme,
                  textTheme,
                  activeCategoryName,
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildActiveCategoryOptions(
    ColorScheme colorScheme,
    TextTheme textTheme,
    String categoryName,
  ) {
    final categoryIndex =
        categories.indexWhere((c) => c.name == categoryName);
    if (categoryIndex == -1) return [];

    return [
      // Select All option
      _buildFilterTile(
        colorScheme,
        textTheme,
        categoryName,
        'Select All',
        isSelectAll: true,
        isSelected: (selectedFilters[categoryName]?.length ?? 0) ==
            categories[categoryIndex].options.length,
        onChanged: (isSelected) {
          if (isSelected ?? false) {
            _selectAllInCategory(categoryName);
          } else {
            _deselectAllInCategory(categoryName);
          }
        },
      ),
      const SizedBox(height: 16),
      // Individual filter options
      for (var option in _getFilteredOptions(categoryName))
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildFilterTile(
            colorScheme,
            textTheme,
            categoryName,
            option.name,
            isSelected: selectedFilters[categoryName]?.contains(option.name),
            onChanged: (isSelected) {
              _toggleFilter(categoryName, option.name);
            },
          ),
        ),
    ];
  }

  Widget _buildFilterTile(
    ColorScheme colorScheme,
    TextTheme textTheme,
    String categoryName,
    String optionName, {
    bool? isSelected,
    bool isSelectAll = false,
    required Function(bool?) onChanged,
  }) {
    final isOptionSelected = isSelected ?? false;

    return GestureDetector(
      onTap: () => onChanged(!isOptionSelected),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              optionName,
              style: isSelectAll
                  ? textTheme.b3SemiBold.copyWith(
                      color: isOptionSelected
                          ? colorScheme.primaryWhite
                          : colorScheme.textPrimary,
                    )
                  : textTheme.b3Regular.copyWith(
                      color: isOptionSelected
                          ? colorScheme.primaryWhite
                          : colorScheme.textBody,
                    ),
            ),
          ),
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              border: Border.all(
                color: isOptionSelected
                    ? colorScheme.primaryColor
                    : colorScheme.textDisabled,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: isOptionSelected
                ? Center(
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _clearAllFilters,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: colorScheme.elevation2),
              backgroundColor: colorScheme.elevation2,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Clear Filters',
              style: textTheme.b2SemiBold.copyWith(
                color: colorScheme.textSecondary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              widget.onApply(selectedFilters);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.elevation3,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Apply',
              style: textTheme.b2SemiBold.copyWith(
                color: colorScheme.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Model class representing a filter category
class FilterCategory {
  final String name;
  final List<FilterOption> options;

  FilterCategory({
    required this.name,
    required this.options,
  });
}

/// Model class representing a single filter option
class FilterOption {
  final String name;
  final String? id;

  FilterOption({
    required this.name,
    this.id,
  });
}

