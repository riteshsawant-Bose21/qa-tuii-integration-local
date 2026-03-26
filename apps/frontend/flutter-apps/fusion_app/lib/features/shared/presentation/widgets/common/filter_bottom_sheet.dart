import 'package:flutter/material.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/app_bar/app_bar_search.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/divider.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/text_field/text_field.dart';
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
  TextEditingController controller = TextEditingController();
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

      final allOptions = <String>[];

      for (final filter in category.options) {
        // Add parent option
        allOptions.add(filter.name);

        // Add nested options if present
        if (filter.options != null) {
          allOptions.addAll(filter.options!.map((o) => o.name));
        }
      }
      print("allOptions.length");
      print(categoryName);
      print(selectedFilters[categoryName]);
      print(allOptions.length);

      selectedFilters[categoryName] = allOptions;
    });
  }
  void _deselectAllInCategory(String categoryName) {
    setState(() {
      selectedFilters.remove(categoryName);
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
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: BoxDecoration(
        color: colorScheme.elevation1,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Header with title
          SizedBox(height: 24,),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
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

                  ],
                ),
                const SizedBox(height: 16),
                // Search field
                Container(
                    child:AppTextField(
                      controller: controller,
                      filledColor: colorScheme.elevation2,
                      hint: 'Search across filters...',
                      prefixIcon: GestureDetector(
                        onTap: (){
                          Navigator.pop(context);
                        },
                        child: Icon(
                            Icons.search,
                            color: context.colorScheme.iconDefault),
                      ),
                    )),
              ],
            ),
          ),
          // Filter content
          Expanded(
            child: Container(
              margin: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.elevation2,
                borderRadius: const BorderRadius.all( Radius.circular(16),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
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
          ),
          // Bottom action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildActionButtons(context, colorScheme, textTheme),
          ),
          SizedBox(height: 40,)
        ],
      ),
    );
  }


  Widget _buildCategorySidebar(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      width: 120,
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
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
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
        isSelected: isAllSelected(categoryName,categoryIndex),
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
        Column(
          children: [
            _buildFilterTile(
              colorScheme,
              textTheme,
              categoryName,
              option.name,
              isSelected: selectedFilters[categoryName]?.contains(option.name),
              onChanged: (isSelected) {
                _toggleFilter(categoryName, option.name);
              },
            ),
            (option.options?.isNotEmpty ?? false) ? SizedBox(height: 20) : SizedBox.shrink(),
            ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                physics: NeverScrollableScrollPhysics(),
                itemCount: option.options?.length ?? 0,
                separatorBuilder: (context,i){
                    return  SizedBox(height: 20,);
                },
                itemBuilder: (context,i){
                  Option item = option.options![i];
                  return _buildFilterTile(
                    colorScheme,
                    textTheme,
                    categoryName,
                    item.name,
                    isSelected: selectedFilters[categoryName]?.contains(item.name),
                    onChanged: (isSelected) {
                      _toggleFilter(categoryName, item.name);
                    },
                  );
                }),
            SizedBox(height: 20),
            if(option.options!=null )
            ...[
              CommonDivider(paddingValue: 0,),
              SizedBox(height: 20),
            ],

          ],
        )
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
              color: isOptionSelected ? colorScheme.iconWhite : Colors.transparent,
              border: Border.all(
                color: isOptionSelected
                    ? colorScheme.iconWhite
                    : colorScheme.textDisabled,

              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: isOptionSelected
                ? Center(
                    child: Icon(Icons.done, size: 12, color: context.colorScheme.primaryBlack),
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
              backgroundColor: colorScheme.elevation1,
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

    bool isAllSelected(String categoryName, int categoryIndex) {
      final category = categories[categoryIndex];

      final totalOptions = category.options.fold<int>(0, (sum, filter) {
        if (filter.options != null && filter.options!.isNotEmpty) {
          return sum + filter.options!.length; // count children
        }
        return sum + 1; // count parent if no children
      });

      final selectedCount = selectedFilters[categoryName]?.length ?? 0;
      print("isAllSelected: " +category.name);
      print(selectedCount);
      print(totalOptions);
      return selectedCount == totalOptions;
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
  final List<Option>? options;
  final String? id;
  final String name;

  FilterOption({
    required this.name,
     this.options,
    this.id,
  });
}

class Option {
  final String name;
  final String? id;

  Option({
    required this.name,
    this.id,
  });
}

